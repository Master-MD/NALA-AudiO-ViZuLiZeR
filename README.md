# NALA-AudiO-ViZuLiZeR

Native macOS music visualizer for turning audio plus cover art into social-ready visualizer videos.

![NALA app icon](docs/screenshots/app-icon.png)

## macOS Preview

![macOS UI reference](docs/screenshots/macos-ui-reference.png)

## Current macOS Build

A test DMG is included for quick installation:

[dist/NALA-AudiO-ViZuLiZeR.dmg](dist/NALA-AudiO-ViZuLiZeR.dmg)

Open the DMG and drag `NALA-AudiO-ViZuLiZeR.app` into `Applications`.

## Quick Start

1. Drag an audio file into the app, or double-click the audio area and choose `mp3`, `wav`, `flac`, `aac`, or `m4a`.
2. Drag a cover image into the app, or double-click the image area and choose `jpg`, `png`, or `webp`.
3. Pick a canvas preset such as `9:16 Vertical` for TikTok/Reels/Shorts or `16:9 Landscape` for YouTube.
4. Choose a visualizer preset from the left-side `Krasse Waves` library.
5. Fine-tune transparency, bar count, height, line width, glow, smoothing, color mode, and effects in the right sidebar.
6. Set the output filename and export folder in the bottom bar.
7. Click `RENDERN` to create the MP4.

## How To Use

### Import

Use drag and drop anywhere in the window, or use the media tray buttons:

- `Bilder` imports image backgrounds and covers.
- `Videos` stores video media and can use MP4/MOV/M4V audio as the audio source.
- `Audio` imports a standalone audio file.
- Each imported media item has an `X` control to remove mistakes without restarting the app.

### Canvas And Cover Framing

The app supports social formats for music promotion:

- `1:1 Square`: Instagram/Facebook feed.
- `9:16 Vertical`: TikTok, Instagram Reels, YouTube Shorts, Spotify Canvas-style clips.
- `16:9 Landscape`: YouTube, Vimeo, desktop playback.
- `Super Wide`: cinematic/banner use.
- `Ultra Wide`: monitor/cinematic layouts.
- `Custom`: manual width and height.

Use `Fit`, `Fill`, `Stretch`, or `Blur Extend` to control how the image fills the canvas. Use the cover controls for zoom, rotation, and X/Y positioning.

### Visualizer Presets

The left sidebar contains fast presets that configure multiple render settings at once:

- `Mesh Storm`: layered 3D-style FFT lines.
- `Liquid Ice`: smooth neon ribbon.
- `Sub Blocks`: stereo block bars.
- `Circle Halo`: radial pulse spectrum.
- `Stereo Razor`: left/right split bars.
- `Side Walls`: vertical side waves.
- `Mid Out`: center-outward burst.
- `Pulse Core`: centered waveform.
- `Ghost Low`: low-contrast cinematic visual.
- `Trap Bars`: high-contrast EDM/trap-style bars.

After choosing a preset, all settings remain editable in the right sidebar.

### Effects

The current global effects are:

- `Bass Shake`
- `Zoom Punch`
- `RGB Split`
- `Glitch`
- `Particles`
- `Beat Flash`
- `Lens Glow`

Each effect can be enabled/disabled and controlled with a strength slider.

### YouTube Music Cover

Enable `Still Icon aktivieren` to use a specific still cover/thumbnail image. The app can also export a still-cover PNG next to the rendered MP4.

### Export

The export bar lets you choose:

- output filename
- output folder
- render start via `RENDERN`

The exporter creates H.264/AAC MP4 files and automatically avoids overwriting by adding suffixes such as `-2`, `-3`, etc.

## Performance Notes

The current app intentionally prioritizes stable output over maximum hardware saturation:

- Video encoding uses macOS AVFoundation/VideoToolbox, so some work happens on Apple media engines and may not show as `GPU 100%` in Activity Monitor.
- Frame composition is still mostly CPU/CoreGraphics based, so the GPU can look underused even while the export is working.
- `200% CPU` on macOS means roughly two full CPU cores, not 200% of the whole M-series chip.
- Full Metal export rendering is planned for Phase 2, where GPU utilization should become much more visible.

## What It Does

- Audio import by drag and drop, button, or double-click.
- Image import by drag and drop, button, or double-click.
- Video import as project media.
- MP4/MOV/M4V import can automatically use the video's audio track as the audio source.
- Remove accidentally imported media with visible `X` controls.
- Canvas presets: `1:1`, `9:16`, `16:9`, `Super Wide`, `Ultra Wide`, and `Custom`.
- Ultra/4K resolutions for Square, Vertical, Landscape, and Super Wide.
- Canvas fit modes: Fit, Fill, Stretch, and Blur Extend.
- Cover adjustment with zoom below `1.0`, X/Y offset, rotation, and reset.
- Visualizers: Bottom, Top, Center Wave, Stereo Left/Right, Mid-Outward, Vertical Side Waves, Bars, Block Stereo Bars, Circle, Neon FFT Wave, and Frequency Mesh.
- Left-side visualizer preset library with mini FFT tiles for Mesh Storm, Liquid Ice, Sub Blocks, Circle Halo, Stereo Razor, Side Walls, Mid Out, Pulse Core, Ghost Low, and Trap Bars.
- Waveform controls: position, stereo mode, direction, mirroring, transparency, bar count, height, line width, glow, and smoothing.
- Color modes: Intelligent Match, Extreme Contrast, Colorful, Manual HEX, and Low Contrast.
- Ken Burns: Zoom In, Zoom Out, Pan Left/Right/Up/Down, and Smooth Drift.
- Effects: Bass Shake, Zoom Punch, RGB Split, Glitch, Particles, Beat Flash, and Lens Glow.
- YouTube Music Still Icon: choose a cover image or use the current image as cover.
- Adaptive FFT spectrum frames for smoother bars, circles, block visuals, and mesh waves.
- Export naming with automatic filename sanitizing and suffix handling.
- Export MP4 through macOS AVFoundation / VideoToolbox with H.264 video and AAC audio.
- Export smoke tests for generated assets and MP4-as-audio-source workflows.

## Build From Source

Requirements:

- macOS 14 or newer
- Xcode 26 / Swift 6 toolchain or newer

Build:

```bash
swift build -c release
```

Run from source:

```bash
swift run
```

The app exports videos to:

```text
~/Movies/NALA-Exports
```

## Export Smoke Tests

Basic generated asset export:

```bash
.build/release/NALA-AudiO-ViZuLiZeR --smoke-export
```

Double export including MP4 audio-track reuse:

```bash
.build/release/NALA-AudiO-ViZuLiZeR --smoke-double-export
```

Render a short real-asset test:

```bash
.build/release/NALA-AudiO-ViZuLiZeR --render-test-set "/path/song.mp3" "/path/cover.png" 8
```

The third parameter is the test duration in seconds. Rendering a full song can take longer because this MVP uses a stable CPU/CoreGraphics export path.

## DMG Build

```bash
./build_dmg.sh
```

The generated local DMG is written to:

```text
/Users/ultramacuser/Downloads/NALA-AudiO-ViZuLiZeR-Release/NALA-AudiO-ViZuLiZeR.dmg
```

## Known Limits

- The preview is SwiftUI/Canvas-based in this MVP. A shared Metal/MTKView renderer is still the target architecture for a later high-performance release.
- Video backgrounds are prepared as project media. The stable v0.3 export uses a still image/cover as the video background and can extract/use audio from an imported video.
- Effect timing is prepared conceptually; v0.3.2 renders global effect strength. Per-effect start/end keyframes are planned for Phase 2.
- ProRes/H.265, full particles, and shader-grade visualizer scenes are Phase 2.

See [PORTING_PLAN.md](PORTING_PLAN.md) for the Windows/Linux GPU strategy.

## License

This repository uses a dual-license strategy:

- Community/open-source use: GNU AGPL-3.0-or-later, see [LICENSE](LICENSE).
- Proprietary or closed commercial apps based on this work require a separate commercial license from Master-MD.

Important: AGPL is a real open-source license. It allows commercial use when the license terms are followed. If someone wants to build a closed/proprietary commercial product from this project without AGPL obligations, they need a separate commercial agreement.

Attribution is required through the AGPL copyright notices and the project [NOTICE](NOTICE.md).

This is not legal advice. For stronger protection of the product idea, brand, commercial licensing terms, or royalties, consult an IP/software licensing lawyer.
