#include "hardware_surface.h"

#ifdef __ANDROID__
#include <android/native_window.h>
#include <android/native_window_jni.h>
#include <mutex>

namespace vlc_modern {

class AndroidHardwareSurface {
public:
    static AndroidHardwareSurface& instance() {
        static AndroidHardwareSurface s_instance;
        return s_instance;
    }

    int initialize(void* platform_context) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (platform_context) {
            m_window = static_cast<ANativeWindow*>(platform_context);
            ANativeWindow_acquire(m_window);
        }
        m_initialized = true;
        return 0;
    }

    void destroy() {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (m_window) {
            ANativeWindow_release(m_window);
            m_window = nullptr;
        }
        m_initialized = false;
    }

private:
    mutable std::mutex m_mutex;
    bool m_initialized{false};
    ANativeWindow* m_window{nullptr};
};

} // namespace vlc_modern
#endif
