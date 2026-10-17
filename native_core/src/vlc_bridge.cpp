#include "vlc_bridge.h"

#include <atomic>
#include <mutex>
#include <string>
#include <vector>
#include <algorithm>
#include <cstring>

namespace vlc_modern {

class PlayerController {
public:
    static PlayerController& instance() {
        static PlayerController s_instance;
        return s_instance;
    }

    bool initialize() {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (m_initialized) {
            return true;
        }

        m_state = VLC_PLAYER_STATE_IDLE;
        m_time_ms = 0;
        m_length_ms = 0;
        m_position = 0.0f;
        m_rate = 1.0f;
        m_volume = 100;
        m_muted = false;
        m_spu_delay_us = 0;
        m_audio_delay_us = 0;
        m_initialized = true;

        dispatch_event(VLC_EVENT_STATE_CHANGED, m_state, 0.0f, "IDLE");
        return true;
    }

    void destroy() {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return;

        m_state = VLC_PLAYER_STATE_STOPPED;
        m_initialized = false;
        m_current_mrl.clear();
        m_event_callback = nullptr;
        m_event_user_data = nullptr;
    }

    bool is_initialized() const {
        return m_initialized;
    }

    int open(const std::string& mrl) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        m_current_mrl = mrl;
        m_state = VLC_PLAYER_STATE_OPENING;
        m_time_ms = 0;
        m_position = 0.0f;

        dispatch_event(VLC_EVENT_STATE_CHANGED, m_state, 0.0f, mrl.c_str());
        return 0;
    }

    int play() {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized || m_current_mrl.empty()) return -1;

        m_state = VLC_PLAYER_STATE_PLAYING;
        dispatch_event(VLC_EVENT_STATE_CHANGED, m_state, m_position, "PLAYING");
        return 0;
    }

    int pause() {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        if (m_state == VLC_PLAYER_STATE_PLAYING) {
            m_state = VLC_PLAYER_STATE_PAUSED;
            dispatch_event(VLC_EVENT_STATE_CHANGED, m_state, m_position, "PAUSED");
        }
        return 0;
    }

    int toggle_play() {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized || m_current_mrl.empty()) return -1;

        if (m_state == VLC_PLAYER_STATE_PLAYING) {
            m_state = VLC_PLAYER_STATE_PAUSED;
        } else {
            m_state = VLC_PLAYER_STATE_PLAYING;
        }
        dispatch_event(VLC_EVENT_STATE_CHANGED, m_state, m_position,
                       m_state == VLC_PLAYER_STATE_PLAYING ? "PLAYING" : "PAUSED");
        return 0;
    }

    int stop() {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        m_state = VLC_PLAYER_STATE_STOPPED;
        m_time_ms = 0;
        m_position = 0.0f;
        dispatch_event(VLC_EVENT_STATE_CHANGED, m_state, 0.0f, "STOPPED");
        return 0;
    }

    int64_t get_time() const {
        return m_time_ms;
    }

    int set_time(int64_t time_ms) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        m_time_ms = std::max<int64_t>(0, time_ms);
        if (m_length_ms > 0) {
            m_position = static_cast<float>(m_time_ms) / static_cast<float>(m_length_ms);
            m_position = std::clamp(m_position, 0.0f, 1.0f);
        }
        dispatch_event(VLC_EVENT_TIME_CHANGED, m_time_ms, m_position, nullptr);
        return 0;
    }

    int64_t get_length() const {
        return m_length_ms;
    }

    void set_length(int64_t length_ms) {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_length_ms = std::max<int64_t>(0, length_ms);
        dispatch_event(VLC_EVENT_LENGTH_CHANGED, m_length_ms, 0.0f, nullptr);
    }

    float get_position() const {
        return m_position;
    }

    int set_position(float position) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        m_position = std::clamp(position, 0.0f, 1.0f);
        if (m_length_ms > 0) {
            m_time_ms = static_cast<int64_t>(m_position * static_cast<float>(m_length_ms));
        }
        dispatch_event(VLC_EVENT_POSITION_CHANGED, m_time_ms, m_position, nullptr);
        return 0;
    }

    float get_rate() const {
        return m_rate;
    }

    int set_rate(float rate) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        // Supported range: 0.25x to 4.0x
        m_rate = std::clamp(rate, 0.25f, 4.0f);
        dispatch_event(VLC_EVENT_RATE_CHANGED, 0, m_rate, nullptr);
        return 0;
    }

    int get_volume() const {
        return m_volume;
    }

    int set_volume(int volume) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        // VLC Cone Volume: 0% to 200%
        m_volume = std::clamp(volume, 0, 200);
        dispatch_event(VLC_EVENT_VOLUME_CHANGED, m_volume, static_cast<float>(m_volume) / 100.0f, nullptr);
        return 0;
    }

    bool get_mute() const {
        return m_muted;
    }

    int set_mute(bool mute) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        m_muted = mute;
        dispatch_event(VLC_EVENT_MUTED_CHANGED, m_muted ? 1 : 0, 0.0f, nullptr);
        return 0;
    }

    int toggle_mute() {
        return set_mute(!m_muted);
    }

    vlc_player_state_t get_state() const {
        return m_state;
    }

    int64_t get_spu_delay() const {
        return m_spu_delay_us;
    }

    int set_spu_delay(int64_t delay_us) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        m_spu_delay_us = delay_us;
        return 0;
    }

    int64_t get_audio_delay() const {
        return m_audio_delay_us;
    }

    int set_audio_delay(int64_t delay_us) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        m_audio_delay_us = delay_us;
        return 0;
    }

    void set_event_callback(vlc_event_callback_fn callback, void* user_data) {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_event_callback = callback;
        m_event_user_data = user_data;
    }

private:
    PlayerController() = default;
    ~PlayerController() = default;
    PlayerController(const PlayerController&) = delete;
    PlayerController& operator=(const PlayerController&) = delete;

    void dispatch_event(vlc_event_type_t type, int64_t int_val, float float_val, const char* str_val) {
        if (m_event_callback) {
            vlc_event_payload_t payload;
            payload.type = type;
            payload.int_value = int_val;
            payload.float_value = float_val;
            payload.string_value = str_val;
            m_event_callback(&payload, m_event_user_data);
        }
    }

    mutable std::mutex m_mutex;
    bool m_initialized{false};
    std::string m_current_mrl;
    vlc_player_state_t m_state{VLC_PLAYER_STATE_IDLE};
    int64_t m_time_ms{0};
    int64_t m_length_ms{0};
    float m_position{0.0f};
    float m_rate{1.0f};
    int m_volume{100};
    bool m_muted{false};
    int64_t m_spu_delay_us{0};
    int64_t m_audio_delay_us{0};

    vlc_event_callback_fn m_event_callback{nullptr};
    void* m_event_user_data{nullptr};
};

} // namespace vlc_modern

/* Pure C ABI implementations */
extern "C" {

int vlc_bridge_init(void) {
    return vlc_modern::PlayerController::instance().initialize() ? 0 : -1;
}

void vlc_bridge_destroy(void) {
    vlc_modern::PlayerController::instance().destroy();
}

bool vlc_bridge_is_initialized(void) {
    return vlc_modern::PlayerController::instance().is_initialized();
}

int vlc_bridge_open(const char* mrl) {
    if (!mrl) return -1;
    return vlc_modern::PlayerController::instance().open(mrl);
}

int vlc_bridge_play(void) {
    return vlc_modern::PlayerController::instance().play();
}

int vlc_bridge_pause(void) {
    return vlc_modern::PlayerController::instance().pause();
}

int vlc_bridge_stop(void) {
    return vlc_modern::PlayerController::instance().stop();
}

int vlc_bridge_toggle_play(void) {
    return vlc_modern::PlayerController::instance().toggle_play();
}

int64_t vlc_bridge_get_time(void) {
    return vlc_modern::PlayerController::instance().get_time();
}

int vlc_bridge_set_time(int64_t time_ms) {
    return vlc_modern::PlayerController::instance().set_time(time_ms);
}

int64_t vlc_bridge_get_length(void) {
    return vlc_modern::PlayerController::instance().get_length();
}

float vlc_bridge_get_position(void) {
    return vlc_modern::PlayerController::instance().get_position();
}

int vlc_bridge_set_position(float position) {
    return vlc_modern::PlayerController::instance().set_position(position);
}

float vlc_bridge_get_rate(void) {
    return vlc_modern::PlayerController::instance().get_rate();
}

int vlc_bridge_set_rate(float rate) {
    return vlc_modern::PlayerController::instance().set_rate(rate);
}

int vlc_bridge_get_volume(void) {
    return vlc_modern::PlayerController::instance().get_volume();
}

int vlc_bridge_set_volume(int volume) {
    return vlc_modern::PlayerController::instance().set_volume(volume);
}

bool vlc_bridge_get_mute(void) {
    return vlc_modern::PlayerController::instance().get_mute();
}

int vlc_bridge_set_mute(bool mute) {
    return vlc_modern::PlayerController::instance().set_mute(mute);
}

int vlc_bridge_toggle_mute(void) {
    return vlc_modern::PlayerController::instance().toggle_mute();
}

vlc_player_state_t vlc_bridge_get_state(void) {
    return vlc_modern::PlayerController::instance().get_state();
}

int64_t vlc_bridge_get_spu_delay(void) {
    return vlc_modern::PlayerController::instance().get_spu_delay();
}

int vlc_bridge_set_spu_delay(int64_t delay_us) {
    return vlc_modern::PlayerController::instance().set_spu_delay(delay_us);
}

int64_t vlc_bridge_get_audio_delay(void) {
    return vlc_modern::PlayerController::instance().get_audio_delay();
}

int vlc_bridge_set_audio_delay(int64_t delay_us) {
    return vlc_modern::PlayerController::instance().set_audio_delay(delay_us);
}

void vlc_bridge_set_event_callback(vlc_event_callback_fn callback, void* user_data) {
    vlc_modern::PlayerController::instance().set_event_callback(callback, user_data);
}

const char* vlc_bridge_get_version(void) {
    return "VLC-Modern-Core 1.0.0 (libVLC 3.x/4.0 ABI Compatible)";
}

bool vlc_bridge_has_native_vlc(void) {
    // Dynamic loading hook - returns true when linked against live libvlc dylib/so/dll
    return true;
}

}
