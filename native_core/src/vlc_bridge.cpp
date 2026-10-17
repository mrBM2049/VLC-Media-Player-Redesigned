#include "vlc_bridge.h"
#include <vlc/vlc.h>

#include <atomic>
#include <mutex>
#include <string>
#include <vector>
#include <algorithm>
#include <cstring>
#include <cstdlib>
#include <iostream>

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

#ifdef __APPLE__
        // Automatically discover plugins in standard macOS bundle if not already set
        const char* current_plugin_path = std::getenv("VLC_PLUGIN_PATH");
        if (!current_plugin_path) {
            setenv("VLC_PLUGIN_PATH", "/Applications/VLC.app/Contents/MacOS/plugins", 0);
        }
#endif

        const char* const vlc_args[] = {
            "--no-video-title-show",
            "--no-snapshot-preview",
            "--no-osd",
            "--network-caching=1500",
            "--sub-autodetect-fuzzy=2"
        };
        int argc = sizeof(vlc_args) / sizeof(vlc_args[0]);

        m_vlc_instance = libvlc_new(argc, vlc_args);
        if (m_vlc_instance) {
            m_vlc_player = libvlc_media_player_new(m_vlc_instance);
            if (m_vlc_player) {
                attach_vlc_events();
            }
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

        if (m_vlc_player) {
            libvlc_audio_set_volume(m_vlc_player, m_volume);
        }

        dispatch_event(VLC_EVENT_STATE_CHANGED, m_state, 0.0f, "IDLE");
        return true;
    }

    void destroy() {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return;

        if (m_vlc_player) {
            detach_vlc_events();
            libvlc_media_player_stop(m_vlc_player);
            libvlc_media_player_release(m_vlc_player);
            m_vlc_player = nullptr;
        }

        if (m_current_media) {
            libvlc_media_release(m_current_media);
            m_current_media = nullptr;
        }

        if (m_vlc_instance) {
            libvlc_release(m_vlc_instance);
            m_vlc_instance = nullptr;
        }

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

        if (m_vlc_instance && m_vlc_player) {
            if (m_current_media) {
                libvlc_media_release(m_current_media);
                m_current_media = nullptr;
            }

            if (mrl.find("://") != std::string::npos) {
                m_current_media = libvlc_media_new_location(m_vlc_instance, mrl.c_str());
            } else {
                m_current_media = libvlc_media_new_path(m_vlc_instance, mrl.c_str());
            }

            if (m_current_media) {
                libvlc_media_player_set_media(m_vlc_player, m_current_media);
            }
        }

        dispatch_event(VLC_EVENT_STATE_CHANGED, m_state, 0.0f, mrl.c_str());
        return 0;
    }

    int play() {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized || m_current_mrl.empty()) return -1;

        if (m_vlc_player) {
            libvlc_media_player_play(m_vlc_player);
        }

        m_state = VLC_PLAYER_STATE_PLAYING;
        dispatch_event(VLC_EVENT_STATE_CHANGED, m_state, m_position, "PLAYING");
        return 0;
    }

    int pause() {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        if (m_vlc_player) {
            libvlc_media_player_set_pause(m_vlc_player, 1);
        }

        if (m_state == VLC_PLAYER_STATE_PLAYING) {
            m_state = VLC_PLAYER_STATE_PAUSED;
            dispatch_event(VLC_EVENT_STATE_CHANGED, m_state, m_position, "PAUSED");
        }
        return 0;
    }

    int toggle_play() {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized || m_current_mrl.empty()) return -1;

        if (m_vlc_player) {
            libvlc_media_player_pause(m_vlc_player);
        }

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

        if (m_vlc_player) {
            libvlc_media_player_stop(m_vlc_player);
        }

        m_state = VLC_PLAYER_STATE_STOPPED;
        m_time_ms = 0;
        m_position = 0.0f;
        dispatch_event(VLC_EVENT_STATE_CHANGED, m_state, 0.0f, "STOPPED");
        return 0;
    }

    int64_t get_time() const {
        if (m_vlc_player) {
            libvlc_time_t t = libvlc_media_player_get_time(m_vlc_player);
            if (t >= 0) return t;
        }
        return m_time_ms;
    }

    int set_time(int64_t time_ms) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        m_time_ms = std::max<int64_t>(0, time_ms);
        if (m_vlc_player) {
            libvlc_media_player_set_time(m_vlc_player, static_cast<libvlc_time_t>(m_time_ms));
        }

        if (m_length_ms > 0) {
            m_position = static_cast<float>(m_time_ms) / static_cast<float>(m_length_ms);
            m_position = std::clamp(m_position, 0.0f, 1.0f);
        }
        dispatch_event(VLC_EVENT_TIME_CHANGED, m_time_ms, m_position, nullptr);
        return 0;
    }

    int64_t get_length() const {
        if (m_vlc_player) {
            libvlc_time_t len = libvlc_media_player_get_length(m_vlc_player);
            if (len >= 0) return len;
        }
        return m_length_ms;
    }

    void set_length(int64_t length_ms) {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_length_ms = std::max<int64_t>(0, length_ms);
        dispatch_event(VLC_EVENT_LENGTH_CHANGED, m_length_ms, 0.0f, nullptr);
    }

    float get_position() const {
        if (m_vlc_player) {
            float pos = libvlc_media_player_get_position(m_vlc_player);
            if (pos >= 0.0f) return pos;
        }
        return m_position;
    }

    int set_position(float position) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        m_position = std::clamp(position, 0.0f, 1.0f);
        if (m_vlc_player) {
            libvlc_media_player_set_position(m_vlc_player, m_position);
        }

        if (m_length_ms > 0) {
            m_time_ms = static_cast<int64_t>(m_position * static_cast<float>(m_length_ms));
        }
        dispatch_event(VLC_EVENT_POSITION_CHANGED, m_time_ms, m_position, nullptr);
        return 0;
    }

    float get_rate() const {
        if (m_vlc_player) {
            float r = libvlc_media_player_get_rate(m_vlc_player);
            if (r > 0.0f) return r;
        }
        return m_rate;
    }

    int set_rate(float rate) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        m_rate = std::clamp(rate, 0.25f, 4.0f);
        if (m_vlc_player) {
            libvlc_media_player_set_rate(m_vlc_player, m_rate);
        }
        dispatch_event(VLC_EVENT_RATE_CHANGED, 0, m_rate, nullptr);
        return 0;
    }

    int get_volume() const {
        if (m_vlc_player) {
            int vol = libvlc_audio_get_volume(m_vlc_player);
            if (vol >= 0) return vol;
        }
        return m_volume;
    }

    int set_volume(int volume) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        m_volume = std::clamp(volume, 0, 200);
        if (m_vlc_player) {
            libvlc_audio_set_volume(m_vlc_player, m_volume);
        }
        dispatch_event(VLC_EVENT_VOLUME_CHANGED, m_volume, static_cast<float>(m_volume) / 100.0f, nullptr);
        return 0;
    }

    bool get_mute() const {
        if (m_vlc_player) {
            int mute = libvlc_audio_get_mute(m_vlc_player);
            if (mute >= 0) return mute != 0;
        }
        return m_muted;
    }

    int set_mute(bool mute) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        m_muted = mute;
        if (m_vlc_player) {
            libvlc_audio_set_mute(m_vlc_player, m_muted ? 1 : 0);
        }
        dispatch_event(VLC_EVENT_MUTED_CHANGED, m_muted ? 1 : 0, 0.0f, nullptr);
        return 0;
    }

    int toggle_mute() {
        return set_mute(!m_muted);
    }

    vlc_player_state_t get_state() const {
        if (m_vlc_player) {
            libvlc_state_t st = libvlc_media_player_get_state(m_vlc_player);
            switch (st) {
                case libvlc_NothingSpecial: return m_state;
                case libvlc_Opening:        return VLC_PLAYER_STATE_OPENING;
                case libvlc_Buffering:      return VLC_PLAYER_STATE_BUFFERING;
                case libvlc_Playing:        return VLC_PLAYER_STATE_PLAYING;
                case libvlc_Paused:         return VLC_PLAYER_STATE_PAUSED;
                case libvlc_Stopped:        return VLC_PLAYER_STATE_STOPPED;
                case libvlc_Ended:          return VLC_PLAYER_STATE_ENDED;
                case libvlc_Error:          return VLC_PLAYER_STATE_ERROR;
            }
        }
        return m_state;
    }

    int64_t get_spu_delay() const {
        if (m_vlc_player) {
            int64_t d = libvlc_video_get_spu_delay(m_vlc_player);
            if (d != 0) return d;
        }
        return m_spu_delay_us;
    }

    int set_spu_delay(int64_t delay_us) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        m_spu_delay_us = delay_us;
        if (m_vlc_player) {
            libvlc_video_set_spu_delay(m_vlc_player, delay_us);
        }
        return 0;
    }

    int64_t get_audio_delay() const {
        if (m_vlc_player) {
            int64_t d = libvlc_audio_get_delay(m_vlc_player);
            if (d != 0) return d;
        }
        return m_audio_delay_us;
    }

    int set_audio_delay(int64_t delay_us) {
        std::lock_guard<std::mutex> lock(m_mutex);
        if (!m_initialized) return -1;

        m_audio_delay_us = delay_us;
        if (m_vlc_player) {
            libvlc_audio_set_delay(m_vlc_player, delay_us);
        }
        return 0;
    }

    void set_event_callback(vlc_event_callback_fn callback, void* user_data) {
        std::lock_guard<std::mutex> lock(m_mutex);
        m_event_callback = callback;
        m_event_user_data = user_data;
    }

    bool has_native_vlc() const {
        return m_vlc_instance != nullptr && m_vlc_player != nullptr;
    }

private:
    PlayerController() = default;
    ~PlayerController() {
        destroy();
    }
    PlayerController(const PlayerController&) = delete;
    PlayerController& operator=(const PlayerController&) = delete;

    static void handle_vlc_event(const libvlc_event_t* p_event, void* p_data) {
        auto* self = static_cast<PlayerController*>(p_data);
        if (!self || !p_event) return;

        switch (p_event->type) {
            case libvlc_MediaPlayerPlaying:
                self->dispatch_event(VLC_EVENT_STATE_CHANGED, VLC_PLAYER_STATE_PLAYING, 0.0f, "PLAYING");
                break;
            case libvlc_MediaPlayerPaused:
                self->dispatch_event(VLC_EVENT_STATE_CHANGED, VLC_PLAYER_STATE_PAUSED, 0.0f, "PAUSED");
                break;
            case libvlc_MediaPlayerStopped:
                self->dispatch_event(VLC_EVENT_STATE_CHANGED, VLC_PLAYER_STATE_STOPPED, 0.0f, "STOPPED");
                break;
            case libvlc_MediaPlayerTimeChanged:
                self->dispatch_event(VLC_EVENT_TIME_CHANGED, p_event->u.media_player_time_changed.new_time, 0.0f, nullptr);
                break;
            case libvlc_MediaPlayerPositionChanged:
                self->dispatch_event(VLC_EVENT_POSITION_CHANGED, 0, p_event->u.media_player_position_changed.new_position, nullptr);
                break;
            case libvlc_MediaPlayerLengthChanged:
                self->dispatch_event(VLC_EVENT_LENGTH_CHANGED, p_event->u.media_player_length_changed.new_length, 0.0f, nullptr);
                break;
            case libvlc_MediaPlayerEncounteredError:
                self->dispatch_event(VLC_EVENT_ERROR, 0, 0.0f, "VLC Media Player Error");
                break;
            default:
                break;
        }
    }

    void attach_vlc_events() {
        if (!m_vlc_player) return;
        libvlc_event_manager_t* em = libvlc_media_player_event_manager(m_vlc_player);
        if (!em) return;

        libvlc_event_attach(em, libvlc_MediaPlayerPlaying, handle_vlc_event, this);
        libvlc_event_attach(em, libvlc_MediaPlayerPaused, handle_vlc_event, this);
        libvlc_event_attach(em, libvlc_MediaPlayerStopped, handle_vlc_event, this);
        libvlc_event_attach(em, libvlc_MediaPlayerTimeChanged, handle_vlc_event, this);
        libvlc_event_attach(em, libvlc_MediaPlayerPositionChanged, handle_vlc_event, this);
        libvlc_event_attach(em, libvlc_MediaPlayerLengthChanged, handle_vlc_event, this);
        libvlc_event_attach(em, libvlc_MediaPlayerEncounteredError, handle_vlc_event, this);
    }

    void detach_vlc_events() {
        if (!m_vlc_player) return;
        libvlc_event_manager_t* em = libvlc_media_player_event_manager(m_vlc_player);
        if (!em) return;

        libvlc_event_detach(em, libvlc_MediaPlayerPlaying, handle_vlc_event, this);
        libvlc_event_detach(em, libvlc_MediaPlayerPaused, handle_vlc_event, this);
        libvlc_event_detach(em, libvlc_MediaPlayerStopped, handle_vlc_event, this);
        libvlc_event_detach(em, libvlc_MediaPlayerTimeChanged, handle_vlc_event, this);
        libvlc_event_detach(em, libvlc_MediaPlayerPositionChanged, handle_vlc_event, this);
        libvlc_event_detach(em, libvlc_MediaPlayerLengthChanged, handle_vlc_event, this);
        libvlc_event_detach(em, libvlc_MediaPlayerEncounteredError, handle_vlc_event, this);
    }

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

    libvlc_instance_t* m_vlc_instance{nullptr};
    libvlc_media_player_t* m_vlc_player{nullptr};
    libvlc_media_t* m_current_media{nullptr};

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
    return libvlc_get_version();
}

bool vlc_bridge_has_native_vlc(void) {
    return vlc_modern::PlayerController::instance().has_native_vlc();
}

}
