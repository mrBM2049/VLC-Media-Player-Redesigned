#ifndef VLC_BRIDGE_H
#define VLC_BRIDGE_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include "hardware_surface.h"

#if defined(_WIN32) || defined(__CYGWIN__)
  #ifdef VLC_BRIDGE_BUILD_SHARED
    #define VLC_BRIDGE_API __declspec(dllexport)
  #else
    #define VLC_BRIDGE_API __declspec(dllimport)
  #endif
#else
  #if __GNUC__ >= 4
    #define VLC_BRIDGE_API __attribute__((visibility("default")))
  #else
    #define VLC_BRIDGE_API
  #endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

/**
 * VLC Modern Player Playback States
 */
typedef enum vlc_player_state_e {
    VLC_PLAYER_STATE_IDLE = 0,
    VLC_PLAYER_STATE_OPENING = 1,
    VLC_PLAYER_STATE_BUFFERING = 2,
    VLC_PLAYER_STATE_PLAYING = 3,
    VLC_PLAYER_STATE_PAUSED = 4,
    VLC_PLAYER_STATE_STOPPING = 5,
    VLC_PLAYER_STATE_STOPPED = 6,
    VLC_PLAYER_STATE_ENDED = 7,
    VLC_PLAYER_STATE_ERROR = 8
} vlc_player_state_t;

/**
 * Event Types dispatched to cross-platform UI layer
 */
typedef enum vlc_event_type_e {
    VLC_EVENT_STATE_CHANGED = 1,
    VLC_EVENT_TIME_CHANGED = 2,
    VLC_EVENT_POSITION_CHANGED = 3,
    VLC_EVENT_LENGTH_CHANGED = 4,
    VLC_EVENT_VOLUME_CHANGED = 5,
    VLC_EVENT_MUTED_CHANGED = 6,
    VLC_EVENT_RATE_CHANGED = 7,
    VLC_EVENT_MEDIA_PARSED = 8,
    VLC_EVENT_ERROR = 9,
    VLC_EVENT_TRACKS_CHANGED = 10,
    VLC_EVENT_CHAPTER_CHANGED = 11
} vlc_event_type_t;

typedef struct vlc_event_payload_s {
    vlc_event_type_t type;
    int64_t int_value;
    float float_value;
    const char* string_value;
} vlc_event_payload_t;

typedef void (*vlc_event_callback_fn)(const vlc_event_payload_t* payload, void* user_data);
typedef void (*vlc_track_enumeration_callback_fn)(int id, const char* name, void* user_data);

/* Core Lifecycle */
VLC_BRIDGE_API int vlc_bridge_init(void);
VLC_BRIDGE_API void vlc_bridge_destroy(void);
VLC_BRIDGE_API bool vlc_bridge_is_initialized(void);

/* Media Management & Playback Controls */
VLC_BRIDGE_API int vlc_bridge_open(const char* mrl);
VLC_BRIDGE_API int vlc_bridge_play(void);
VLC_BRIDGE_API int vlc_bridge_pause(void);
VLC_BRIDGE_API int vlc_bridge_stop(void);
VLC_BRIDGE_API int vlc_bridge_toggle_play(void);

/* Time & Seeking */
VLC_BRIDGE_API int64_t vlc_bridge_get_time(void);
VLC_BRIDGE_API int vlc_bridge_set_time(int64_t time_ms);
VLC_BRIDGE_API int64_t vlc_bridge_get_length(void);
VLC_BRIDGE_API float vlc_bridge_get_position(void);
VLC_BRIDGE_API int vlc_bridge_set_position(float position);

/* Rate / Speed (0.25x - 4.0x) */
VLC_BRIDGE_API float vlc_bridge_get_rate(void);
VLC_BRIDGE_API int vlc_bridge_set_rate(float rate);

/* Volume (0 - 200% cone volume) */
VLC_BRIDGE_API int vlc_bridge_get_volume(void);
VLC_BRIDGE_API int vlc_bridge_set_volume(int volume);
VLC_BRIDGE_API bool vlc_bridge_get_mute(void);
VLC_BRIDGE_API int vlc_bridge_set_mute(bool mute);
VLC_BRIDGE_API int vlc_bridge_toggle_mute(void);

/* Current State */
VLC_BRIDGE_API vlc_player_state_t vlc_bridge_get_state(void);

/* Track Delays (Microsecond precision per libVLC spec) */
VLC_BRIDGE_API int64_t vlc_bridge_get_spu_delay(void);
VLC_BRIDGE_API int vlc_bridge_set_spu_delay(int64_t delay_us);
VLC_BRIDGE_API int64_t vlc_bridge_get_audio_delay(void);
VLC_BRIDGE_API int vlc_bridge_set_audio_delay(int64_t delay_us);

/* Track Management (Audio & Subtitles / SPU) */
VLC_BRIDGE_API int vlc_bridge_get_audio_track_count(void);
VLC_BRIDGE_API int vlc_bridge_get_audio_track(void);
VLC_BRIDGE_API int vlc_bridge_set_audio_track(int track_id);
VLC_BRIDGE_API void vlc_bridge_enumerate_audio_tracks(vlc_track_enumeration_callback_fn callback, void* user_data);

/* Audio Hardware Output Devices (OS CoreAudio, WASAPI, PulseAudio) */
typedef void (*vlc_device_enumeration_callback_fn)(const char* id, const char* name, void* user_data);
VLC_BRIDGE_API void vlc_bridge_enumerate_audio_devices(vlc_device_enumeration_callback_fn callback, void* user_data);
VLC_BRIDGE_API int vlc_bridge_set_audio_device(const char* device_id);
VLC_BRIDGE_API const char* vlc_bridge_get_audio_device(void);

VLC_BRIDGE_API int vlc_bridge_get_spu_count(void);
VLC_BRIDGE_API int vlc_bridge_get_spu_track(void);
VLC_BRIDGE_API int vlc_bridge_set_spu_track(int spu_id);
VLC_BRIDGE_API void vlc_bridge_enumerate_spu_tracks(vlc_track_enumeration_callback_fn callback, void* user_data);
VLC_BRIDGE_API int vlc_bridge_add_subtitle_file(const char* file_path, bool select);

/* Chapter & Title Navigation */
VLC_BRIDGE_API int vlc_bridge_get_chapter_count(void);
VLC_BRIDGE_API int vlc_bridge_get_chapter(void);
VLC_BRIDGE_API int vlc_bridge_set_chapter(int chapter);
VLC_BRIDGE_API int vlc_bridge_next_chapter(void);
VLC_BRIDGE_API int vlc_bridge_previous_chapter(void);

/* Frame Stepping & Snapshot Extraction */
VLC_BRIDGE_API int vlc_bridge_next_frame(void);
VLC_BRIDGE_API int vlc_bridge_take_snapshot(const char* filepath, unsigned int width, unsigned int height);

/* 10-Band Audio Equalizer (libvlc_audio_equalizer_t) */
VLC_BRIDGE_API unsigned int vlc_bridge_equalizer_get_preset_count(void);
VLC_BRIDGE_API const char* vlc_bridge_equalizer_get_preset_name(unsigned int index);
VLC_BRIDGE_API unsigned int vlc_bridge_equalizer_get_band_count(void);
VLC_BRIDGE_API float vlc_bridge_equalizer_get_band_frequency(unsigned int index);
VLC_BRIDGE_API int vlc_bridge_equalizer_set_preset(unsigned int preset_index);
VLC_BRIDGE_API int vlc_bridge_equalizer_set_preamp(float preamp);
VLC_BRIDGE_API float vlc_bridge_equalizer_get_preamp(void);
VLC_BRIDGE_API int vlc_bridge_equalizer_set_amp(unsigned int band, float amp);
VLC_BRIDGE_API float vlc_bridge_equalizer_get_amp(unsigned int band);
VLC_BRIDGE_API int vlc_bridge_equalizer_enable(bool enable);

/* Hardware Surface & Window Integration */
VLC_BRIDGE_API int vlc_bridge_set_nsobject(void* nsobject_view);
VLC_BRIDGE_API int vlc_bridge_set_hwnd(void* hwnd);
VLC_BRIDGE_API int vlc_bridge_set_android_context(void* awindow_handler);
VLC_BRIDGE_API int vlc_bridge_setup_gpu_surface(vlc_surface_type_t type, void* platform_context);
VLC_BRIDGE_API void vlc_bridge_set_gpu_frame_callback(vlc_surface_frame_callback_fn callback, void* user_data);
VLC_BRIDGE_API void vlc_bridge_get_video_dimensions(uint32_t* width, uint32_t* height);

/* Event Dispatch */
VLC_BRIDGE_API void vlc_bridge_set_event_callback(vlc_event_callback_fn callback, void* user_data);

/* Version & Backend Info */
VLC_BRIDGE_API const char* vlc_bridge_get_version(void);
VLC_BRIDGE_API bool vlc_bridge_has_native_vlc(void);

#ifdef __cplusplus
}
#endif

#endif /* VLC_BRIDGE_H */
