#include "hardware_surface.h"

#ifdef __APPLE__
#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <Metal/Metal.h>
#include <mutex>
#include <atomic>
#include <vector>

namespace vlc_modern {

class MetalHardwareSurface {
public:
    static MetalHardwareSurface& instance() {
        static MetalHardwareSurface s_instance;
        return s_instance;
    }

    int initialize(void* platform_context) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (m_initialized) return 0;

        if (platform_context) {
            m_device = (__bridge id<MTLDevice>)platform_context;
        } else {
            m_device = MTLCreateSystemDefaultDevice();
        }

        if (!m_device) return -1;

        CVReturn err = CVMetalTextureCacheCreate(
            kCFAllocatorDefault,
            nil,
            m_device,
            nil,
            &m_texture_cache
        );
        if (err != kCVReturnSuccess) return -1;

        m_width = 1920;
        m_height = 1080;
        m_stride = m_width * 4;
        create_pixel_buffer_pool(m_width, m_height);

        m_initialized = true;
        return 0;
    }

    void destroy() {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return;

        if (m_texture_cache) {
            CFRelease(m_texture_cache);
            m_texture_cache = nullptr;
        }

        if (m_pool) {
            CVPixelBufferPoolRelease(m_pool);
            m_pool = nullptr;
        }

        if (m_current_buffer) {
            CVPixelBufferRelease(m_current_buffer);
            m_current_buffer = nullptr;
        }

        m_device = nil;
        m_initialized = false;
        m_frame_callback = nullptr;
        m_user_data = nullptr;
    }

    bool is_ready() const {
        return m_initialized;
    }

    void set_callback(vlc_surface_frame_callback_fn cb, void* user_data) {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_frame_callback = cb;
        m_user_data = user_data;
    }

    void get_dimensions(uint32_t* width, uint32_t* height) const {
        if (width) *width = m_width;
        if (height) *height = m_height;
    }

    unsigned int setup_format(unsigned* width, unsigned* height, unsigned* pitches, unsigned* lines) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (width && *width > 0) m_width = *width;
        if (height && *height > 0) m_height = *height;

        m_stride = m_width * 4;
        if (pitches) pitches[0] = m_stride;
        if (lines) lines[0] = m_height;

        create_pixel_buffer_pool(m_width, m_height);
        return 1; // 1 plane (32-bit BGRA)
    }

    void* lock_frame(void** planes) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_pool || !planes) return nullptr;

        CVPixelBufferRef pixel_buffer = nullptr;
        CVReturn err = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, m_pool, &pixel_buffer);
        if (err != kCVReturnSuccess || !pixel_buffer) return nullptr;

        CVPixelBufferLockBaseAddress(pixel_buffer, 0);
        void* base_address = CVPixelBufferGetBaseAddress(pixel_buffer);
        planes[0] = base_address;

        return (void*)pixel_buffer;
    }

    void unlock_frame(void* picture, void* const* /*planes*/) {
        if (!picture) return;
        CVPixelBufferRef pixel_buffer = (CVPixelBufferRef)picture;
        CVPixelBufferUnlockBaseAddress(pixel_buffer, 0);
    }

    void display_frame(void* picture) {
        if (!picture) return;
        CVPixelBufferRef pixel_buffer = (CVPixelBufferRef)picture;

        id<MTLTexture> mtl_texture = nil;
        if (m_texture_cache) {
            CVMetalTextureRef cv_texture = nullptr;
            size_t w = CVPixelBufferGetWidth(pixel_buffer);
            size_t h = CVPixelBufferGetHeight(pixel_buffer);

            CVReturn err = CVMetalTextureCacheCreateTextureFromImage(
                kCFAllocatorDefault,
                m_texture_cache,
                pixel_buffer,
                nil,
                MTLPixelFormatBGRA8Unorm,
                w,
                h,
                0,
                &cv_texture
            );
            if (err == kCVReturnSuccess && cv_texture) {
                mtl_texture = CVMetalTextureGetTexture(cv_texture);
                CFRelease(cv_texture);
            }
        }

        vlc_surface_video_frame_t frame;
        frame.surface_type = VLC_SURFACE_TYPE_METAL;
        frame.width = m_width;
        frame.height = m_height;
        frame.stride = m_stride;
        frame.buffer = (void*)pixel_buffer;
        frame.native_texture_handle = (__bridge void*)mtl_texture;
        frame.pts_us = 0;

        if (m_frame_callback) {
            m_frame_callback(&frame, m_user_data);
        }

        CVPixelBufferRelease(pixel_buffer);
    }

private:
    MetalHardwareSurface() = default;
    ~MetalHardwareSurface() {
        destroy();
    }

    void create_pixel_buffer_pool(uint32_t width, uint32_t height) {
        if (m_pool) {
            CVPixelBufferPoolRelease(m_pool);
            m_pool = nullptr;
        }

        NSDictionary* pool_attrs = @{
            (id)kCVPixelBufferPoolMinimumBufferCountKey: @(3)
        };

        NSDictionary* buffer_attrs = @{
            (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
            (id)kCVPixelBufferWidthKey: @(width),
            (id)kCVPixelBufferHeightKey: @(height),
            (id)kCVPixelBufferBytesPerRowAlignmentKey: @(64),
            (id)kCVPixelBufferMetalCompatibilityKey: @(YES)
        };

        CVPixelBufferPoolCreate(
            kCFAllocatorDefault,
            (__bridge CFDictionaryRef)pool_attrs,
            (__bridge CFDictionaryRef)buffer_attrs,
            &m_pool
        );
    }

    mutable std::mutex m_mutex;
    bool m_initialized{false};
    id<MTLDevice> m_device{nil};
    CVMetalTextureCacheRef m_texture_cache{nullptr};
    CVPixelBufferPoolRef m_pool{nullptr};
    CVPixelBufferRef m_current_buffer{nullptr};

    uint32_t m_width{1920};
    uint32_t m_height{1080};
    uint32_t m_stride{1920 * 4};

    vlc_surface_frame_callback_fn m_frame_callback{nullptr};
    void* m_user_data{nullptr};
};

} // namespace vlc_modern
#endif

/* C ABI Hardware Surface dispatchers */
extern "C" {

static vlc_surface_type_t g_surface_type = VLC_SURFACE_TYPE_NATIVE_WINDOW;

int vlc_surface_init(vlc_surface_type_t type, void* platform_context) {
    g_surface_type = type;
#ifdef __APPLE__
    if (type == VLC_SURFACE_TYPE_METAL) {
        return vlc_modern::MetalHardwareSurface::instance().initialize(platform_context);
    }
#endif
    return 0;
}

void vlc_surface_destroy(void) {
#ifdef __APPLE__
    if (g_surface_type == VLC_SURFACE_TYPE_METAL) {
        vlc_modern::MetalHardwareSurface::instance().destroy();
    }
#endif
}

bool vlc_surface_is_ready(void) {
#ifdef __APPLE__
    if (g_surface_type == VLC_SURFACE_TYPE_METAL) {
        return vlc_modern::MetalHardwareSurface::instance().is_ready();
    }
#endif
    return true;
}

vlc_surface_type_t vlc_surface_get_type(void) {
    return g_surface_type;
}

void vlc_surface_set_frame_callback(vlc_surface_frame_callback_fn callback, void* user_data) {
#ifdef __APPLE__
    if (g_surface_type == VLC_SURFACE_TYPE_METAL) {
        vlc_modern::MetalHardwareSurface::instance().set_callback(callback, user_data);
    }
#endif
}

void vlc_surface_get_dimensions(uint32_t* width, uint32_t* height) {
#ifdef __APPLE__
    if (g_surface_type == VLC_SURFACE_TYPE_METAL) {
        vlc_modern::MetalHardwareSurface::instance().get_dimensions(width, height);
        return;
    }
#endif
    if (width) *width = 1920;
    if (height) *height = 1080;
}

void* vlc_surface_lock(void** planes) {
#ifdef __APPLE__
    if (g_surface_type == VLC_SURFACE_TYPE_METAL) {
        return vlc_modern::MetalHardwareSurface::instance().lock_frame(planes);
    }
#endif
    return nullptr;
}

void vlc_surface_unlock(void* picture, void* const* planes) {
#ifdef __APPLE__
    if (g_surface_type == VLC_SURFACE_TYPE_METAL) {
        vlc_modern::MetalHardwareSurface::instance().unlock_frame(picture, planes);
    }
#endif
}

void vlc_surface_display(void* picture) {
#ifdef __APPLE__
    if (g_surface_type == VLC_SURFACE_TYPE_METAL) {
        vlc_modern::MetalHardwareSurface::instance().display_frame(picture);
    }
#endif
}

unsigned int vlc_surface_format_setup(char* chroma, unsigned* width, unsigned* height, unsigned* pitches, unsigned* lines) {
    if (chroma) {
        // 32-bit BGRA for direct Metal / D3D / GPU texture compatibility
        memcpy(chroma, "BGRA", 4);
    }
#ifdef __APPLE__
    if (g_surface_type == VLC_SURFACE_TYPE_METAL) {
        return vlc_modern::MetalHardwareSurface::instance().setup_format(width, height, pitches, lines);
    }
#endif
    if (pitches && width) pitches[0] = (*width) * 4;
    if (lines && height) lines[0] = *height;
    return 1;
}

void vlc_surface_format_cleanup(void) {
    // Cleanup picture buffers format if needed
}

}
