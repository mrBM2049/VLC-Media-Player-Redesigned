#include "hardware_surface.h"

#ifdef _WIN32
#include <d3d11.h>
#include <dxgi1_2.h>
#include <mutex>

namespace vlc_modern {

class D3D11HardwareSurface {
public:
    static D3D11HardwareSurface& instance() {
        static D3D11HardwareSurface s_instance;
        return s_instance;
    }

    int initialize(void* platform_context) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (m_initialized) return 0;

        if (platform_context) {
            m_device = static_cast<ID3D11Device*>(platform_context);
            m_device->AddRef();
        } else {
            D3D_FEATURE_LEVEL feature_levels[] = {
                D3D_FEATURE_LEVEL_11_1,
                D3D_FEATURE_LEVEL_11_0
            };
            D3D_FEATURE_LEVEL feature_level;
            HRESULT hr = D3D11CreateDevice(
                nullptr,
                D3D_DRIVER_TYPE_HARDWARE,
                nullptr,
                D3D11_CREATE_DEVICE_BGRA_SUPPORT,
                feature_levels,
                2,
                D3D11_SDK_VERSION,
                &m_device,
                &feature_level,
                &m_context
            );
            if (FAILED(hr)) return -1;
        }

        m_width = 1920;
        m_height = 1080;
        m_initialized = true;
        return 0;
    }

    void destroy() {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return;

        if (m_texture) {
            m_texture->Release();
            m_texture = nullptr;
        }
        if (m_context) {
            m_context->Release();
            m_context = nullptr;
        }
        if (m_device) {
            m_device->Release();
            m_device = nullptr;
        }
        m_initialized = false;
    }

private:
    mutable std::mutex m_mutex;
    bool m_initialized{false};
    ID3D11Device* m_device{nullptr};
    ID3D11DeviceContext* m_context{nullptr};
    ID3D11Texture2D* m_texture{nullptr};
    uint32_t m_width{1920};
    uint32_t m_height{1080};
};

} // namespace vlc_modern
#endif

