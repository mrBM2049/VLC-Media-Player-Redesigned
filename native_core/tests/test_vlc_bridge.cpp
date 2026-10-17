#include "vlc_bridge.h"
#include <cassert>
#include <iostream>
#include <vector>
#include <string>

static std::vector<vlc_event_type_t> g_dispatched_events;

static void test_callback(const vlc_event_payload_t* payload, void* /*user_data*/) {
    if (payload) {
        g_dispatched_events.push_back(payload->type);
    }
}

static std::vector<std::pair<int, std::string>> g_enumerated_tracks;
static void test_track_callback(int id, const char* name, void* /*user_data*/) {
    g_enumerated_tracks.emplace_back(id, name ? name : "");
}

int main() {
    std::cout << "[TEST] Running native_core vlc_bridge tests..." << std::endl;

    // 1. Lifecycle
    assert(!vlc_bridge_is_initialized());
    int init_res = vlc_bridge_init();
    assert(init_res == 0);
    assert(vlc_bridge_is_initialized());
    assert(vlc_bridge_get_state() == VLC_PLAYER_STATE_IDLE);

    std::cout << "[INFO] Bound libVLC Version: " << vlc_bridge_get_version() << std::endl;
    assert(vlc_bridge_has_native_vlc());

    // 2. Event Callback
    vlc_bridge_set_event_callback(test_callback, nullptr);

    // 3. Media open and playback controls
    const char* test_mrl = "file:///dummy/video.mp4";
    assert(vlc_bridge_open(test_mrl) == 0);
    assert(vlc_bridge_get_state() == VLC_PLAYER_STATE_OPENING);

    assert(vlc_bridge_play() == 0);
    assert(vlc_bridge_get_state() == VLC_PLAYER_STATE_PLAYING);

    assert(vlc_bridge_pause() == 0);
    assert(vlc_bridge_get_state() == VLC_PLAYER_STATE_PAUSED);

    assert(vlc_bridge_toggle_play() == 0);
    assert(vlc_bridge_get_state() == VLC_PLAYER_STATE_PLAYING);

    assert(vlc_bridge_stop() == 0);
    assert(vlc_bridge_get_state() == VLC_PLAYER_STATE_STOPPED);

    // 4. Volume Cone Clamping (0% - 200%)
    vlc_bridge_set_volume(150);
    assert(vlc_bridge_get_volume() == 150);

    vlc_bridge_set_volume(250);
    assert(vlc_bridge_get_volume() == 200);

    vlc_bridge_set_volume(-20);
    assert(vlc_bridge_get_volume() == 0);

    // Mute toggle
    assert(!vlc_bridge_get_mute());
    vlc_bridge_set_mute(true);
    assert(vlc_bridge_get_mute());
    vlc_bridge_toggle_mute();
    assert(!vlc_bridge_get_mute());

    // 5. Rate Clamping (0.25x - 4.0x)
    vlc_bridge_set_rate(1.5f);
    assert(vlc_bridge_get_rate() == 1.5f);

    vlc_bridge_set_rate(0.1f);
    assert(vlc_bridge_get_rate() == 0.25f);

    vlc_bridge_set_rate(10.0f);
    assert(vlc_bridge_get_rate() == 4.0f);

    // 6. Track delays (microseconds)
    int64_t sample_spu_delay = 500000; // +500ms
    assert(vlc_bridge_set_spu_delay(sample_spu_delay) == 0);
    assert(vlc_bridge_get_spu_delay() == sample_spu_delay);

    int64_t sample_audio_delay = -250000; // -250ms
    assert(vlc_bridge_set_audio_delay(sample_audio_delay) == 0);
    assert(vlc_bridge_get_audio_delay() == sample_audio_delay);

    // 7. Track Selection (Audio & SPU)
    assert(vlc_bridge_set_audio_track(2) == 0);
    assert(vlc_bridge_get_audio_track() == 2);

    assert(vlc_bridge_set_spu_track(1) == 0);
    assert(vlc_bridge_get_spu_track() == 1);

    vlc_bridge_enumerate_audio_tracks(test_track_callback, nullptr);
    vlc_bridge_enumerate_spu_tracks(test_track_callback, nullptr);

    // 8. Chapters
    assert(vlc_bridge_set_chapter(3) == 0);
    assert(vlc_bridge_get_chapter() == 3);
    assert(vlc_bridge_next_chapter() == 0);
    assert(vlc_bridge_get_chapter() == 4);
    assert(vlc_bridge_previous_chapter() == 0);
    assert(vlc_bridge_get_chapter() == 3);

    // 9. 10-Band Equalizer
    unsigned int preset_count = vlc_bridge_equalizer_get_preset_count();
    std::cout << "[INFO] Equalizer Preset Count: " << preset_count << std::endl;
    assert(preset_count > 0);
    for (unsigned int i = 0; i < std::min(preset_count, 3u); ++i) {
        const char* name = vlc_bridge_equalizer_get_preset_name(i);
        std::cout << "  Preset " << i << ": " << (name ? name : "Unknown") << std::endl;
        assert(name != nullptr);
    }

    unsigned int band_count = vlc_bridge_equalizer_get_band_count();
    std::cout << "[INFO] Equalizer Band Count: " << band_count << std::endl;
    assert(band_count == 10); // Standard libVLC 10-band equalizer

    assert(vlc_bridge_equalizer_set_preset(0) == 0);
    assert(vlc_bridge_equalizer_set_preamp(3.5f) == 0);
    assert(vlc_bridge_equalizer_set_amp(0, 4.0f) == 0);
    assert(vlc_bridge_equalizer_set_amp(9, -2.5f) == 0);
    assert(vlc_bridge_equalizer_enable(true) == 0);
    assert(vlc_bridge_equalizer_enable(false) == 0);

    // 10. Frame Step & Snapshot API
    vlc_bridge_next_frame();
    vlc_bridge_take_snapshot("/tmp/test_snapshot.png", 0, 0);

    // Verify events were dispatched
    assert(!g_dispatched_events.empty());

    // Teardown
    vlc_bridge_destroy();
    assert(!vlc_bridge_is_initialized());

    std::cout << "[PASS] All native_core vlc_bridge tests passed successfully!" << std::endl;
    return 0;
}
