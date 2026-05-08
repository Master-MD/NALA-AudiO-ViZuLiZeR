# NALA-AudiO-ViZuLiZeR Porting Prompts

Diese Prompts dienen als Startpunkt fuer spaetere Ports. Die macOS-App bleibt die Referenz.

## iOS / iPadOS Prompt

Act as a senior Apple multimedia engineer. Port the native macOS app `NALA-AudiO-ViZuLiZeR` to iOS and iPadOS while preserving the product concept, visual style, offline workflow, and render behavior.

Reference features:

- Import audio, image, and video from Files/Photos.
- If a video is imported, use its audio track as an audio source while rendering the chosen image as the visual background.
- Canvas presets: 1:1, 9:16, 16:9, Super Wide where practical, and Custom where the UI can support it.
- Visualizer presets: Bottom, Top, Center, Stereo L/R, Mid-Out, Vertical Sides, Bars, Block Stereo Bars, Circle, Neon FFT, Frequency Mesh.
- Controls: transparency, bar count, height, line width, glow, smoothing, color mode, effects, Ken Burns, cover crop, YouTube Music still cover, lyrics overlay.
- Lyrics overlay: support embedded metadata where available, plus copy/paste plain text, LRC, and SRT. Allow position above/below wave, top, center, bottom.
- Export H.264/AAC MP4 to Photos/Files with Standard, Turbo, and MAX modes adapted to device thermals.
- Use SwiftUI, AVFoundation, Accelerate FFT, VideoToolbox, and Metal/MTKView where possible.

Architecture:

- Shared Swift package for models, color engine, lyric parser, audio analysis, render settings, and preset definitions.
- iOS-specific UI optimized for touch, compact side panels, sheets, and iPad split views.
- Metal preview renderer should be the default on capable devices.
- Export must preserve orientation correctly and avoid upside-down frames.
- Long renders should run as foreground tasks with clear progress and cancellation.

Deliverables:

- Xcode iOS/iPadOS project.
- Reused shared core modules from macOS where possible.
- Test assets and smoke tests for MP4-as-audio-source, lyrics overlay, 9:16 export, and still-cover PNG export.
- README with device limitations, thermal notes, and App Store privacy notes.

## Windows ARM64 / AMD64 Prompt

Act as a senior cross-platform multimedia engineer. Plan and build a Windows version of `NALA-AudiO-ViZuLiZeR` for Windows 11 on AMD64 and ARM64, preserving the macOS workflow and visual style.

Reference features:

- Offline import of audio, image, and video files.
- Use video files as audio sources while rendering chosen image backgrounds.
- Canvas presets and custom resolution.
- Wave/FFT visualizer presets matching the macOS app.
- Lyrics overlay with metadata detection where available plus copy/paste plain text, LRC, and SRT.
- Batch queue similar to HandBrake.
- Export H.264/AAC MP4 with Standard, Turbo, and MAX render modes.

Recommended stack:

- UI: Qt 6 / QML or .NET 9 + WinUI 3. Prefer Qt if Linux is a near-term target too.
- GPU preview: Direct3D 12 or Vulkan. Use Vulkan if sharing more code with Linux matters.
- Audio analysis: KissFFT, FFTW, or Accelerate-equivalent SIMD FFT.
- Decode/demux: FFmpeg libraries or Media Foundation, depending on licensing goals.
- Hardware encode:
  - NVIDIA: NVENC
  - AMD: AMF
  - Intel: Quick Sync / oneVPL
  - Windows ARM: Media Foundation hardware encoder where available

Architecture:

- Cross-platform core in C++20/Rust for render settings, lyrics parser, preset definitions, color extraction, and batch queue.
- Platform render backends: Metal on Apple, Vulkan/D3D12 on Windows/Linux.
- Platform encode backends selected at runtime with CPU fallback.
- Deterministic smoke tests for orientation, audio muxing, lyrics overlay, and 9:16 output.

Deliverables:

- Windows installer.
- Portable ZIP build.
- GPU capability detection screen.
- README explaining NVIDIA/AMD/Intel/ARM acceleration and fallback behavior.
