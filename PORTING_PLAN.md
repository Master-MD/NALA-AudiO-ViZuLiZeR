# NALA-AudiO-ViZuLiZeR Cross-Platform Port Plan

## Goal

Keep the macOS app native, but extract a shared rendering/audio/export core that can ship on:

- macOS Apple Silicon and Intel
- Windows x64 and Windows ARM64
- Ubuntu x64 and Ubuntu ARM64

## Recommended Architecture

Use a shared C++/Rust core plus thin platform UIs:

- UI shell:
  - macOS: SwiftUI/AppKit
  - Windows: Qt 6 or Tauri/React shell with native file dialogs
  - Ubuntu: Qt 6 or Tauri/GTK shell
- Rendering core:
  - Preferred cross-platform API: Vulkan
  - macOS: Vulkan through MoltenVK or keep native Metal backend
  - Windows: Vulkan first, optional Direct3D 12 backend later
  - Linux: Vulkan first
- GPU vendors:
  - NVIDIA: Vulkan + NVENC for export
  - AMD: Vulkan + AMF on Windows, VAAPI on Linux
  - Intel: Vulkan + Quick Sync / oneVPL where available
  - Apple: Metal + VideoToolbox
- Audio analysis:
  - Cross-platform FFT: FFTW, KissFFT, or Accelerate on Apple behind the same interface
  - Decode: FFmpeg/libavformat or platform media readers
- Encoding:
  - Apple: VideoToolbox
  - Windows NVIDIA: NVENC
  - Windows AMD: AMF
  - Windows Intel: Quick Sync / Media Foundation / oneVPL
  - Linux NVIDIA: NVENC
  - Linux AMD/Intel: VAAPI
  - CPU fallback: x264/x265 only as fallback, not default

## Core Interfaces To Extract

Create a `nala-core` package with these stable interfaces:

- `AudioAnalyzer`
  - input media path
  - output waveform, FFT bins, beat markers, duration
- `VisualizerRenderer`
  - input image/video frame, audio analysis frame, visualizer settings
  - output GPU framebuffer or CPU fallback frame
- `Encoder`
  - input frames + audio stream
  - codec/profile/bitrate/fps/resolution
  - output MP4/MOV/WebM
- `ProjectModel`
  - JSON-compatible schema for media paths and settings

## Build Matrix

Phase 1:

- macOS universal binary: arm64 + x86_64
- Windows x64 portable build
- Ubuntu x64 AppImage

Phase 2:

- Windows ARM64
- Ubuntu ARM64
- GPU capability detection screen
- CI builds for all targets

## Practical Next Step

Do not rewrite the whole app immediately. First extract the project model, audio analysis, and export settings into a shared schema. Then build a standalone Vulkan prototype that renders:

1. background image
2. bottom waveform
3. block stereo bars
4. opacity/glow controls

After that, wire the prototype into Windows/Linux packaging.

## Risk Notes

- GPU video encoding APIs differ heavily by OS/vendor.
- Linux hardware encoding depends on driver install quality.
- Windows ARM64 GPU encoding support must be tested per device.
- Vulkan rendering is portable, but media decode/encode is the real compatibility risk.
