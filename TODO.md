# NALA-AudiO-ViZuLiZeR TODO

## Performance Notes From v0.3.8

- Current MAX render works and batch render works.
- Activity Monitor shows roughly `220% CPU`, which means about 2.2 fully loaded CPU cores, not the whole M4 Max.
- GPU usage around 20-35% is expected in v0.3.8 because export composition is still CPU/CoreGraphics based.
- VideoToolbox/media engines do part of the encode work, but they do not always appear as normal GPU load.
- SSD is probably not the main limit for typical MP4 export. A 1080x1920 H.264/AAC export writes tens of MB/minute, while the internal SSD can handle far more. The bigger current limits are per-frame composition, encoder backpressure, and sequential frame generation.
- v0.3.8 adds optional `2 Pipelines` batch rendering. This increases throughput when several independent jobs are queued, but does not replace the planned Metal compositor.

## Safe Optimizations First

These should be done before a big renderer rewrite because they are low risk.

- Add a small performance overlay/log for export:
  - total render time
  - average FPS generated
  - encode/mux time
  - output file size
  - selected render mode
- Wrap each exported frame in an `autoreleasepool` to reduce memory pressure on long renders.
- Throttle UI progress updates during batch render so the UI does not get spammed every frame.
- Precompute per-frame audio sample slices for the selected export duration before writing frames.
- Precompute per-frame lyric text/index for exports with lyrics enabled.
- Pre-render the static background image at the final canvas size once, then copy that buffer per frame before drawing waves/effects/lyrics.
- Keep temporary video files in the same output directory volume to avoid cross-volume file moves.
- Add a `Reveal after render` toggle and keep it off during batch renders.
- Add a `Benchmark 10s` command that renders the same 10-second project in Standard, Turbo, and MAX and writes a simple report.

## MAX Render vNext

MAX should eventually mean more than 60 FPS plus bitrate. Target behavior:

- Standard: stable 30 FPS, conservative bitrate, safest path.
- Turbo: 30 FPS, higher bitrate, faster settings, low UI overhead.
- MAX: 60 FPS or 120 FPS preview/export where useful, highest bitrate preset, all safe precomputes enabled.
- MAX Metal: GPU compositor path using Metal/Core Image into `CVPixelBuffer`.

Implementation order:

1. Build an internal `RenderBackend` abstraction:
   - `cpuCoreGraphics`
   - future `metalCompositor`
2. Keep the current CPU renderer as the fallback and golden-reference renderer.
3. Move background transform, Ken Burns, RGB split, glow, visualizer bars/mesh, particles, lyrics, and beat flash behind backend functions.
4. Add pixel-diff smoke tests between CPU and Metal frames for fixed test inputs.
5. Only expose `MAX Metal` once orientation, lyrics, wave placement, and audio muxing match the current stable output.

## Metal Export Compositor

Goal: make GPU usage visible and reduce CPU-bound drawing.

- Use `MTLTexture` or `CIImage` pipeline for background image transform.
- Render visualizer geometry directly on GPU.
- Render glow/blur as Metal/Core Image passes.
- Convert final GPU frame into a `CVPixelBuffer` compatible with `AVAssetWriterInputPixelBufferAdaptor`.
- Keep VideoToolbox for H.264/H.265 encoding.
- Avoid changing audio muxing while replacing only the video frame compositor.

Risks:

- Orientation bugs can return if pixel-buffer coordinate systems are changed carelessly.
- Text rendering for lyrics is harder on pure Metal. Use a cached text layer/texture first.
- Exact glow/particle look may change. Compare frames before replacing the stable path.

## Batch Queue vNext

- Add duplicate job button.
- Add failed-job retry.
- Add queue save/load as JSON.
- Add drag-and-drop reordering on top of the current left/right move controls.
- Add multi-format output groups per source job:
  - one source image/audio setup can render 9:16, 16:9, and 1:1 variants automatically
  - each variant stores canvas preset, fit mode, render mode, output suffix, and optional image crop override
- Add import decision dialog when several images with different aspect ratios are dropped:
  - `Ein Video pro Format/Bild`
  - `Als Ken-Burns/Slideshow verwenden`
  - `Nur aktuelles Bild verwenden`
- Add batch presets:
  - TikTok 9:16
  - YouTube 16:9
  - Spotify Canvas style
  - Square social
- Keep sequential rendering as default.
- Only add parallel rendering after memory and encoder limits are measured. Multiple simultaneous encoders can reduce stability and may not be faster.

## Measurements To Run Before Optimizing

- Instruments Time Profiler on a 30-second MAX export.
- Instruments Metal System Trace after a Metal compositor prototype exists.
- Activity Monitor Disk tab during export to confirm SSD is not saturated.
- Compare 10-second export times:
  - Standard 30 FPS
  - Turbo 30 FPS
  - MAX 60 FPS
  - future MAX Metal 60 FPS
- Confirm output correctness with:
  - portrait 9:16 image
  - MP4 as audio source
  - lyrics overlay enabled
  - block bars and mesh preset
  - batch with at least 2 jobs

## iOS / Windows Planning

- Keep macOS v0.3.x as the reference app.
- Extract shared models and settings first.
- Do not port the current CPU renderer blindly.
- For iOS/iPadOS, target SwiftUI + AVFoundation + Metal.
- For Windows ARM64/AMD64, target a shared C++/Rust core with Vulkan/D3D12 rendering and vendor encoders later.
- See `PORTING_PLAN.md` and `PORTING_PROMPTS.md`.
