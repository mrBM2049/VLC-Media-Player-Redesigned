# VLC Modern Redesign — Master Build Progress & State Index (`progress.md`)

> **FOR INCOMING AGENTS:** Do NOT read the entire codebase to figure out what is built. Read the **Current Status Summary** below, open the **Latest Handoff Log** in `logs/`, and pick up the next `[ ]` task in the active Phase. Always update this file and write a new log in `logs/` before ending your session.

---

## Current Status Summary
- **Current Active Phase:** `Phase 4 — medialibrary Integration, Compact Drawer, Music Mode & IPTV Streams`
- **Current Next Task:** `4.6 Build NetworkStreamsView with GitHub/IPTV .m3u / .m3u8 channel list parser and split classic "Open Media" into dedicated single-purpose modals (Stream, Capture Device, Convert, Cast)`
- **Chosen UI / Native Stack:** `Flutter Impeller + C++ FFI (Option A) with Direct libvlc C ABI`
- **Latest Handoff Log:** `logs/022-music-view-and-music-player-canvas.md`
- **Overall Completion:** `24 / 28 Tasks (85.7%)`
- **Last Updated:** `2026-10-18`

---

## Module Ownership & File Map (Updated as files are created)
| Module | Directory / Primary Files | Status | Last Log Ref |
| :--- | :--- | :--- | :--- |
| **Native `libVLC` Core Bridge** | `native_core/include/vlc/`, `native_core/src/vlc_bridge.cpp`, `lib/src/controller/` | Complete (Controls, Tracks, EQ Verified) | `logs/002-player-controller-ffi.md` |
| **Hardware Video Surfaces** | `native_core/include/hardware_surface.h`, `hardware_surface_metal.mm` (Metal), `hardware_surface_d3d11.cpp`, `hardware_surface_jni.cpp` | Complete (Metal 4K Zero-Copy Verified) | `logs/003-hardware-video-surfaces.md` |
| **Design Tokens & Theme Engine** | `lib/theme/` (`vlc_colors.dart`, `vlc_geometry.dart`, `vlc_typography.dart`, `vlc_icons.dart`, `vlc_theme.dart`) | Complete (Tokens, Accent Engine, Dual Icons) | `logs/004-theme-tokens-engine.md` |
| **Shell, TopBar & OSD Layer** | `lib/ui/shell/` (`app_shell.dart`, `top_player_bar.dart`, `osd_notification_layer.dart`) | Complete (`AppShell`, `TopPlayerBar`, `OSD Layer`) | `logs/009-osd-notification-layer.md` |
| **Bottom Controls & Thick SeekBar** | `lib/ui/controls/` (`bottom_transport_row.dart`, `volume_control.dart`, `thick_seek_bar.dart`, `interactive_subtitle_timeline.dart`) | Complete (Transport, Overdrive Volume, ThickSeekBar, SubtitleTimeline) | `logs/014-subtitles-inspector-tab-and-interactive-timeline.md` |
| **Popups & 4-Tab Inspector** | `lib/ui/popups/`, `lib/ui/sidebar/` (`inspector_sidebar.dart`, `subtitle_inspector_tab.dart`, `audio_inspector_tab.dart`, `video_inspector_tab.dart`, `playback_inspector_tab.dart`, `preset_models.dart`, `video_models.dart`, `playback_models.dart`) | Complete (Phase 3 Complete: Tasks 3.1–3.8) | `logs/017-playback-inspector-tab-and-chapters.md` |
| **Media Library, Music & IPTV** | `lib/models/media_library_models.dart`, `lib/services/media_library_service.dart`, `lib/ui/drawer/compact_library_drawer.dart`, `lib/ui/library/`, `lib/ui/player/` | In Progress (Tasks 4.1–4.5 Complete) | `logs/022-music-view-and-music-player-canvas.md` |
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
- [x] **3.2** Build `AudioQuickPopup` combining embedded Audio Tracks (`libvlc_audio_set_track`) and live OS **Hardware Output Device Selector** (`libvlc_audio_output_device_set`).
- [x] **3.3** Build `QueueDrawer` (temporary drag-and-drop playback queue, separate from saved Playlists).
- [x] **3.4** Build `InspectorSidebar` (Right `340dp` drawer on Desktop / Modal Bottom Sheet on Mobile) with **Per-Show Preset Bar**.
- [x] **3.5** Implement **Tab 1 (`SubtitlesInspectorTab`)** + **`InteractiveSubtitleTimeline`** above the seek bar (drag dialogue block while paused to set `libvlc_video_set_spu_delay`) + Relative/Precise font styling.
- [x] **3.6** Implement **Tab 2 (`AudioInspectorTab`)** (Audio delay slider, visual Audio Filter Preset cards with previews, expandable 10-band `libvlc_audio_equalizer_t`).
- [x] **3.7** Implement **Tab 3 (`VideoInspectorTab`)** (Geometry/Crop/Aspect/Rotate/HDR toggles + Video Filter cards with live thumbnail previews).
- [x] **3.8** Implement **Tab 4 (`PlaybackInspectorTab`)** (Speed `0.25x–4.0x`, Reverse playback, Sleep Timer, Seekbar overlay toggles, Visual Bookmarks `Ctrl+B` & Chapters list).

### Phase 4: `medialibrary` Integration, Compact Drawer, Music Mode & IPTV Streams
- [x] **4.1** Integrate VideoLAN `medialibrary` SQLite indexer for folder watching, resume positions, and **Watched First / Unwatched First** sorting.
- [x] **4.2** Build `CompactLibraryDrawer` (opens alongside playing video from the top folder breadcrumb so users can drag episodes into Queue without leaving the video).
- [x] **4.3** Build `FullLibraryView` with draggable bottom-right `MiniPlayerOverlay`, breadcrumb address bar, Grid/List/Details view switcher, and Pinned sidebar items.
- [x] **4.4** Build `HomeView` (replaces empty cone screen with Continue Watching, Recent Files, Playlists, Streams) and `VideosView`.
- [x] **4.5** Build `MusicView` (*Songs, Albums, Artists, Genres*) and `MusicPlayerCanvas` (large cover art, ambient blur, waveform seek bar).
- [x] **4.6** Build `NetworkStreamsView` with GitHub/IPTV `.m3u` / `.m3u8` channel list parser and split classic "Open Media" into dedicated single-purpose modals (*Stream, Capture Device, Convert, Cast*).

### Phase 5: Reimagined Settings, Hotkeys, Drag-and-Drop Customizer & Mobile Polish
- [x] **5.1** Build `UnifiedSettingsModal` across all **12 Categories** with **continuous Basic-to-Advanced scroll** (no Simple/All toggle), human-readable dropdowns, and `ⓘ` tooltips on every setting.
- [ ] **5.2** Build standalone searchable `HotkeysModal` and `FirstLaunchOnboarding` (Theme/Accent picker + shortcut cheat-sheet).
- [ ] **5.3** Build `DragDropLayoutCustomizer` (dashed drop-zone canvas for dragging buttons in/out of bars) with switchable **User Profiles**.
- [ ] **5.4** Complete iOS & Android touch gestures (vertical swipe volume/brightness with Cone HUD, double-tap `±10s` seek, native OS PiP) and run final `/ponytail-audit` across the repository.