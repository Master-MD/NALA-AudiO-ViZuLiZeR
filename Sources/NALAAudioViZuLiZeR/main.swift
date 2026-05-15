import Accelerate
import AVFoundation
import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@main
struct NALAApp: App {
    @StateObject private var model = AppModel()

    init() {
        SmokeTest.runIfRequested()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .preferredColorScheme(.dark)
                .frame(minWidth: 1180, minHeight: 760)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

struct MediaItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
}

enum CanvasPreset: String, CaseIterable, Identifiable, Sendable {
    case square = "1:1 Square"
    case vertical = "9:16 Vertical"
    case landscape = "16:9 Landscape"
    case superWide = "Super Wide"
    case ultraWide = "Ultra Wide"
    case custom = "Custom"

    var id: String { rawValue }
    var standardSize: CGSize {
        switch self {
        case .square: CGSize(width: 1080, height: 1080)
        case .vertical: CGSize(width: 1080, height: 1920)
        case .landscape: CGSize(width: 1920, height: 1080)
        case .superWide: CGSize(width: 2560, height: 1080)
        case .ultraWide: CGSize(width: 3440, height: 1440)
        case .custom: CGSize(width: 1920, height: 1080)
        }
    }

    var ultraSize: CGSize {
        switch self {
        case .square: CGSize(width: 2160, height: 2160)
        case .vertical: CGSize(width: 2160, height: 3840)
        case .landscape: CGSize(width: 3840, height: 2160)
        case .superWide: CGSize(width: 3840, height: 1600)
        case .ultraWide: CGSize(width: 3440, height: 1440)
        case .custom: CGSize(width: 1920, height: 1080)
        }
    }

    func resolvedSize(useUltra: Bool, customWidth: Double, customHeight: Double) -> CGSize {
        if self == .custom {
            return CGSize(width: max(320, customWidth), height: max(320, customHeight))
        }
        return useUltra ? ultraSize : standardSize
    }

    var platformHint: String {
        switch self {
        case .square: "Instagram Feed, Facebook"
        case .vertical: "TikTok, Reels, YouTube Shorts"
        case .landscape: "YouTube, Vimeo, Desktop"
        case .superWide: "Cinematic, YouTube Banner"
        case .ultraWide: "Ultra-Cinematic, Wallpaper"
        case .custom: "Spezialprojekte / Client-Requests"
        }
    }
}

enum CanvasFitMode: String, CaseIterable, Identifiable, Sendable {
    case fit = "Fit"
    case fill = "Fill"
    case stretch = "Stretch"
    case blurExtend = "Blur Extend"
    var id: String { rawValue }
}

enum VisualizerKind: String, CaseIterable, Identifiable, Sendable {
    case waveform = "Bottom Waveform"
    case topWaveform = "Top Waveform"
    case centerWave = "Center Wave"
    case stereoLeftRight = "Stereo Left/Right"
    case midOutward = "Mid-Outward"
    case verticalSideWaves = "Vertical Side Waves"
    case barsSpectrum = "Bars Spectrum"
    case blockBars = "Block Stereo Bars"
    case circleSpectrum = "Circle Spectrum"
    case neonFFT = "Neon FFT Wave"
    case frequencyMesh = "Frequency Mesh"
    var id: String { rawValue }
}

struct RenderEffects: Sendable {
    var bassShake: Double
    var zoomPunch: Double
    var rgbSplit: Double
    var glitch: Double
    var particles: Double
    var beatFlash: Double
    var lensGlow: Double

    static let none = RenderEffects(
        bassShake: 0,
        zoomPunch: 0,
        rgbSplit: 0,
        glitch: 0,
        particles: 0,
        beatFlash: 0,
        lensGlow: 0
    )
}

enum WavePosition: String, CaseIterable, Identifiable, Sendable {
    case bottom = "unten"
    case top = "oben"
    case center = "mitte"
    case left = "links"
    case right = "rechts"
    var id: String { rawValue }
}

enum LyricsPosition: String, CaseIterable, Identifiable, Sendable {
    case aboveWave = "Über Wave"
    case belowWave = "Unter Wave"
    case top = "Oben"
    case center = "Mitte"
    case bottom = "Unten"

    var id: String { rawValue }
}

struct LyricsCue: Identifiable, Sendable {
    let id = UUID()
    let start: Double?
    let end: Double?
    let text: String

    var isTimed: Bool { start != nil }
}

enum StereoMode: String, CaseIterable, Identifiable, Sendable {
    case combined = "Combined"
    case leftRight = "Links/Rechts"
    case midOut = "Mitte-Out"
    case outsideIn = "L/R separat"
    var id: String { rawValue }
}

enum WaveDirection: String, CaseIterable, Identifiable, Sendable {
    case leftToRight = "left -> right"
    case rightToLeft = "right -> left"
    case centerOutward = "center -> outward"
    case outwardCenter = "outward -> center"
    var id: String { rawValue }
}

enum MirrorMode: String, CaseIterable, Identifiable, Sendable {
    case none = "none"
    case horizontal = "horizontal"
    case vertical = "vertical"
    case both = "both"
    var id: String { rawValue }
}

enum NALAColorMode: String, CaseIterable, Identifiable, Sendable {
    case intelligent = "Intelligent Match"
    case extreme = "Extreme Contrast"
    case colorful = "Colorful"
    case manual = "Manual"
    case lowContrast = "Low Contrast"
    var id: String { rawValue }
}

enum KenBurnsMode: String, CaseIterable, Identifiable, Sendable {
    case zoomIn = "Zoom In"
    case zoomOut = "Zoom Out"
    case panLeft = "Pan Left"
    case panRight = "Pan Right"
    case panUp = "Pan Up"
    case panDown = "Pan Down"
    case smoothDrift = "Smooth Drift"
    var id: String { rawValue }
}

enum RenderMode: String, CaseIterable, Identifiable, Sendable {
    case standard = "Standard"
    case turbo = "Turbo"
    case max = "MAX"

    var id: String { rawValue }

    var fps: Int {
        switch self {
        case .standard, .turbo: 30
        case .max: 60
        }
    }

    var bitrate: Int {
        switch self {
        case .standard: 12_000_000
        case .turbo: 22_000_000
        case .max: 38_000_000
        }
    }

    var buttonTitle: String {
        switch self {
        case .standard: "RENDERN"
        case .turbo: "TURBO RENDERN"
        case .max: "MAX RENDERN"
        }
    }

    var summary: String {
        "\(fps) fps / \(bitrate / 1_000_000) Mbps"
    }
}

enum SceneTemplateKind: String, CaseIterable, Identifiable, Sendable {
    case off = "Aus"
    case djHud = "DJ HUD"
    case djLowerThird = "DJ Lower Third"
    case fullscreenWave = "Fullscreen Wave"

    var id: String { rawValue }

    var summary: String {
        switch self {
        case .off: "Keine Scene-Overlays"
        case .djHud: "BPM/Genre/HUD über Artwork"
        case .djLowerThird: "DJ-Titel, Player-Bar und Preset-Leiste"
        case .fullscreenWave: "Minimaler Fullscreen-Live-Look"
        }
    }
}

struct SceneOverlaySettings: Sendable {
    var template: SceneTemplateKind
    var artist: String
    var subtitle: String
    var bpm: String
    var genre: String
    var tag: String
    var showBadges: Bool
    var showTitle: Bool
    var showStats: Bool
    var opacity: Double
    var accentHex: String
    var magentaHex: String

    var isEnabled: Bool { template != .off }

    static let none = SceneOverlaySettings(
        template: .off,
        artist: "DJ SeN-SiZE",
        subtitle: "DRUM N BASS IN SEINER LEBENDIGSTEN FORM",
        bpm: "174 BPM",
        genre: "NEURO\nBASS",
        tag: "DNB",
        showBadges: true,
        showTitle: true,
        showStats: false,
        opacity: 0.85,
        accentHex: "#00E6FF",
        magentaHex: "#FF00D6"
    )
}

struct VisualizerPreset: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let kind: VisualizerKind
    let position: WavePosition
    let stereoMode: StereoMode
    let direction: WaveDirection
    let mirror: MirrorMode
    let colorMode: NALAColorMode
    let primaryHex: String
    let secondaryHex: String
    let glowHex: String
    let opacity: Double
    let barCount: Double
    let waveHeight: Double
    let lineWidth: Double
    let glow: Double
    let smoothing: Double
    let effects: RenderEffects
    let seed: Double

    static let library: [VisualizerPreset] = [
        VisualizerPreset(id: "mesh-storm", title: "Mesh Storm", subtitle: "3D FFT Lines", kind: .frequencyMesh, position: .center, stereoMode: .combined, direction: .leftToRight, mirror: .none, colorMode: .manual, primaryHex: "#6FEAFF", secondaryHex: "#FFFFFF", glowHex: "#00E6FF", opacity: 0.82, barCount: 112, waveHeight: 0.34, lineWidth: 1.05, glow: 0.82, smoothing: 0.88, effects: RenderEffects(bassShake: 0.10, zoomPunch: 0.16, rgbSplit: 0.20, glitch: 0.05, particles: 0.34, beatFlash: 0.06, lensGlow: 0.30), seed: 1.2),
        VisualizerPreset(id: "liquid-ice", title: "Liquid Ice", subtitle: "Smooth Ribbon", kind: .neonFFT, position: .center, stereoMode: .midOut, direction: .centerOutward, mirror: .horizontal, colorMode: .manual, primaryHex: "#B8F6FF", secondaryHex: "#38A7FF", glowHex: "#FFFFFF", opacity: 0.78, barCount: 120, waveHeight: 0.28, lineWidth: 1.4, glow: 0.76, smoothing: 0.94, effects: RenderEffects(bassShake: 0.06, zoomPunch: 0.12, rgbSplit: 0.14, glitch: 0, particles: 0.26, beatFlash: 0.04, lensGlow: 0.24), seed: 2.6),
        VisualizerPreset(id: "sub-blocks", title: "Sub Blocks", subtitle: "Stereo Cubes", kind: .blockBars, position: .bottom, stereoMode: .leftRight, direction: .leftToRight, mirror: .none, colorMode: .manual, primaryHex: "#00E6FF", secondaryHex: "#FF00D6", glowHex: "#FFFFFF", opacity: 0.74, barCount: 72, waveHeight: 0.24, lineWidth: 2.4, glow: 0.62, smoothing: 0.58, effects: RenderEffects(bassShake: 0.24, zoomPunch: 0.24, rgbSplit: 0.20, glitch: 0.10, particles: 0.16, beatFlash: 0.12, lensGlow: 0.18), seed: 3.1),
        VisualizerPreset(id: "circle-halo", title: "Circle Halo", subtitle: "Radial Pulse", kind: .circleSpectrum, position: .center, stereoMode: .combined, direction: .centerOutward, mirror: .both, colorMode: .manual, primaryHex: "#7EF9FF", secondaryHex: "#A75CFF", glowHex: "#FFFFFF", opacity: 0.86, barCount: 144, waveHeight: 0.32, lineWidth: 1.15, glow: 0.88, smoothing: 0.72, effects: RenderEffects(bassShake: 0.04, zoomPunch: 0.18, rgbSplit: 0.12, glitch: 0, particles: 0.42, beatFlash: 0.10, lensGlow: 0.36), seed: 4.4),
        VisualizerPreset(id: "stereo-razor", title: "Stereo Razor", subtitle: "L/R Split", kind: .stereoLeftRight, position: .bottom, stereoMode: .leftRight, direction: .leftToRight, mirror: .horizontal, colorMode: .manual, primaryHex: "#00DFFF", secondaryHex: "#FF2D7A", glowHex: "#FFFFFF", opacity: 0.88, barCount: 96, waveHeight: 0.27, lineWidth: 1.8, glow: 0.70, smoothing: 0.46, effects: RenderEffects(bassShake: 0.16, zoomPunch: 0.16, rgbSplit: 0.28, glitch: 0.08, particles: 0.24, beatFlash: 0.08, lensGlow: 0.22), seed: 5.7),
        VisualizerPreset(id: "side-walls", title: "Side Walls", subtitle: "Vertical Waves", kind: .verticalSideWaves, position: .left, stereoMode: .outsideIn, direction: .centerOutward, mirror: .both, colorMode: .manual, primaryHex: "#00E6FF", secondaryHex: "#6EFFB7", glowHex: "#FFFFFF", opacity: 0.78, barCount: 120, waveHeight: 0.26, lineWidth: 1.7, glow: 0.74, smoothing: 0.66, effects: RenderEffects(bassShake: 0.08, zoomPunch: 0.14, rgbSplit: 0.12, glitch: 0.06, particles: 0.30, beatFlash: 0.06, lensGlow: 0.24), seed: 6.9),
        VisualizerPreset(id: "mid-out", title: "Mid Out", subtitle: "Center Burst", kind: .midOutward, position: .center, stereoMode: .midOut, direction: .centerOutward, mirror: .horizontal, colorMode: .manual, primaryHex: "#FFFFFF", secondaryHex: "#00E6FF", glowHex: "#FF00D6", opacity: 0.82, barCount: 104, waveHeight: 0.30, lineWidth: 1.25, glow: 0.80, smoothing: 0.76, effects: RenderEffects(bassShake: 0.12, zoomPunch: 0.22, rgbSplit: 0.18, glitch: 0.04, particles: 0.30, beatFlash: 0.10, lensGlow: 0.32), seed: 7.5),
        VisualizerPreset(id: "pulse-core", title: "Pulse Core", subtitle: "Center Wave", kind: .centerWave, position: .center, stereoMode: .combined, direction: .outwardCenter, mirror: .horizontal, colorMode: .manual, primaryHex: "#EFFFFF", secondaryHex: "#31C7FF", glowHex: "#FFFFFF", opacity: 0.72, barCount: 96, waveHeight: 0.25, lineWidth: 2.2, glow: 0.82, smoothing: 0.86, effects: RenderEffects(bassShake: 0.06, zoomPunch: 0.20, rgbSplit: 0.10, glitch: 0, particles: 0.22, beatFlash: 0.12, lensGlow: 0.28), seed: 8.3),
        VisualizerPreset(id: "ghost-low", title: "Ghost Low", subtitle: "Cinematic", kind: .neonFFT, position: .bottom, stereoMode: .combined, direction: .leftToRight, mirror: .none, colorMode: .manual, primaryHex: "#DDEEFF", secondaryHex: "#6B8797", glowHex: "#99E6FF", opacity: 0.48, barCount: 92, waveHeight: 0.18, lineWidth: 1.0, glow: 0.40, smoothing: 0.92, effects: RenderEffects(bassShake: 0.03, zoomPunch: 0.08, rgbSplit: 0, glitch: 0, particles: 0.10, beatFlash: 0, lensGlow: 0.12), seed: 9.8),
        VisualizerPreset(id: "trap-bars", title: "Trap Bars", subtitle: "Hard Contrast", kind: .barsSpectrum, position: .bottom, stereoMode: .leftRight, direction: .leftToRight, mirror: .none, colorMode: .manual, primaryHex: "#00E6FF", secondaryHex: "#FFFFFF", glowHex: "#FF2D68", opacity: 0.92, barCount: 128, waveHeight: 0.30, lineWidth: 2.0, glow: 0.86, smoothing: 0.38, effects: RenderEffects(bassShake: 0.22, zoomPunch: 0.28, rgbSplit: 0.24, glitch: 0.16, particles: 0.22, beatFlash: 0.18, lensGlow: 0.24), seed: 10.4)
    ]
}

enum BatchJobStatus: Equatable, Sendable {
    case queued
    case rendering
    case done(String)
    case cancelled
    case failed(String)

    var label: String {
        switch self {
        case .queued: "Wartet"
        case .rendering: "Rendert"
        case .done(let filename): "Fertig: \(filename)"
        case .cancelled: "Gestoppt"
        case .failed(let message): "Fehler: \(message)"
        }
    }
}

struct BatchJob: Identifiable, Sendable {
    let id = UUID()
    let audioURL: URL
    let imageURL: URL
    let outputDirectory: URL
    let requestedName: String
    var snapshot: ExportSnapshot
    var status: BatchJobStatus = .queued
    var progress: Double = 0
}

struct BatchRenderResult: Sendable {
    let jobID: UUID
    let outputName: String?
    let errorMessage: String?
    let cancelled: Bool
}

@MainActor
final class AppModel: ObservableObject, @unchecked Sendable {
    @Published var audioURL: URL?
    @Published var images: [MediaItem] = []
    @Published var videos: [MediaItem] = []
    @Published var selectedImageID: UUID?
    @Published var selectedVideoID: UUID?
    @Published var stillIconURL: URL?
    @Published var stillIconEnabled = false
    @Published var canvasPreset: CanvasPreset = .vertical
    @Published var useUltraResolution = false
    @Published var canvasFitMode: CanvasFitMode = .fill
    @Published var customCanvasWidth = 1080.0
    @Published var customCanvasHeight = 1080.0
    @Published var visualizerKind: VisualizerKind = .waveform
    @Published var wavePosition: WavePosition = .bottom
    @Published var stereoMode: StereoMode = .combined
    @Published var waveDirection: WaveDirection = .leftToRight
    @Published var mirrorMode: MirrorMode = .none
    @Published var colorMode: NALAColorMode = .intelligent
    @Published var primaryHex = "#00E6FF"
    @Published var secondaryHex = "#FF00D6"
    @Published var glowHex = "#FFFFFF"
    @Published var opacity = 0.9
    @Published var barCount = 72.0
    @Published var waveHeight = 0.25
    @Published var lineWidth = 1.6
    @Published var glowStrength = 0.55
    @Published var smoothing = 0.65
    @Published var imageZoom = 1.0
    @Published var imageRotation = 0.0
    @Published var imageOffsetX = 0.0
    @Published var imageOffsetY = 0.0
    @Published var kenBurnsMode: KenBurnsMode = .zoomIn
    @Published var kenBurnsStrength = 0.35
    @Published var kenBurnsSpeed = 0.35
    @Published var kenBurnsAudioReactive = false
    @Published var bassShakeEnabled = true
    @Published var bassShakeStrength = 0.40
    @Published var zoomPunchEnabled = true
    @Published var zoomPunchStrength = 0.30
    @Published var rgbSplitEnabled = true
    @Published var rgbSplitStrength = 0.25
    @Published var glitchEnabled = false
    @Published var glitchStrength = 0.20
    @Published var particlesEnabled = true
    @Published var particlesStrength = 0.30
    @Published var beatFlashEnabled = false
    @Published var beatFlashStrength = 0.35
    @Published var lensGlowEnabled = true
    @Published var lensGlowStrength = 0.25
    @Published var waveform = AudioTools.placeholderWaveform()
    @Published var spectrumFrames = AudioTools.placeholderSpectrumFrames()
    @Published var isRendering = false
    @Published var renderProgress = 0.0
    @Published var status = "Bereit"
    @Published var outputFileName = "NALA-Visualizer"
    @Published var outputDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Movies/NALA-Exports")
    @Published var selectedPresetID = ""
    @Published var renderMode: RenderMode = .standard
    @Published var batchJobs: [BatchJob] = []
    @Published var isBatchRendering = false
    @Published var selectedBatchJobID: UUID?
    @Published var isBatchInspectorPresented = false
    @Published var batchCancelRequested = false
    @Published var batchParallelPipelines = ProcessInfo.processInfo.activeProcessorCount >= 12
    @Published var audioDuration = 165.0
    @Published var sceneTemplate: SceneTemplateKind = .off
    @Published var sceneArtist = "DJ SeN-SiZE"
    @Published var sceneSubtitle = "DRUM N BASS IN SEINER LEBENDIGSTEN FORM"
    @Published var sceneBPM = "174 BPM"
    @Published var sceneGenre = "NEURO\nBASS"
    @Published var sceneTag = "DNB"
    @Published var sceneShowBadges = true
    @Published var sceneShowTitle = true
    @Published var sceneShowStats = false
    @Published var sceneOpacity = 0.85
    @Published var sceneAccentHex = "#00E6FF"
    @Published var sceneMagentaHex = "#FF00D6"
    @Published var lyricsEnabled = false
    @Published var lyricsPosition: LyricsPosition = .aboveWave
    @Published var lyricsSize = 1.0
    @Published var lyricsOpacity = 0.95
    @Published var lyricsText = "" {
        didSet {
            lyricsCues = LyricsEngine.parse(lyricsText)
        }
    }
    @Published private(set) var lyricsCues: [LyricsCue] = []
    private var batchRenderTask: Task<Void, Never>?

    var selectedImage: MediaItem? {
        if let selectedImageID, let item = images.first(where: { $0.id == selectedImageID }) { return item }
        return images.first
    }

    var selectedVideo: MediaItem? {
        if let selectedVideoID, let item = videos.first(where: { $0.id == selectedVideoID }) { return item }
        return videos.first
    }

    var selectedBatchJob: BatchJob? {
        guard let selectedBatchJobID else { return batchJobs.first }
        return batchJobs.first { $0.id == selectedBatchJobID } ?? batchJobs.first
    }

    var batchPipelineLimit: Int {
        batchParallelPipelines ? 2 : 1
    }

    var previewImageURL: URL? {
        stillIconEnabled ? (stillIconURL ?? selectedImage?.url) : selectedImage?.url
    }

    var effectiveAudioURL: URL? {
        audioURL ?? selectedVideo?.url
    }

    var audioSourceDescription: String {
        guard let effectiveAudioURL else { return "Noch kein Audio" }
        if ["mp4", "mov", "m4v"].contains(effectiveAudioURL.pathExtension.lowercased()) {
            return "Video-Audiotrack: \(effectiveAudioURL.lastPathComponent)"
        }
        return effectiveAudioURL.lastPathComponent
    }

    var canvasSize: CGSize {
        canvasPreset.resolvedSize(useUltra: useUltraResolution, customWidth: customCanvasWidth, customHeight: customCanvasHeight)
    }

    var canvasDescription: String {
        "\(Int(canvasSize.width)) x \(Int(canvasSize.height))"
    }

    var canvasAspectWarning: String? {
        let ratio = canvasSize.width / max(1, canvasSize.height)
        if ratio < 0.5 || ratio > 3.0 {
            return "Hinweis: sehr extremes Seitenverhältnis. Manche Plattformen schneiden neu zu."
        }
        return nil
    }

    var renderEffects: RenderEffects {
        RenderEffects(
            bassShake: bassShakeEnabled ? bassShakeStrength : 0,
            zoomPunch: zoomPunchEnabled ? zoomPunchStrength : 0,
            rgbSplit: rgbSplitEnabled ? rgbSplitStrength : 0,
            glitch: glitchEnabled ? glitchStrength : 0,
            particles: particlesEnabled ? particlesStrength : 0,
            beatFlash: beatFlashEnabled ? beatFlashStrength : 0,
            lensGlow: lensGlowEnabled ? lensGlowStrength : 0
        )
    }

    var sceneOverlaySettings: SceneOverlaySettings {
        SceneOverlaySettings(
            template: sceneTemplate,
            artist: sceneArtist,
            subtitle: sceneSubtitle,
            bpm: sceneBPM,
            genre: sceneGenre,
            tag: sceneTag,
            showBadges: sceneShowBadges,
            showTitle: sceneShowTitle,
            showStats: sceneShowStats,
            opacity: sceneOpacity,
            accentHex: sceneAccentHex,
            magentaHex: sceneMagentaHex
        )
    }

    var canCreateRenderJob: Bool {
        effectiveAudioURL != nil && previewImageURL != nil && !isRendering && !isBatchRendering
    }

    var lyricsLineCount: Int {
        lyricsCues.count
    }

    var lyricsStatus: String {
        if lyricsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Keine Lyrics geladen"
        }
        return lyricsCues.contains(where: { $0.isTimed }) ? "\(lyricsLineCount) getimte Zeilen" : "\(lyricsLineCount) Zeilen, automatisch verteilt"
    }

    func importURLs(_ urls: [URL]) {
        for url in urls {
            switch url.pathExtension.lowercased() {
            case "mp3", "wav", "flac", "aac", "m4a":
                setAudioSource(url, statusText: "Audio importiert")
            case "jpg", "jpeg", "png", "webp":
                let item = MediaItem(url: url)
                images.append(item)
                selectedImageID = selectedImageID ?? item.id
                applyDefaultOutputNameIfNeeded(from: url)
            case "mp4", "mov", "m4v":
                let item = MediaItem(url: url)
                videos.append(item)
                selectedVideoID = selectedVideoID ?? item.id
                if audioURL == nil {
                    Task {
                        if await AudioTools.containsAudio(url: url) {
                            await MainActor.run {
                                self.setAudioSource(url, statusText: "Video importiert, Audiotrack als Audioquelle gesetzt")
                            }
                        } else {
                            await MainActor.run {
                                self.status = "Video importiert, aber kein Audiotrack gefunden"
                            }
                        }
                    }
                }
            case "txt", "md", "markdown", "lrc", "srt":
                importLyrics(url)
            default:
                break
            }
        }
        if !urls.isEmpty, !status.contains("Audiotrack") {
            status = "Medien importiert"
        }
    }

    private func setAudioSource(_ url: URL, statusText: String) {
        audioURL = url
        waveform = AudioTools.placeholderWaveform()
        spectrumFrames = AudioTools.placeholderSpectrumFrames()
        status = "\(statusText) - Analyse läuft ..."
        Task {
            let duration = await AudioTools.duration(url: url)
            let embeddedLyrics = await LyricsEngine.embeddedLyrics(url: url)
            let adaptiveFrameCount = max(720, min(7200, Int(duration * 24)))
            let analysis = await AudioTools.analysis(url: url, waveformCount: 420, frameCount: adaptiveFrameCount, bins: max(24, min(160, Int(barCount))))
            await MainActor.run {
                self.audioDuration = duration
                self.waveform = analysis.waveform
                self.spectrumFrames = analysis.spectrumFrames
                if let embeddedLyrics, self.lyricsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    self.lyricsText = embeddedLyrics
                    self.lyricsEnabled = true
                    self.status = "\(statusText) - FFT + Lyrics bereit"
                } else {
                    self.status = "\(statusText) - FFT bereit"
                }
            }
        }
    }

    func chooseAudio() { choose(["mp3", "wav", "flac", "aac", "m4a"], multiple: false) { importURLs($0) } }
    func chooseImages() { choose(["jpg", "jpeg", "png", "webp"], multiple: true) { importURLs($0) } }
    func chooseVideos() { choose(["mp4", "mov", "m4v"], multiple: true) { importURLs($0) } }
    func chooseLyrics() { choose(["txt", "md", "markdown", "lrc", "srt"], multiple: false) { importURLs($0) } }
    func chooseStillIcon() {
        choose(["jpg", "jpeg", "png", "webp"], multiple: false) { urls in
            stillIconURL = urls.first
            stillIconEnabled = stillIconURL != nil
            status = "YouTube-Music-Cover gewählt"
        }
    }

    func importLyrics(_ url: URL) {
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            lyricsText = text
            lyricsEnabled = true
            status = "Lyrics importiert: \(url.lastPathComponent)"
        } catch {
            status = "Lyrics konnten nicht geladen werden: \(error.localizedDescription)"
        }
    }

    private func applyDefaultOutputNameIfNeeded(from imageURL: URL) {
        let current = outputFileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard current.isEmpty || current == "NALA-Visualizer" else { return }
        outputFileName = Exporter.defaultOutputName(for: imageURL)
    }

    func reloadLyricsFromAudioMetadata() {
        guard let url = effectiveAudioURL else {
            status = "Bitte zuerst Audio oder Video importieren"
            return
        }
        status = "Lyrics-Metadaten werden gelesen ..."
        Task {
            let embeddedLyrics = await LyricsEngine.embeddedLyrics(url: url)
            await MainActor.run {
                if let embeddedLyrics {
                    self.lyricsText = embeddedLyrics
                    self.lyricsEnabled = true
                    self.status = "Lyrics aus Metadaten geladen"
                } else {
                    self.status = "Keine eingebetteten Lyrics gefunden - Copy/Paste nutzen"
                }
            }
        }
    }

    func clearLyrics() {
        lyricsText = ""
        lyricsEnabled = false
        status = "Lyrics geleert"
    }

    func previewLyrics(at phase: TimeInterval) -> String? {
        guard lyricsEnabled else { return nil }
        let duration = max(1, audioDuration)
        let time = phase.truncatingRemainder(dividingBy: duration)
        return LyricsEngine.text(at: time, duration: duration, cues: lyricsCues)
    }

    func removeImage(_ item: MediaItem) {
        images.removeAll { $0.id == item.id }
        if selectedImageID == item.id { selectedImageID = images.first?.id }
        if stillIconURL == item.url { stillIconURL = nil; stillIconEnabled = false }
        status = "Bild entfernt"
    }

    func removeVideo(_ item: MediaItem) {
        videos.removeAll { $0.id == item.id }
        if selectedVideoID == item.id { selectedVideoID = videos.first?.id }
        status = "Video entfernt"
    }

    func clearAudio() {
        audioURL = nil
        waveform = AudioTools.placeholderWaveform()
        spectrumFrames = AudioTools.placeholderSpectrumFrames()
        status = "Audio entfernt"
    }

    func useSelectedAsCover() {
        guard let selectedImage else { status = "Kein Bild ausgewählt"; return }
        stillIconURL = selectedImage.url
        stillIconEnabled = true
        status = "Aktuelles Bild als Cover gesetzt"
    }

    func resetImageAdjustment() {
        imageZoom = 1
        imageRotation = 0
        imageOffsetX = 0
        imageOffsetY = 0
    }

    func applyVisualizerPreset(_ preset: VisualizerPreset) {
        selectedPresetID = preset.id
        visualizerKind = preset.kind
        wavePosition = preset.position
        stereoMode = preset.stereoMode
        waveDirection = preset.direction
        mirrorMode = preset.mirror
        colorMode = preset.colorMode
        primaryHex = preset.primaryHex
        secondaryHex = preset.secondaryHex
        glowHex = preset.glowHex
        opacity = preset.opacity
        barCount = preset.barCount
        waveHeight = preset.waveHeight
        lineWidth = preset.lineWidth
        glowStrength = preset.glow
        smoothing = preset.smoothing
        applyEffects(preset.effects)
        status = "Wave-Preset aktiviert: \(preset.title)"
    }

    func applySceneTemplateDefaults() {
        switch sceneTemplate {
        case .off:
            status = "DJ Scene deaktiviert"
        case .djHud:
            canvasPreset = .landscape
            canvasFitMode = .fill
            visualizerKind = .neonFFT
            wavePosition = .center
            stereoMode = .midOut
            waveDirection = .centerOutward
            mirrorMode = .horizontal
            opacity = 0.72
            barCount = 112
            waveHeight = 0.26
            lineWidth = 1.35
            glowStrength = 0.78
            smoothing = 0.88
            colorMode = .manual
            primaryHex = sceneAccentHex
            secondaryHex = "#B9F7FF"
            glowHex = "#FFFFFF"
            sceneShowBadges = true
            sceneShowTitle = true
            sceneShowStats = true
            status = "DJ HUD Scene aktiviert"
        case .djLowerThird:
            canvasPreset = .landscape
            canvasFitMode = .fill
            visualizerKind = .barsSpectrum
            wavePosition = .bottom
            stereoMode = .combined
            waveDirection = .leftToRight
            mirrorMode = .none
            opacity = 0.92
            barCount = 128
            waveHeight = 0.30
            lineWidth = 2.0
            glowStrength = 0.86
            smoothing = 0.48
            colorMode = .manual
            primaryHex = sceneAccentHex
            secondaryHex = "#E9FEFF"
            glowHex = "#FFFFFF"
            sceneShowBadges = true
            sceneShowTitle = true
            sceneShowStats = false
            status = "DJ Lower-Third Scene aktiviert"
        case .fullscreenWave:
            canvasPreset = .landscape
            canvasFitMode = .fill
            visualizerKind = .frequencyMesh
            wavePosition = .center
            stereoMode = .midOut
            waveDirection = .centerOutward
            mirrorMode = .both
            opacity = 0.76
            barCount = 144
            waveHeight = 0.34
            lineWidth = 0.95
            glowStrength = 0.86
            smoothing = 0.94
            colorMode = .manual
            primaryHex = sceneAccentHex
            secondaryHex = sceneMagentaHex
            glowHex = "#FFFFFF"
            sceneShowBadges = false
            sceneShowTitle = false
            sceneShowStats = true
            status = "Fullscreen Wave Scene aktiviert"
        }
    }

    private func applyEffects(_ effects: RenderEffects) {
        bassShakeEnabled = effects.bassShake > 0.001
        bassShakeStrength = effects.bassShake
        zoomPunchEnabled = effects.zoomPunch > 0.001
        zoomPunchStrength = effects.zoomPunch
        rgbSplitEnabled = effects.rgbSplit > 0.001
        rgbSplitStrength = effects.rgbSplit
        glitchEnabled = effects.glitch > 0.001
        glitchStrength = effects.glitch
        particlesEnabled = effects.particles > 0.001
        particlesStrength = effects.particles
        beatFlashEnabled = effects.beatFlash > 0.001
        beatFlashStrength = effects.beatFlash
        lensGlowEnabled = effects.lensGlow > 0.001
        lensGlowStrength = effects.lensGlow
    }

    func export() async {
        guard !isRendering, !isBatchRendering else { return }
        guard let audioURL = effectiveAudioURL else { status = "Bitte Audio oder Video mit Audiotrack auswählen"; return }
        guard let imageURL = previewImageURL else { status = "Bitte Bild auswählen"; return }
        let snapshot = makeSnapshot()
        isRendering = true
        renderProgress = 0
        status = "\(renderMode.rawValue)-Render läuft ..."
        do {
            let output = try await Exporter.export(snapshot: snapshot, audioURL: audioURL, imageURL: imageURL, outputDirectory: outputDirectory, requestedName: outputFileName) { progress in
                Task { @MainActor in
                    self.renderProgress = progress
                    self.status = "\(self.renderMode.rawValue)-Render läuft ... \(Int(progress * 100))%"
                }
            }
            if stillIconEnabled, let image = NSImage(contentsOf: imageURL), let data = image.pngData {
                let coverStem = output.deletingPathExtension().lastPathComponent
                try? data.write(to: output.deletingLastPathComponent().appendingPathComponent("\(coverStem)-Still-Cover.png"))
            }
            status = "Export fertig: \(output.lastPathComponent)"
            NSWorkspace.shared.activateFileViewerSelecting([output])
        } catch {
            status = "Export fehlgeschlagen: \(error.localizedDescription)"
        }
        isRendering = false
    }

    func addCurrentToBatch() {
        guard let audioURL = effectiveAudioURL else { status = "Bitte Audio oder Video mit Audiotrack auswählen"; return }
        guard let imageURL = previewImageURL else { status = "Bitte Bild auswählen"; return }
        let snapshot = makeSnapshot()
        let requestedName = uniqueBatchRequestedName(base: outputFileName, snapshot: snapshot, directory: outputDirectory)
        let job = BatchJob(audioURL: audioURL, imageURL: imageURL, outputDirectory: outputDirectory, requestedName: requestedName, snapshot: snapshot)
        batchJobs.append(job)
        selectedBatchJobID = job.id
        let addedName = Exporter.outputFileStem(requestedName: requestedName, snapshot: snapshot)
        clearCurrentInputsAfterBatchAdd()
        status = "Batch-Job hinzugefügt: \(addedName)"
    }

    func removeBatchJob(_ job: BatchJob) {
        guard !isBatchRendering else { return }
        batchJobs.removeAll { $0.id == job.id }
        if selectedBatchJobID == job.id {
            selectedBatchJobID = batchJobs.first?.id
        }
        status = "Batch-Job entfernt"
    }

    func clearBatch() {
        guard !isBatchRendering else { return }
        batchJobs.removeAll()
        selectedBatchJobID = nil
        isBatchInspectorPresented = false
        status = "Batch geleert"
    }

    func selectBatchJob(_ job: BatchJob) {
        selectedBatchJobID = job.id
    }

    func showBatchInspector(for job: BatchJob? = nil) {
        if let job {
            selectedBatchJobID = job.id
        } else if selectedBatchJobID == nil {
            selectedBatchJobID = batchJobs.first?.id
        }
        isBatchInspectorPresented = selectedBatchJob != nil
    }

    func updateBatchRenderMode(_ job: BatchJob, to mode: RenderMode) {
        guard !isBatchRendering else { return }
        guard let index = batchJobs.firstIndex(where: { $0.id == job.id }) else { return }
        batchJobs[index].snapshot.renderMode = mode
        status = "Batch-Job auf \(mode.rawValue) gesetzt"
    }

    func updateSelectedBatchRenderMode(to mode: RenderMode) {
        guard let job = selectedBatchJob else { return }
        updateBatchRenderMode(job, to: mode)
    }

    func applyRenderModeToAllBatchJobs(_ mode: RenderMode) {
        guard !isBatchRendering else { return }
        for index in batchJobs.indices {
            batchJobs[index].snapshot.renderMode = mode
        }
        status = "\(mode.rawValue) für alle Batch-Jobs gesetzt"
    }

    private func uniqueBatchRequestedName(base: String, snapshot: ExportSnapshot, directory: URL) -> String {
        let baseStem = Exporter.safeFileStem(base)
        var candidate = baseStem
        var counter = 2
        let queuedStems = Set(batchJobs
            .filter { $0.outputDirectory == directory }
            .map { Exporter.outputFileStem(requestedName: $0.requestedName, snapshot: $0.snapshot) })
        while queuedStems.contains(Exporter.outputFileStem(requestedName: candidate, snapshot: snapshot)) {
            candidate = "\(baseStem)-\(counter)"
            counter += 1
        }
        return candidate
    }

    func moveBatchJob(_ job: BatchJob, offset: Int) {
        guard !isBatchRendering else { return }
        guard let source = batchJobs.firstIndex(where: { $0.id == job.id }) else { return }
        let target = max(0, min(batchJobs.count - 1, source + offset))
        guard source != target else { return }
        let moved = batchJobs.remove(at: source)
        batchJobs.insert(moved, at: target)
        selectedBatchJobID = moved.id
        status = "Batch-Reihenfolge geändert"
    }

    func startBatchRender() {
        guard !isBatchRendering else { return }
        batchCancelRequested = false
        batchRenderTask = Task { [weak self] in
            guard let self else { return }
            await self.renderBatch()
        }
    }

    func cancelBatchRender() {
        guard isBatchRendering else { return }
        batchCancelRequested = true
        batchRenderTask?.cancel()
        status = "Batch wird gestoppt ..."
    }

    func renderBatch() async {
        guard !isRendering, !isBatchRendering else { return }
        guard !batchJobs.isEmpty else { status = "Batch ist leer"; return }
        isBatchRendering = true
        batchCancelRequested = false
        renderProgress = 0
        status = "Batch-Render läuft ..."
        defer {
            isBatchRendering = false
            batchRenderTask = nil
            if batchCancelRequested || Task.isCancelled {
                status = "Batch gestoppt"
            } else {
                status = "Batch abgeschlossen"
            }
        }
        let jobIDs = batchJobs.map(\.id)
        let limit = max(1, min(batchPipelineLimit, 2))
        var cursor = 0
        while cursor < jobIDs.count {
            if batchCancelRequested || Task.isCancelled { break }
            let chunkIDs = Array(jobIDs[cursor..<min(cursor + limit, jobIDs.count)])
            let jobs = chunkIDs.compactMap { id in batchJobs.first { $0.id == id } }
            for job in jobs {
                if let index = batchJobs.firstIndex(where: { $0.id == job.id }) {
                    batchJobs[index].status = .rendering
                    batchJobs[index].progress = 0
                }
            }
            await withTaskGroup(of: BatchRenderResult.self) { group in
                for job in jobs {
                    group.addTask { [self] in
                        do {
                            let output = try await Exporter.export(
                                snapshot: job.snapshot,
                                audioURL: job.audioURL,
                                imageURL: job.imageURL,
                                outputDirectory: job.outputDirectory,
                                requestedName: job.requestedName
                            ) { progress in
                                Task { @MainActor in
                                    if let currentIndex = self.batchJobs.firstIndex(where: { $0.id == job.id }) {
                                        self.batchJobs[currentIndex].progress = progress
                                    }
                                    let total = max(1, self.batchJobs.count)
                                    self.renderProgress = self.batchJobs.map(\.progress).reduce(0, +) / Double(total)
                                    self.status = "Batch rendert \(job.requestedName) ... \(Int(progress * 100))% (\(self.batchPipelineLimit) Pipeline\(self.batchPipelineLimit == 1 ? "" : "s"))"
                                }
                            }
                            return BatchRenderResult(jobID: job.id, outputName: output.lastPathComponent, errorMessage: nil, cancelled: false)
                        } catch is CancellationError {
                            return BatchRenderResult(jobID: job.id, outputName: nil, errorMessage: nil, cancelled: true)
                        } catch {
                            return BatchRenderResult(jobID: job.id, outputName: nil, errorMessage: error.localizedDescription, cancelled: false)
                        }
                    }
                }
                for await result in group {
                    guard let currentIndex = batchJobs.firstIndex(where: { $0.id == result.jobID }) else { continue }
                    if result.cancelled {
                        batchJobs[currentIndex].status = .cancelled
                        batchCancelRequested = true
                    } else if let outputName = result.outputName {
                        batchJobs[currentIndex].status = .done(outputName)
                        batchJobs[currentIndex].progress = 1
                    } else {
                        batchJobs[currentIndex].status = .failed(result.errorMessage ?? "Unbekannter Batch-Fehler")
                    }
                    renderProgress = batchJobs.map(\.progress).reduce(0, +) / Double(max(1, batchJobs.count))
                }
            }
            cursor += limit
        }
    }

    private func clearCurrentInputsAfterBatchAdd() {
        audioURL = nil
        images.removeAll()
        videos.removeAll()
        selectedImageID = nil
        selectedVideoID = nil
        stillIconURL = nil
        stillIconEnabled = false
        lyricsText = ""
        lyricsEnabled = false
        waveform = AudioTools.placeholderWaveform()
        spectrumFrames = AudioTools.placeholderSpectrumFrames()
        audioDuration = 165.0
        outputFileName = ""
    }

    private func makeSnapshot() -> ExportSnapshot {
        ExportSnapshot(
            size: canvasSize,
            canvasFitMode: canvasFitMode,
            visualizerKind: visualizerKind,
            wavePosition: resolvedWavePosition,
            stereoMode: stereoMode,
            waveDirection: waveDirection,
            mirrorMode: mirrorMode,
            colorMode: colorMode,
            colors: resolvedColors().map { CodableColor($0) },
            opacity: opacity,
            barCount: Int(barCount),
            waveHeight: waveHeight,
            lineWidth: lineWidth,
            glowStrength: glowStrength,
            smoothing: smoothing,
            imageZoom: imageZoom,
            imageRotation: imageRotation,
            imageOffsetX: imageOffsetX,
            imageOffsetY: imageOffsetY,
            kenBurnsMode: kenBurnsMode,
            kenBurnsStrength: kenBurnsStrength,
            kenBurnsSpeed: kenBurnsSpeed,
            renderMode: renderMode,
            effects: renderEffects,
            sceneOverlay: sceneOverlaySettings,
            lyricsEnabled: lyricsEnabled,
            lyricsPosition: lyricsPosition,
            lyricsSize: lyricsSize,
            lyricsOpacity: lyricsOpacity,
            lyricsCues: lyricsCues,
            samples: waveform,
            spectrumFrames: spectrumFrames
        )
    }

    private func choose(_ extensions: [String], multiple: Bool, handler: ([URL]) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        panel.allowsMultipleSelection = multiple
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK { handler(panel.urls) }
    }

    func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.title = "Speicherort für NALA-Exports wählen"
        panel.prompt = "Ordner wählen"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = outputDirectory
        if panel.runModal() == .OK, let url = panel.url {
            outputDirectory = url
            status = "Speicherort gewählt"
        }
    }

    var resolvedWavePosition: WavePosition {
        switch visualizerKind {
        case .topWaveform:
            return .top
        case .centerWave:
            return .center
        default:
            return wavePosition
        }
    }

    func resolvedColors() -> [NSColor] {
        switch colorMode {
        case .intelligent:
            return [.cyan, .systemBlue, .systemPink]
        case .extreme:
            return [.cyan, .white, .systemPink]
        case .colorful:
            return [.systemPink, .systemOrange, .systemGreen, .cyan, .systemPurple]
        case .manual:
            return [NSColor(hex: primaryHex) ?? .cyan, NSColor(hex: secondaryHex) ?? .systemPink, NSColor(hex: glowHex) ?? .white]
        case .lowContrast:
            return [.init(white: 0.85, alpha: 1), .init(calibratedRed: 0.45, green: 0.75, blue: 0.85, alpha: 1)]
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("NALA-AudiO-ViZuLiZeR").font(.headline)
                Spacer()
                Text("Offline Engine: SwiftUI / AVFoundation / VideoToolbox").font(.caption).foregroundStyle(.cyan)
            }
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(.black.opacity(0.75))

            HStack(spacing: 8) {
                sidebar
                    .frame(width: 260)
                VStack(spacing: 8) {
                    PreviewPanel()
                    MediaTray()
                        .frame(height: 150)
                    if !model.batchJobs.isEmpty {
                        BatchQueueView()
                            .frame(height: 145)
                    }
                    ExportBar()
                        .frame(height: 104)
                }
                settings
                    .frame(width: 330)
            }
            .padding(8)
        }
        .background(Color(red: 0.015, green: 0.022, blue: 0.026))
        .foregroundStyle(.white)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            DropLoader.load(providers) { model.importURLs($0) }
            return true
        }
    }

    private var sidebar: some View {
        VStack(spacing: 8) {
            Panel("NALA") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("NALA").font(.system(size: 42, weight: .black)).italic()
                    Text("AUDIO-VIZULIZER").foregroundStyle(.cyan).font(.headline)
                    feature("square.and.arrow.down", "Drag & Drop oder Doppelklick")
                    feature("rectangle.on.rectangle.angled", "DJ Scene HUD & Live Looks")
                    feature("waveform", "Krasse FFT Waves links")
                    feature("slider.horizontal.3", "Transparenz, Zoom, Rotation")
                    feature("xmark.circle", "Falsche Medien per X löschen")
                    feature("photo", "YouTube Music Still Cover")
                }
            }
            .frame(height: 260)

            Panel("Krasse Waves") {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                        ForEach(VisualizerPreset.library) { preset in
                            WavePresetCard(
                                preset: preset,
                                selected: model.selectedPresetID == preset.id
                            ) {
                                model.applyVisualizerPreset(preset)
                            }
                        }
                    }
                    .padding(.bottom, 2)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var settings: some View {
        ScrollView {
            VStack(spacing: 8) {
                Panel("Visualizer Einstellungen") {
                    Picker("Typ", selection: $model.visualizerKind) {
                        ForEach(VisualizerKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Position", selection: $model.wavePosition) {
                        ForEach(WavePosition.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Stereo", selection: $model.stereoMode) {
                        ForEach(StereoMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Richtung", selection: $model.waveDirection) {
                        ForEach(WaveDirection.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Spiegelung", selection: $model.mirrorMode) {
                        ForEach(MirrorMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    slider("Transparenz", value: $model.opacity, range: 0.1...1, percent: true)
                    slider("Balken", value: $model.barCount, range: 24...144, percent: false)
                    slider("Höhe", value: $model.waveHeight, range: 0.12...0.42, percent: true)
                    slider("Linie", value: $model.lineWidth, range: 0.5...8, percent: false)
                    slider("Glow", value: $model.glowStrength, range: 0...1, percent: true)
                    slider("Glättung", value: $model.smoothing, range: 0...1, percent: true)
                }
                Panel("Canvas") {
                    Picker("Format", selection: $model.canvasPreset) {
                        ForEach(CanvasPreset.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Toggle("Ultra / 4K", isOn: $model.useUltraResolution)
                        .disabled(model.canvasPreset == .custom || model.canvasPreset == .ultraWide)
                    HStack {
                        Text("Auflösung").font(.caption).frame(width: 86, alignment: .leading)
                        Text(model.canvasDescription)
                            .font(.caption.bold())
                            .foregroundStyle(.cyan)
                        Spacer()
                    }
                    Text(model.canvasPreset.platformHint)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.62))
                    Picker("Anpassung", selection: $model.canvasFitMode) {
                        ForEach(CanvasFitMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    if model.canvasPreset == .custom {
                        HStack {
                            Text("Breite").font(.caption).frame(width: 86, alignment: .leading)
                            TextField("1080", value: $model.customCanvasWidth, format: .number)
                                .textFieldStyle(.roundedBorder)
                            Text("Höhe").font(.caption)
                            TextField("1080", value: $model.customCanvasHeight, format: .number)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    if let warning = model.canvasAspectWarning {
                        Text(warning)
                            .font(.caption2)
                            .foregroundStyle(.orange.opacity(0.9))
                    }
                }
                Panel("DJ Scene / Live HUD") {
                    Picker("Template", selection: $model.sceneTemplate) {
                        ForEach(SceneTemplateKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Text(model.sceneTemplate.summary)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.62))
                    Button {
                        model.applySceneTemplateDefaults()
                    } label: {
                        Label("Scene anwenden", systemImage: "rectangle.on.rectangle.angled")
                    }
                    .disabled(model.sceneTemplate == .off)
                    Toggle("Badges links", isOn: $model.sceneShowBadges)
                        .disabled(model.sceneTemplate == .off)
                    Toggle("Titel einblenden", isOn: $model.sceneShowTitle)
                        .disabled(model.sceneTemplate == .off)
                    Toggle("FPS/Status HUD", isOn: $model.sceneShowStats)
                        .disabled(model.sceneTemplate == .off)
                    slider("Deckkraft", value: $model.sceneOpacity, range: 0.2...1, percent: true)
                        .disabled(model.sceneTemplate == .off)
                    TextField("Artist", text: $model.sceneArtist)
                        .disabled(model.sceneTemplate == .off)
                    TextField("Subline", text: $model.sceneSubtitle)
                        .disabled(model.sceneTemplate == .off)
                    HStack {
                        TextField("BPM", text: $model.sceneBPM)
                        TextField("Genre", text: $model.sceneGenre)
                        TextField("Tag", text: $model.sceneTag)
                    }
                    .disabled(model.sceneTemplate == .off)
                    TextField("Accent HEX", text: $model.sceneAccentHex)
                        .disabled(model.sceneTemplate == .off)
                    TextField("Magenta HEX", text: $model.sceneMagentaHex)
                        .disabled(model.sceneTemplate == .off)
                }
                Panel("Bild / Cover Zuschnitt") {
                    slider("Zoom", value: $model.imageZoom, range: 0.2...3, percent: false)
                    slider("Rotation", value: $model.imageRotation, range: -180...180, percent: false)
                    slider("X", value: $model.imageOffsetX, range: -1...1, percent: false)
                    slider("Y", value: $model.imageOffsetY, range: -1...1, percent: false)
                    Button("Reset") { model.resetImageAdjustment() }
                }
                Panel("Ken Burns Animation") {
                    Picker("Modus", selection: $model.kenBurnsMode) {
                        ForEach(KenBurnsMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    slider("Stärke", value: $model.kenBurnsStrength, range: 0...1, percent: true)
                    slider("Speed", value: $model.kenBurnsSpeed, range: 0...1, percent: true)
                    Toggle("Audio Reactive", isOn: $model.kenBurnsAudioReactive)
                }
                Panel("Effekte") {
                    effectRow("Bass Shake", enabled: $model.bassShakeEnabled, value: $model.bassShakeStrength)
                    effectRow("Zoom Punch", enabled: $model.zoomPunchEnabled, value: $model.zoomPunchStrength)
                    effectRow("RGB Split", enabled: $model.rgbSplitEnabled, value: $model.rgbSplitStrength)
                    effectRow("Glitch", enabled: $model.glitchEnabled, value: $model.glitchStrength)
                    effectRow("Particles", enabled: $model.particlesEnabled, value: $model.particlesStrength)
                    effectRow("Beat Flash", enabled: $model.beatFlashEnabled, value: $model.beatFlashStrength)
                    effectRow("Lens Glow", enabled: $model.lensGlowEnabled, value: $model.lensGlowStrength)
                }
                Panel("Farbmodus") {
                    Picker("Modus", selection: $model.colorMode) {
                        ForEach(NALAColorMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    HStack {
                        ForEach(model.resolvedColors().indices, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(model.resolvedColors()[index]))
                                .frame(height: 24)
                        }
                    }
                    TextField("Primär HEX", text: $model.primaryHex)
                    TextField("Sekundär HEX", text: $model.secondaryHex)
                    TextField("Glow HEX", text: $model.glowHex)
                }
                Panel("YouTube Music Cover") {
                    Toggle("Still Icon aktivieren", isOn: $model.stillIconEnabled)
                    HStack {
                        Button("Cover wählen") { model.chooseStillIcon() }
                        Button("Aktuelles Bild") { model.useSelectedAsCover() }
                    }
                }
                Panel("Lyrics") {
                    Toggle("Lyrics einblenden", isOn: $model.lyricsEnabled)
                    Picker("Position", selection: $model.lyricsPosition) {
                        ForEach(LyricsPosition.allCases) { Text($0.rawValue).tag($0) }
                    }
                    slider("Größe", value: $model.lyricsSize, range: 0.65...1.6, percent: false)
                    slider("Deckkraft", value: $model.lyricsOpacity, range: 0.25...1, percent: true)
                    HStack {
                        Button("Datei laden") { model.chooseLyrics() }
                        Button("Aus Metadaten") { model.reloadLyricsFromAudioMetadata() }
                        Button("Leeren") { model.clearLyrics() }
                    }
                    TextEditor(text: $model.lyricsText)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(height: 130)
                        .scrollContentBackground(.hidden)
                        .background(Color.white.opacity(0.045))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    Text(model.lyricsStatus)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.62))
                }
            }
        }
    }

    private func feature(_ icon: String, _ text: String) -> some View {
        Label(text, systemImage: icon).font(.caption).foregroundStyle(.white.opacity(0.78))
    }

    private func slider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, percent: Bool) -> some View {
        HStack {
            Text(title).font(.caption).frame(width: 86, alignment: .leading)
            Slider(value: value, in: range)
            Text(percent ? "\(Int(value.wrappedValue * 100))%" : String(format: "%.2f", value.wrappedValue))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
                .frame(width: 48, alignment: .trailing)
        }
    }

    private func effectRow(_ title: String, enabled: Binding<Bool>, value: Binding<Double>) -> some View {
        VStack(spacing: 4) {
            HStack {
                Toggle(title, isOn: enabled)
                    .font(.caption.bold())
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.65))
            }
            Slider(value: value, in: 0...1)
                .disabled(!enabled.wrappedValue)
        }
        .opacity(enabled.wrappedValue ? 1 : 0.52)
    }
}

struct WavePresetCard: View {
    let preset: VisualizerPreset
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 5) {
                WavePresetMiniCanvas(preset: preset)
                    .frame(height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(selected ? .cyan : .white.opacity(0.08), lineWidth: selected ? 2 : 1))
                Text(preset.title)
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(preset.subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.52))
                    .lineLimit(1)
            }
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Color.cyan.opacity(0.15) : Color.white.opacity(0.045))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(selected ? .cyan.opacity(0.75) : .white.opacity(0.07), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help("\(preset.title): \(preset.kind.rawValue)")
    }
}

struct WavePresetMiniCanvas: View {
    let preset: VisualizerPreset

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(colors: [
                    Color(red: 0.015, green: 0.025, blue: 0.032),
                    Color(red: 0.030, green: 0.055, blue: 0.070)
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: size.height)
            ))
            let colors = presetColors
            let samples = miniSamples(count: 72, seed: preset.seed)
            switch preset.kind {
            case .circleSpectrum:
                drawCircle(context: &context, size: size, samples: samples, colors: colors)
            case .blockBars, .barsSpectrum, .stereoLeftRight:
                drawBars(context: &context, size: size, samples: samples, colors: colors)
            case .verticalSideWaves:
                drawSideWave(context: &context, size: size, samples: samples, colors: colors)
            case .frequencyMesh, .neonFFT:
                drawMesh(context: &context, size: size, samples: samples, colors: colors, layers: preset.kind == .frequencyMesh ? 5 : 3)
            default:
                drawWave(context: &context, size: size, samples: samples, colors: colors)
            }
        }
    }

    private var presetColors: [Color] {
        [
            Color(NSColor(hex: preset.primaryHex) ?? .cyan),
            Color(NSColor(hex: preset.secondaryHex) ?? .systemPink),
            Color(NSColor(hex: preset.glowHex) ?? .white)
        ]
    }

    private func miniSamples(count: Int, seed: Double) -> [CGFloat] {
        (0..<count).map { index in
            let x = Double(index)
            let bass = abs(sin(x * 0.16 + seed)) * 0.44
            let mid = abs(sin(x * 0.41 + seed * 0.7)) * 0.34
            let spike = pow(abs(sin(x * 0.073 + seed * 1.9)), 5.0) * 0.32
            return CGFloat(min(1, 0.08 + bass + mid + spike))
        }
    }

    private func drawBars(context: inout GraphicsContext, size: CGSize, samples: [CGFloat], colors: [Color]) {
        let count = 34
        let slot = size.width / CGFloat(count)
        let base = size.height * 0.72
        for index in 0..<count {
            let sample = samples[(index * max(1, samples.count / count)) % samples.count]
            let height = sample * size.height * 0.52
            let rect = CGRect(x: CGFloat(index) * slot + slot * 0.18, y: base - height, width: slot * 0.62, height: height)
            context.fill(Path(rect), with: .color(colors[index % colors.count].opacity(0.88)))
            if preset.stereoMode != .combined || preset.kind == .blockBars {
                context.fill(Path(CGRect(x: rect.minX, y: base, width: rect.width, height: height * 0.45)), with: .color(colors[(index + 1) % colors.count].opacity(0.55)))
            }
        }
    }

    private func drawWave(context: inout GraphicsContext, size: CGSize, samples: [CGFloat], colors: [Color]) {
        let base = size.height * 0.58
        let band = size.height * 0.30
        let step = size.width / CGFloat(max(1, samples.count - 1))
        var path = Path()
        for index in samples.indices {
            let point = CGPoint(x: CGFloat(index) * step, y: base + sin(CGFloat(index) * 0.18) * 3 - samples[index] * band)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        context.addFilter(.shadow(color: colors[0].opacity(0.9), radius: 5))
        context.stroke(path, with: .linearGradient(Gradient(colors: colors), startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)), lineWidth: 2)
    }

    private func drawMesh(context: inout GraphicsContext, size: CGSize, samples: [CGFloat], colors: [Color], layers: Int) {
        let step = size.width / CGFloat(max(1, samples.count - 1))
        context.addFilter(.shadow(color: colors[0].opacity(0.85), radius: 5))
        for layer in 0..<layers {
            let t = CGFloat(layer) / CGFloat(max(1, layers - 1))
            let base = size.height * (0.30 + t * 0.42)
            var path = Path()
            for index in samples.indices {
                let ripple = sin(CGFloat(index) * 0.21 + t * 5) * size.height * 0.035
                let point = CGPoint(x: CGFloat(index) * step, y: base + ripple - samples[index] * size.height * (0.18 + t * 0.14))
                if index == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            context.stroke(path, with: .linearGradient(Gradient(colors: colors), startPoint: .zero, endPoint: CGPoint(x: size.width, y: base)), lineWidth: layers > 3 ? 0.9 : 1.6)
        }
    }

    private func drawCircle(context: inout GraphicsContext, size: CGSize, samples: [CGFloat], colors: [Color]) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) * 0.18
        context.addFilter(.shadow(color: colors[0].opacity(0.9), radius: 5))
        for index in 0..<64 {
            let angle = CGFloat(index) / 64 * .pi * 2
            let sample = samples[index % samples.count]
            let length = radius + sample * min(size.width, size.height) * 0.23
            var path = Path()
            path.move(to: CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius))
            path.addLine(to: CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length))
            context.stroke(path, with: .color(colors[index % colors.count].opacity(0.85)), lineWidth: 0.9)
        }
    }

    private func drawSideWave(context: inout GraphicsContext, size: CGSize, samples: [CGFloat], colors: [Color]) {
        let count = min(54, samples.count)
        let step = size.height / CGFloat(count)
        context.addFilter(.shadow(color: colors[0].opacity(0.8), radius: 5))
        for index in 0..<count {
            let y = CGFloat(index) * step
            let width = samples[index] * size.width * 0.40
            var left = Path()
            left.move(to: CGPoint(x: size.width * 0.12, y: y))
            left.addLine(to: CGPoint(x: size.width * 0.12 + width, y: y))
            context.stroke(left, with: .color(colors[index % colors.count].opacity(0.85)), lineWidth: 1.0)
            var right = Path()
            right.move(to: CGPoint(x: size.width * 0.88, y: y))
            right.addLine(to: CGPoint(x: size.width * 0.88 - width, y: y))
            context.stroke(right, with: .color(colors[(index + 1) % colors.count].opacity(0.65)), lineWidth: 1.0)
        }
    }
}

struct Panel<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased()).font(.caption.bold()).foregroundStyle(.white.opacity(0.7))
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.035, green: 0.055, blue: 0.065))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.08), lineWidth: 1))
    }
}

enum SampleFrames {
    static func preview(samples: [CGFloat], spectrumFrames: [[CGFloat]], phase: TimeInterval, smoothing: Double, direction: WaveDirection, mirror: MirrorMode) -> [CGFloat] {
        var values: [CGFloat]
        if !spectrumFrames.isEmpty {
            values = interpolated(frames: spectrumFrames, position: phase * 28.0)
            for index in values.indices {
                let flutter = CGFloat(0.93 + 0.07 * sin(phase * 8.0 + Double(index) * 0.29))
                values[index] = clamp(values[index] * flutter)
            }
        } else {
            values = samples
        }
        return processed(values, fallback: samples, smoothing: smoothing, direction: direction, mirror: mirror)
    }

    static func export(snapshot: ExportSnapshot, fallback: [CGFloat], time: Double, duration: Double) -> [CGFloat] {
        guard !snapshot.spectrumFrames.isEmpty else {
            return processed(fallback, fallback: fallback, smoothing: snapshot.smoothing, direction: snapshot.waveDirection, mirror: snapshot.mirrorMode)
        }
        let progress = duration > 0 ? min(0.999_999, max(0, time / duration)) : 0
        let position = progress * Double(max(1, snapshot.spectrumFrames.count - 1))
        return processed(interpolated(frames: snapshot.spectrumFrames, position: position), fallback: fallback, smoothing: snapshot.smoothing, direction: snapshot.waveDirection, mirror: snapshot.mirrorMode)
    }

    static func energy(_ values: [CGFloat]) -> CGFloat {
        guard !values.isEmpty else { return 0 }
        let peak = values.max() ?? 0
        let avg = values.reduce(CGFloat(0), +) / CGFloat(values.count)
        return clamp(peak * 0.62 + avg * 0.55)
    }

    private static func interpolated(frames: [[CGFloat]], position: Double) -> [CGFloat] {
        guard !frames.isEmpty else { return [] }
        if frames.count == 1 { return frames[0] }
        let wrapped = position.truncatingRemainder(dividingBy: Double(frames.count))
        let safePosition = wrapped < 0 ? wrapped + Double(frames.count) : wrapped
        let lower = Int(floor(safePosition)) % frames.count
        let upper = (lower + 1) % frames.count
        let amount = CGFloat(safePosition - floor(safePosition))
        let first = frames[lower]
        let second = frames[upper]
        let count = min(first.count, second.count)
        guard count > 0 else { return first }
        return (0..<count).map { index in
            clamp(first[index] * (1 - amount) + second[index] * amount)
        }
    }

    private static func processed(_ input: [CGFloat], fallback: [CGFloat], smoothing: Double, direction: WaveDirection, mirror: MirrorMode) -> [CGFloat] {
        var values = input.isEmpty ? fallback : input
        guard !values.isEmpty else { return AudioTools.placeholderWaveform() }
        if smoothing > 0.01 {
            let radius = max(1, Int(smoothing * 5))
            values = values.indices.map { index in
                let range = max(0, index - radius)...min(values.count - 1, index + radius)
                let sum = range.reduce(CGFloat(0)) { $0 + values[$1] }
                return sum / CGFloat(range.count)
            }
        }
        switch direction {
        case .rightToLeft, .outwardCenter:
            values.reverse()
        default:
            break
        }
        if mirror == .horizontal || mirror == .both {
            let half = Array(values.prefix(max(1, values.count / 2)))
            values = half + half.reversed()
        }
        return values
    }

    private static func clamp(_ value: CGFloat) -> CGFloat {
        min(1, max(0, value))
    }
}

struct PreviewPanel: View {
    @EnvironmentObject private var model: AppModel
    @State private var animateKenBurns = false

    var body: some View {
        Panel("Live Preview") {
            GeometryReader { proxy in
                let rect = fit(canvas: model.canvasSize, into: proxy.size)
                ZStack {
                    Color.black
                    TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                        let phase = timeline.date.timeIntervalSinceReferenceDate
                        let previewSamples = SampleFrames.preview(
                            samples: model.waveform,
                            spectrumFrames: model.spectrumFrames,
                            phase: phase,
                            smoothing: model.smoothing,
                            direction: model.waveDirection,
                            mirror: model.mirrorMode
                        )
                        let energy = SampleFrames.energy(previewSamples)
                        let effects = model.renderEffects
                        let shake = CGFloat(effects.bassShake) * energy * min(rect.width, rect.height) * 0.018
                        let effectOffset = CGSize(width: CGFloat(sin(phase * 71)) * shake, height: CGFloat(cos(phase * 55)) * shake * 0.7)
                        if let url = model.previewImageURL, let image = NSImage(contentsOf: url) {
                            CanvasImageLayer(
                                image: image,
                                mode: model.canvasFitMode,
                                zoom: CGFloat(model.imageZoom) * kenBurnsScale * (1 + energy * CGFloat(effects.zoomPunch) * 0.08),
                                rotation: model.imageRotation,
                                offsetX: model.imageOffsetX,
                                offsetY: model.imageOffsetY,
                                kenBurnsOffset: kenBurnsOffset(in: rect.size),
                                effectOffset: effectOffset
                            )
                            .frame(width: rect.width, height: rect.height)
                            .clipped()
                            .animation(.easeInOut(duration: max(2.5, 10 - model.kenBurnsSpeed * 7)).repeatForever(autoreverses: true), value: animateKenBurns)
                        } else {
                            VStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.down").font(.largeTitle).foregroundStyle(.cyan)
                                Text("Audio + Bild hier ablegen oder unten doppelklicken")
                            }
                        }
                        VisualizerCanvas(
                            samples: model.waveform,
                            spectrumFrames: model.spectrumFrames,
                            phase: phase,
                            kind: model.visualizerKind,
                            position: model.resolvedWavePosition,
                            stereoMode: model.stereoMode,
                            direction: model.waveDirection,
                            mirror: model.mirrorMode,
                            colors: model.resolvedColors().map(Color.init),
                            opacity: model.opacity,
                            bars: Int(model.barCount),
                            heightScale: model.waveHeight,
                            lineWidth: model.lineWidth,
                            glow: model.glowStrength,
                            smoothing: model.smoothing,
                            effects: effects
                        )
                        SceneOverlayView(
                            settings: model.sceneOverlaySettings,
                            phase: phase,
                            energy: energy,
                            renderMode: model.renderMode,
                            canvasDescription: model.canvasDescription
                        )
                        if let lyric = model.previewLyrics(at: phase) {
                            LyricsOverlayView(
                                text: lyric,
                                position: model.lyricsPosition,
                                wavePosition: model.resolvedWavePosition,
                                heightScale: model.waveHeight,
                                sizeScale: model.lyricsSize,
                                opacity: model.lyricsOpacity
                            )
                        }
                    }
                    .frame(width: rect.width, height: rect.height)
                }
                .frame(width: rect.width, height: rect.height)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
            .onAppear { animateKenBurns = true }
        }
    }

    private var kenBurnsScale: CGFloat {
        let amount = CGFloat(model.kenBurnsStrength) * 0.22
        switch model.kenBurnsMode {
        case .zoomOut:
            return animateKenBurns ? 1.0 : 1.0 + amount
        case .zoomIn:
            return animateKenBurns ? 1.0 + amount : 1.0
        default:
            return 1.0 + amount * 0.4
        }
    }

    private func kenBurnsOffset(in size: CGSize) -> CGSize {
        let amount = CGFloat(model.kenBurnsStrength) * min(size.width, size.height) * 0.04
        switch model.kenBurnsMode {
        case .panLeft:
            return CGSize(width: animateKenBurns ? -amount : amount, height: 0)
        case .panRight:
            return CGSize(width: animateKenBurns ? amount : -amount, height: 0)
        case .panUp:
            return CGSize(width: 0, height: animateKenBurns ? -amount : amount)
        case .panDown:
            return CGSize(width: 0, height: animateKenBurns ? amount : -amount)
        case .smoothDrift:
            return CGSize(width: animateKenBurns ? amount : -amount, height: animateKenBurns ? -amount * 0.45 : amount * 0.45)
        default:
            return .zero
        }
    }

    private func fit(canvas: CGSize, into container: CGSize) -> CGRect {
        let scale = min(container.width / canvas.width, container.height / canvas.height)
        return CGRect(origin: .zero, size: CGSize(width: canvas.width * scale, height: canvas.height * scale))
    }
}

struct CanvasImageLayer: View {
    let image: NSImage
    let mode: CanvasFitMode
    let zoom: CGFloat
    let rotation: Double
    let offsetX: Double
    let offsetY: Double
    let kenBurnsOffset: CGSize
    let effectOffset: CGSize

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                if mode == .blurExtend {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .blur(radius: 26)
                        .opacity(0.72)
                        .clipped()
                    fittedImage(mode: .fit)
                } else {
                    fittedImage(mode: mode)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(Color.black)
            .clipped()
        }
    }

    @ViewBuilder
    private func fittedImage(mode: CanvasFitMode) -> some View {
        switch mode {
        case .fit:
            transformed(Image(nsImage: image).resizable().scaledToFit())
        case .fill:
            transformed(Image(nsImage: image).resizable().scaledToFill())
        case .stretch:
            transformed(Image(nsImage: image).resizable())
        case .blurExtend:
            transformed(Image(nsImage: image).resizable().scaledToFit())
        }
    }

    private func transformed<V: View>(_ view: V) -> some View {
        GeometryReader { proxy in
            view
                .frame(width: proxy.size.width, height: proxy.size.height)
                .scaleEffect(zoom)
                .rotationEffect(.degrees(rotation))
                .offset(
                    x: CGFloat(offsetX) * proxy.size.width * 0.35 + kenBurnsOffset.width + effectOffset.width,
                    y: -CGFloat(offsetY) * proxy.size.height * 0.35 + kenBurnsOffset.height + effectOffset.height
                )
        }
    }
}

struct SceneOverlayView: View {
    let settings: SceneOverlaySettings
    let phase: TimeInterval
    let energy: CGFloat
    var renderMode: RenderMode
    let canvasDescription: String

    var body: some View {
        Group {
            if settings.isEnabled {
                GeometryReader { proxy in
                    let landscape = proxy.size.width >= proxy.size.height
                    let accent = Color(NSColor(hex: settings.accentHex) ?? .cyan)
                    let magenta = Color(NSColor(hex: settings.magentaHex) ?? .systemPink)
                    ZStack {
                        if settings.showBadges {
                            badgeStack(accent: accent, magenta: magenta, landscape: landscape)
                                .position(x: proxy.size.width * (landscape ? 0.062 : 0.105), y: proxy.size.height * (landscape ? 0.17 : 0.13))
                        }
                        if settings.showTitle && settings.template != .djLowerThird {
                            titleBlock(accent: accent, magenta: magenta, landscape: landscape, size: proxy.size)
                                .position(titlePosition(in: proxy.size, landscape: landscape))
                        }
                        if settings.showStats {
                            statsBlock(accent: accent, magenta: magenta)
                                .position(x: proxy.size.width * 0.84, y: proxy.size.height * (landscape ? 0.12 : 0.08))
                        }
                        if settings.template == .djLowerThird {
                            lowerThirdPanel(accent: accent, magenta: magenta, size: proxy.size)
                                .position(x: proxy.size.width * (landscape ? 0.40 : 0.50), y: proxy.size.height * (landscape ? 0.88 : 0.90))
                        }
                        if settings.template == .fullscreenWave {
                            liveStatus(accent: accent)
                                .position(x: proxy.size.width * 0.14, y: proxy.size.height * 0.93)
                        }
                    }
                    .opacity(settings.opacity)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func badgeStack(accent: Color, magenta: Color, landscape: Bool) -> some View {
        VStack(spacing: landscape ? 14 : 9) {
            sceneBadge(settings.bpm, accent: accent)
            sceneBadge(settings.genre, accent: accent)
            sceneBadge(settings.tag, accent: magenta.opacity(0.86))
        }
    }

    private func sceneBadge(_ text: String, accent: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .multilineTextAlignment(.center)
            .foregroundStyle(.white.opacity(0.9))
            .lineLimit(2)
            .minimumScaleFactor(0.68)
            .frame(width: 66, height: 54)
            .background(.black.opacity(0.42))
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: 2).stroke(accent.opacity(0.72), lineWidth: 1)
                    CornerMarks(color: accent.opacity(0.9))
                }
            )
            .shadow(color: accent.opacity(0.24), radius: 8)
    }

    private func titleBlock(accent: Color, magenta: Color, landscape: Bool, size: CGSize) -> some View {
        VStack(alignment: landscape ? .leading : .center, spacing: 2) {
            Text("DJ")
                .font(.system(size: max(17, min(size.width, size.height) * 0.042), weight: .black, design: .rounded))
                .italic()
                .foregroundStyle(accent)
            Text(settings.artist)
                .font(.system(size: max(24, min(size.width, size.height) * 0.065), weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.94))
                .shadow(color: .black.opacity(0.9), radius: 6, x: 0, y: 2)
                .shadow(color: accent.opacity(0.26), radius: 12)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
            Text(settings.subtitle)
                .font(.system(size: max(9, min(size.width, size.height) * 0.016), weight: .semibold, design: .rounded))
                .foregroundStyle(accent.opacity(0.95))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .frame(width: landscape ? size.width * 0.36 : size.width * 0.76, alignment: landscape ? .leading : .center)
    }

    private func statsBlock(accent: Color, magenta: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            statRow("FPS", "\(renderMode.fps).00", color: accent)
            statRow("MODE", renderMode.rawValue, color: magenta)
            statRow("RES", canvasDescription, color: accent.opacity(0.9))
            statRow("SYNC", energy > 0.18 ? "LOCKED" : "IDLE", color: energy > 0.18 ? magenta : .white.opacity(0.55))
        }
        .font(.system(size: 10, weight: .semibold, design: .monospaced))
        .padding(8)
        .background(.black.opacity(0.44))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(.white.opacity(0.16), lineWidth: 1))
    }

    private func lowerThirdPanel(accent: Color, magenta: Color, size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.black.opacity(0.58))
                    .frame(width: 56, height: 56)
                    .overlay(Text("DJ").font(.headline.bold()).foregroundStyle(accent))
                VStack(alignment: .leading, spacing: 3) {
                    Text(settings.artist)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .lineLimit(1)
                    Text(settings.subtitle)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(accent)
                        .lineLimit(1)
                }
            }
            HStack(spacing: 8) {
                Text("2:15").font(.system(size: 10, design: .monospaced)).foregroundStyle(.white.opacity(0.75))
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.18)).frame(height: 3)
                    Capsule().fill(LinearGradient(colors: [accent, magenta], startPoint: .leading, endPoint: .trailing)).frame(width: size.width * 0.18, height: 3)
                    Circle().fill(.white).frame(width: 7, height: 7).offset(x: size.width * 0.18)
                }
                Text("4:45").font(.system(size: 10, design: .monospaced)).foregroundStyle(.white.opacity(0.75))
            }
            HStack(spacing: 7) {
                ForEach(["Bottom", "Top", "Center", "Stereo", "Bars", "Circle"], id: \.self) { label in
                    Text(label)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.76))
                        .frame(width: 52, height: 24)
                        .background(.black.opacity(0.38), in: RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(label == "Bottom" ? accent.opacity(0.9) : .white.opacity(0.12), lineWidth: 1))
                }
            }
        }
        .padding(10)
        .frame(width: min(size.width * 0.62, 620), alignment: .leading)
        .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 6))
    }

    private func statRow(_ label: String, _ value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(label).foregroundStyle(.white.opacity(0.62)).frame(width: 34, alignment: .leading)
            Text(value).foregroundStyle(color).lineLimit(1)
        }
    }

    private func liveStatus(accent: Color) -> some View {
        HStack(spacing: 7) {
            Circle().fill(accent).frame(width: 6, height: 6)
            Text("AUDIO STREAM ACTIVE")
            Text("[IN] MASTER_BUS_L/R")
        }
        .font(.system(size: 10, weight: .semibold, design: .monospaced))
        .foregroundStyle(.white.opacity(0.62))
    }

    private func titlePosition(in size: CGSize, landscape: Bool) -> CGPoint {
        switch settings.template {
        case .djLowerThird:
            return CGPoint(x: landscape ? size.width * 0.22 : size.width * 0.50, y: landscape ? size.height * 0.76 : size.height * 0.82)
        case .djHud:
            return CGPoint(x: landscape ? size.width * 0.21 : size.width * 0.50, y: landscape ? size.height * 0.75 : size.height * 0.80)
        case .fullscreenWave:
            return CGPoint(x: size.width * 0.50, y: size.height * 0.82)
        case .off:
            return CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        }
    }
}

struct CornerMarks: View {
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let l = min(w, h) * 0.16
            Path { path in
                path.move(to: CGPoint(x: 0, y: l))
                path.addLine(to: .zero)
                path.addLine(to: CGPoint(x: l, y: 0))
                path.move(to: CGPoint(x: w - l, y: 0))
                path.addLine(to: CGPoint(x: w, y: 0))
                path.addLine(to: CGPoint(x: w, y: l))
                path.move(to: CGPoint(x: w, y: h - l))
                path.addLine(to: CGPoint(x: w, y: h))
                path.addLine(to: CGPoint(x: w - l, y: h))
                path.move(to: CGPoint(x: l, y: h))
                path.addLine(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: 0, y: h - l))
            }
            .stroke(color, lineWidth: 1.4)
        }
    }
}

struct LyricsOverlayView: View {
    let text: String
    let position: LyricsPosition
    let wavePosition: WavePosition
    let heightScale: Double
    let sizeScale: Double
    let opacity: Double

    var body: some View {
        GeometryReader { proxy in
            Text(text)
                .font(.system(size: fontSize(in: proxy.size), weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(opacity))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.55)
                .shadow(color: .black.opacity(0.95), radius: 6, x: 0, y: 2)
                .shadow(color: .cyan.opacity(0.30 * opacity), radius: 12, x: 0, y: 0)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.black.opacity(0.18 * opacity), in: RoundedRectangle(cornerRadius: 8))
                .frame(width: proxy.size.width * 0.86)
                .position(x: proxy.size.width / 2, y: yPosition(in: proxy.size))
        }
        .allowsHitTesting(false)
    }

    private func fontSize(in size: CGSize) -> CGFloat {
        max(18, min(size.width, size.height) * 0.038 * CGFloat(sizeScale))
    }

    private func yPosition(in size: CGSize) -> CGFloat {
        let wave = CGFloat(heightScale)
        switch position {
        case .top:
            return size.height * 0.12
        case .center:
            return size.height * 0.50
        case .bottom:
            return size.height * 0.86
        case .aboveWave:
            switch wavePosition {
            case .top:
                return size.height * min(0.36, wave + 0.12)
            case .center:
                return size.height * 0.36
            case .left, .right:
                return size.height * 0.74
            case .bottom:
                return size.height * max(0.58, 0.90 - wave)
            }
        case .belowWave:
            switch wavePosition {
            case .top:
                return size.height * max(0.10, wave * 0.52)
            case .center:
                return size.height * 0.64
            case .left, .right:
                return size.height * 0.88
            case .bottom:
                return size.height * 0.94
            }
        }
    }
}

struct VisualizerCanvas: View {
    let samples: [CGFloat]
    let spectrumFrames: [[CGFloat]]
    let phase: TimeInterval
    let kind: VisualizerKind
    let position: WavePosition
    let stereoMode: StereoMode
    let direction: WaveDirection
    let mirror: MirrorMode
    let colors: [Color]
    let opacity: Double
    let bars: Int
    let heightScale: Double
    let lineWidth: Double
    let glow: Double
    let smoothing: Double
    let effects: RenderEffects

    var body: some View {
        Canvas { context, size in
            let palette = (colors.isEmpty ? [Color.cyan, Color.pink, Color.blue] : colors).map { $0.opacity(opacity) }
            let band = size.height * heightScale
            let base = baseLine(size: size, band: band)
            let normalizedSamples = displaySamples()
            let energy = SampleFrames.energy(normalizedSamples)
            if effects.beatFlash > 0 {
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(Double(energy) * effects.beatFlash * 0.16)))
            }
            if effects.lensGlow > 0 {
                drawLensGlow(context: &context, size: size, energy: energy, palette: palette)
            }
            context.addFilter(.shadow(color: .cyan.opacity(opacity), radius: 4 + max(glow, effects.lensGlow) * 18))
            drawParticles(context: &context, size: size, samples: normalizedSamples, palette: palette, amount: max(glow, effects.particles))
            if kind == .blockBars || kind == .barsSpectrum || kind == .stereoLeftRight {
                let count = max(8, min(160, bars))
                let step = max(1, normalizedSamples.count / count)
                let slot = size.width / CGFloat(count)
                for bar in 0..<count {
                    let value = normalizedSamples[min(normalizedSamples.count - 1, bar * step)] * band
                    let x = CGFloat(bar) * slot + slot * 0.14
                    let w = slot * 0.72
                    if stereoMode == .combined && kind != .blockBars {
                        context.fill(Path(CGRect(x: x, y: base - value, width: w, height: value)), with: .color(palette[bar % palette.count]))
                    } else {
                        context.fill(Path(CGRect(x: x, y: base - value, width: w, height: value)), with: .color(palette[bar % palette.count]))
                        context.fill(Path(CGRect(x: x, y: base, width: w, height: value * 0.72)), with: .color(palette[(bar + 1) % palette.count]))
                    }
                }
            } else if kind == .circleSpectrum {
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) * 0.18
                for (index, sample) in normalizedSamples.enumerated().prefix(180) {
                    let angle = CGFloat(index) / 180 * .pi * 2
                    let length = radius + sample * band * 0.55
                    var path = Path()
                    path.move(to: CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius))
                    path.addLine(to: CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length))
                    context.stroke(path, with: .color(palette[index % palette.count]), lineWidth: max(1, lineWidth))
                }
            } else if kind == .neonFFT || kind == .frequencyMesh {
                drawFrequencyMesh(context: &context, size: size, samples: normalizedSamples, palette: palette, base: base, band: band)
            } else {
                var path = Path()
                let step = size.width / CGFloat(max(1, normalizedSamples.count - 1))
                for (index, sample) in normalizedSamples.enumerated() {
                    let x = horizontalPosition(index: index, count: normalizedSamples.count, size: size, step: step)
                    let h = sample * band
                    switch position {
                    case .left, .right:
                        let y = CGFloat(index) / CGFloat(max(1, normalizedSamples.count - 1)) * size.height
                        let xBase = position == .left ? size.width * 0.08 : size.width * 0.92
                        path.move(to: CGPoint(x: xBase, y: y))
                        path.addLine(to: CGPoint(x: xBase + (position == .left ? h : -h), y: y))
                    default:
                        if stereoMode == .combined {
                            path.move(to: CGPoint(x: x, y: base - h * 0.5))
                            path.addLine(to: CGPoint(x: x, y: base + h * 0.5))
                        } else {
                            path.move(to: CGPoint(x: x, y: base - h))
                            path.addLine(to: CGPoint(x: x, y: base + h * 0.72))
                        }
                    }
                }
                context.stroke(path, with: .linearGradient(Gradient(colors: palette), startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)), lineWidth: max(0.5, lineWidth))
            }
        }
        .allowsHitTesting(false)
    }

    private func displaySamples() -> [CGFloat] {
        SampleFrames.preview(samples: samples, spectrumFrames: spectrumFrames, phase: phase, smoothing: smoothing, direction: direction, mirror: mirror)
    }

    private func drawParticles(context: inout GraphicsContext, size: CGSize, samples: [CGFloat], palette: [Color], amount: Double) {
        guard amount > 0.05, !samples.isEmpty else { return }
        let count = min(120, samples.count)
        for index in 0..<count {
            let value = samples[(index * max(1, samples.count / count)) % samples.count]
            guard value > 0.18 else { continue }
            let t = (CGFloat(index) * 37.0 + CGFloat(phase * 26.0)).truncatingRemainder(dividingBy: 997) / 997
            let x = (CGFloat(index) / CGFloat(max(1, count - 1))) * size.width
            let y = size.height * (0.18 + 0.58 * t)
            let radius = max(0.8, value * CGFloat(amount) * 5.4)
            let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: rect), with: .color(palette[index % palette.count].opacity(0.16 + value * 0.32)))
        }
    }

    private func drawLensGlow(context: inout GraphicsContext, size: CGSize, energy: CGFloat, palette: [Color]) {
        let radius = min(size.width, size.height) * CGFloat(0.42 + effects.lensGlow * 0.24)
        let origin = CGPoint(x: size.width * 0.72, y: size.height * 0.18)
        let rect = CGRect(x: origin.x - radius, y: origin.y - radius, width: radius * 2, height: radius * 2)
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                Gradient(colors: [palette.first?.opacity(0.18 + Double(energy) * effects.lensGlow * 0.18) ?? .cyan.opacity(0.2), .clear]),
                center: origin,
                startRadius: 0,
                endRadius: radius
            )
        )
    }

    private func drawFrequencyMesh(context: inout GraphicsContext, size: CGSize, samples: [CGFloat], palette: [Color], base: CGFloat, band: CGFloat) {
        guard samples.count > 2 else { return }
        let layers = kind == .frequencyMesh ? 7 : 4
        let step = size.width / CGFloat(max(1, samples.count - 1))
        for layer in 0..<layers {
            var path = Path()
            let layerProgress = CGFloat(layer) / CGFloat(max(1, layers - 1))
            let lift = (layerProgress - 0.5) * band * 0.95
            for index in samples.indices {
                let x = CGFloat(index) * step
                let sample = samples[index]
                let ripple = sin(CGFloat(phase) * (1.7 + layerProgress) + CGFloat(index) * 0.13 + layerProgress * 4.2)
                let y = base + lift - sample * band * (0.42 + layerProgress * 0.42) + ripple * band * 0.045
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.stroke(
                path,
                with: .linearGradient(Gradient(colors: palette), startPoint: .zero, endPoint: CGPoint(x: size.width, y: base)),
                lineWidth: max(0.55, lineWidth * (kind == .frequencyMesh ? 0.62 : 1.15))
            )
        }
    }

    private func baseLine(size: CGSize, band: CGFloat) -> CGFloat {
        switch position {
        case .top:
            return band * 0.55 + size.height * 0.03
        case .center:
            return size.height * 0.5
        default:
            return size.height - band * 0.42 - size.height * 0.03
        }
    }

    private func horizontalPosition(index: Int, count: Int, size: CGSize, step: CGFloat) -> CGFloat {
        switch direction {
        case .centerOutward:
            let half = CGFloat(count - 1) / 2
            return size.width / 2 + (CGFloat(index) - half) * step
        case .outwardCenter:
            let half = CGFloat(count - 1) / 2
            return size.width / 2 - (CGFloat(index) - half) * step
        default:
            return CGFloat(index) * step
        }
    }
}

struct MediaTray: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        HStack(spacing: 8) {
            mediaColumn("Bilder", items: model.images, selectedID: model.selectedImageID, choose: model.chooseImages, select: { model.selectedImageID = $0.id }, remove: model.removeImage)
            mediaColumn("Videos", items: model.videos, selectedID: model.selectedVideoID, choose: model.chooseVideos, select: { model.selectedVideoID = $0.id }, remove: model.removeVideo)
            Panel("Audio") {
                HStack {
                    Button { model.chooseAudio() } label: { Label("Audio wählen", systemImage: "folder") }
                    Spacer()
                    if model.effectiveAudioURL != nil {
                        Button { model.clearAudio() } label: { Image(systemName: "xmark.circle.fill") }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.red)
                    }
                }
                if model.effectiveAudioURL != nil {
                    Label(model.audioSourceDescription, systemImage: "waveform")
                        .font(.caption)
                        .lineLimit(2)
                } else {
                    Text("Doppelklick zum Auswählen oder Video mit Audio laden").font(.caption).foregroundStyle(.white.opacity(0.55))
                }
            }
            .frame(width: 210)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { model.chooseAudio() }
        }
    }

    private func mediaColumn(_ title: String, items: [MediaItem], selectedID: UUID?, choose: @escaping () -> Void, select: @escaping (MediaItem) -> Void, remove: @escaping (MediaItem) -> Void) -> some View {
        Panel(title) {
            HStack {
                Button { choose() } label: { Label("Wählen", systemImage: "folder") }
                Spacer()
                Text("X löscht").font(.caption2).foregroundStyle(.white.opacity(0.5))
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(items) { item in
                        ZStack(alignment: .topTrailing) {
                            thumb(item)
                                .frame(width: 62, height: 62)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(selectedID == item.id ? .cyan : .white.opacity(0.1), lineWidth: selectedID == item.id ? 2 : 1))
                                .onTapGesture { select(item) }
                            Button { remove(item) } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .red)
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .buttonStyle(.plain)
                            .help("\(title) entfernen")
                        }
                    }
                    if items.isEmpty {
                        Button { choose() } label: {
                            VStack {
                                Image(systemName: title == "Bilder" ? "photo" : "film")
                                Text("Wählen").font(.caption2)
                            }
                            .frame(width: 66, height: 62)
                            .background(.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { choose() }
    }

    private func thumb(_ item: MediaItem) -> some View {
        Group {
            if let image = NSImage(contentsOf: item.url) {
                Image(nsImage: image).resizable().scaledToFill()
            } else {
                ZStack { Color.black.opacity(0.5); Image(systemName: "film").font(.title2) }
            }
        }
    }
}

struct ExportBar: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Dateiname")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                    TextField("NALA-Visualizer", text: $model.outputFileName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                        .disabled(model.isRendering || model.isBatchRendering)
                    Text("Speicherort")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                    Text(model.outputDirectory.path)
                        .font(.caption2)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(width: 260, alignment: .leading)
                        .foregroundStyle(.white.opacity(0.7))
                    Button("Wählen ...") { model.chooseOutputDirectory() }
                        .disabled(model.isRendering || model.isBatchRendering)
                }
                HStack(spacing: 10) {
                    Text("Render")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                    Picker("Render", selection: $model.renderMode) {
                        ForEach(RenderMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 120)
                    .disabled(model.isRendering || model.isBatchRendering)
                    Text(model.renderMode.summary)
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                    Button { model.addCurrentToBatch() } label: {
                        Label("Zur Batch", systemImage: "plus.rectangle.on.rectangle")
                    }
                    .disabled(!model.canCreateRenderJob)
                    Text("\(model.batchJobs.count) Jobs")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.55))
                }
                Text(model.status).font(.caption).foregroundStyle(model.status.contains("fehl") ? .orange : .green)
            }
            Spacer()
            if model.isRendering || model.isBatchRendering { ProgressView(value: model.renderProgress).frame(width: 180) }
            Button {
                Task { await model.export() }
            } label: {
                Label(model.isRendering ? "RENDERT" : model.renderMode.buttonTitle, systemImage: model.renderMode == .max ? "bolt.fill" : "square.and.arrow.up")
                    .frame(width: 210, height: 48)
                    .background(renderGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .disabled(!model.canCreateRenderJob)
        }
        .padding(12)
        .background(Color(red: 0.035, green: 0.055, blue: 0.065))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var renderGradient: LinearGradient {
        switch model.renderMode {
        case .standard:
            LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
        case .turbo:
            LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing)
        case .max:
            LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
        }
    }
}

struct BatchQueueView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Panel("Batch Queue") {
            HStack(spacing: 10) {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(model.batchJobs) { job in
                            batchCard(job)
                        }
                    }
                }
                VStack(spacing: 8) {
                    if model.isBatchRendering {
                        Button {
                            model.cancelBatchRender()
                        } label: {
                            Label("Batch stoppen", systemImage: "stop.fill")
                                .frame(width: 126)
                        }
                    } else {
                        Button {
                            model.startBatchRender()
                        } label: {
                            Label("Batch starten", systemImage: "play.fill")
                                .frame(width: 126)
                        }
                        .disabled(model.batchJobs.isEmpty || model.isRendering)
                    }
                    Button {
                        model.showBatchInspector()
                    } label: {
                        Label("Details", systemImage: "sidebar.right")
                            .frame(width: 126)
                    }
                    .disabled(model.batchJobs.isEmpty)
                    Button("MAX für alle") { model.applyRenderModeToAllBatchJobs(.max) }
                        .frame(width: 126)
                        .disabled(model.batchJobs.isEmpty || model.isBatchRendering)
                    Toggle("2 Pipelines", isOn: $model.batchParallelPipelines)
                        .font(.caption)
                        .frame(width: 126, alignment: .leading)
                        .disabled(model.isBatchRendering)
                        .help("Auf starken Macs bis zu zwei Batch-Jobs parallel rendern")
                    Button("Leeren") { model.clearBatch() }
                        .frame(width: 126)
                        .disabled(model.batchJobs.isEmpty || model.isBatchRendering)
                }
            }
        }
        .sheet(isPresented: $model.isBatchInspectorPresented) {
            BatchInspectorSheet()
                .environmentObject(model)
        }
    }

    private func batchCard(_ job: BatchJob) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(job.requestedName)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .help(job.requestedName)
                Spacer()
                if !model.isBatchRendering {
                    Button { model.moveBatchJob(job, offset: -1) } label: {
                        Image(systemName: "chevron.left.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .help("Nach links schieben")
                    Button { model.moveBatchJob(job, offset: 1) } label: {
                        Image(systemName: "chevron.right.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .help("Nach rechts schieben")
                    Button { model.removeBatchJob(job) } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .red)
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(job.snapshot.renderMode.rawValue + " - " + job.snapshot.renderMode.summary)
                .font(.system(size: 9))
                .foregroundStyle(.cyan.opacity(0.85))
            if !model.isBatchRendering {
                Picker("Render", selection: Binding(
                    get: { job.snapshot.renderMode },
                    set: { model.updateBatchRenderMode(job, to: $0) }
                )) {
                    ForEach(RenderMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(width: 92)
            }
            ProgressView(value: job.progress)
                .frame(width: 150)
            Text(job.status.label)
                .font(.system(size: 9))
                .lineLimit(1)
                .foregroundStyle(statusColor(job.status))
        }
        .padding(8)
        .frame(width: 190, height: 100, alignment: .leading)
        .background(Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(model.selectedBatchJobID == job.id ? .cyan : .white.opacity(0.08), lineWidth: model.selectedBatchJobID == job.id ? 2 : 1))
        .contentShape(Rectangle())
        .onTapGesture {
            model.selectBatchJob(job)
        }
        .onTapGesture(count: 2) {
            model.showBatchInspector(for: job)
        }
    }

    private func statusColor(_ status: BatchJobStatus) -> Color {
        switch status {
        case .queued: .white.opacity(0.62)
        case .rendering: .cyan
        case .done: .green
        case .cancelled: .orange
        case .failed: .orange
        }
    }
}

struct BatchInspectorSheet: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Warteschlange Details")
                        .font(.title2.bold())
                    Text("\(model.batchJobs.count) Batch-Job(s)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                }
                Spacer()
                Button("Schließen") { model.isBatchInspectorPresented = false }
            }
            if let job = model.selectedBatchJob {
                HStack(spacing: 12) {
                    Button { model.moveBatchJob(job, offset: -1) } label: {
                        Label("Hoch", systemImage: "arrow.left")
                    }
                    .disabled(model.isBatchRendering)
                    Button { model.moveBatchJob(job, offset: 1) } label: {
                        Label("Runter", systemImage: "arrow.right")
                    }
                    .disabled(model.isBatchRendering)
                    Picker("Render", selection: Binding(
                        get: { job.snapshot.renderMode },
                        set: { model.updateSelectedBatchRenderMode(to: $0) }
                    )) {
                        ForEach(RenderMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .frame(width: 190)
                    .disabled(model.isBatchRendering)
                    Button("MAX für diesen Job") { model.updateSelectedBatchRenderMode(to: .max) }
                        .disabled(model.isBatchRendering)
                    Button("MAX für alle") { model.applyRenderModeToAllBatchJobs(.max) }
                        .disabled(model.isBatchRendering)
                }
                detailsGrid(job)
            } else {
                Text("Keine Aufgabe ausgewählt")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .padding(18)
        .frame(width: 760, height: 520)
        .background(Color(red: 0.025, green: 0.035, blue: 0.042))
        .foregroundStyle(.white)
    }

    private func detailsGrid(_ job: BatchJob) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                detailRow("Dateiname", Exporter.outputFileStem(requestedName: job.requestedName, snapshot: job.snapshot))
                detailRow("Status", job.status.label)
                detailRow("Render", "\(job.snapshot.renderMode.rawValue) - \(job.snapshot.renderMode.summary)")
                detailRow("Format", "\(Int(job.snapshot.size.width)) x \(Int(job.snapshot.size.height)) / \(job.snapshot.canvasFitMode.rawValue)")
                detailRow("Visualizer", job.snapshot.visualizerKind.rawValue)
                detailRow("Wave", "\(job.snapshot.wavePosition.rawValue), \(job.snapshot.stereoMode.rawValue), \(job.snapshot.waveDirection.rawValue)")
                detailRow("Audio", job.audioURL.path)
                detailRow("Bild/Cover", job.imageURL.path)
                detailRow("Zielordner", job.outputDirectory.path)
                detailRow("Lyrics", job.snapshot.lyricsEnabled ? "\(job.snapshot.lyricsCues.count) Zeilen" : "Aus")
                detailRow("Scene", job.snapshot.sceneOverlay.template.rawValue)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.045))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.cyan)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.caption)
                .textSelection(.enabled)
                .lineLimit(3)
            Spacer()
        }
    }
}

enum DropLoader {
    static func load(_ providers: [NSItemProvider], completion: @escaping ([URL]) -> Void) {
        var urls: [URL] = []
        let group = DispatchGroup()
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                if let url = item as? URL { urls.append(url) }
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) { urls.append(url) }
            }
        }
        group.notify(queue: .main) { completion(urls) }
    }
}

enum LyricsEngine {
    static func parse(_ rawText: String) -> [LyricsCue] {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let srt = parseSRT(trimmed)
        if !srt.isEmpty { return srt }
        let lrc = parseLRC(trimmed)
        if !lrc.isEmpty { return lrc }
        return trimmed
            .components(separatedBy: .newlines)
            .compactMap(cleanPlainLine)
            .map { LyricsCue(start: nil, end: nil, text: $0) }
    }

    static func text(at time: Double, duration: Double, cues: [LyricsCue]) -> String? {
        guard !cues.isEmpty else { return nil }
        if cues.contains(where: { $0.isTimed }) {
            if let cue = cues.first(where: { cue in
                guard let start = cue.start else { return false }
                let end = cue.end ?? (start + 4.0)
                return time >= start && time < end
            }) {
                return cue.text
            }
            return nil
        }
        let lineDuration = max(1.75, duration / Double(max(1, cues.count)))
        let index = min(cues.count - 1, max(0, Int(time / lineDuration)))
        return cues[index].text
    }

    static func embeddedLyrics(url: URL) async -> String? {
        let asset = AVURLAsset(url: url)
        var items: [AVMetadataItem] = []
        if let common = try? await asset.load(.commonMetadata) {
            items.append(contentsOf: common)
        }
        if let formats = try? await asset.load(.availableMetadataFormats) {
            for format in formats {
                if let metadata = try? await asset.loadMetadata(for: format) {
                    items.append(contentsOf: metadata)
                }
            }
        }
        for item in items {
            let identifier = item.identifier?.rawValue.lowercased() ?? ""
            let commonKey = item.commonKey?.rawValue.lowercased() ?? ""
            let key = item.key.map { String(describing: $0).lowercased() } ?? ""
            let keySpace = item.keySpace?.rawValue.lowercased() ?? ""
            let looksLikeLyrics = identifier.contains("lyric")
                || commonKey.contains("lyric")
                || key.contains("lyric")
                || key.contains("©lyr")
                || keySpace.contains("lyrics")
            guard looksLikeLyrics else { continue }
            if let value = try? await item.load(.stringValue) {
                let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    return trimmed
                }
            }
        }
        return nil
    }

    private static func parseLRC(_ text: String) -> [LyricsCue] {
        let pattern = #"\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        var timed: [(Double, String)] = []
        for line in text.components(separatedBy: .newlines) {
            let nsLine = line as NSString
            let range = NSRange(location: 0, length: nsLine.length)
            let matches = regex.matches(in: line, range: range)
            guard !matches.isEmpty else { continue }
            let lyricStart = matches.last.map { $0.range.location + $0.range.length } ?? 0
            let lyric = nsLine.substring(from: min(lyricStart, nsLine.length)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard let clean = cleanPlainLine(lyric) else { continue }
            for match in matches {
                let minutes = Double(nsLine.substring(with: match.range(at: 1))) ?? 0
                let seconds = Double(nsLine.substring(with: match.range(at: 2))) ?? 0
                let fraction: Double
                if match.range(at: 3).location != NSNotFound {
                    let raw = nsLine.substring(with: match.range(at: 3))
                    fraction = (Double(raw) ?? 0) / pow(10, Double(raw.count))
                } else {
                    fraction = 0
                }
                timed.append((minutes * 60 + seconds + fraction, clean))
            }
        }
        return finalizeTimed(timed)
    }

    private static func parseSRT(_ text: String) -> [LyricsCue] {
        let blocks = text.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n\n")
        var cues: [LyricsCue] = []
        for block in blocks {
            let lines = block.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            guard let timeIndex = lines.firstIndex(where: { $0.contains("-->") }) else { continue }
            let parts = lines[timeIndex].components(separatedBy: "-->")
            guard parts.count == 2, let start = parseTimecode(parts[0]), let end = parseTimecode(parts[1]) else { continue }
            let lyricLines = lines.dropFirst(timeIndex + 1).compactMap(cleanPlainLine)
            guard !lyricLines.isEmpty else { continue }
            cues.append(LyricsCue(start: start, end: max(start + 0.2, end), text: lyricLines.joined(separator: "\n")))
        }
        return cues.sorted { ($0.start ?? 0) < ($1.start ?? 0) }
    }

    private static func finalizeTimed(_ timed: [(Double, String)]) -> [LyricsCue] {
        let sorted = timed.sorted { $0.0 < $1.0 }
        guard !sorted.isEmpty else { return [] }
        return sorted.enumerated().map { index, item in
            let next = index + 1 < sorted.count ? sorted[index + 1].0 : item.0 + 4.0
            return LyricsCue(start: item.0, end: max(item.0 + 0.35, next), text: item.1)
        }
    }

    private static func parseTimecode(_ value: String) -> Double? {
        let clean = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        let parts = clean.components(separatedBy: ":")
        guard parts.count >= 2 else { return nil }
        let seconds = Double(parts.last ?? "") ?? 0
        let minutes = Double(parts.dropLast().last ?? "") ?? 0
        let hours = parts.count > 2 ? (Double(parts.dropLast(2).last ?? "") ?? 0) : 0
        return hours * 3600 + minutes * 60 + seconds
    }

    private static func cleanPlainLine(_ line: String) -> String? {
        var clean = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return nil }
        if clean.hasPrefix("[") && clean.hasSuffix("]") { return nil }
        if clean.hasPrefix("(") && clean.hasSuffix(")") { return nil }
        clean = clean.replacingOccurrences(of: #"^\d+[\.)]\s*"#, with: "", options: .regularExpression)
        clean = clean.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return clean.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : clean
    }
}

struct AudioAnalysis: Sendable {
    let waveform: [CGFloat]
    let spectrumFrames: [[CGFloat]]
}

enum AudioTools {
    static func placeholderWaveform(count: Int = 360) -> [CGFloat] {
        (0..<count).map { index in
            CGFloat(max(0.08, min(1, abs(sin(Double(index) * 0.13)) * 0.65 + Double.random(in: 0.04...0.25))))
        }
    }

    static func placeholderSpectrumFrames(frameCount: Int = 180, bins: Int = 96) -> [[CGFloat]] {
        (0..<frameCount).map { frame in
            (0..<bins).map { bin in
                let bass = abs(sin(Double(frame) * 0.08 + Double(bin) * 0.11)) * 0.42
                let pulse = abs(sin(Double(frame) * 0.21 + Double(bin) * 0.025)) * 0.32
                return CGFloat(max(0.04, min(1, bass + pulse + Double.random(in: 0.0...0.08))))
            }
        }
    }

    static func containsAudio(url: URL) async -> Bool {
        let asset = AVURLAsset(url: url)
        return ((try? await asset.loadTracks(withMediaType: .audio)) ?? []).isEmpty == false
    }

    static func duration(url: URL) async -> Double {
        let asset = AVURLAsset(url: url)
        let duration = (try? await asset.load(.duration)) ?? CMTime(seconds: 1, preferredTimescale: 600)
        return max(1, CMTimeGetSeconds(duration))
    }

    static func analysis(url: URL, waveformCount: Int = 420, frameCount: Int = 320, bins: Int = 96) async -> AudioAnalysis {
        await Task.detached(priority: .userInitiated) {
            let samples = (try? await audioSamplesViaAssetReader(url: url)) ?? audioSamplesViaAVAudioFile(url: url)
            guard samples.count > 512 else {
                return AudioAnalysis(waveform: placeholderWaveform(count: waveformCount), spectrumFrames: placeholderSpectrumFrames(frameCount: frameCount, bins: bins))
            }
            return AudioAnalysis(
                waveform: waveform(from: samples, count: waveformCount),
                spectrumFrames: fftSpectrumFrames(from: samples, frameCount: frameCount, bins: bins)
            )
        }.value
    }

    static func waveform(url: URL, count: Int = 360) async -> [CGFloat] {
        await analysis(url: url, waveformCount: count, frameCount: 120, bins: 64).waveform
    }

    private static func audioSamplesViaAssetReader(url: URL) async throws -> [Float] {
        let asset = AVURLAsset(url: url)
        let loadedTracks = try await asset.loadTracks(withMediaType: .audio)
        guard let track = loadedTracks.first else { return [] }
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ])
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else { return [] }
        reader.add(output)
        guard reader.startReading() else { return [] }
        var samples: [Float] = []
        samples.reserveCapacity(600_000)
        while let sampleBuffer = output.copyNextSampleBuffer() {
            samples.append(contentsOf: monoSamples(from: sampleBuffer))
        }
        return samples
    }

    private static func monoSamples(from sampleBuffer: CMSampleBuffer) -> [Float] {
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return [] }
        let byteLength = CMBlockBufferGetDataLength(blockBuffer)
        guard byteLength > 1 else { return [] }
        var data = [UInt8](repeating: 0, count: byteLength)
        let status = data.withUnsafeMutableBytes {
            CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: byteLength, destination: $0.baseAddress!)
        }
        guard status == kCMBlockBufferNoErr else { return [] }
        let channels: Int
        if let format = CMSampleBufferGetFormatDescription(sampleBuffer),
           let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(format) {
            channels = max(1, Int(streamDescription.pointee.mChannelsPerFrame))
        } else {
            channels = 1
        }
        return data.withUnsafeBytes { rawBuffer in
            let values = rawBuffer.bindMemory(to: Int16.self)
            var mono: [Float] = []
            mono.reserveCapacity(values.count / channels)
            var index = 0
            while index < values.count {
                var sum: Float = 0
                var used: Float = 0
                for channel in 0..<channels where index + channel < values.count {
                    sum += Float(values[index + channel]) / 32768.0
                    used += 1
                }
                mono.append(sum / max(1, used))
                index += channels
            }
            return mono
        }
    }

    private static func audioSamplesViaAVAudioFile(url: URL) -> [Float] {
        do {
            let file = try AVAudioFile(forReading: url)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else { return [] }
            try file.read(into: buffer)
            guard let channels = buffer.floatChannelData else { return [] }
            let frames = Int(buffer.frameLength)
            let channelCount = Int(file.processingFormat.channelCount)
            return (0..<frames).map { frame in
                var sum: Float = 0
                for channel in 0..<channelCount {
                    sum += channels[channel][frame]
                }
                return sum / Float(max(1, channelCount))
            }
        } catch {
            return []
        }
    }

    private static func waveform(from samples: [Float], count: Int) -> [CGFloat] {
        let stride = max(1, samples.count / count)
        var values: [CGFloat] = []
        values.reserveCapacity(count)
        for index in Swift.stride(from: 0, to: samples.count, by: stride) {
            let end = min(samples.count, index + stride)
            var sum: Float = 0
            for sample in samples[index..<end] {
                sum += sample * sample
            }
            values.append(CGFloat(sqrt(sum / Float(max(1, end - index)))))
        }
        let maxValue = max(values.max() ?? 0.01, 0.01)
        return values.prefix(count).map { min(1, max(0.02, $0 / maxValue)) }
    }

    private static func fftSpectrumFrames(from samples: [Float], frameCount: Int, bins: Int) -> [[CGFloat]] {
        let fftSize = 1024
        guard let setup = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(fftSize), vDSP_DFT_Direction.FORWARD) else {
            return placeholderSpectrumFrames(frameCount: frameCount, bins: bins)
        }
        defer { vDSP_DFT_DestroySetup(setup) }
        let hop = max(1, max(0, samples.count - fftSize) / max(1, frameCount - 1))
        let window = (0..<fftSize).map { index in
            Float(0.5 - 0.5 * cos(2 * Double.pi * Double(index) / Double(fftSize - 1)))
        }
        var frames: [[CGFloat]] = []
        frames.reserveCapacity(frameCount)
        var previous = [CGFloat](repeating: 0, count: bins)
        for frame in 0..<frameCount {
            let start = min(max(0, samples.count - fftSize), frame * hop)
            var real = [Float](repeating: 0, count: fftSize)
            var imag = [Float](repeating: 0, count: fftSize)
            var outReal = [Float](repeating: 0, count: fftSize)
            var outImag = [Float](repeating: 0, count: fftSize)
            for index in 0..<fftSize where start + index < samples.count {
                real[index] = samples[start + index] * window[index]
            }
            vDSP_DFT_Execute(setup, &real, &imag, &outReal, &outImag)
            let half = fftSize / 2
            var magnitudes = [Float](repeating: 0, count: half)
            for index in 0..<half {
                magnitudes[index] = sqrt(outReal[index] * outReal[index] + outImag[index] * outImag[index])
            }
            var frameBins = [CGFloat](repeating: 0, count: bins)
            for bin in 0..<bins {
                let lower = pow(Double(bin) / Double(max(1, bins)), 1.65)
                let upper = pow(Double(bin + 1) / Double(max(1, bins)), 1.65)
                let startIndex = min(half - 1, max(0, Int(lower * Double(half - 1))))
                let endIndex = min(half - 1, max(startIndex + 1, Int(upper * Double(half - 1))))
                var sum: Float = 0
                for index in startIndex..<endIndex {
                    sum += magnitudes[index]
                }
                let average = sum / Float(max(1, endIndex - startIndex))
                let compressed = CGFloat(min(1, log10(1 + average * 18) / 2.2))
                frameBins[bin] = previous[bin] * 0.62 + compressed * 0.38
            }
            previous = frameBins
            frames.append(frameBins)
        }
        return frames
    }
}

struct ExportSnapshot: Sendable {
    let size: CGSize
    let canvasFitMode: CanvasFitMode
    let visualizerKind: VisualizerKind
    let wavePosition: WavePosition
    let stereoMode: StereoMode
    let waveDirection: WaveDirection
    let mirrorMode: MirrorMode
    let colorMode: NALAColorMode
    let colors: [CodableColor]
    let opacity: Double
    let barCount: Int
    let waveHeight: Double
    let lineWidth: Double
    let glowStrength: Double
    let smoothing: Double
    let imageZoom: Double
    let imageRotation: Double
    let imageOffsetX: Double
    let imageOffsetY: Double
    let kenBurnsMode: KenBurnsMode
    let kenBurnsStrength: Double
    let kenBurnsSpeed: Double
    var renderMode: RenderMode
    let effects: RenderEffects
    let sceneOverlay: SceneOverlaySettings
    let lyricsEnabled: Bool
    let lyricsPosition: LyricsPosition
    let lyricsSize: Double
    let lyricsOpacity: Double
    let lyricsCues: [LyricsCue]
    let samples: [CGFloat]
    let spectrumFrames: [[CGFloat]]
}

struct CodableColor: Sendable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat

    init(_ color: NSColor) {
        let rgb = color.usingColorSpace(.sRGB) ?? color
        red = rgb.redComponent
        green = rgb.greenComponent
        blue = rgb.blueComponent
        alpha = rgb.alphaComponent
    }

    var nsColor: NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

enum Exporter {
    static func export(snapshot: ExportSnapshot, audioURL: URL, imageURL: URL, outputDirectory: URL, requestedName: String, maxDuration: Double? = nil, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        let outputDir = outputDirectory
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        let outputStem = outputFileStem(requestedName: requestedName, snapshot: snapshot)
        let output = uniqueOutputURL(in: outputDir, stem: outputStem, extension: "mp4")
        let videoOnlyOutput = outputDir.appendingPathComponent(".\(outputStem)-\(UUID().uuidString)-video.mp4")
        try? FileManager.default.removeItem(at: output)
        try? FileManager.default.removeItem(at: videoOnlyOutput)

        let asset = AVURLAsset(url: audioURL)
        let assetDuration = max(1, CMTimeGetSeconds((try? await asset.load(.duration)) ?? CMTime(seconds: 8, preferredTimescale: 600)))
        let duration = max(1, min(maxDuration ?? assetDuration, assetDuration))
        let size = snapshot.size
        let fps = snapshot.renderMode.fps
        let writer = try AVAssetWriter(outputURL: videoOnlyOutput, fileType: .mp4)
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: snapshot.renderMode.bitrate,
                AVVideoExpectedSourceFrameRateKey: fps,
                AVVideoMaxKeyFrameIntervalKey: fps * 2,
                AVVideoAllowFrameReorderingKey: false,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ])
        videoInput.expectsMediaDataInRealTime = false
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(size.width),
            kCVPixelBufferHeightKey as String: Int(size.height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ])
        guard writer.canAdd(videoInput) else {
            throw NSError(domain: "NALA", code: 29, userInfo: [NSLocalizedDescriptionKey: "VideoInput konnte nicht hinzugefügt werden"])
        }
        writer.add(videoInput)
        guard writer.startWriting() else {
            throw writer.error ?? NSError(domain: "NALA", code: 30, userInfo: [NSLocalizedDescriptionKey: "AVAssetWriter konnte nicht starten"])
        }
        writer.startSession(atSourceTime: .zero)
        func checkCancelled() throws {
            if Task.isCancelled {
                writer.cancelWriting()
                try? FileManager.default.removeItem(at: videoOnlyOutput)
                throw CancellationError()
            }
        }

        guard let image = NSImage(contentsOf: imageURL)?.cgImageValue else { throw NSError(domain: "NALA", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bild konnte nicht geladen werden"]) }
        let samples = snapshot.samples
        let frameCount = Int(duration * Double(fps))
        for frame in 0..<frameCount {
            try checkCancelled()
            var waitTicks = 0
            while !videoInput.isReadyForMoreMediaData {
                try checkCancelled()
                if writer.status == .failed || writer.status == .cancelled {
                    throw writer.error ?? NSError(domain: "NALA", code: 31, userInfo: [NSLocalizedDescriptionKey: "VideoWriter ist nicht mehr aktiv"])
                }
                waitTicks += 1
                if waitTicks > 2500 {
                    throw NSError(domain: "NALA", code: 32, userInfo: [NSLocalizedDescriptionKey: "VideoWriter wurde nicht bereit für neue Frames"])
                }
                try await Task.sleep(nanoseconds: 2_000_000)
            }
            guard let pool = adaptor.pixelBufferPool else { continue }
            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
            guard let pixelBuffer else { continue }
            render(buffer: pixelBuffer, image: image, snapshot: snapshot, samples: samples, size: size, time: Double(frame) / Double(fps), duration: duration)
            guard adaptor.append(pixelBuffer, withPresentationTime: CMTime(value: CMTimeValue(frame), timescale: CMTimeScale(fps))) else {
                throw writer.error ?? NSError(domain: "NALA", code: 33, userInfo: [NSLocalizedDescriptionKey: "VideoFrame konnte nicht geschrieben werden"])
            }
            if frame % fps == 0 { progress(Double(frame) / Double(frameCount)) }
        }
        videoInput.markAsFinished()
        try await withCheckedThrowingContinuation { continuation in
            writer.finishWriting {
                writer.status == .completed ? continuation.resume(returning: ()) : continuation.resume(throwing: writer.error ?? NSError(domain: "NALA", code: 2))
            }
        }
        progress(0.94)
        let muxed = try await muxAudio(videoURL: videoOnlyOutput, audioURL: audioURL, outputURL: output, artworkURL: imageURL)
        try? FileManager.default.removeItem(at: videoOnlyOutput)
        progress(1.0)
        return muxed
    }

    static func defaultOutputName(for imageURL: URL) -> String {
        safeFileStem(imageURL.deletingPathExtension().lastPathComponent)
    }

    static func outputFileStem(requestedName: String, snapshot: ExportSnapshot) -> String {
        let base = safeFileStem(requestedName)
        let suffix = formatSuffix(size: snapshot.size)
        return base.hasSuffix("-\(suffix)") ? base : "\(base)-\(suffix)"
    }

    static func formatSuffix(size: CGSize) -> String {
        let width = max(size.width, size.height)
        let ratio = size.width / max(1, size.height)
        let format: String
        if abs(ratio - 1.0) < 0.04 {
            format = "1-1"
        } else if abs(ratio - (9.0 / 16.0)) < 0.06 {
            format = "9-16"
        } else if abs(ratio - (16.0 / 9.0)) < 0.08 {
            format = "16-9"
        } else if ratio > 2.2 {
            format = "ultra-wide"
        } else if ratio > 1.9 {
            format = "super-wide"
        } else {
            format = "\(Int(size.width))x\(Int(size.height))"
        }
        return width >= 2160 ? "\(format)-4k" : format
    }

    static func safeFileStem(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = trimmed.isEmpty ? "NALA-Visualizer" : trimmed
        let illegal = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = fallback.components(separatedBy: illegal).joined(separator: "-")
        return cleaned.replacingOccurrences(of: #"[\s-]+"#, with: "-", options: .regularExpression)
    }

    static func canCreateArtworkMetadata(from url: URL) -> Bool {
        artworkMetadata(from: url) != nil
    }

    private static func uniqueOutputURL(in directory: URL, stem: String, extension ext: String) -> URL {
        var candidate = directory.appendingPathComponent("\(stem).\(ext)")
        var counter = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(stem)-\(counter).\(ext)")
            counter += 1
        }
        return candidate
    }

    private static func muxAudio(videoURL: URL, audioURL: URL, outputURL: URL, artworkURL: URL?) async throws -> URL {
        let composition = AVMutableComposition()
        let videoAsset = AVURLAsset(url: videoURL)
        let audioAsset = AVURLAsset(url: audioURL)
        guard let sourceVideoTrack = try await videoAsset.loadTracks(withMediaType: .video).first,
              let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw NSError(domain: "NALA", code: 40, userInfo: [NSLocalizedDescriptionKey: "Gerendertes Video konnte nicht gemuxt werden"])
        }
        let videoDuration = try await videoAsset.load(.duration)
        try compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration), of: sourceVideoTrack, at: .zero)
        if let transform = try? await sourceVideoTrack.load(.preferredTransform) {
            compositionVideoTrack.preferredTransform = transform
        }
        if let sourceAudioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            let audioDuration = try await audioAsset.load(.duration)
            let duration = CMTimeCompare(audioDuration, videoDuration) < 0 ? audioDuration : videoDuration
            try compositionAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: sourceAudioTrack, at: .zero)
        }
        try? FileManager.default.removeItem(at: outputURL)
        let compatiblePresets = AVAssetExportSession.exportPresets(compatibleWith: composition)
        let preset = compatiblePresets.contains(AVAssetExportPresetPassthrough) ? AVAssetExportPresetPassthrough : AVAssetExportPresetHighestQuality
        guard let export = AVAssetExportSession(asset: composition, presetName: preset) else {
            throw NSError(domain: "NALA", code: 41, userInfo: [NSLocalizedDescriptionKey: "AVAssetExportSession konnte nicht erstellt werden"])
        }
        export.outputURL = outputURL
        export.outputFileType = .mp4
        export.shouldOptimizeForNetworkUse = true
        if let artworkURL, let artwork = artworkMetadata(from: artworkURL) {
            export.metadata = [artwork]
        }
        try await withCheckedThrowingContinuation { continuation in
            export.exportAsynchronously {
                switch export.status {
                case .completed:
                    continuation.resume(returning: ())
                case .failed, .cancelled:
                    continuation.resume(throwing: export.error ?? NSError(domain: "NALA", code: 42, userInfo: [NSLocalizedDescriptionKey: "Audio-Muxing fehlgeschlagen"]))
                default:
                    continuation.resume(throwing: NSError(domain: "NALA", code: 43, userInfo: [NSLocalizedDescriptionKey: "Audio-Muxing endete unerwartet"]))
                }
            }
        }
        return outputURL
    }

    private static func artworkMetadata(from url: URL) -> AVMetadataItem? {
        guard let image = NSImage(contentsOf: url), let data = image.pngData else { return nil }
        let item = AVMutableMetadataItem()
        item.identifier = .commonIdentifierArtwork
        item.value = data as NSData
        item.dataType = kCMMetadataBaseDataType_PNG as String
        item.locale = Locale.current
        return item
    }

    private static func appendAudio(asset: AVURLAsset, input: AVAssetWriterInput, duration: Double) async throws {
        guard let track = try await asset.loadTracks(withMediaType: .audio).first else { return }
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false
        ])
        reader.add(output)
        reader.startReading()
        while let sample = output.copyNextSampleBuffer() {
            while !input.isReadyForMoreMediaData { try await Task.sleep(nanoseconds: 2_000_000) }
            if CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sample)) > duration { break }
            input.append(sample)
        }
    }

    private static func render(buffer: CVPixelBuffer, image: CGImage, snapshot: ExportSnapshot, samples: [CGFloat], size: CGSize, time: Double, duration: Double) {
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer),
              let context = CGContext(data: base, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue) else { return }
        context.setFillColor(NSColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        let progress = CGFloat(duration > 0 ? time / duration : 0)
        let displaySamples = SampleFrames.export(snapshot: snapshot, fallback: samples, time: time, duration: duration)
        let energy = SampleFrames.energy(displaySamples)
        let beat = CGFloat(pow(Double(energy), 1.45))
        let colors = (snapshot.colors.isEmpty ? [CodableColor(.cyan), CodableColor(.systemPink), CodableColor(.systemBlue)] : snapshot.colors).map { $0.nsColor.withAlphaComponent(snapshot.opacity) }
        let kenBurnsScale: CGFloat
        switch snapshot.kenBurnsMode {
        case .zoomOut:
            kenBurnsScale = 1 + CGFloat(snapshot.kenBurnsStrength) * 0.20 * (1 - progress)
        case .zoomIn:
            kenBurnsScale = 1 + CGFloat(snapshot.kenBurnsStrength) * 0.20 * progress
        default:
            kenBurnsScale = 1 + CGFloat(snapshot.kenBurnsStrength) * 0.08
        }
        if snapshot.canvasFitMode == .blurExtend {
            let backgroundScale = max(size.width / CGFloat(image.width), size.height / CGFloat(image.height))
            let backgroundSize = CGSize(width: CGFloat(image.width) * backgroundScale, height: CGFloat(image.height) * backgroundScale)
            let backgroundRect = CGRect(x: (size.width - backgroundSize.width) / 2, y: (size.height - backgroundSize.height) / 2, width: backgroundSize.width, height: backgroundSize.height)
            context.saveGState()
            context.setAlpha(0.55)
            drawImage(context: context, image: image, rect: backgroundRect, rotation: 0)
            context.restoreGState()
            context.setFillColor(NSColor.black.withAlphaComponent(0.22).cgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }
        let baseScale: CGFloat
        switch snapshot.canvasFitMode {
        case .fit, .blurExtend:
            baseScale = min(size.width / CGFloat(image.width), size.height / CGFloat(image.height))
        case .fill:
            baseScale = max(size.width / CGFloat(image.width), size.height / CGFloat(image.height))
        case .stretch:
            baseScale = 1
        }
        let imageSize: CGSize
        let reactiveZoom = 1 + CGFloat(snapshot.effects.zoomPunch) * beat * 0.08
        if snapshot.canvasFitMode == .stretch {
            imageSize = CGSize(width: size.width * CGFloat(snapshot.imageZoom) * kenBurnsScale * reactiveZoom, height: size.height * CGFloat(snapshot.imageZoom) * kenBurnsScale * reactiveZoom)
        } else {
            let scale = baseScale * CGFloat(snapshot.imageZoom) * kenBurnsScale * reactiveZoom
            imageSize = CGSize(width: CGFloat(image.width) * scale, height: CGFloat(image.height) * scale)
        }
        var x = (size.width - imageSize.width) / 2 + CGFloat(snapshot.imageOffsetX) * size.width * 0.25
        var y = (size.height - imageSize.height) / 2 - CGFloat(snapshot.imageOffsetY) * size.height * 0.25
        let pan = CGFloat(snapshot.kenBurnsStrength) * min(size.width, size.height) * 0.08
        switch snapshot.kenBurnsMode {
        case .panLeft: x += pan * (1 - progress * 2)
        case .panRight: x += pan * (progress * 2 - 1)
        case .panUp: y += pan * (1 - progress * 2)
        case .panDown: y += pan * (progress * 2 - 1)
        case .smoothDrift:
            x += sin(progress * .pi * 2) * pan
            y += cos(progress * .pi * 2) * pan * 0.5
        default: break
        }
        let shake = CGFloat(snapshot.effects.bassShake) * beat * min(size.width, size.height) * 0.018
        x += sin(CGFloat(time) * 71) * shake
        y += cos(CGFloat(time) * 55) * shake * 0.7
        let imageRect = CGRect(x: x, y: y, width: imageSize.width, height: imageSize.height)
        let imageRotation = CGFloat(snapshot.imageRotation * .pi / 180)
        if snapshot.effects.rgbSplit > 0.01 {
            let amount = CGFloat(snapshot.effects.rgbSplit) * beat * min(size.width, size.height) * 0.014
            context.saveGState()
            context.setAlpha(min(0.34, CGFloat(snapshot.effects.rgbSplit) * 0.42))
            drawImage(context: context, image: image, rect: imageRect.offsetBy(dx: amount, dy: 0), rotation: imageRotation)
            drawImage(context: context, image: image, rect: imageRect.offsetBy(dx: -amount, dy: 0), rotation: imageRotation)
            context.restoreGState()
        }
        drawImage(context: context, image: image, rect: imageRect, rotation: imageRotation)
        if snapshot.effects.glitch > 0.01 {
            drawGlitchStrips(context: context, image: image, rect: imageRect, rotation: imageRotation, size: size, time: time, strength: snapshot.effects.glitch, energy: beat)
        }
        if snapshot.effects.lensGlow > 0.01 {
            drawExportLensGlow(context: context, size: size, colors: colors, energy: energy, strength: snapshot.effects.lensGlow)
        }
        if snapshot.effects.beatFlash > 0.01 {
            context.setFillColor(NSColor.white.withAlphaComponent(min(0.18, CGFloat(snapshot.effects.beatFlash) * beat * 0.20)).cgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }
        let band = size.height * CGFloat(snapshot.waveHeight)
        let baseY = exportBaseY(size: size, band: band, position: snapshot.wavePosition)
        context.setShadow(offset: .zero, blur: CGFloat(4 + snapshot.glowStrength * 18), color: (colors.first ?? .cyan).cgColor)
        if snapshot.visualizerKind == .blockBars || snapshot.visualizerKind == .barsSpectrum || snapshot.visualizerKind == .stereoLeftRight {
            let count = max(8, min(160, snapshot.barCount))
            let sampleStep = max(1, displaySamples.count / count)
            let slot = size.width / CGFloat(count)
            for bar in 0..<count {
                let value = displaySamples[min(displaySamples.count - 1, bar * sampleStep)] * band
                let x = CGFloat(bar) * slot + slot * 0.14
                context.setFillColor(colors[bar % colors.count].cgColor)
                context.fill(CGRect(x: x, y: baseY - value, width: slot * 0.72, height: value))
                if snapshot.stereoMode != .combined || snapshot.visualizerKind == .blockBars {
                    context.setFillColor(colors[(bar + 1) % colors.count].cgColor)
                    context.fill(CGRect(x: x, y: baseY, width: slot * 0.72, height: value * 0.72))
                }
            }
        } else if snapshot.visualizerKind == .circleSpectrum {
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) * 0.18
            context.setLineWidth(max(0.5, CGFloat(snapshot.lineWidth)))
            for (index, sample) in displaySamples.enumerated().prefix(180) {
                let angle = CGFloat(index) / 180 * .pi * 2
                let length = radius + sample * band * 0.55
                context.setStrokeColor(colors[index % colors.count].cgColor)
                context.move(to: CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius))
                context.addLine(to: CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length))
                context.strokePath()
            }
        } else if snapshot.visualizerKind == .neonFFT || snapshot.visualizerKind == .frequencyMesh {
            drawExportFrequencyMesh(context: context, size: size, samples: displaySamples, colors: colors, baseY: baseY, band: band, snapshot: snapshot, time: time)
        } else {
            context.setLineWidth(max(0.5, CGFloat(snapshot.lineWidth)))
            context.setLineCap(.round)
            let step = size.width / CGFloat(max(1, displaySamples.count - 1))
            for (index, sample) in displaySamples.enumerated() {
                let x = CGFloat(index) * step
                let h = sample * band
                context.setStrokeColor(colors[index % colors.count].cgColor)
                if snapshot.wavePosition == .left || snapshot.wavePosition == .right {
                    let y = CGFloat(index) / CGFloat(max(1, displaySamples.count - 1)) * size.height
                    let xBase = snapshot.wavePosition == .left ? size.width * 0.08 : size.width * 0.92
                    context.move(to: CGPoint(x: xBase, y: y))
                    context.addLine(to: CGPoint(x: xBase + (snapshot.wavePosition == .left ? h : -h), y: y))
                } else if snapshot.stereoMode == .combined {
                    context.move(to: CGPoint(x: x, y: baseY - h * 0.5))
                    context.addLine(to: CGPoint(x: x, y: baseY + h * 0.5))
                } else {
                    context.move(to: CGPoint(x: x, y: baseY - h))
                    context.addLine(to: CGPoint(x: x, y: baseY + h * 0.72))
                }
                context.strokePath()
            }
        }
        drawExportParticles(context: context, size: size, samples: displaySamples, colors: colors, amount: max(snapshot.effects.particles, snapshot.glowStrength * 0.55), time: time)
        drawSceneOverlay(context: context, size: size, snapshot: snapshot, time: time, energy: energy)
        drawLyrics(context: context, size: size, snapshot: snapshot, time: time, duration: duration)
    }

    private static func drawImage(context: CGContext, image: CGImage, rect: CGRect, rotation: CGFloat) {
        context.saveGState()
        context.translateBy(x: rect.midX, y: rect.midY)
        context.rotate(by: rotation)
        context.draw(image, in: CGRect(x: -rect.width / 2, y: -rect.height / 2, width: rect.width, height: rect.height))
        context.restoreGState()
    }

    private static func drawExportFrequencyMesh(context: CGContext, size: CGSize, samples: [CGFloat], colors: [NSColor], baseY: CGFloat, band: CGFloat, snapshot: ExportSnapshot, time: Double) {
        guard samples.count > 2 else { return }
        let layers = snapshot.visualizerKind == .frequencyMesh ? 7 : 4
        let step = size.width / CGFloat(max(1, samples.count - 1))
        context.setLineCap(.round)
        context.setLineJoin(.round)
        for layer in 0..<layers {
            let layerProgress = CGFloat(layer) / CGFloat(max(1, layers - 1))
            let lift = (layerProgress - 0.5) * band * 0.95
            context.beginPath()
            for index in samples.indices {
                let x = CGFloat(index) * step
                let sample = samples[index]
                let ripple = sin(CGFloat(time) * (5.5 + layerProgress) + CGFloat(index) * 0.13 + layerProgress * 4.2)
                let y = baseY + lift - sample * band * (0.42 + layerProgress * 0.42) + ripple * band * 0.045
                if index == 0 {
                    context.move(to: CGPoint(x: x, y: y))
                } else {
                    context.addLine(to: CGPoint(x: x, y: y))
                }
            }
            context.setLineWidth(max(0.55, CGFloat(snapshot.lineWidth) * (snapshot.visualizerKind == .frequencyMesh ? 0.62 : 1.15)))
            context.setStrokeColor(colors[layer % colors.count].cgColor)
            context.strokePath()
        }
    }

    private static func drawGlitchStrips(context: CGContext, image: CGImage, rect: CGRect, rotation: CGFloat, size: CGSize, time: Double, strength: Double, energy: CGFloat) {
        let bands = max(3, Int(5 + strength * 9))
        let stripHeight = size.height / CGFloat(bands) * 0.42
        for band in 0..<bands where (band + Int(time * 22)) % 3 == 0 {
            let y = CGFloat(band) / CGFloat(bands) * size.height
            let offset = sin(CGFloat(time) * 33 + CGFloat(band) * 1.7) * CGFloat(strength) * energy * size.width * 0.035
            context.saveGState()
            context.clip(to: CGRect(x: 0, y: y, width: size.width, height: stripHeight))
            context.setAlpha(min(0.36, CGFloat(strength) * 0.52))
            drawImage(context: context, image: image, rect: rect.offsetBy(dx: offset, dy: 0), rotation: rotation)
            context.restoreGState()
        }
    }

    private static func drawExportLensGlow(context: CGContext, size: CGSize, colors: [NSColor], energy: CGFloat, strength: Double) {
        let origin = CGPoint(x: size.width * 0.72, y: size.height * 0.18)
        let radius = min(size.width, size.height) * CGFloat(0.42 + strength * 0.24)
        let color = (colors.first ?? .cyan).withAlphaComponent(0.12 + min(0.24, CGFloat(strength) * energy * 0.28))
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: [color.cgColor, NSColor.clear.cgColor] as CFArray, locations: [0, 1]) else { return }
        context.saveGState()
        context.setBlendMode(.screen)
        context.drawRadialGradient(gradient, startCenter: origin, startRadius: 0, endCenter: origin, endRadius: radius, options: [.drawsAfterEndLocation])
        context.restoreGState()
    }

    private static func drawExportParticles(context: CGContext, size: CGSize, samples: [CGFloat], colors: [NSColor], amount: Double, time: Double) {
        guard amount > 0.05, !samples.isEmpty else { return }
        let count = min(140, samples.count)
        context.saveGState()
        context.setBlendMode(.screen)
        for index in 0..<count {
            let value = samples[(index * max(1, samples.count / count)) % samples.count]
            guard value > 0.22 else { continue }
            let t = (CGFloat(index) * 37 + CGFloat(time) * 29).truncatingRemainder(dividingBy: 997) / 997
            let x = CGFloat(index) / CGFloat(max(1, count - 1)) * size.width
            let y = size.height * (0.16 + 0.62 * t)
            let radius = max(1.0, value * CGFloat(amount) * 6.0)
            context.setFillColor(colors[index % colors.count].withAlphaComponent(0.18 + value * 0.32).cgColor)
            context.fillEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))
        }
        context.restoreGState()
    }

    private static func drawSceneOverlay(context: CGContext, size: CGSize, snapshot: ExportSnapshot, time: Double, energy: CGFloat) {
        let settings = snapshot.sceneOverlay
        guard settings.isEnabled else { return }
        let accent = (NSColor(hex: settings.accentHex) ?? .cyan).withAlphaComponent(settings.opacity)
        let magenta = (NSColor(hex: settings.magentaHex) ?? .systemPink).withAlphaComponent(settings.opacity)
        let white = NSColor.white.withAlphaComponent(0.92 * settings.opacity)
        let landscape = size.width >= size.height

        context.saveGState()
        context.setBlendMode(.normal)
        if settings.showBadges {
            let badgeWidth = max(62, min(112, size.width * (landscape ? 0.052 : 0.10)))
            let badgeHeight = badgeWidth * 0.82
            let x = size.width * (landscape ? 0.035 : 0.055)
            var y = size.height - size.height * (landscape ? 0.055 : 0.035) - badgeHeight
            for (index, text) in [settings.bpm, settings.genre, settings.tag].enumerated() {
                let rect = CGRect(x: x, y: y, width: badgeWidth, height: badgeHeight)
                drawSceneBadge(context: context, rect: rect, text: text, accent: index == 2 ? magenta : accent, opacity: settings.opacity)
                y -= badgeHeight + max(10, badgeHeight * 0.18)
            }
        }

        if settings.showTitle && settings.template != .djLowerThird {
            drawSceneTitle(context: context, size: size, settings: settings, accent: accent, white: white, landscape: landscape)
        }
        if settings.showStats {
            drawSceneStats(context: context, size: size, snapshot: snapshot, energy: energy, accent: accent, magenta: magenta, opacity: settings.opacity)
        }
        if settings.template == .djLowerThird {
            drawLowerThird(context: context, size: size, settings: settings, accent: accent, magenta: magenta, white: white, opacity: settings.opacity)
        }
        if settings.template == .fullscreenWave {
            drawSceneText(
                "[IN] AUDIO STREAM ACTIVE    MASTER_BUS_L/R",
                in: CGRect(x: size.width * 0.035, y: size.height * 0.045, width: size.width * 0.42, height: 22),
                font: NSFont.monospacedSystemFont(ofSize: max(11, min(size.width, size.height) * 0.012), weight: .semibold),
                color: white.withAlphaComponent(0.58),
                alignment: .left,
                context: context
            )
        }
        context.restoreGState()
    }

    private static func drawSceneBadge(context: CGContext, rect: CGRect, text: String, accent: NSColor, opacity: Double) {
        context.saveGState()
        context.setFillColor(NSColor.black.withAlphaComponent(0.42 * opacity).cgColor)
        context.fill(rect)
        context.setStrokeColor(accent.cgColor)
        context.setLineWidth(max(1, rect.width * 0.014))
        context.stroke(rect)
        let corner = min(rect.width, rect.height) * 0.18
        context.beginPath()
        let points: [(CGPoint, CGPoint)] = [
            (CGPoint(x: rect.minX, y: rect.minY + corner), CGPoint(x: rect.minX, y: rect.minY)),
            (CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.minX + corner, y: rect.minY)),
            (CGPoint(x: rect.maxX - corner, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY)),
            (CGPoint(x: rect.maxX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY + corner)),
            (CGPoint(x: rect.maxX, y: rect.maxY - corner), CGPoint(x: rect.maxX, y: rect.maxY)),
            (CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.maxX - corner, y: rect.maxY)),
            (CGPoint(x: rect.minX + corner, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY)),
            (CGPoint(x: rect.minX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY - corner))
        ]
        for segment in points {
            context.move(to: segment.0)
            context.addLine(to: segment.1)
        }
        context.strokePath()
        drawSceneText(
            text,
            in: rect.insetBy(dx: 5, dy: rect.height * 0.24),
            font: NSFont.monospacedSystemFont(ofSize: max(12, rect.width * 0.19), weight: .semibold),
            color: NSColor.white.withAlphaComponent(0.88 * opacity),
            alignment: .center,
            context: context
        )
        context.restoreGState()
    }

    private static func drawSceneTitle(context: CGContext, size: CGSize, settings: SceneOverlaySettings, accent: NSColor, white: NSColor, landscape: Bool) {
        let x = landscape ? size.width * 0.055 : size.width * 0.12
        let y: CGFloat
        switch settings.template {
        case .djLowerThird:
            y = size.height * (landscape ? 0.27 : 0.12)
        case .fullscreenWave:
            y = size.height * 0.12
        default:
            y = size.height * (landscape ? 0.19 : 0.12)
        }
        let width = landscape ? size.width * 0.40 : size.width * 0.76
        drawSceneText(
            "DJ",
            in: CGRect(x: x, y: y + size.height * 0.088, width: width, height: size.height * 0.045),
            font: NSFont.systemFont(ofSize: max(26, min(size.width, size.height) * 0.045), weight: .black),
            color: accent,
            alignment: landscape ? .left : .center,
            context: context
        )
        drawSceneText(
            settings.artist,
            in: CGRect(x: x, y: y + size.height * 0.028, width: width, height: size.height * 0.074),
            font: NSFont.systemFont(ofSize: max(38, min(size.width, size.height) * 0.066), weight: .black),
            color: white,
            alignment: landscape ? .left : .center,
            context: context
        )
        drawSceneText(
            settings.subtitle,
            in: CGRect(x: x, y: y, width: width, height: size.height * 0.032),
            font: NSFont.systemFont(ofSize: max(13, min(size.width, size.height) * 0.017), weight: .semibold),
            color: accent,
            alignment: landscape ? .left : .center,
            context: context
        )
    }

    private static func drawSceneStats(context: CGContext, size: CGSize, snapshot: ExportSnapshot, energy: CGFloat, accent: NSColor, magenta: NSColor, opacity: Double) {
        let rect = CGRect(x: size.width * 0.73, y: size.height * 0.80, width: size.width * 0.20, height: size.height * 0.115)
        context.setFillColor(NSColor.black.withAlphaComponent(0.38 * opacity).cgColor)
        context.fill(rect)
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.15 * opacity).cgColor)
        context.stroke(rect)
        let rows = [
            ("FPS", "\(snapshot.renderMode.fps).00", accent),
            ("MODE", snapshot.renderMode.rawValue, magenta),
            ("RES", "\(Int(size.width))x\(Int(size.height))", accent),
            ("SYNC", energy > 0.18 ? "LOCKED" : "IDLE", energy > 0.18 ? magenta : NSColor.white.withAlphaComponent(0.55))
        ]
        let rowHeight = rect.height / CGFloat(rows.count)
        for (index, row) in rows.enumerated() {
            let y = rect.maxY - CGFloat(index + 1) * rowHeight + rowHeight * 0.18
            drawSceneText(row.0, in: CGRect(x: rect.minX + 10, y: y, width: rect.width * 0.32, height: rowHeight), font: NSFont.monospacedSystemFont(ofSize: max(10, rowHeight * 0.45), weight: .semibold), color: NSColor.white.withAlphaComponent(0.62 * opacity), alignment: .left, context: context)
            drawSceneText(row.1, in: CGRect(x: rect.minX + rect.width * 0.42, y: y, width: rect.width * 0.52, height: rowHeight), font: NSFont.monospacedSystemFont(ofSize: max(10, rowHeight * 0.45), weight: .semibold), color: row.2.withAlphaComponent(opacity), alignment: .left, context: context)
        }
    }

    private static func drawLowerThird(context: CGContext, size: CGSize, settings: SceneOverlaySettings, accent: NSColor, magenta: NSColor, white: NSColor, opacity: Double) {
        let rect = CGRect(x: size.width * 0.11, y: size.height * 0.055, width: size.width * 0.58, height: size.height * 0.17)
        context.setFillColor(NSColor.black.withAlphaComponent(0.22 * opacity).cgColor)
        context.fill(rect)
        let thumb = CGRect(x: rect.minX + 12, y: rect.maxY - 70, width: 58, height: 58)
        context.setFillColor(NSColor.black.withAlphaComponent(0.55 * opacity).cgColor)
        context.fill(thumb)
        context.setStrokeColor(accent.cgColor)
        context.stroke(thumb)
        drawSceneText("DJ", in: thumb.insetBy(dx: 5, dy: 15), font: NSFont.systemFont(ofSize: 18, weight: .black), color: accent, alignment: .center, context: context)
        drawSceneText(settings.artist, in: CGRect(x: thumb.maxX + 16, y: rect.maxY - 44, width: rect.width * 0.42, height: 22), font: NSFont.systemFont(ofSize: 18, weight: .bold), color: white, alignment: .left, context: context)
        drawSceneText(settings.subtitle, in: CGRect(x: thumb.maxX + 16, y: rect.maxY - 66, width: rect.width * 0.48, height: 18), font: NSFont.systemFont(ofSize: 13, weight: .semibold), color: accent, alignment: .left, context: context)
        let bar = CGRect(x: thumb.maxX + 16, y: rect.minY + 52, width: rect.width * 0.44, height: 4)
        context.setFillColor(NSColor.white.withAlphaComponent(0.18 * opacity).cgColor)
        context.fill(bar)
        context.setFillColor(accent.cgColor)
        context.fill(CGRect(x: bar.minX, y: bar.minY, width: bar.width * 0.45, height: bar.height))
        context.setFillColor(NSColor.white.withAlphaComponent(0.90 * opacity).cgColor)
        context.fillEllipse(in: CGRect(x: bar.minX + bar.width * 0.45 - 4, y: bar.midY - 4, width: 8, height: 8))
        let labels = ["Bottom", "Top", "Center", "Stereo", "Bars", "Circle"]
        let chipWidth = min(74, rect.width * 0.11)
        for (index, label) in labels.enumerated() {
            let chip = CGRect(x: rect.minX + CGFloat(index) * (chipWidth + 12) + 12, y: rect.minY + 10, width: chipWidth, height: 30)
            context.setFillColor(NSColor.black.withAlphaComponent(0.35 * opacity).cgColor)
            context.fill(chip)
            context.setStrokeColor((index == 0 ? accent : NSColor.white.withAlphaComponent(0.14 * opacity)).cgColor)
            context.stroke(chip)
            drawSceneText(label, in: chip.insetBy(dx: 3, dy: 8), font: NSFont.systemFont(ofSize: 9, weight: .semibold), color: NSColor.white.withAlphaComponent(0.74 * opacity), alignment: .center, context: context)
        }
    }

    private static func drawSceneText(_ text: String, in rect: CGRect, font: NSFont, color: NSColor, alignment: NSTextAlignment, context: CGContext) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byTruncatingTail
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.86)
        shadow.shadowBlurRadius = max(4, font.pointSize * 0.16)
        shadow.shadowOffset = CGSize(width: 0, height: -1)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
            .shadow: shadow
        ]
        let previous = NSGraphicsContext.current
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        NSString(string: text).draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs)
        NSGraphicsContext.current = previous
    }

    private static func drawLyrics(context: CGContext, size: CGSize, snapshot: ExportSnapshot, time: Double, duration: Double) {
        guard snapshot.lyricsEnabled,
              let text = LyricsEngine.text(at: time, duration: duration, cues: snapshot.lyricsCues),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let fontSize = max(32, min(size.width, size.height) * 0.044 * CGFloat(snapshot.lyricsSize))
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.96)
        shadow.shadowBlurRadius = max(8, fontSize * 0.18)
        shadow.shadowOffset = CGSize(width: 0, height: -2)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .black),
            .foregroundColor: NSColor.white.withAlphaComponent(snapshot.lyricsOpacity),
            .strokeColor: NSColor.black.withAlphaComponent(0.90),
            .strokeWidth: -4.0,
            .paragraphStyle: paragraph,
            .shadow: shadow
        ]
        let attributed = NSAttributedString(string: text, attributes: attrs)
        let maxWidth = size.width * 0.84
        let measured = attributed.boundingRect(
            with: CGSize(width: maxWidth, height: size.height * 0.25),
            options: [.usesLineFragmentOrigin, .usesFontLeading]
        )
        let height = min(size.height * 0.24, max(fontSize * 1.35, measured.height + fontSize * 0.30))
        let y = lyricsY(size: size, rectHeight: height, snapshot: snapshot)
        let rect = CGRect(x: (size.width - maxWidth) / 2, y: y, width: maxWidth, height: height)

        context.saveGState()
        context.setBlendMode(.normal)
        let previous = NSGraphicsContext.current
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        attributed.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading])
        NSGraphicsContext.current = previous
        context.restoreGState()
    }

    private static func lyricsY(size: CGSize, rectHeight: CGFloat, snapshot: ExportSnapshot) -> CGFloat {
        let band = size.height * CGFloat(snapshot.waveHeight)
        let baseY = exportBaseY(size: size, band: band, position: snapshot.wavePosition)
        let raw: CGFloat
        switch snapshot.lyricsPosition {
        case .top:
            raw = size.height * 0.84
        case .center:
            raw = size.height * 0.50 - rectHeight / 2
        case .bottom:
            raw = size.height * 0.08
        case .aboveWave:
            switch snapshot.wavePosition {
            case .top:
                raw = baseY - band * 1.05 - rectHeight
            case .center:
                raw = baseY + band * 0.48
            case .left, .right:
                raw = size.height * 0.74
            case .bottom:
                raw = baseY + band * 0.92
            }
        case .belowWave:
            switch snapshot.wavePosition {
            case .top:
                raw = baseY + band * 0.18
            case .center:
                raw = baseY - band * 0.58 - rectHeight
            case .left, .right:
                raw = size.height * 0.08
            case .bottom:
                raw = baseY - band * 0.62 - rectHeight
            }
        }
        return min(size.height - rectHeight - 24, max(24, raw))
    }

    private static func exportFrameSamples(snapshot: ExportSnapshot, fallback: [CGFloat], time: Double, duration: Double) -> [CGFloat] {
        guard !snapshot.spectrumFrames.isEmpty else { return fallback }
        let progress = duration > 0 ? min(0.999, max(0, time / duration)) : 0
        let index = min(snapshot.spectrumFrames.count - 1, max(0, Int(progress * Double(snapshot.spectrumFrames.count))))
        return snapshot.spectrumFrames[index]
    }

    private static func exportSamples(_ samples: [CGFloat], snapshot: ExportSnapshot) -> [CGFloat] {
        guard !samples.isEmpty else { return samples }
        var values = samples
        switch snapshot.waveDirection {
        case .rightToLeft, .outwardCenter:
            values.reverse()
        default:
            break
        }
        if snapshot.mirrorMode == .horizontal || snapshot.mirrorMode == .both {
            let half = Array(values.prefix(max(1, values.count / 2)))
            values = half + half.reversed()
        }
        return values
    }

    private static func exportBaseY(size: CGSize, band: CGFloat, position: WavePosition) -> CGFloat {
        switch position {
        case .top:
            return size.height - band * 0.55 - size.height * 0.03
        case .center:
            return size.height * 0.5
        default:
            return band * 0.42 + size.height * 0.03
        }
    }
}

enum SmokeTest {
    private static let sampleLyricsCues = LyricsEngine.parse("""
    [00:00.00] WEISCH NO?!
    [00:01.20] Seven-three crew
    [00:02.40] Still making noise like we always do
    [00:03.80] Eine Runde noch
    """)

    private static let sampleSceneOverlay = SceneOverlaySettings(
        template: .djLowerThird,
        artist: "DJ SeN-SiZE",
        subtitle: "DRUM N BASS IN SEINER LEBENDIGSTEN FORM",
        bpm: "174 BPM",
        genre: "NEURO\nBASS",
        tag: "DNB",
        showBadges: true,
        showTitle: true,
        showStats: true,
        opacity: 0.86,
        accentHex: "#00E6FF",
        magentaHex: "#FF00D6"
    )

    static func runIfRequested() {
        let args = CommandLine.arguments
        let doubleExport = args.contains("--smoke-double-export")
        let maxExport = args.contains("--smoke-max-export")
        let batchPhase1 = args.contains("--smoke-batch-phase1")
        let namingArtwork = args.contains("--smoke-naming-artwork")
        let renderTestIndex = args.firstIndex(of: "--render-test-set")
        guard args.contains("--smoke-export") || doubleExport || maxExport || batchPhase1 || namingArtwork || renderTestIndex != nil else { return }
        if batchPhase1 {
            do {
                try runBatchPhase1Smoke()
                print("Batch phase1 smoke passed")
                exit(0)
            } catch {
                fputs("Batch phase1 smoke failed: \(error.localizedDescription)\n", stderr)
                exit(2)
            }
        }
        if namingArtwork {
            do {
                try runNamingArtworkSmoke()
                print("Naming artwork smoke passed")
                exit(0)
            } catch {
                fputs("Naming artwork smoke failed: \(error.localizedDescription)\n", stderr)
                exit(2)
            }
        }
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            do {
                if let renderTestIndex {
                    try await runRealAssetTest(args: args, index: renderTestIndex)
                    exit(0)
                }
                let outputDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("NALA-SmokeExport", isDirectory: true)
                try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
                let imageURL = outputDirectory.appendingPathComponent("cover.png")
                let audioURL = outputDirectory.appendingPathComponent("tone.wav")
                try writeSmokeImage(to: imageURL)
                try writeSmokeAudio(to: audioURL)
                let snapshot = ExportSnapshot(
                    size: CGSize(width: 540, height: 960),
                    canvasFitMode: .fill,
                    visualizerKind: .blockBars,
                    wavePosition: .bottom,
                    stereoMode: .leftRight,
                    waveDirection: .leftToRight,
                    mirrorMode: .none,
                    colorMode: .manual,
                    colors: [CodableColor(.cyan), CodableColor(.systemPink), CodableColor(.white)],
                    opacity: 0.72,
                    barCount: 64,
                    waveHeight: 0.22,
                    lineWidth: 2,
                    glowStrength: 0.45,
                    smoothing: 0.62,
                    imageZoom: 1,
                    imageRotation: 0,
                    imageOffsetX: 0,
                    imageOffsetY: 0,
                    kenBurnsMode: .zoomIn,
                    kenBurnsStrength: 0.15,
                    kenBurnsSpeed: 0.35,
                    renderMode: maxExport ? .max : .standard,
                    effects: RenderEffects(
                        bassShake: 0.20,
                        zoomPunch: 0.18,
                        rgbSplit: 0.15,
                        glitch: 0,
                        particles: 0.25,
                        beatFlash: 0.12,
                        lensGlow: 0.24
                    ),
                    sceneOverlay: args.contains("--with-scene") ? sampleSceneOverlay : SceneOverlaySettings.none,
                    lyricsEnabled: args.contains("--with-lyrics"),
                    lyricsPosition: .aboveWave,
                    lyricsSize: 1.0,
                    lyricsOpacity: 0.95,
                    lyricsCues: args.contains("--with-lyrics") ? sampleLyricsCues : [],
                    samples: AudioTools.placeholderWaveform(),
                    spectrumFrames: AudioTools.placeholderSpectrumFrames(frameCount: 120, bins: 64)
                )
                let output = try await Exporter.export(snapshot: snapshot, audioURL: audioURL, imageURL: imageURL, outputDirectory: outputDirectory, requestedName: "NALA-Smoke-Test") { _ in }
                print(output.path)
                if doubleExport {
                    let videoAudioAnalysis = await AudioTools.analysis(url: output, waveformCount: 120, frameCount: 80, bins: 48)
                    guard videoAudioAnalysis.spectrumFrames.flatMap({ $0 }).contains(where: { $0 > 0.02 }) else {
                        throw NSError(domain: "NALA", code: 20, userInfo: [NSLocalizedDescriptionKey: "MP4-Audiotrack konnte nicht per FFT analysiert werden"])
                    }
                    let second = try await Exporter.export(snapshot: snapshot, audioURL: output, imageURL: imageURL, outputDirectory: outputDirectory, requestedName: "NALA-Smoke-VideoAudio-Test") { _ in }
                    print(second.path)
                }
                exit(0)
            } catch {
                fputs("Smoke export failed: \(error.localizedDescription)\n", stderr)
                exit(2)
            }
            semaphore.signal()
        }
        semaphore.wait()
    }

    private static func runNamingArtworkSmoke() throws {
        let outputDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("NALA-NamingArtworkSmoke", isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let imageURL = outputDirectory.appendingPathComponent("name-des-bild-843737.png")
        try writeSmokeImage(to: imageURL)
        let snapshot = ExportSnapshot(
            size: CGSize(width: 3840, height: 2160),
            canvasFitMode: .fill,
            visualizerKind: .barsSpectrum,
            wavePosition: .bottom,
            stereoMode: .combined,
            waveDirection: .leftToRight,
            mirrorMode: .none,
            colorMode: .manual,
            colors: [CodableColor(.cyan), CodableColor(.systemPink), CodableColor(.white)],
            opacity: 0.72,
            barCount: 96,
            waveHeight: 0.26,
            lineWidth: 2,
            glowStrength: 0.55,
            smoothing: 0.72,
            imageZoom: 1,
            imageRotation: 0,
            imageOffsetX: 0,
            imageOffsetY: 0,
            kenBurnsMode: .zoomIn,
            kenBurnsStrength: 0.12,
            kenBurnsSpeed: 0.35,
            renderMode: .max,
            effects: RenderEffects.none,
            sceneOverlay: SceneOverlaySettings.none,
            lyricsEnabled: false,
            lyricsPosition: .aboveWave,
            lyricsSize: 1.0,
            lyricsOpacity: 0.95,
            lyricsCues: [],
            samples: AudioTools.placeholderWaveform(),
            spectrumFrames: AudioTools.placeholderSpectrumFrames(frameCount: 120, bins: 64)
        )
        let defaultName = Exporter.defaultOutputName(for: imageURL)
        guard defaultName == "name-des-bild-843737" else {
            throw NSError(domain: "NALA", code: 81, userInfo: [NSLocalizedDescriptionKey: "Bildname wurde nicht als Default-Dateiname übernommen"])
        }
        let outputStem = Exporter.outputFileStem(requestedName: defaultName, snapshot: snapshot)
        guard outputStem == "name-des-bild-843737-16-9-4k" else {
            throw NSError(domain: "NALA", code: 82, userInfo: [NSLocalizedDescriptionKey: "Format-Suffix falsch: \(outputStem)"])
        }
        guard Exporter.canCreateArtworkMetadata(from: imageURL) else {
            throw NSError(domain: "NALA", code: 83, userInfo: [NSLocalizedDescriptionKey: "MP4-Artwork-Metadaten konnten nicht aus dem Cover erzeugt werden"])
        }
    }

    private static func runBatchPhase1Smoke() throws {
        let outputDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("NALA-BatchPhase1Smoke", isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let imageURL = outputDirectory.appendingPathComponent("cover.png")
        let audioURL = outputDirectory.appendingPathComponent("tone.wav")
        try writeSmokeImage(to: imageURL)
        try writeSmokeAudio(to: audioURL)
        var snapshot = ExportSnapshot(
            size: CGSize(width: 540, height: 960),
            canvasFitMode: .fill,
            visualizerKind: .blockBars,
            wavePosition: .bottom,
            stereoMode: .leftRight,
            waveDirection: .leftToRight,
            mirrorMode: .none,
            colorMode: .manual,
            colors: [CodableColor(.cyan), CodableColor(.systemPink), CodableColor(.white)],
            opacity: 0.72,
            barCount: 64,
            waveHeight: 0.22,
            lineWidth: 2,
            glowStrength: 0.45,
            smoothing: 0.62,
            imageZoom: 1,
            imageRotation: 0,
            imageOffsetX: 0,
            imageOffsetY: 0,
            kenBurnsMode: .zoomIn,
            kenBurnsStrength: 0.15,
            kenBurnsSpeed: 0.35,
            renderMode: .max,
            effects: RenderEffects.none,
            sceneOverlay: SceneOverlaySettings.none,
            lyricsEnabled: true,
            lyricsPosition: .aboveWave,
            lyricsSize: 1.0,
            lyricsOpacity: 0.95,
            lyricsCues: LyricsEngine.parse("[00:00.00] Smoke lyric"),
            samples: AudioTools.placeholderWaveform(),
            spectrumFrames: AudioTools.placeholderSpectrumFrames(frameCount: 120, bins: 64)
        )
        var job = BatchJob(audioURL: audioURL, imageURL: imageURL, outputDirectory: outputDirectory, requestedName: "Batch Phase 1 Test", snapshot: snapshot)
        guard job.snapshot.renderMode == .max else {
            throw NSError(domain: "NALA", code: 71, userInfo: [NSLocalizedDescriptionKey: "MAX RenderMode wurde nicht in den Batch übernommen"])
        }
        guard job.snapshot.lyricsEnabled, !job.snapshot.lyricsCues.isEmpty else {
            throw NSError(domain: "NALA", code: 72, userInfo: [NSLocalizedDescriptionKey: "Lyrics wurden nicht in den Batch-Snapshot übernommen"])
        }
        job.snapshot.renderMode = .standard
        guard job.snapshot.renderMode == .standard else {
            throw NSError(domain: "NALA", code: 74, userInfo: [NSLocalizedDescriptionKey: "Batch-RenderMode konnte nicht pro Job geändert werden"])
        }
        snapshot.renderMode = .max
        job.snapshot.renderMode = snapshot.renderMode
        guard job.snapshot.renderMode == .max else {
            throw NSError(domain: "NALA", code: 75, userInfo: [NSLocalizedDescriptionKey: "MAX für alle Batch-Jobs hat nicht gegriffen"])
        }
    }

    private static func runRealAssetTest(args: [String], index: Int) async throws {
        guard args.count > index + 2 else {
            throw NSError(domain: "NALA", code: 50, userInfo: [NSLocalizedDescriptionKey: "Usage: --render-test-set <audio-or-video> <image> [seconds]"])
        }
        let audioURL = URL(fileURLWithPath: args[index + 1])
        let imageURL = URL(fileURLWithPath: args[index + 2])
        let seconds = args.count > index + 3 ? (Double(args[index + 3]) ?? 8.0) : 8.0
        let withLyrics = args.contains("--with-lyrics")
        let outputDirectory = URL(fileURLWithPath: "/Users/ultramacuser/Downloads/NALA-Real-Asset-Tests", isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let analysis = await AudioTools.analysis(url: audioURL, waveformCount: 420, frameCount: 360, bins: 96)
        guard analysis.spectrumFrames.flatMap({ $0 }).contains(where: { $0 > 0.02 }) else {
            throw NSError(domain: "NALA", code: 51, userInfo: [NSLocalizedDescriptionKey: "Audioanalyse lieferte keine nutzbaren FFT-Daten"])
        }
        let snapshot = ExportSnapshot(
            size: CGSize(width: 1080, height: 1920),
            canvasFitMode: .fill,
            visualizerKind: .blockBars,
            wavePosition: .bottom,
            stereoMode: .leftRight,
            waveDirection: .leftToRight,
            mirrorMode: .none,
            colorMode: .manual,
            colors: [CodableColor(.cyan), CodableColor(.systemPink), CodableColor(.white)],
            opacity: 0.72,
            barCount: 96,
            waveHeight: 0.24,
            lineWidth: 2.2,
            glowStrength: 0.72,
            smoothing: 0.72,
            imageZoom: 1.0,
            imageRotation: 0,
            imageOffsetX: 0,
            imageOffsetY: 0,
            kenBurnsMode: .zoomIn,
            kenBurnsStrength: 0.10,
            kenBurnsSpeed: 0.35,
            renderMode: .standard,
            effects: RenderEffects(
                bassShake: 0.18,
                zoomPunch: 0.12,
                rgbSplit: 0.20,
                glitch: 0.08,
                particles: 0.36,
                beatFlash: 0.10,
                lensGlow: 0.28
            ),
            sceneOverlay: args.contains("--with-scene") ? sampleSceneOverlay : SceneOverlaySettings.none,
            lyricsEnabled: withLyrics,
            lyricsPosition: .aboveWave,
            lyricsSize: 1.0,
            lyricsOpacity: 0.95,
            lyricsCues: withLyrics ? sampleLyricsCues : [],
            samples: analysis.waveform,
            spectrumFrames: analysis.spectrumFrames
        )
        let output = try await Exporter.export(
            snapshot: snapshot,
            audioURL: audioURL,
            imageURL: imageURL,
            outputDirectory: outputDirectory,
            requestedName: "dJ-NoFoCuS-Still-Fighting-NALA-Test",
            maxDuration: seconds
        ) { progress in
            if Int(progress * 100) % 10 == 0 {
                print("progress \(Int(progress * 100))%")
            }
        }
        print(output.path)
    }

    private static func writeSmokeImage(to url: URL) throws {
        let image = NSImage(size: CGSize(width: 900, height: 1200))
        image.lockFocus()
        NSGradient(colors: [.black, .darkGray, .cyan, .systemPink])?.draw(in: NSRect(x: 0, y: 0, width: 900, height: 1200), angle: -35)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 88, weight: .black),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraph
        ]
        "NALA\nAUDIO".draw(in: NSRect(x: 70, y: 505, width: 760, height: 220), withAttributes: attrs)
        image.unlockFocus()
        guard let data = image.pngData else { throw NSError(domain: "NALA", code: 10, userInfo: [NSLocalizedDescriptionKey: "Smoke-Bild konnte nicht erzeugt werden"]) }
        try data.write(to: url)
    }

    private static func writeSmokeAudio(to url: URL) throws {
        let sampleRate = 44_100.0
        let duration = 1.2
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        for channel in 0..<2 {
            guard let channelData = buffer.floatChannelData?[channel] else { continue }
            for frame in 0..<Int(frameCount) {
                let t = Double(frame) / sampleRate
                channelData[frame] = Float(sin(t * 440 * 2 * .pi) * 0.25 + sin(t * 92 * 2 * .pi) * 0.12)
            }
        }
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
    }
}

private extension NSImage {
    var cgImageValue: CGImage? {
        var rect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }
    var pngData: Data? {
        guard let tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}

private extension NSColor {
    convenience init?(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        guard cleaned.count == 6, let value = UInt64(cleaned, radix: 16) else {
            return nil
        }
        let red = CGFloat((value & 0xFF0000) >> 16) / 255
        let green = CGFloat((value & 0x00FF00) >> 8) / 255
        let blue = CGFloat(value & 0x0000FF) / 255
        self.init(calibratedRed: red, green: green, blue: blue, alpha: 1)
    }
}
