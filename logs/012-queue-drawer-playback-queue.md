# Handoff Log 012: Task 3.3 — QueueDrawer & Temporary Playback Queue

**Date:** 2026-10-18  
**Phase:** Phase 3 — Quick Popups, Batch Subtitle Auto-Matcher & 4-Tab Inspector Sidebar  
**Task:** 3.3 Build `QueueDrawer` (temporary drag-and-drop playback queue, separate from saved Playlists)  
**Status:** Complete  

---

## 1. What Was Built
1. **Queue Models (`lib/models/queue_models.dart`)**:
   - `QueueItem`: id, mrl, title, artist/show, duration, thumbnailUri, isPlaying flag, `copyWith`, equality, hashcode.
   - `QueueRepeatMode`: `off`, `all`, `one`.
   - `QueueController`: State management for temporary in-memory queue:
     - `items`, `currentIndex`, `count`, `totalDuration`, `totalRemainingDuration`.
     - Methods: `addItem`, `addItems`, `removeItem`, `removeAt`, `clear`, `reorder` (with Flutter index adjustment), `playIndex`, `playItem`, `playNext`, `playPrevious`, `toggleShuffle`, `cycleRepeatMode`.

2. **Custom Vector Glyphs (`lib/theme/vlc_icons.dart`)**:
   - Implemented custom vector drawings for `VlcIconGlyph.queue` (stacked list lines with bottom play indicator) and `VlcIconGlyph.playlist`.

3. **QueueDrawer Widget (`lib/ui/drawer/queue_drawer.dart`)**:
   - Width: `VlcGeometry.inspectorDrawerWidth` (340.0dp) with left border `1.0dp` `colors.border`.
   - **Header**: Leading queue icon, "Play Queue" title, item count badge (`${count}`), clear queue button, and close button (`✕` / `[Q]`).
   - **Sub-Header**: Total remaining duration summary (e.g. `1h 45m remaining`), shuffle mode toggle button, and repeat mode toggle button (`Off` / `All` / `One`).
   - **Empty State**: Centered icon, "Queue is Empty" title, descriptive helper text, and "Add Media to Queue" call-to-action.
   - **Reorderable List**: Powered by `ReorderableListView.builder`:
     - Custom drag handle (`ReorderableDragStartListener`) with 6-dot grip icon.
     - Active playing item highlight: `colors.accent.subtleBackground`, left accent indicator, and play icon.
     - Index badges (`#01`, `#02`, etc.) or play glyph.
     - Video thumbnail / folder placeholder box with 4dp rounded corners.
     - Item title and artist/details with text overflow ellipsis.
     - Monospace duration string.
     - Quick item delete button (`✕`).
     - Proxy decorator with elevated accent border when dragging.
   - **Footer**: "Save Playlist" and "Add Media" action buttons.

4. **Shell & Transport Row Integration (`lib/ui/shell/app_shell.dart`, `lib/ui/controls/bottom_transport_row.dart`, `lib/main.dart`)**:
   - Added `isQueueOpen`, `openQueue()`, `closeQueue()`, `toggleQueue()` to `AppShellController`.
   - Added `queueDrawer` slot in `AppShell` with slide animation.
   - Added keyboard shortcut `Q` (toggle queue) and `Escape` (closes queue/drawer).
   - Added `onQueueTap` and `isQueueOpen` to `BottomTransportRow` utility cluster.
   - Wired live queue items, play-from-queue selection, and OSD pill feedback in `lib/main.dart`.

5. **Automated Unit & Widget Tests (`test/models/queue_models_test.dart`, `test/ui/drawer/queue_drawer_test.dart`)**:
   - 6 unit tests covering queue manipulation, duration calculations, reordering, shuffle, and repeat modes.
   - Widget tests covering empty state, rendering items, selection, item removal, queue clear, mode toggles, and callbacks.
   - Added tests in `app_shell_test.dart` and `bottom_transport_row_test.dart`.
   - **Total Tests:** 56 / 56 Flutter tests pass (100%) + 11 / 11 Native C++ bridge tests pass (100%).

---

## 2. Next Priority Task
- **Task 3.4**: Build `InspectorSidebar` (Right `340dp` drawer on Desktop / Modal Bottom Sheet on Mobile) with **Per-Show Preset Bar**.

