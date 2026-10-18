# Task Log 020: FullLibraryView and Draggable MiniPlayerOverlay (Task 4.3)

**Date:** October 18, 2026  
**Task:** Phase 4, Task 4.3: Build `FullLibraryView` with draggable bottom-right `MiniPlayerOverlay`, breadcrumb address bar, Grid/List/Details view switcher, and Pinned sidebar items.  
**Discipline:** Ponytail 7-Rung UI Engineering • Juxtopposed 25-Year Redesign (`TKMz3UlzGRDOxFHHXq4Bln`)  
**Status:** COMPLETE (8 new widget tests, 138/138 tests passing)

---

## 1. Objectives & Overview
- Build `FullLibraryView` (`lib/ui/library/full_library_view.dart`) allowing fullscreen switching between Video Player mode and Full Library browsing.
- Provide a pinned left sidebar with sections (`Home`, `Videos`, `Music`, `Streams`, `Playlists`) and dynamically listed indexed folders.
- Implement breadcrumb address bar with real-time file search and view layout switcher (`Grid`, `List`, `Details`).
- Implement 3 responsive view modes:
  - **Grid View:** 16:9 thumbnail previews, resume progress bars, duration badges, and hover actions (`▶ Play`, `+ Enqueue`, `✓ Mark Watched`).
  - **List View:** Compact media rows with technical badges, progress indicators, and inline action triggers.
  - **Details View:** Tabular display showing Title, Watched Status, Duration, File Size, Parent Folder, and Quick Actions.
- Implement floating, draggable `MiniPlayerOverlay` pinned to the bottom-right corner with 16:9 simulated player canvas, seek bar progress, mini transport row (Prev, Play/Pause, Next, Volume/Mute), and maximize button to return to video playback without losing state.
- Wire view toggles via `TopPlayerBar` (`[L / Ctrl+L]`), `AppShell` shortcut listener, and `main.dart`.

---

## 2. Key Architectural Decisions & Ponytail Discipline
1. **Separation of Compact Drawer vs. Full Library View:**
   - `CompactLibraryDrawer` (Task 4.2) slides in alongside the video (340dp width) for quick episode queuing during playback.
   - `FullLibraryView` (Task 4.3) is an immersive, standalone workspace for exploring extensive local video and audio libraries while video playback continues seamlessly inside the floating `MiniPlayerOverlay`.
2. **Draggable MiniPlayer Overlay:**
   - Utilizes `GestureDetector(onPanUpdate: ...)` to allow users to move the mini player card anywhere across the screen.
   - Pinned resting position at `right: 24, bottom: 24`.
   - Supports 1-click maximize (`Esc` or maximize button) to return directly to the main video player canvas.
3. **Responsive Grid & Table Bounds:**
   - Column counts dynamically scale based on available layout width (`math.max(2, (constraints.maxWidth / 220).floor())`).
   - Table uses `FixedColumnWidth(90)` for the action column and compact `InkWell` buttons with custom padding to guarantee zero `RenderFlex` overflow across desktop viewports.

---

## 3. Files Created & Modified
- **Created:**
  - `lib/ui/library/full_library_view.dart`: Complete `FullLibraryView` and `MiniPlayerOverlay` implementation.
  - `test/ui/library/full_library_view_test.dart`: 8 widget tests verifying sidebar navigation, address bar, layout switching, filter tabs, search, hover actions, draggable mini player, and maximize return.
  - `logs/020-full-library-view-and-mini-player.md`: This task handoff log.
- **Modified:**
  - `lib/models/media_library_models.dart`: Added `folderName` helper getter to `MediaItem`.
  - `lib/theme/vlc_icons.dart`: Added glyphs and vector painters for `home`, `video`, `music`, `stream`, `viewGrid`, `viewList`, `viewDetails`, `maximize`, `minimize`, and `folder`.
  - `lib/ui/shell/top_player_bar.dart`: Added `onLibraryViewToggle` callback and library toggle button (`VlcIconGlyph.viewGrid`).
  - `lib/ui/shell/app_shell.dart`: Added `onToggleLibrary` and `onToggleFullLibrary` parameters and keyboard shortcut handlers for `L` / `Ctrl+L`.
  - `lib/vlc_modern.dart`: Exported `full_library_view.dart`.
  - `lib/main.dart`: Wired `_isFullLibraryView` conditional rendering, batch playback, enqueuing, and mini player transport hooks.
  - `docs/Progress.md`: Updated checklist and milestone metrics to 22 / 28 tasks (78.6%).

---

## 4. Test Verification
- Ran `flutter test`:
  ```bash
  138 / 138 tests passed (100% pass rate)
  ```
- Native tests:
  ```bash
  11 / 11 C++ bridge tests passing (100% pass rate)
  ```

---

## 5. Next Steps
- **Task 4.4:** Build `HomeView` (replaces empty cone screen with Continue Watching carousel, Recent Files, Playlists, Streams) and `VideosView`.
