# Handoff Log 011: Task 3.2 — Audio Quick Popup & Hardware Output Device Selector

**Date:** 2026-10-18  
**Phase:** Phase 3 — Quick Popups, Batch Subtitle Auto-Matcher & 4-Tab Inspector Sidebar  
**Task:** 3.2 Build AudioQuickPopup combining embedded Audio Tracks (`libvlc_audio_set_track`) and live OS Hardware Output Device Selector (`libvlc_audio_output_device_set`)  
**Status:** Complete  

---

## 1. What Was Built
1. **Audio Models (`lib/models/audio_models.dart`)**:
   - `VlcAudioTrack`: id, name, language, codec, channels (e.g. 5.1 Surround, Stereo, Dolby Atmos), isSelected.
   - `VlcAudioOutputDevice`: id, name, description, isDefault, isSelected (e.g. System Default, Built-in Speakers, External DAC).

2. **Native C ABI Bridge (`native_core/include/vlc_bridge.h`, `native_core/src/vlc_bridge.cpp`)**:
   - `vlc_device_enumeration_callback_fn`: Function pointer callback for enumerating audio hardware devices.
   - `vlc_bridge_enumerate_audio_devices`: Queries `libvlc_audio_output_device_enum` or yields default audio output device entries.
   - `vlc_bridge_set_audio_device`: Calls `libvlc_audio_output_device_set(mp, nullptr, device_id)` to switch physical audio routing.
   - `vlc_bridge_get_audio_device`: Retrieves active audio device name/id via `libvlc_audio_output_device_get`.

3. **FFI Bindings & Controller (`lib/src/ffi/vlc_bindings.dart`, `lib/src/controller/vlc_player_controller.dart`)**:
   - Wired native device enumeration, setting, and getting.
   - Added `getAudioOutputDevices()` and `setAudioOutputDevice(String deviceId)` on `VlcPlayerController`.

4. **Audio Quick Popup UI (`lib/ui/popups/audio_quick_popup.dart`)**:
   - Quick access popup adhering to Ponytail 7-Rung discipline and Figma design tokens (`#1A1A1A`, 8dp corners, 1dp border `#2A2A2A`).
   - **Audio Tracks Section**: Track list with checkmarks, language tags, and channel badges (e.g. "English (Dolby 5.1)").
   - **Hardware Output Device Selector**: Radio selection for switching between speakers, headphones, or HDMI/DAC outputs.
   - **Audio Delay Stepper**: Millisecond precision stepper (`-50ms`, `+50ms`) with Direct Reset to 0ms and instant OSD notification.
   - **"Audio Effects & Equalizer" Action Button**: Direct trigger into Inspector Tab 2 (Audio & 10-Band EQ).

5. **App Shell & Main Integration (`lib/main.dart`)**:
   - Added Audio quick button callback to `BottomTransportRow` and `AppShellController`.
   - Wired live switching to `vlcPlayerController.setAudioTrack` and `vlcPlayerController.setAudioOutputDevice`.
   - Live OSD pills showing active track, output device change, and audio sync adjustment.

6. **Comprehensive Automated Tests (`test/ui/popups/audio_quick_popup_test.dart`)**:
   - Tested track selection, hardware device selection, delay stepper decrement/increment, reset, and equalizer open action.
   - All 47 Flutter unit/widget tests passing (100%).
   - All 11 Native C++ bridge tests passing (100%).

---

## 2. Next Priority Task
- **Task 3.3**: Build `QueueDrawer` (temporary drag-and-drop playback queue, separate from saved Playlists).

