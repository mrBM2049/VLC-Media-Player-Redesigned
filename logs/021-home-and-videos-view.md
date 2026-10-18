# Task Log 021: HomeView and VideosView Implementation (Task 4.4)

**Date:** October 18, 2026  
**Task:** Phase 4, Task 4.4: Build `HomeView` (replaces empty cone screen with Continue Watching carousel, Recent Files, Playlists, Streams) and `VideosView` (Movies vs TV Shows vs Clips segmentation, Series season/episode grouping).  
**Discipline:** Ponytail 7-Rung UI Engineering • Juxtopposed 25-Year Redesign (`TKMz3UlzGRDOxFHHXq4Bln`)  
**Status:** COMPLETE (11 new widget tests, 149 / 149 tests passing, 11 / 11 native tests passing)

---

## 1. Objectives & Overview
- Build `HomeView` (`lib/ui/library/home_view.dart`) as the rich default welcome hub:
  - **Hero Welcome Banner:** Greeting, indexed media count, quick actions for "Open File [⌘O]", "Open Network Stream [⌘N]", and "Add Folder".
  - **Continue Watching Carousel:** Horizontal scrollable card row for in-progress media items with playback progress bars, remaining time indicators, and 1-click resume.
  - **Recent Media Grid:** Responsive grid of recently added or opened media items with instant hover play/queue actions.
  - **Smart Collections & Playlists:** Quick access cards for Continue Watching, Completed/Watched history, All Video Library, and Music & Audio Tracks.
  - **Indexed Folders Chips:** Interactive directory chips with monitored item counts and "+ Add Folder" button.
- Build `VideosView` (`lib/ui/library/videos_view.dart`) as the dedicated video browser:
  - **Category Segmentation Tabs:** `All Videos`, `Movies` (duration >= 40m), `TV Shows` (season/episode detection), and `Clips` (< 40m).
  - **Collapsible TV Shows & Series Grouping:** Groups episodes by folder/show name, organizes seasons, and renders episode rows with badges and instant play/queue buttons.
  - **Real-Time Video Search:** Instant filtering by show name, file name, or folder path.
  - **Fast Batch Actions:** One-click "Play All" and "Enqueue All" triggers.
- Harmonize routing in `FullLibraryView` so `HomeView` and `VideosView` mount cleanly into the main workspace without duplicate search bars or header clutter, while retaining full layout switching (Grid, List, Details) for folder exploration.

---

## 2. Key Architectural Decisions & Ponytail Discipline
1. **Ponytail Ladder Rung 1 (YAGNI) & Rung 7 (Minimum Implementation):**
   - Implemented TV Show episode grouping directly using existing `MediaItem.season` and `MediaItem.episode` fields parsed during SQLite indexing.
   - Built collapsible series cards using pure Flutter `StatefulWidget` primitives with `Set<String> _collapsedSeries` rather than third-party accordion packages.
2. **Ponytail Design Tokens & Geometry:**
   - Adhered strictly to `#FF8800` cone orange accents, `4dp`–`8dp` rectangular corner geometry, and dual-tone / monochrome vector icon glyphs.
   - 16:9 aspect ratio media cards with high-contrast duration badges and subtle gradient text overlays.
3. **Clean Workspace Routing in `FullLibraryView`:**
   - `HomeView` renders when `_activeSection == LibrarySection.home` and search query is empty.
   - `VideosView` renders when `_activeSection == LibrarySection.videos` and search query is empty.
   - Generic breadcrumb address bar, layout switcher (Grid, List, Details table), and filter pills (`All`, `Unwatched`, `Watched`, `In Progress`) remain active for browsing folders and media collections.

---

## 3. Files Created & Modified
- **Created:**
  - `lib/ui/library/home_view.dart`: Rich home hub replacing classic empty screen.
  - `lib/ui/library/videos_view.dart`: Dedicated video catalog with Movies, TV Shows, Clips segmentation and season/episode accordion.
  - `test/ui/library/home_view_test.dart`: 5 widget tests for HomeView hero, continue watching, recent files, and navigation.
  - `test/ui/library/videos_view_test.dart`: 6 widget tests for VideosView categories, series grouping, search, and batch actions.
  - `logs/021-home-and-videos-view.md`: This task handoff log.
- **Modified:**
  - `lib/models/media_library_models.dart`: Added `MediaPlaylistGroup` model.
  - `lib/services/media_library_service.dart`: Added `getRecentFiles({int limit})` and `getPlaylists()`.
  - `lib/ui/library/full_library_view.dart`: Integrated `HomeView` and `VideosView` into main workspace routing; added `initialSection` parameter (defaulting to `LibrarySection.home`).
  - `lib/vlc_modern.dart`: Exported `home_view.dart` and `videos_view.dart`.
  - `lib/main.dart`: Fixed `_playerController.open/play` and `_queueController.playNext/playPrevious` method calls.
  - `test/ui/library/full_library_view_test.dart`: Configured `initialSection: LibrarySection.folders` for layout switcher and filter pill verification.
  - `docs/Progress.md`: Updated checklist and milestone status.

---

## 4. Test Verification
- Ran full test suite:
  ```bash
  flutter test
  # 149 / 149 tests passed (100% pass rate)
  ```
- Ran native core tests:
  ```bash
  ./build/native_core/native_core_tests
  # [PASS] All native_core vlc_bridge tests passed successfully! (11 / 11 checks)
  ```

---

## 5. Next Steps
- **Task 4.5:** Build `MusicView` (*Songs, Albums, Artists, Genres*) and `MusicPlayerCanvas` (large cover art, ambient blur, waveform seek bar).

