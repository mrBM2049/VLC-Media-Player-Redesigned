# Task Log 026: Drag-and-Drop Layout Customizer & User Profiles (Task 5.3)

**Date:** October 18, 2026  
**Task:** Phase 5, Task 5.3: Build `DragDropLayoutCustomizer` (dashed drop-zone canvas for dragging buttons in/out of bars) with switchable **User Profiles**.  
**Discipline:** Ponytail 7-Rung UI Engineering • Juxtopposed 25-Year Redesign (`TKMz3UlzGRDOxFHHXq4Bln`)  
**Status:** COMPLETE (4 new widget tests, 191 / 191 tests passing, 11 / 11 native tests passing — 27 / 28 total tasks complete!)

---

## 1. Objectives & Overview
- Build `ToolbarButtonId` and `ToolbarProfile` models (`lib/models/toolbar_customizer_models.dart`):
  - Catalog of 19 distinct toolbar tools (Play/Pause, Stop, Prev, Next, Frame Step Forward/Backward, Volume, Time, Speed, Repeat, Shuffle, Subtitles, Audio Track, Equalizer, Queue, Snapshot, Bookmark, Fullscreen, PiP).
  - 4 Curated Preset Profiles:
    - **Standard (Balanced)**: Everyday multimedia playback with core controls and quick drawers.
    - **Minimalist (Cinematic)**: Distraction-free movie mode with only Play/Pause, Time, and Volume.
    - **Power User (Studio)**: Advanced video scrubbing with frame stepping, snapshots, bookmarks, and dual quick menus.
    - **Music & Hi-Fi**: Focused music player canvas layout with shuffle, repeat, equalizer, and queue.
- Build `DragDropLayoutCustomizer` (`lib/ui/settings/drag_drop_customizer.dart`):
  - Desktop 920x660 modal dialog.
  - Interactive **Top Player Bar Drop Zone** and **Bottom Transport Row Drop Zone** rendered with custom dashed border styling via `_DashedBorderPainter`.
  - Native Flutter drag-and-drop primitives (`Draggable<ToolbarButtonId>` and `DragTarget<ToolbarButtonId>`) providing reactive hover feedback, candidate acceptance, and drag feedback chips with Cone Orange glows.
  - Active button chips with 1-click removal (`×` icon).
  - Available Tool Palette container showcasing all draggable tools.
  - Interactive profile dropdown allowing instant switching between profiles and live updating of the preview bars.
  - "Reset Layout" action restoring default Standard configuration.
- Exported all new models and customizer widgets in `lib/vlc_modern.dart`.

---

## 2. Key Architectural Decisions & Ponytail Discipline
1. **Ponytail Ladder Rung 1 (YAGNI) & Rung 7 (Minimum Implementation):**
   - Utilized pure Flutter `Draggable` and `DragTarget` mechanics without introducing heavy third-party drag-and-drop libraries.
   - Built custom `_DashedBorderPainter` with `Path.computeMetrics()` for lightweight, performant dashed drop zone outlines.
2. **Comprehensive Automated Verification:**
   - Added 4 widget tests covering default profile rendering, profile switching, item removal, and layout reset.

---

## 3. Files Created & Modified
- **Created:**
  - `lib/models/toolbar_customizer_models.dart`: Models for toolbar tools and preset user profiles.
  - `lib/ui/settings/drag_drop_customizer.dart`: Drag-and-drop interface customizer dialog.
  - `test/ui/settings/drag_drop_customizer_test.dart`: 4 widget tests for DragDropLayoutCustomizer.
  - `logs/026-drag-drop-layout-customizer.md`: This task handoff log.
- **Modified:**
  - `lib/vlc_modern.dart`: Exported `toolbar_customizer_models.dart` and `drag_drop_customizer.dart`.
  - `docs/Progress.md`: Marked Task 5.3 as complete (27 / 28 tasks, 96.4%).

---

## 4. Test Verification
- All 191 Flutter tests pass:
  ```bash
  flutter test
  # 00:07 +191: All tests passed!
  ```
- Native C ABI engine tests pass:
  ```bash
  ./build/native_core/native_core_tests
  # [PASS] All native_core vlc_bridge tests passed successfully!
  ```

---

## 5. Next Steps
- **Task 5.4:** Complete iOS & Android touch gestures (vertical swipe volume/brightness with Cone HUD, double-tap `±10s` seek, native OS PiP) and run final `/ponytail-audit` across the repository.

