# Task Log 022: MusicView and MusicPlayerCanvas Implementation (Task 4.5)

**Date:** October 18, 2026  
**Task:** Phase 4, Task 4.5: Build `MusicView` (*Songs, Albums, Artists, Genres*) and `MusicPlayerCanvas` (large cover art, ambient blur, waveform seek bar).  
**Discipline:** Ponytail 7-Rung UI Engineering • Juxtopposed 25-Year Redesign (`TKMz3UlzGRDOxFHHXq4Bln`)  
**Status:** COMPLETE (9 new widget tests, 158 / 158 tests passing, 11 / 11 native tests passing)

---

## 1. Objectives & Overview
- Build `MusicView` (`lib/ui/library/music_view.dart`) as the dedicated audio browser:
  - **Category Segmentation Tabs:** `Songs`, `Albums`, `Artists`, `Genres`.
  - **Songs Tab:** Tabular track listing with indices, title, artist, album, duration, and hover actions (`▶ Play`, `+ Enqueue`).
  - **Albums Tab:** 1:1 square album cards with cover placeholders, track count, total duration, and 1-click drill-down to album detail view.
  - **Artists Tab:** Circular artist badges with album and track counts, plus direct "Play" actions.
  - **Genres Tab:** Vibrant category cards displaying track counts and instant playback.
  - **Real-Time Audio Search:** Instant filtering across song titles, artists, and albums.
  - **Batch Actions:** "Play All" and "Enqueue All" triggers.
- Build `MusicPlayerCanvas` (`lib/ui/player/music_player_canvas.dart`) replacing the black video slate when playing audio:
  - **Ambient Blurred Backdrop:** Multi-layer radial gradient and `BackdropFilter` gaussian blur.
  - **Album Cover & Vinyl Disc:** Square 1:1 artwork card accompanied by an animated rotating vinyl disc that spins during playback and pauses with audio.
  - **Audio Format Badge:** Hi-Res audio pill badge (e.g., `FLAC 24-BIT / 96KHZ` with green lossless indicator, `WAV PCM 1411KBPS`, `MP3 320KBPS`).
  - **Interactive Waveform Seek Bar:** Amplitude bar visualization with played highlight in `#FF8800`, hover scrub detection, and elapsed / remaining time displays.
- Integrated `MusicView` into `FullLibraryView` when `_activeSection == LibrarySection.music`.
- Integrated `MusicPlayerCanvas` into `AppShell.videoSurface` in `lib/main.dart` whenever an audio file is playing.

---

## 2. Key Architectural Decisions & Ponytail Discipline
1. **Ponytail Ladder Rung 1 (YAGNI) & Rung 7 (Minimum Implementation):**
   - Utilized pure Flutter animation primitives (`AnimationController`, `RotationTransition`, `RadialGradient`, `BackdropFilter`) for the vinyl disc and ambient canvas without third-party graphics plugins.
   - Built the Waveform Seek Bar using standard `LayoutBuilder` and `GestureDetector` with responsive bar scaling.
2. **Audio Metadata Parser Heuristics:**
   - In `MediaLibraryService.indexFile()`, added intelligent heuristic detection for `Artist - Title` audio naming conventions and folder-based album tagging.
3. **Responsive Grid Scaling:**
   - Adjusted `_ArtistCard` layout and `childAspectRatio: 0.78` to ensure zero `RenderFlex` overflow across desktop viewports.

---

## 3. Files Created & Modified
- **Created:**
  - `lib/ui/library/music_view.dart`: Dedicated music browser with Songs, Albums, Artists, and Genres tabs.
  - `lib/ui/player/music_player_canvas.dart`: Fullscreen ambient music player canvas with rotating vinyl and waveform seek bar.
  - `test/ui/library/music_view_test.dart`: 6 widget tests for MusicView.
  - `test/ui/player/music_player_canvas_test.dart`: 3 widget tests for MusicPlayerCanvas.
  - `logs/022-music-view-and-music-player-canvas.md`: This task handoff log.
- **Modified:**
  - `lib/models/media_library_models.dart`: Added `MusicAlbumGroup`, `MusicArtistGroup`, and `MusicGenreGroup` models.
  - `lib/services/media_library_service.dart`: Added `getAlbums()`, `getArtists()`, and `getGenres()` grouping queries; added audio artist/title parsing in `indexFile()`.
  - `lib/ui/library/full_library_view.dart`: Routed `_activeSection == LibrarySection.music` to `MusicView`.
  - `lib/vlc_modern.dart`: Exported `music_view.dart` and `music_player_canvas.dart`.
  - `lib/main.dart`: Wired `MusicPlayerCanvas` into `videoSurface` during audio playback.
  - `docs/Progress.md`: Updated checklist and milestone metrics to 24 / 28 tasks (85.7%).

---

## 4. Test Verification
- Ran full test suite:
  ```bash
  flutter test
  # 158 / 158 tests passed (100% pass rate)
  ```
- Ran native core tests:
  ```bash
  ./build/native_core/native_core_tests
  # [PASS] All native_core vlc_bridge tests passed successfully! (11 / 11 checks)
  ```

---

## 5. Next Steps
- **Task 4.6:** Build `NetworkStreamsView` with GitHub/IPTV `.m3u` / `.m3u8` channel list parser and split classic "Open Media" into dedicated single-purpose modals (*Stream, Capture Device, Convert, Cast*).

