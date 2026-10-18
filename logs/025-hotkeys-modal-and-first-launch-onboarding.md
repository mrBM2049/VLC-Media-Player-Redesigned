# Task Log 025: Hotkeys Modal and First-Launch Onboarding (Task 5.2)

**Date:** October 18, 2026  
**Task:** Phase 5, Task 5.2: Build standalone searchable `HotkeysModal` and `FirstLaunchOnboarding` (Theme/Accent picker + shortcut cheat-sheet).  
**Discipline:** Ponytail 7-Rung UI Engineering • Juxtopposed 25-Year Redesign (`TKMz3UlzGRDOxFHHXq4Bln`)  
**Status:** COMPLETE (8 new widget tests, 187 / 187 tests passing, 11 / 11 native tests passing)

---

## 1. Objectives & Overview
- Build `HotkeysModal` (`lib/ui/settings/hotkeys_modal.dart`):
  - Categorized keyboard shortcut mappings: Playback & Navigation, Audio & Volume, Subtitles & Timing, Video & Display, Drawers & Library, General & Files.
  - Interactive category selector pills with active accent styling.
  - Live real-time search input filtering shortcuts by action name, description, key label, or category.
  - Interactive "Rebind Key" dialog capturing arbitrary physical key events via `KeyboardListener`.
  - Monospace visual key badges with customized indicator borders.
  - "Reset All" action restoring default bindings.
- Build `FirstLaunchOnboarding` (`lib/ui/settings/first_launch_onboarding.dart`):
  - Step 0: **Personalize Your Experience** — Theme mode selection (Dark Modern, OLED Pure Black, Clean Light) with immediate visual cards, plus signature accent color picker (Cone Orange `#FF8800`, Electric Cyan, Royal Purple, Lime Green, Crimson).
  - Step 1: **Master Essential Hotkeys** — 2-column shortcut cheat-sheet emphasizing Space (Play/Pause), F (Fullscreen), V / S (Subtitles), B (Audio), Q (Play Queue), and Ctrl+P (Preferences).
  - Step 2: **Ready to Watch** — Completion confirmation with "Start Watching" and quick tip on Ctrl+P access.
  - Smooth progress indicator bar tracking wizard progress.
  - "Skip Setup" and "Back" navigation controls.
- Exported all new components in `lib/vlc_modern.dart`.

---

## 2. Key Architectural Decisions & Ponytail Discipline
1. **Ponytail Ladder Rung 1 (YAGNI) & Rung 7 (Minimum Implementation):**
   - Implemented hotkey mapping and rebinding using native Flutter `KeyboardListener` and `LogicalKeyboardKey` without bulky external shortcut plugins.
   - Designed onboarding wizard with responsive step transitions using pure Flutter animation primitives (`AnimatedFractionallySizedBox`).
2. **Comprehensive Automated Verification:**
   - Added 8 widget tests validating hotkey filtering by category, live keyword search, rebinding dialog lifecycle, reset functionality, step transitions, theme selection callbacks, and skip actions.

---

## 3. Files Created & Modified
- **Created:**
  - `lib/ui/settings/hotkeys_modal.dart`: Standalone hotkeys modal with search and rebinding.
  - `lib/ui/settings/first_launch_onboarding.dart`: 3-step first launch onboarding wizard.
  - `test/ui/settings/hotkeys_modal_test.dart`: 5 widget tests for HotkeysModal.
  - `test/ui/settings/first_launch_onboarding_test.dart`: 3 widget tests for FirstLaunchOnboarding.
  - `logs/025-hotkeys-modal-and-first-launch-onboarding.md`: This task handoff log.
- **Modified:**
  - `lib/vlc_modern.dart`: Exported `hotkeys_modal.dart` and `first_launch_onboarding.dart`.
  - `docs/Progress.md`: Marked Task 5.2 as complete (27 / 28 tasks, 96.4%).

---

## 4. Test Verification
- All 187 Flutter tests pass:
  ```bash
  flutter test
  # 00:07 +187: All tests passed!
  ```
- Native C ABI engine tests pass:
  ```bash
  ./build/native_core/native_core_tests
  # [PASS] All native_core vlc_bridge tests passed successfully!
  ```

---

## 5. Next Steps
- **Task 5.3:** Build `DragDropLayoutCustomizer` (dashed drop-zone canvas for dragging buttons in/out of bars) with switchable User Profiles.
- **Task 5.4:** Complete iOS & Android touch gestures and final repo audit.

