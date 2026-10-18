# Session Log: [Phase 4.1 — medialibrary SQLite Indexer & Folder Watcher]
- **Date & Timestamp:** 2026-10-18 20:25
- **Agent / Session ID:** Antigravity / Task 4.1
- **Completed Tasks from `docs/Progress.md`:** `[x] 4.1 Integrate VideoLAN medialibrary SQLite indexer for folder watching, resume positions, and Watched First / Unwatched First sorting`
- **Next Up Task in `docs/Progress.md`:** `[ ] 4.2 Build CompactLibraryDrawer (opens alongside playing video from the top folder breadcrumb so users can drag episodes into Queue without leaving the video)`

---

## 1. Executive Summary (Read This Instead of Scanning the Codebase)
Engineered the native VideoLAN `medialibrary` SQLite indexer, live folder watcher, persistent resume tracker, and priority sorting engine (Task 4.1):
1. **Domain Models (`MediaItem`, `MediaFolder`, `MediaPlaybackHistoryEntry`):**
   - Media classification (`video`, `audio`, `stream`), file size formatting (`KB`, `MB`, `GB`), duration and resume timestamps (`hh:mm:ss` / `mm:ss`), TV Season/Episode parsing (`S01E05 - Title`), and full JSON/Map serialization roundtrips.
2. **VideoLAN `medialibrary` SQLite Schema & Indexer (`MediaLibraryService`):**
   - Initialized relational SQLite schema with `folders`, `media`, `history`, and `bookmarks` tables, along with 6 B-Tree performance indexes (`idx_media_mrl`, `idx_media_folder`, `idx_media_watched`, `idx_media_last_played`, `idx_media_type`, `idx_folders_path`).
   - Supports both persistent user database (`~/.vlc_modern/medialibrary.db`) and in-memory SQLite instances for zero-disk-latency unit testing.
3. **Folder Scanning & Continuous File Watching:**
   - Recursive and shallow directory scanner targeting all standard VideoLAN formats: video (`.mp4`, `.mkv`, `.avi`, `.mov`, `.wmv`, `.flv`, `.webm`, `.m4v`, `.ts`, `.m2ts`, `.iso`) and audio (`.mp3`, `.flac`, `.wav`, `.aac`, `.m4a`, `.ogg`, `.opus`, `.wma`, `.alac`, `.aiff`).
   - Continuous directory watching using asynchronous `Directory.watch()` streams that instantly index new downloads/copies and purge deleted files in real-time.
   - Folder banning mechanism that marks folders excluded and deletes associated media indices.
4. **Resume Position Tracking & Auto-Watched Detection:**
   - Tracks exact playback position and ratio (`resumeProgress = positionMs / durationMs`).
   - Automatically marks media as `isWatched = true` once playback reaches or exceeds **90%** of total duration.
   - Smart resume query: in-progress media returns saved resume time, while completed media (>95% watched) returns 0 to allow starting fresh.
5. **Watched First / Unwatched First Prioritization:**
   - `watchedFirst`: Prioritizes watched items first sorted by `lastPlayed DESC`, followed by unwatched items.
   - `unwatchedFirst`: Prioritizes unwatched items first sorted by `dateAdded DESC`, followed by completed items.
   - `getContinueWatching()`: Dedicated query for in-progress items between 2% and 90% progress for home views.
6. **Wired into `lib/main.dart`:**
   - Initialized persistent `_mediaLibraryService`, hooked into `_loadAndPlayMedia` to auto-trigger the OSD resume prompt when opening media with saved progress, and synchronized progress updates on seek bar interaction.

Verified with **122 / 122 Flutter tests passing (100%)**, **11 / 11 Native C++ bridge tests passing (100%)**, and macOS debug application compiled cleanly.

## 2. Files Created or Modified (With Exact Responsibility)
| File Path | Action (`Created`/`Modified`/`Deleted`) | Public Exports / Key Functions / State |
| :--- | :--- | :--- |
| `lib/models/media_library_models.dart` | Created | `MediaItem`, `MediaFolder`, `MediaPlaybackHistoryEntry`, `MediaType`, `MediaSortOrder`, `MediaFilter` |
| `lib/services/media_library_service.dart` | Created | `MediaLibraryService` SQLite indexer, directory watcher, resume tracker, and query engine |
| `test/models/media_library_models_test.dart` | Created | 7 unit tests covering duration/resume/size formatting, displayName S01E05 tags, and JSON serialization |
| `test/services/media_library_service_test.dart` | Created | 11 unit tests covering schema creation, episode parsing, auto-watched 90% threshold, sorting, folder banning, and live file watcher |
| `lib/vlc_modern.dart` | Modified | Exported `media_library_models.dart` and `media_library_service.dart` |
| `lib/main.dart` | Modified | Initialized `_mediaLibraryService`, wired resume detection into `_loadAndPlayMedia`, and updated playback progress on seek |
| `pubspec.yaml` | Modified | Added `sqlite3: ^3.7.1` official C ABI binding |

## 3. Native & State Contracts Wired
- **C ABI / Database:** `sqlite3` direct C ABI via `dart:ffi` binding to system `/usr/lib/libsqlite3.dylib` / OS SQLite binaries.
- **State Updates:** Wired `MediaLibraryService` with `ChangeNotifier` and reactive broadcast `mediaStream`.

## 4. Ponytail & Design Skill Decisions
- **Ponytail Ladder Rung Used:** Rung 1 & 2. Official standard Dart `ffi` / `sqlite3` library with zero bloated third-party plugin wrappers or platform channel overhead.
- **Figma Geometry:** Matches Juxtopposed 4dp–8dp corner radii, `#FF8800` accent highlights, and tabular monospace timestamps.

## 5. Verification & Build Status
- **Flutter Tests:** `flutter test` — **122 / 122 tests passed (100%)**.
- **Native C Tests:** `native_core/build/native_core_tests` — **11 / 11 C++ tests passed (100%)**.
- **Platform Compilation:** macOS application built successfully (`vlc_modern.app`).

## 6. Handoff Instructions for the Next Agent
- **Immediate Next Step:** Phase 4, Task 4.2: Build `CompactLibraryDrawer` (opens alongside playing video from the top folder breadcrumb so users can drag episodes into Queue without leaving the video).
- **Files the Next Agent Should Read First:**
  1. `lib/models/media_library_models.dart` & `lib/services/media_library_service.dart` — Library models and query APIs.
  2. `lib/ui/shell/top_player_bar.dart` — `onFolderBreadcrumbTap` trigger.
  3. `lib/ui/drawer/queue_drawer.dart` — Reference drawer pattern with drag-and-drop mechanics.
- **Known Edge Cases / Blockers:** None.
