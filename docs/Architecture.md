# VLC Modern Redesign — Native Cross-Platform Architecture & Component Specification (`ARCHITECTURE.md`)

> **AGENT DIRECTIVE:** This document is the single source of truth for building a **100% Standalone, Native Cross-Platform VLC Media Player Application** across **macOS, Windows, Linux, iOS, and Android** using official **VideoLAN (`libVLC` / `medialibrary`)** open-source engines and the **Juxtopposed 25-Year Redesign** specification (`Figma: TKMz3UlzGRDOxFHHXq4Bln`).
>
> **CRITICAL CONSTRAINT:** Do **NOT** build a website, browser wrapper, or HTML5 `<video>` mockup. Every target platform must compile to a standalone native binary/bundle (`.app`/`.dmg`, `.exe`/`.msix`, `.ipa`, `.apk`/`.aab`) powered directly by `libVLC` C/C++ native libraries.

---

## 1. Official VideoLAN Open-Source Resources to Use

Pull directly from VideoLAN's official open-source repositories (`https://code.videolan.org/videolan/`):

| Resource / Repo | Purpose in This Build | Official Source |
| :--- | :--- | :--- |
| **`libVLC` (VLC 3.x / 4.0 Core)** | Core C/C++ multimedia engine (demuxers, hardware decoding, audio/video filters, 10-band EQ, subtitle renderer, Chromecast/UPnP). | `https://code.videolan.org/videolan/vlc` (`include/vlc/libvlc*.h`) |
| **`medialibrary`** | VideoLAN's official C++ SQLite media indexer used by VLC Android/iOS/4.0 to scan folders, track watched progress, and group albums/artists/shows. | `https://code.videolan.org/videolan/medialibrary` |
| **`VLCKit` (`MobileVLCKit` / `TVVLCKit`)** | Official Objective-C / Swift framework wrapping `libVLC` for **macOS and iOS**. | `https://code.videolan.org/videolan/VLCKit` |
| **`libvlcjni` (VLC Android Core)** | Official Kotlin / Java / JNI bindings wrapping `libVLC` and `medialibrary` for **Android**. | `https://code.videolan.org/videolan/libvlcjni` |
| **`LibVLCSharp` (VideoLAN .NET)** | Official VideoLAN C# bindings for Windows, macOS, Linux, iOS, and Android (works with Avalonia UI & .NET MAUI). | `https://code.videolan.org/videolan/LibVLCSharp` |
| **`vlcpp` (`libvlcpp`)** | Official header-only C++11/17/20 wrapper around the `libVLC` C API. | `https://code.videolan.org/videolan/libvlcpp` |

---

## 2. Choosing Your Cross-Platform Native UI Engine

To ship a single unified codebase to **macOS, Windows, iOS, and Android** with zero WebView overhead and pixel-perfect custom UI (rounded rectangles, backdrop glass blur, custom cone sliders, and drag-and-drop), use one of these three native toolkits:

| Architecture Option | UI Framework | Native `libVLC` Bridge | Why Choose This |
| :--- | :--- | :--- | :--- |
| **Option A (Recommended for 100% Shared GPU UI)** | **Flutter (Impeller GPU Engine — Dart + C++ FFI)** | **`dart:ffi`** direct bindings to `libvlc.dylib` / `.dll` / `.so` + `MobileVLCKit` (iOS) / `libvlcjni` (Android) Texture Registry | Skia/Impeller renders identical pixel-perfect custom Figma UI at 120fps on macOS, Windows, iOS, and Android with native C FFI speed. |
| **Option B (Official VideoLAN Managed Stack)** | **Avalonia UI / .NET 9 Multi-Target (C# & XAML)** | **`LibVLCSharp`** (`VideoLAN.LibVLC.Windows`, `.Mac`, `.iOS`, `.Android`) | Maintained directly by the VideoLAN team (`videolan/LibVLCSharp`) with ready-made NuGet binaries for all 5 platforms. |
| **Option C (VLC 4.0 Upstream Native Stack)** | **C++20 + Qt 6 Quick (QML)** | **`libvlcpp` + Direct C API** (`libvlc_media_player_t`) | Matches upstream VLC 4.0 desktop architecture and shaders directly; requires platform adjustments on iOS/Android. |

> **DEFAULT AGENT TARGET:** Unless instructed otherwise by the user, implement using **Option A (Flutter Native Desktop & Mobile + Direct `dart:ffi` / Native Texture `libVLC` Bridge)** OR **Option B (Avalonia UI + `LibVLCSharp`)**. All architectural contracts below are structured so the C/C++ `libVLC` core layer and UI component hierarchy map 1:1 to either engine.

---

## 3. System Architecture & Native Video Surface Rendering

```text
+-----------------------------------------------------------------------------------+
|                 CROSS-PLATFORM NATIVE GPU UI LAYER (macOS/Win/iOS/Android)        |
|                                                                                   |
|  +-----------------------+  +-------------------------+  +---------------------+  |
|  |  Hardware Video View  |  |  4-Tab Inspector Drawer |  |  Compact / Full     |  |
|  |  + OSD Overlay Layer  |  | (Sub/Audio/Video/Play)  |  |  Media Library View |  |
|  +-----------------------+  +-------------------------+  +---------------------+  |
|  +-----------------------------------------------------------------------------+  |
|  |         Adaptive Bottom Control Bar & Thick Edge Seek Bar                   |  |
|  |   (Desktop: Hover/Drag & Right-Click | Mobile: Touch Gestures & Sheets)     |  |
|  +-----------------------------------------------------------------------------+  |
+-----------------------------------------+-----------------------------------------+
                                          |
                        Native FFI / C++ Bridge (Zero Serialization)
                                          |
+-----------------------------------------v-----------------------------------------+
|                        VIDEOLAN NATIVE CORE (`libVLC` + `medialibrary`)           |
|                                                                                   |
|  +-----------------------+  +-------------------------+  +---------------------+  |
|  | `libvlc_media_player` |  |  Thumbnail & Waveform   |  |  Subtitle & Preset  |  |
|  |  Hardware Surface:    |  |  Extractor (`libvlc`    |  |  Engine (OpenSub    |  |
|  |  • macOS/iOS: Metal   |  |  `media_thumbnail_req`  |  |  REST API, Folder   |  |
|  |  • Windows: D3D11     |  |  + PCM Audio Callbacks) |  |  Fuzzy Auto-Match)  |  |
|  |  • Android: AWindow   |  |                         |  |                     |  |
|  +-----------------------+  +-------------------------+  +---------------------+  |
|  +-----------------------------------------------------------------------------+  |
|  |           VideoLAN `medialibrary` (SQLite) + Profile & Preset Store         |  |
|  |       (Folder Watcher, Watched Progress, M3U IPTV Parser, Bookmarks)        |  |
|  +-----------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------+