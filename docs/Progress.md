# VLC Modern Redesign — Master Build Progress & State Index (`progress.md`)

> **FOR INCOMING AGENTS:** Do NOT read the entire codebase to figure out what is built. Read the **Current Status Summary** below, open the **Latest Handoff Log** in `logs/`, and pick up the next `[ ]` task in the active Phase. Always update this file and write a new log in `logs/` before ending your session.

---

## Current Status Summary
- **Current Active Phase:** `Phase 3 — Quick Popups, Batch Subtitle Auto-Matcher & 4-Tab Inspector Sidebar`
- **Current Next Task:** `3.2 Build AudioQuickPopup combining embedded Audio Tracks (libvlc_audio_set_track) and live OS Hardware Output Device Selector (libvlc_audio_output_device_set)`
- **Chosen UI / Native Stack:** `Flutter Impeller + C++ FFI (Option A) with Direct libvlc C ABI`
- **Latest Handoff Log:** `logs/010-subtitle-quick-popup-and-batch-matcher.md`
- **Overall Completion:** `12 / 28 Tasks (42.9%)`
- **Last Updated:** `2026-10-18`

---

## Module Ownership & File Map (Updated as files are created)
| Module | Directory / Primary Files | Status | Last Log Ref |
| :--- | :--- | :--- | :--- |
| **Native `libVLC` Core Bridge** | `native_core/include/vlc/`, `native_core/src/vlc_bridge.cpp`, `lib/src/controller/` | Complete (Controls, Tracks, EQ Verified) | `logs/002-player-controller-ffi.md` |
| **Hardware Video Surfaces** | `native_core/include/hardware_surface.h`, `hardware_surface_metal.mm` (Metal), `hardware_surface_d3d11.cpp`, `hardware_surface_jni.cpp` | Complete (Metal 4K Zero-Copy Verified) | `logs/003-hardware-video-surfaces.md` |
| **Design Tokens & Theme Engine** | `lib/theme/` (`vlc_colors.dart`, `vlc_geometry.dart`, `vlc_typography.dart`, `vlc_icons.dart`, `vlc_theme.dart`) | Complete (Tokens, Accent Engine, Dual Icons) | `logs/004-theme-tokens-engine.md` |
| **Shell, TopBar & OSD Layer** | `lib/ui/shell/` (`app_shell.dart`, `top_player_bar.dart`, `osd_notification_layer.dart`) | Complete (`AppShell`, `TopPlayerBar`, `OSD Layer`) | `logs/009-osd-notification-layer.md` |
| **Bottom Controls & Thick SeekBar** | `lib/ui/controls/` (`bottom_transport_row.dart`, `volume_control.dart`, `thick_seek_bar.dart`) | Complete (Transport, Overdrive Volume, ThickSeekBar) | `logs/008-thick-seek-bar.md` |
| **Popups & 4-Tab Inspector** | `lib/ui/popups/` (`subtitle_quick_popup.dart`, `add_subtitles_modal.dart`), `lib/ui/sidebar/` | In Progress (Task 3.1 Complete) | `logs/010-subtitle-quick-popup-and-batch-matcher.md` |
| **Media Library, Music & IPTV** | `lib/ui/library/` (`medialibrary` SQLite, `CompactLibraryDrawer`, `M3UStreamsView`) | Not Started | — |
| **Settings, Hotkeys & Customizer** | `lib/ui/settings/` (`UnifiedSettingsModal`, `HotkeysModal`, `DragDropCustomizer`) | Not Started | — |

---

## Phased Build Roadmap & Task Checklist

### Phase 1: Multi-Platform Native Workspace & `libVLC` Hardware Surface Bootstrap
- [x] **1.1** Initialize cross-platform native project (`macos/`, `windows/`, `ios/`, `android/`) and `native_core/` CMake scaffold.
- [x] **1.2** Link official VideoLAN binaries (`libvlc` / `VLCKit` on macOS & iOS, `libvlcjni` on Android, `libvlc.dll` on Windows).
- [x] **1.3** Implement `player_controller` C/FFI bridge (`play`, `pause`, `stop`, `seek`, `rate`, `volume` 0–200%).
- [x] **1.4** Bind zero-copy GPU hardware video surfaces (`Metal CVPixelBuffer` on Apple, `D3D11 SwapChain` on Windows, `SurfaceTexture` on Android) so UI overlays render cleanly over 4K video.
- [x] **1.5** Run `/ponytail-review` on Phase 1 FFI memory safety and write `logs/001-phase1-complete.md`.

### Phase 2: Design System, `AppShell`, Top/Bottom Bars & Thick Seek Bar (COMPLETE)
- [x] **2.1** Extract Figma tokens (`TKMz3UlzGRDOxFHHXq4Bln`) into `theme/`: Dark/Light palettes, `#FF8800` accent color engine, rectangular `4dp–8dp` geometry, and Dual Icon sets (Two-Tone vs. Monochrome).
- [x] **2.2** Build `AppShell` with desktop hover auto-hide (`1.8s`), mobile tap auto-hide (`3.0s`), and `Hide UI Completely` (`Ctrl+H`) lock mode.
- [x] **2.3** Build `TopPlayerBar` with `UnifiedMenuButton`, `FolderBreadcrumbTrigger` (`[Show Folder] › [Title]`), PiP toggle, and Fullscreen controls.
- [x] **2.4** Build `BottomTransportRow` (left-aligned Play/Pause/Prev/Next + right-aligned utility cluster) and `FullConeVolumeControl` (0–200% striped cone slider).
- [x] **2.5** Build `ThickSeekBar` (`10dp` -> `16dp` on hover) wired to `libvlc_media_thumbnail_request_by_time` hover frame previews, chapter ticks, and `WaveformSeekOverlay`.
- [x] **2.6** Build `OSDNotificationLayer` with **Shortcut-Aware Top-Right Pill** (`Action [Key]`) and **Bottom-Center 5s `"Continue Watching"` Prompt**.

### Phase 3: Quick Popups, Batch Subtitle Auto-Matcher & 4-Tab Inspector Sidebar
- [x] **3.1** Build `SubtitleQuickPopup` (`libvlc_video_get_spu_description`) and `AddSubtitlesModal` with **This File / This Folder / This Playlist** scopes, OpenSubtitles REST API search, and batch season episode fuzzy-matcher.
- [ ] **3.2** Build `AudioQuickPopup` combining embedded Audio Tracks (`libvlc_audio_set_track`) and live OS **Hardware Output Device Selector** (`libvlc_audio_output_device_set`).
- [ ] **3.3** Build `QueueDrawer` (temporary drag-and-drop playback queue, separate from saved Playlists)[span_29](start_span)[span_29](end_span).
- [ ] **3.4** Build `InspectorSidebar` (Right `340dp` drawer on Desktop / Modal Bottom Sheet on Mobile) with **Per-Show Preset Bar**[span_30](start_span)[span_30](end_span).
- [ ] **3.5** Implement **Tab 1 (`SubtitlesInspectorTab`)** + **`InteractiveSubtitleTimeline`** above the seek bar (drag dialogue block while paused to set `libvlc_video_set_spu_delay`) + Relative/Precise font styling[span_31](start_span)[span_31](end_span).
- [ ] **3.6** Implement **Tab 2 (`AudioInspectorTab`)** (Audio delay slider, visual Audio Filter Preset cards with previews, expandable 10-band `libvlc_audio_equalizer_t`)[span_32](start_span)[span_32](end_span).
- [ ] **3.7** Implement **Tab 3 (`VideoInspectorTab`)** (Geometry/Crop/Aspect/Rotate/HDR toggles + Video Filter cards with live thumbnail previews)[span_33](start_span)[span_33](end_span).
- [ ] **3.8** Implement **Tab 4 (`PlaybackInspectorTab`)** (Speed `0.25x–4.0x`, Reverse playback, Sleep Timer, Seekbar overlay toggles, Visual Bookmarks `Ctrl+B` & Chapters list)[span_34](start_span)[span_34](end_span).

### Phase 4: `medialibrary` Integration, Compact Drawer, Music Mode & IPTV Streams
- [ ] **4.1** Integrate VideoLAN `medialibrary` SQLite indexer for folder watching, resume positions, and **Watched First / Unwatched First** sorting[span_35](start_span)[span_35](end_span).
- [ ] **4.2** Build `CompactLibraryDrawer` (opens alongside playing video from the top folder breadcrumb so users can drag episodes into Queue without leaving the video)[span_36](start_span)[span_36](end_span).
- [ ] **4.3** Build `FullLibraryView` with draggable bottom-right `MiniPlayerOverlay`, breadcrumb address bar, Grid/List/Details view switcher, and Pinned sidebar items[span_37](start_span)[span_37](end_span).
- [ ] **4.4** Build `HomeView` (replaces empty cone screen with Continue Watching, Recent Files, Playlists, Streams) and `VideosView`[span_38](start_span)[span_38](end_span).
- [ ] **4.5** Build `MusicView` (*Songs, Albums, Artists, Genres*) and `MusicPlayerCanvas` (large cover art, ambient blur, waveform seek bar)[span_39](start_span)[span_39](end_span).
- [ ] **4.6** Build `NetworkStreamsView` with GitHub/IPTV `.m3u` / `.m3u8` channel list parser and split classic "Open Media" into dedicated single-purpose modals (*Stream, Capture Device, Convert, Cast*)[span_40](start_span)[span_40](end_span).

### Phase 5: Reimagined Settings, Hotkeys, Drag-and-Drop Customizer & Mobile Polish
- [ ] **5.1** Build `UnifiedSettingsModal` across all **12 Categories** with **continuous Basic-to-Advanced scroll** (no Simple/All toggle), human-readable dropdowns, and `ⓘ` tooltips on every setting[span_41](start_span)[span_41](end_span).
- [ ] **5.2** Build standalone searchable `HotkeysModal` and `FirstLaunchOnboarding` (Theme/Accent picker + shortcut cheat-sheet)[span_42](start_span)[span_42](end_span).
- [ ] **5.3** Build `DragDropLayoutCustomizer` (dashed drop-zone canvas for dragging buttons in/out of bars) with switchable **User Profiles**[span_43](start_span)[span_43](end_span).
- [ ] **5.4** Complete iOS & Android touch gestures (vertical swipe volume/brightness with Cone HUD, double-tap `±10s` seek, native OS PiP) and run final `/ponytail-audit` across the repository[span_44](start_span)[span_44](end_span).