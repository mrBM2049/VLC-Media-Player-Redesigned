#ifndef HARDWARE_SURFACE_H
#define HARDWARE_SURFACE_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#if defined(_WIN32) || defined(__CYGWIN__)
  #ifdef VLC_BRIDGE_BUILD_SHARED
    #define VLC_SURFACE_API __declspec(dllexport)
  #else
    #define VLC_SURFACE_API __declspec(dllimport)
  #endif
#else
  #if __GNUC__ >= 4
    #define VLC_SURFACE_API __attribute__((visibility("default")))
  #else
    #define VLC_SURFACE_API
  #endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef enum vlc_surface_type_e {
    VLC_SURFACE_TYPE_NATIVE_WINDOW = 0,   /* Direct NSView / HWND / AWindow */
    VLC_SURFACE_TYPE_METAL = 1,           /* Apple Metal CVPixelBuffer / MTLTexture */
    VLC_SURFACE_TYPE_D3D11 = 2,           /* Windows Direct3D 11 ID3D11Texture2D */
    VLC_SURFACE_TYPE_ANDROID_SURFACE = 3, /* Android ANativeWindow / SurfaceTexture */
    VLC_SURFACE_TYPE_SOFTWARE_BGRA = 4    /* Aligned 32-bit BGRA host memory */
} vlc_surface_type_t;

typedef struct vlc_surface_video_frame_s {
    vlc_surface_type_t surface_type;
    uint32_t width;
    uint32_t height;
    uint32_t stride;
    void* buffer;               /* Aligned pixel memory, or CVPixelBufferRef / ID3D11Texture2D* */
    void* native_texture_handle;/* id<MTLTexture> or ID3D11ShaderResourceView* */
    int64_t pts_us;             /* Presentation timestamp in microseconds */
} vlc_surface_video_frame_t;

typedef void (*vlc_surface_frame_callback_fn)(const vlc_surface_video_frame_t* frame, void* user_data);

/* Hardware Surface Lifecycle */
VLC_SURFACE_API int vlc_surface_init(vlc_surface_type_t type, void* platform_context);
VLC_SURFACE_API void vlc_surface_destroy(void);
VLC_SURFACE_API bool vlc_surface_is_ready(void);
VLC_SURFACE_API vlc_surface_type_t vlc_surface_get_type(void);

/* Frame callback configuration (for Flutter Texture / Impeller composition) */
VLC_SURFACE_API void vlc_surface_set_frame_callback(vlc_surface_frame_callback_fn callback, void* user_data);

/* Dimensions query */
VLC_SURFACE_API void vlc_surface_get_dimensions(uint32_t* width, uint32_t* height);

/* Frame buffer lock/unlock/display primitives for libVLC callback wiring */
VLC_SURFACE_API void* vlc_surface_lock(void** planes);
VLC_SURFACE_API void vlc_surface_unlock(void* picture, void* const* planes);
VLC_SURFACE_API void vlc_surface_display(void* picture);
VLC_SURFACE_API unsigned int vlc_surface_format_setup(char* chroma, unsigned* width, unsigned* height, unsigned* pitches, unsigned* lines);
VLC_SURFACE_API void vlc_surface_format_cleanup(void);

#ifdef __cplusplus
}
#endif

#endif /* HARDWARE_SURFACE_H */
