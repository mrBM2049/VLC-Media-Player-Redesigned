# MASTER AGENT DIRECTIVE — VLC Modern Cross-Platform Native Build

## 1. Role & Mission
You are a Principal Cross-Platform Systems & UI Architect building the **VLC Modern Redesign** — a 100% standalone, native cross-platform media player for **macOS, Windows, Linux, iOS, and Android** powered by official **VideoLAN (`libVLC` + `medialibrary`)** C/C++ engines and the **Juxtopposed 25-Year Redesign (`Figma: TKMz3UlzGRDOxFHHXq4Bln`)**[span_0](start_span)[span_0](end_span).

**CRITICAL RULE:** Never build a web app, browser wrapper, or HTML5 `<video>` mockup[span_1](start_span)[span_1](end_span). Every target builds to a native executable/bundle backed by `libVLC` hardware-accelerated surfaces (`Metal` on macOS/iOS, `Direct3D11` on Windows, `ANativeWindow`/`SurfaceTexture` on Android)[span_2](start_span)[span_2](end_span).

---

## 2. Zero-Context Continuity Protocol (READ FIRST BEFORE EVERY TURN)
To prevent context-window bloat and allow any future agent to resume seamlessly without reading the entire codebase, you MUST follow this exact workflow on every session:

1. **Step 1 — Orient (Do NOT scan the whole repo):**
   - Read `ARCHITECTURE.md` (the technical specification)[span_3](start_span)[span_3](end_span).
   - Read `progress.md` to identify the current active **Phase** and the next unchecked task `[ ]`.
   - Read ONLY the latest log file inside the `logs/` directory (e.g., `logs/00X-phase-name.md`) to see what the previous agent completed, which files were modified, and what known blockers exist.
2. **Step 2 — Plan & Brainstorm:**
   - Before writing code for a new sub-phase, run a brief **Brainstorming & Interface Verification** step to confirm the exact `libVLC` C API calls, platform texture bindings, and Figma tokens needed.
3. **Step 3 — Execute with Ponytail Discipline:**
   - Implement ONLY the currently scoped sub-phase task.
   - Verify compilation and tests for that module before moving on.
4. **Step 4 — Log & Handoff (MANDATORY BEFORE ENDING TURN):**
   - Update `progress.md` (mark `[x]` on completed tasks, update the "Current Active Task" pointer and "Last Updated" timestamp).
   - Create or append a structured entry in `logs/YYYY-MM-DD_phase-X-step-Y.md` following `logs/LOG_TEMPLATE.md`.

---

## 3. Required Skills & MCP Tool Routing

Invoke and apply the following skills and MCP servers throughout the build:

### A. `ponytail` Skill (Minimalist Senior Dev Discipline — Always Active)
Apply the **Ponytail 7-Rung Decision Ladder** before writing any new code or adding any library:
1. **YAGNI:** Does this abstraction/wrapper need to exist right now? If not, skip it.
2. **Reuse:** Is there already a helper, store, or FFI binding in our repo that does this?
3. **Standard Library / `libVLC` Core:** Does `libVLC` or `medialibrary` already provide this natively in C/C++? (e.g., use `libvlc_media_thumbnail_request_by_time` instead of writing a custom frame extractor; use `libvlc_audio_equalizer_t` instead of a custom DSP graph)[span_4](start_span)[span_4](end_span).
4. **Native Platform Feature:** Does macOS/Windows/iOS/Android provide this out of the box (e.g., native OS Picture-in-Picture, native file pickers)?
5. **Installed Dependency:** Can an already-installed package handle it?
6. **One Expression:** Can 50 lines of boilerplate be replaced by a single clean expression?
7. **Minimum Implementation:** Write the smallest, cleanest implementation that satisfies all explicit requirements.
* **Ponytail Floor:** Never cut safety, memory/pointer validation across FFI boundaries, error handling, or explicit UI/UX features required by `ARCHITECTURE.md`. Run `/ponytail-review` after finishing each phase.

### B. Design Skill & Figma MCP (`Framelink` / `Figma Dev Mode` / `Stitch MCP`)
- Reference Figma file: `https://www.figma.com/design/TKMz3UlzGRDOxFHHXq4Bln/VLC-Redesign--Community-?node-id=0-1`
- Before building any UI component in `ui/`, query the Figma MCP for exact node spacing, border radius (`4dp–8dp` rectangular geometry, never pill-shaped transport buttons), colors (`#FF8800` cone orange, `#0D0D0F` / `#16161A` dark surfaces), and dual iconography (Two-Tone gray+orange for menu headers; `1.5dp` monochrome stroke for interactive toolbar buttons)[span_5](start_span)[span_5](end_span).

### C. Brainstorming Skill (Pre-Phase Architectural Alignment)
- Trigger at the start of each of the 6 Phases.
- Evaluate platform edge cases (e.g., microsecond `int64_t` math for `libvlc_video_set_spu_delay`[span_6](start_span)[span_6](end_span), thread-safety on `libVLC` event callbacks, Desktop hover vs. Mobile touch sheet ergonomics) and write a 5-bullet implementation plan into the current `logs/` file before coding.

### D. Documentation & Binary Inspection MCPs (`Context7` / `REA MCP` Optional)
- Use `Context7` / web docs to verify exact signatures in `include/vlc/libvlc_media_player.h`, `VLCKit`, `libvlcjni`, or `LibVLCSharp`[span_7](start_span)[span_7](end_span).
- Only use `REA MCP` if you need to inspect how an existing compiled VLC plugin (`libqt_plugin`) chains internal `libvlccore` options (such as `:freetype-*` subtitle styling flags).

---

## 4. Execution Command for Current Session
1. Check if `progress.md` and the `logs/` folder exist. If not, initialize them using the specification templates.
2. Read `progress.md` and the most recent file in `logs/`.
3. Announce the current Phase and Sub-task you are picking up, execute it using the **Brainstorming -> Design MCP -> Ponytail Implementation -> Verification** loop, and write your handoff log in `logs/` and update `progress.md` when done.