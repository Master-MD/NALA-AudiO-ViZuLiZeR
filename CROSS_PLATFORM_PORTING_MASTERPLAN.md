# NALA-AudiO-ViZuLiZeR Cross-Platform Masterplan

Stand: 2026-05-09

Ziel: aus der stabilen macOS-Version von `NALA-AudiO-ViZuLiZeR` spaeter eine iOS/iPadOS-Version sowie Windows- und Ubuntu-Versionen bauen, ohne die macOS-App zu zerlegen oder den aktuellen Export-Workflow zu riskieren.

## Kurzfazit

Der beste Weg ist nicht ein 1:1 Auto-Port der SwiftUI-macOS-App. Die App sollte zuerst in klar getrennte Schichten zerlegt werden:

1. Gemeinsame Produkt- und Projektlogik
2. Audioanalyse
3. Visualizer-/Render-Einstellungen
4. Preview-Renderer
5. Export-Renderer
6. Plattform-UI
7. Plattform-Encoding und Packaging

Fuer iPhone/iPad ist der Port am einfachsten, weil SwiftUI, AVFoundation, Accelerate, Metal und VideoToolbox auch auf iOS/iPadOS existieren.

Fuer Windows und Ubuntu ist ein echter Neuaufbau des Render-/Export-Cores sinnvoller als ein Swift-Port. Die bessere Zielarchitektur ist ein gemeinsamer C++/Rust-Core plus native Plattform-Shells.

## Skill-Status in dieser Codex-Umgebung

### Bereits installierte bzw. verfuegbare Skills

- `skill-installer`: installiert neue Codex-Skills aus der kuratierten OpenAI-Skill-Liste oder GitHub.
- `openai-docs`: fuer OpenAI API/Produkt-Dokumentation.
- `imagegen`: fuer Bildgenerierung, nicht fuer App-Porting.
- `plugin-creator`, `skill-creator`: fuer Codex-Erweiterungen.

### Neu installiert

Ich habe den kostenlosen kuratierten Skill `winui-app` installiert:

```text
/Users/ultramacuser/.codex/skills/winui-app
```

Wichtig: Codex muss neu gestartet werden, damit dieser Skill als aktiver Skill sauber in der Skill-Liste auftaucht.

### Was `winui-app` leisten kann

Der Skill ist gut fuer:

- neue native Windows Desktop Apps mit WinUI 3
- Windows App SDK Setup
- C#/.NET WinUI Projektstruktur
- Windows UX, Navigation, Fluent Design
- Build-/Run-/Launch-Verifikation
- Windows Packaging-Entscheidungen

Der Skill loest aber nicht automatisch:

- SwiftUI nach WinUI konvertieren
- Metal nach Direct3D/Vulkan portieren
- AVFoundation nach Media Foundation/FFmpeg portieren
- den kompletten Visualizer-Renderer neu schreiben

### Fehlende Skills

In der aktuell verfuegbaren kuratierten Skill-Liste gibt es keinen dedizierten kostenlosen Skill fuer:

- macOS SwiftUI nach iOS SwiftUI Port
- macOS SwiftUI nach Ubuntu App Port
- Multimedia-Renderer-Port Metal -> Vulkan/Direct3D
- AVFoundation/VideoToolbox -> NVENC/AMF/VAAPI Port

Es gibt Skills wie `figma`, `playwright`, `aspnet-core`, `cli-creator`, aber diese sind fuer dieses konkrete Porting nicht der Kern.

## Ist ein Master-Prompt schneller?

Ein sehr guter Master-Prompt ist nuetzlich fuer:

- einen ersten Scaffold
- eine saubere Architekturvorgabe
- Code-Reviews gegen eine Featureliste
- Copilot/Codex als Bauplan zu fuettern

Ein Master-Prompt ersetzt aber nicht:

- echte Build-Tests pro Plattform
- Audio-/Video-Testsets
- GPU-/Encoder-Kompatibilitaet
- Packaging
- Performance-Messungen

Pragmatisch:

- iOS/iPadOS kann man mit einem Master-Prompt relativ schnell scaffolden, weil viel Apple-Technologie wiederverwendbar ist.
- Windows kann man mit `winui-app` und einem Master-Prompt gut als Shell starten, aber der Render-/Export-Core muss bewusst neu gebaut werden.
- Ubuntu sollte nicht als erster Port gebaut werden. Ubuntu ist wegen Treibern, VAAPI/NVENC, FFmpeg-Packaging und AppImage/Flatpak deutlich anspruchsvoller.

## Empfohlene Reihenfolge

### Phase 0: macOS Referenz einfrieren

Ziel: macOS bleibt die Referenz, waehrend Ports entstehen.

Checkliste:

- [ ] Aktuelle macOS-Version taggen, z.B. `v0.3.5-macos-reference`.
- [ ] Testassets festlegen:
  - [ ] ein MP3 + 9:16 Cover
  - [ ] ein MP4 als Audioquelle + separates Bild
  - [ ] Lyrics plain text
  - [ ] Lyrics LRC
  - [ ] 1:1, 9:16, 16:9
- [ ] Smoke-Tests dokumentieren:
  - [ ] Standard Export
  - [ ] MAX Export
  - [ ] Batch Export mit zwei Jobs
  - [ ] MP4-Audioquelle
  - [ ] Lyrics Overlay
- [ ] Screenshots der Referenz-UI behalten.
- [ ] Output-Frames als visuelle Golden-Master speichern.

### Phase 1: Shared Apple Core fuer macOS + iOS

Ziel: Apple-Code so strukturieren, dass iOS nicht alles neu schreiben muss.

Module:

- `NALAProjectCore`
  - Projektmodell
  - Presets
  - Canvas-Settings
  - Effekt-Settings
  - Lyrics Parser
  - JSON Save/Load
- `NALAAudioCore`
  - AVFoundation Decode
  - Accelerate FFT
  - Beat-/Energy-Analyse
- `NALAAppleRenderCore`
  - CPU/CoreGraphics Fallback
  - spaeter Metal Renderer
  - ExportSnapshot
  - Frame-Renderer

Checkliste:

- [ ] `ExportSnapshot` vom UI-Code trennen.
- [ ] `LyricsEngine` in eigenes File/Modul verschieben.
- [ ] `AudioTools` in eigenes File/Modul verschieben.
- [ ] Presets aus `main.swift` entfernen und in Core-Modul legen.
- [ ] Render-Settings codierbar machen.
- [ ] Testbare Funktionen ohne App-UI bereitstellen.
- [ ] macOS App nach Refactor erneut bauen.
- [ ] macOS Export-Tests erneut laufen lassen.

### Phase 2: iOS/iPadOS App

Ziel: echte Touch-App fuer iPhone und iPad.

Technologie:

- SwiftUI
- AVFoundation
- Accelerate
- Metal/MTKView fuer Preview
- VideoToolbox via AVAssetWriter
- PhotosPicker / DocumentPicker

Anpassungen:

- Sidebar-Layout wird zu Tabs/Sheets.
- Preview muss touchfreundlich sein.
- Medienimport ueber Photos/Files.
- Export zu Photos und Files.
- Lange Exports brauchen klare Fortschrittsanzeige und Abbruch.
- MAX-Modus muss thermisch vorsichtiger sein als auf M4 Max.

Checkliste:

- [ ] iOS Target anlegen.
- [ ] iPad Split View Layout.
- [ ] iPhone kompakte Tabs.
- [ ] PhotosPicker fuer Bild/Video.
- [ ] FileImporter fuer Audio/Lyrics.
- [ ] Copy/Paste Lyrics TextEditor.
- [ ] 9:16 Export.
- [ ] MP4 als Audioquelle.
- [ ] Still Cover PNG Export.
- [ ] Orientation-Tests.
- [ ] Thermal-/Performance-Hinweise.

Risiken:

- iOS Background-Rendering ist limitiert.
- Sehr lange Songs + 4K Export koennen thermisch bremsen.
- Files/Photos Permissions muessen sauber erklaert werden.

### Phase 3: Windows Version

Es gibt zwei Wege.

#### Option A: WinUI 3 + C# Shell

Gut fuer:

- native Windows Optik
- schnelle Desktop-UX
- Nutzung des installierten `winui-app` Skills
- Windows Store/Installer Pfad

Schwierig fuer:

- High-End GPU Visualizer
- Cross-platform Wiederverwendung mit Ubuntu
- FFmpeg/Native Encoder Integration

Empfohlen, wenn Windows zuerst als eigenstaendige Windows-App gebaut werden soll.

#### Option B: Qt 6/QML + C++/Rust Core

Gut fuer:

- Windows und Ubuntu mit gleicher UI-Basis
- Vulkan/OpenGL/Skia Integration
- langfristig weniger doppelte Arbeit

Schwierig fuer:

- mehr initiale Architekturarbeit
- Packaging und Styling
- weniger nativer Windows-Look als WinUI

Empfohlen, wenn Windows und Ubuntu beide wichtig sind.

Windows GPU/Encoding:

- NVIDIA: NVENC
- AMD: AMF
- Intel: Quick Sync / oneVPL / Media Foundation
- ARM64 Windows: Media Foundation Hardware Encoder, falls vorhanden
- Fallback: CPU x264/x265 nur als Backup

Windows Checkliste:

- [ ] Ziel-Stack entscheiden: WinUI 3 oder Qt 6.
- [ ] Projektmodell aus macOS als JSON-Schema uebernehmen.
- [ ] Audioanalyse portieren.
- [ ] Lyrics Parser portieren.
- [ ] Preset-System portieren.
- [ ] Preview Renderer bauen.
- [ ] Export Renderer bauen.
- [ ] Encoder Capability Detection.
- [ ] H.264/AAC MP4 Export.
- [ ] Batch Queue.
- [ ] Installer oder Portable ZIP.
- [ ] Windows x64 Build.
- [ ] Windows ARM64 Build.
- [ ] Tests mit NVIDIA/AMD/Intel.

### Phase 4: Ubuntu Version

Empfohlener Stack:

- Qt 6/QML fuer UI
- C++20 oder Rust Core
- Vulkan fuer GPU Preview/Renderer
- FFmpeg/libav fuer Decode/Mux
- VAAPI/NVENC fuer Encoding
- AppImage oder Flatpak fuer Packaging

Ubuntu Checkliste:

- [ ] Ubuntu x64 Zielsystem festlegen.
- [ ] Ubuntu ARM64 optional spaeter.
- [ ] GPU Capability Screen.
- [ ] FFmpeg Runtime/Lizenzstrategie.
- [ ] VAAPI Support testen.
- [ ] NVIDIA NVENC Support testen.
- [ ] Wayland/X11 Verhalten testen.
- [ ] AppImage bauen.
- [ ] Flatpak pruefen.
- [ ] Headless Smoke-Tests fuer Export.

Risiken:

- Linux Hardware Encoding ist stark treiberabhaengig.
- VAAPI/NVENC Setup ist pro Nutzer unterschiedlich.
- AppImage mit FFmpeg kann lizenztechnisch und technisch heikel sein.

## Gemeinsames Projektformat

Alle Plattformen sollten dieselbe Projektdatei lesen koennen.

Dateiendung:

```text
.nala-project.json
```

Schema grob:

```json
{
  "version": "1.0",
  "media": {
    "audioPath": "...",
    "imagePaths": ["..."],
    "videoPaths": ["..."],
    "stillCoverPath": "..."
  },
  "canvas": {
    "preset": "vertical",
    "width": 1080,
    "height": 1920,
    "fitMode": "fill"
  },
  "visualizer": {
    "kind": "blockBars",
    "position": "bottom",
    "stereoMode": "leftRight",
    "barCount": 96,
    "opacity": 0.72
  },
  "colors": {
    "mode": "manual",
    "primary": "#00E6FF",
    "secondary": "#FF00D6",
    "glow": "#FFFFFF"
  },
  "effects": {
    "bassShake": 0.18,
    "zoomPunch": 0.12,
    "rgbSplit": 0.20,
    "glitch": 0.08,
    "particles": 0.36,
    "beatFlash": 0.10,
    "lensGlow": 0.28
  },
  "lyrics": {
    "enabled": true,
    "position": "aboveWave",
    "size": 1.0,
    "opacity": 0.95,
    "text": "..."
  },
  "export": {
    "mode": "max",
    "fps": 60,
    "bitrate": 38000000,
    "codec": "h264",
    "audio": "aac"
  }
}
```

## Lizenz- und Kostenhinweise

Kostenlos nutzbar:

- Swift / Xcode fuer lokale Entwicklung
- .NET / WinUI / Windows App SDK
- Rust
- C++ Toolchains
- Qt unter LGPL, wenn die Lizenzbedingungen eingehalten werden
- FFmpeg je nach Build LGPL/GPL
- Vulkan SDK

Moegliche Kosten:

- Apple Developer Program fuer iOS Distribution ausserhalb lokaler Tests
- Windows Store Signierung / Zertifikate je nach Distributionsweg
- kommerzielle Qt-Lizenz, wenn LGPL nicht passt
- Code Signing Zertifikate fuer Windows

Wichtig:

- FFmpeg kann GPL-Komponenten enthalten, wenn z.B. libx264/libx265 eingebaut werden.
- Fuer eine kommerzielle Closed-Source-App muss die Lizenzstrategie vorab geklaert werden.

## Master-Prompt: iOS/iPadOS

```text
Act as a senior Apple multimedia engineer. Build an iOS and iPadOS version of NALA-AudiO-ViZuLiZeR based on the existing macOS SwiftUI app.

Goal:
Create a native SwiftUI app for iPhone and iPad that imports audio, images, and MP4 videos, uses the video audio track when requested, overlays audio-reactive visualizers and optional lyrics, and exports social-ready MP4 videos.

Architecture:
- Extract or recreate shared modules: ProjectModel, RenderSettings, VisualizerPreset, EffectSettings, LyricsEngine, AudioAnalysisService, ColorEngine.
- Use SwiftUI for UI.
- Use AVFoundation for media import/export.
- Use Accelerate for FFT.
- Use Metal/MTKView for preview where possible.
- Use AVAssetWriter/VideoToolbox for H.264/AAC export.

Features:
- Import audio from Files.
- Import images/videos from Photos and Files.
- MP4/MOV/M4V can be used as audio source while rendering selected image background.
- Canvas presets: 1:1, 9:16, 16:9, custom where practical.
- Visualizer presets: Bottom Waveform, Top, Center, Stereo L/R, Mid-Out, Bars, Block Stereo Bars, Circle, Neon FFT, Frequency Mesh.
- Controls: opacity, bar count, height, line width, glow, smoothing, colors, Ken Burns, effects.
- Lyrics overlay with embedded metadata where available, plus copy/paste plain text, LRC, and SRT.
- Lyrics positions: above wave, below wave, top, center, bottom.
- YouTube Music Still Cover / thumbnail export.
- Standard, Turbo, MAX render modes adapted for iOS thermals.
- Batch queue optional on iPad first.

UI:
- iPad: split view with left presets, center preview, right inspector.
- iPhone: tabs/sheets with preview-first workflow.
- Dark mode, NALA cyan/pink/gunmetal style.

Validation:
- Build and run on iPhone simulator and iPad simulator.
- Export 9:16 test video.
- Test MP4 as audio source.
- Test lyrics overlay.
- Verify no upside-down video.
- Document known iOS limitations.
```

## Master-Prompt: Windows WinUI 3

```text
Act as a senior Windows multimedia engineer. Build a native Windows 11 version of NALA-AudiO-ViZuLiZeR using WinUI 3, C#, .NET, and Windows App SDK.

Goal:
Create a Windows desktop music visualizer app that mirrors the macOS workflow: import audio/image/video, use video audio tracks, render audio-reactive visualizers, optional lyrics, and export MP4.

Use the WinUI 3 shell for:
- main window
- navigation
- media tray
- preset library
- inspector panels
- batch queue
- export controls

Use a separate render/export core for:
- audio decoding and FFT
- image transforms
- visualizer frame generation
- lyrics parsing/rendering
- H.264/AAC export

Technology options:
- UI: WinUI 3 + Windows App SDK.
- Decode/mux: Media Foundation or FFmpeg libraries.
- GPU preview: Direct3D 11/12, Win2D, or Vulkan.
- Encode: Media Foundation first, then NVENC/AMF/Quick Sync detection.

Required features:
- Drag and drop.
- File pickers.
- MP3/WAV/FLAC/AAC/M4A audio.
- JPG/PNG/WEBP images.
- MP4/MOV/M4V video imports.
- MP4 video as audio source.
- 1:1, 9:16, 16:9, Super Wide, Ultra Wide, Custom canvas.
- Visualizer presets matching macOS.
- Lyrics overlay with plain text, LRC, SRT, optional metadata scan.
- Standard/Turbo/MAX render modes.
- Batch queue with sequential rendering first.

Validation:
- Build on Windows x64.
- Build on Windows ARM64 if toolchain supports it.
- Export 9:16 H.264/AAC MP4.
- Test MP4 as audio source.
- Test lyrics overlay.
- Test batch queue with two jobs.
- Add README and installer notes.
```

## Master-Prompt: Ubuntu / Linux

```text
Act as a senior Linux multimedia engineer. Build an Ubuntu version of NALA-AudiO-ViZuLiZeR using Qt 6/QML plus a C++20 or Rust multimedia core.

Goal:
Create a Linux desktop music visualizer app for Ubuntu x64 first, with a later path to ARM64. The app must import audio/images/videos, use MP4 audio tracks, render visualizers, support lyrics, and export MP4.

Recommended stack:
- UI: Qt 6/QML.
- Core: C++20 or Rust.
- GPU preview/render: Vulkan.
- Decode/mux: FFmpeg/libav.
- Encoding:
  - NVIDIA NVENC where available.
  - VAAPI for AMD/Intel where available.
  - CPU x264 fallback.
- Packaging: AppImage first, Flatpak later.

Features:
- Drag and drop.
- Audio/image/video file pickers.
- Project JSON compatible with macOS schema.
- Visualizer presets matching macOS.
- Lyrics plain/LRC/SRT parser.
- Canvas presets and custom resolution.
- Batch queue.
- Standard/Turbo/MAX render modes.
- GPU capability detection screen.

Validation:
- Build on Ubuntu x64.
- Export 9:16 H.264/AAC MP4.
- Test with NVIDIA, AMD, and Intel where possible.
- Verify VAAPI/NVENC fallback handling.
- Package as AppImage.
- Document driver and codec limitations.
```

## Master-Prompt: Shared Core

```text
Act as a senior cross-platform multimedia architect. Extract the platform-independent core of NALA-AudiO-ViZuLiZeR into a shared library design that can power macOS, iOS, Windows, and Ubuntu.

Inputs:
- Current macOS SwiftUI app behavior.
- Existing render settings, presets, lyrics parser, audio analysis, canvas modes, effects, and export modes.

Deliverables:
- Project JSON schema.
- Core module boundaries.
- Renderer backend interface.
- Encoder backend interface.
- Audio analyzer interface.
- Test asset suite.
- Golden-master frame comparison strategy.
- Platform adaptation plan for Apple, Windows, and Linux.

Do not rewrite UI first. Preserve macOS as the reference implementation and move logic behind stable interfaces before building ports.
```

## Empfohlene Entscheidung

Wenn Geschwindigkeit wichtig ist:

1. iOS/iPadOS zuerst.
2. Windows danach mit WinUI 3 Shell und stabilem CPU/GPU-Hybrid-Renderer.
3. Ubuntu zuletzt.

Wenn langfristige Cross-Platform-Wartbarkeit wichtiger ist:

1. Gemeinsames C++/Rust Core-Design.
2. Qt 6/QML fuer Windows und Ubuntu.
3. Apple bleibt SwiftUI mit gemeinsamem Schema, aber separatem Apple-Renderer.

Meine Empfehlung fuer dieses Projekt:

- Kurzfristig: iOS/iPadOS Port planen und bauen, weil Apple-Technologien wiederverwendbar sind.
- Mittelfristig: Windows WinUI 3 Prototyp fuer UI und Workflow.
- Langfristig: gemeinsamer Rust/C++ Render-Core fuer Windows/Ubuntu mit Vulkan und Hardware-Encoder-Abstraktion.

