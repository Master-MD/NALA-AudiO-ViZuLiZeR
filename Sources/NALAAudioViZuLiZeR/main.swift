import AVFoundation
import AppKit
import SwiftUI
import UniformTypeIdentifiers

@main
struct NALAApp: App {
    @StateObject private var model = AppModel()

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

enum CanvasPreset: String, CaseIterable, Identifiable {
    case square = "1:1 Square"
    case vertical = "9:16 Vertical"
    case landscape = "16:9 Landscape"
    case superWide = "Super Wide"

    var id: String { rawValue }
    var size: CGSize {
        switch self {
        case .square: CGSize(width: 1080, height: 1080)
        case .vertical: CGSize(width: 1080, height: 1920)
        case .landscape: CGSize(width: 1920, height: 1080)
        case .superWide: CGSize(width: 2560, height: 1080)
        }
    }
}

enum VisualizerKind: String, CaseIterable, Identifiable {
    case waveform = "Bottom Waveform"
    case blockBars = "Block Stereo Bars"
    var id: String { rawValue }
}

@MainActor
final class AppModel: ObservableObject {
    @Published var audioURL: URL?
    @Published var images: [MediaItem] = []
    @Published var videos: [MediaItem] = []
    @Published var selectedImageID: UUID?
    @Published var selectedVideoID: UUID?
    @Published var stillIconURL: URL?
    @Published var stillIconEnabled = false
    @Published var canvasPreset: CanvasPreset = .vertical
    @Published var visualizerKind: VisualizerKind = .waveform
    @Published var opacity = 0.9
    @Published var barCount = 72.0
    @Published var waveHeight = 0.25
    @Published var imageZoom = 1.0
    @Published var imageRotation = 0.0
    @Published var imageOffsetX = 0.0
    @Published var imageOffsetY = 0.0
    @Published var waveform = AudioTools.placeholderWaveform()
    @Published var isRendering = false
    @Published var renderProgress = 0.0
    @Published var status = "Bereit"
    @Published var outputFileName = "NALA-Visualizer"

    var selectedImage: MediaItem? {
        if let selectedImageID, let item = images.first(where: { $0.id == selectedImageID }) { return item }
        return images.first
    }

    var previewImageURL: URL? {
        stillIconEnabled ? (stillIconURL ?? selectedImage?.url) : selectedImage?.url
    }

    func importURLs(_ urls: [URL]) {
        for url in urls {
            switch url.pathExtension.lowercased() {
            case "mp3", "wav", "flac", "aac", "m4a":
                audioURL = url
                Task { waveform = await AudioTools.waveform(url: url) }
            case "jpg", "jpeg", "png", "webp":
                let item = MediaItem(url: url)
                images.append(item)
                selectedImageID = selectedImageID ?? item.id
            case "mp4", "mov", "m4v":
                let item = MediaItem(url: url)
                videos.append(item)
                selectedVideoID = selectedVideoID ?? item.id
            default:
                break
            }
        }
        status = "Medien importiert"
    }

    func chooseAudio() { choose(["mp3", "wav", "flac", "aac", "m4a"], multiple: false) { importURLs($0) } }
    func chooseImages() { choose(["jpg", "jpeg", "png", "webp"], multiple: true) { importURLs($0) } }
    func chooseVideos() { choose(["mp4", "mov", "m4v"], multiple: true) { importURLs($0) } }
    func chooseStillIcon() {
        choose(["jpg", "jpeg", "png", "webp"], multiple: false) { urls in
            stillIconURL = urls.first
            stillIconEnabled = stillIconURL != nil
            status = "YouTube-Music-Cover gewählt"
        }
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

    func export() async {
        guard let audioURL else { status = "Bitte Audio auswählen"; return }
        guard let imageURL = previewImageURL else { status = "Bitte Bild auswählen"; return }
        let snapshot = ExportSnapshot(
            size: canvasPreset.size,
            visualizerKind: visualizerKind,
            opacity: opacity,
            barCount: Int(barCount),
            waveHeight: waveHeight,
            imageZoom: imageZoom,
            imageRotation: imageRotation,
            imageOffsetX: imageOffsetX,
            imageOffsetY: imageOffsetY,
            samples: waveform
        )
        isRendering = true
        renderProgress = 0
        status = "Render läuft ..."
        do {
            let output = try await Exporter.export(snapshot: snapshot, audioURL: audioURL, imageURL: imageURL, requestedName: outputFileName) { progress in
                Task { @MainActor in self.renderProgress = progress }
            }
            if stillIconEnabled, let image = NSImage(contentsOf: imageURL), let data = image.pngData {
                try? data.write(to: output.deletingLastPathComponent().appendingPathComponent("\(Exporter.safeFileStem(outputFileName))-Still-Cover.png"))
            }
            status = "Export fertig: \(output.lastPathComponent)"
            NSWorkspace.shared.activateFileViewerSelecting([output])
        } catch {
            status = "Export fehlgeschlagen: \(error.localizedDescription)"
        }
        isRendering = false
    }

    private func choose(_ extensions: [String], multiple: Bool, handler: ([URL]) -> Void) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = extensions.compactMap { UTType(filenameExtension: $0) }
        panel.allowsMultipleSelection = multiple
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        if panel.runModal() == .OK { handler(panel.urls) }
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
                    ExportBar()
                        .frame(height: 74)
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
        Panel("NALA") {
            VStack(alignment: .leading, spacing: 14) {
                Text("NALA").font(.system(size: 42, weight: .black)).italic()
                Text("AUDIO-VIZULIZER").foregroundStyle(.cyan).font(.headline)
                feature("square.and.arrow.down", "Drag & Drop oder Doppelklick")
                feature("waveform", "Waveform oder Block Stereo Bars")
                feature("slider.horizontal.3", "Transparenz, Zoom, Rotation")
                feature("xmark.circle", "Falsche Medien per X löschen")
                feature("photo", "YouTube Music Still Cover")
            }
        }
    }

    private var settings: some View {
        ScrollView {
            VStack(spacing: 8) {
                Panel("Visualizer") {
                    Picker("Typ", selection: $model.visualizerKind) {
                        ForEach(VisualizerKind.allCases) { Text($0.rawValue).tag($0) }
                    }
                    slider("Transparenz", value: $model.opacity, range: 0.1...1, percent: true)
                    slider("Balken", value: $model.barCount, range: 24...144, percent: false)
                    slider("Höhe", value: $model.waveHeight, range: 0.12...0.42, percent: true)
                }
                Panel("Canvas") {
                    Picker("Format", selection: $model.canvasPreset) {
                        ForEach(CanvasPreset.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                Panel("Bild / Cover Zuschnitt") {
                    slider("Zoom", value: $model.imageZoom, range: 1...3, percent: false)
                    slider("Rotation", value: $model.imageRotation, range: -180...180, percent: false)
                    slider("X", value: $model.imageOffsetX, range: -1...1, percent: false)
                    slider("Y", value: $model.imageOffsetY, range: -1...1, percent: false)
                    Button("Reset") { model.resetImageAdjustment() }
                }
                Panel("YouTube Music Cover") {
                    Toggle("Still Icon aktivieren", isOn: $model.stillIconEnabled)
                    HStack {
                        Button("Cover wählen") { model.chooseStillIcon() }
                        Button("Aktuelles Bild") { model.useSelectedAsCover() }
                    }
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
            Text(percent ? "\(Int(value.wrappedValue * 100))%" : "\(Int(value.wrappedValue))")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
                .frame(width: 42, alignment: .trailing)
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

struct PreviewPanel: View {
    @EnvironmentObject private var model: AppModel
    var body: some View {
        Panel("Live Preview") {
            GeometryReader { proxy in
                let rect = fit(canvas: model.canvasPreset.size, into: proxy.size)
                ZStack {
                    Color.black
                    if let url = model.previewImageURL, let image = NSImage(contentsOf: url) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(model.imageZoom)
                            .rotationEffect(.degrees(model.imageRotation))
                            .offset(x: model.imageOffsetX * rect.width * 0.25, y: -model.imageOffsetY * rect.height * 0.25)
                            .frame(width: rect.width, height: rect.height)
                            .clipped()
                    } else {
                        VStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.down").font(.largeTitle).foregroundStyle(.cyan)
                            Text("Audio + Bild hier ablegen oder unten doppelklicken")
                        }
                    }
                    VisualizerCanvas(samples: model.waveform, kind: model.visualizerKind, opacity: model.opacity, bars: Int(model.barCount), heightScale: model.waveHeight)
                        .frame(width: rect.width, height: rect.height)
                }
                .frame(width: rect.width, height: rect.height)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
    }

    private func fit(canvas: CGSize, into container: CGSize) -> CGRect {
        let scale = min(container.width / canvas.width, container.height / canvas.height)
        return CGRect(origin: .zero, size: CGSize(width: canvas.width * scale, height: canvas.height * scale))
    }
}

struct VisualizerCanvas: View {
    let samples: [CGFloat]
    let kind: VisualizerKind
    let opacity: Double
    let bars: Int
    let heightScale: Double

    var body: some View {
        Canvas { context, size in
            let colors = [Color.cyan.opacity(opacity), Color.pink.opacity(opacity), Color.blue.opacity(opacity)]
            let band = size.height * heightScale
            let base = size.height - band * 0.42 - size.height * 0.03
            context.addFilter(.shadow(color: .cyan.opacity(opacity), radius: 10))
            if kind == .blockBars {
                let count = max(8, min(160, bars))
                let step = max(1, samples.count / count)
                let slot = size.width / CGFloat(count)
                for bar in 0..<count {
                    let value = samples[min(samples.count - 1, bar * step)] * band
                    let x = CGFloat(bar) * slot + slot * 0.14
                    let w = slot * 0.72
                    context.fill(Path(CGRect(x: x, y: base - value, width: w, height: value)), with: .color(colors[bar % colors.count]))
                    context.fill(Path(CGRect(x: x, y: base, width: w, height: value * 0.72)), with: .color(colors[(bar + 1) % colors.count]))
                }
            } else {
                var path = Path()
                let step = size.width / CGFloat(max(1, samples.count - 1))
                for (index, sample) in samples.enumerated() {
                    let x = CGFloat(index) * step
                    let h = sample * band
                    path.move(to: CGPoint(x: x, y: base - h * 0.5))
                    path.addLine(to: CGPoint(x: x, y: base + h * 0.5))
                }
                context.stroke(path, with: .linearGradient(Gradient(colors: colors), startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0)), lineWidth: 1.6)
            }
        }
        .allowsHitTesting(false)
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
                    if model.audioURL != nil {
                        Button { model.clearAudio() } label: { Image(systemName: "xmark.circle.fill") }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.red)
                    }
                }
                if let audioURL = model.audioURL {
                    Label(audioURL.lastPathComponent, systemImage: "waveform")
                        .font(.caption)
                        .lineLimit(2)
                } else {
                    Text("Doppelklick zum Auswählen").font(.caption).foregroundStyle(.white.opacity(0.55))
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
                        .frame(width: 260)
                        .disabled(model.isRendering)
                }
                Text(model.status).font(.caption).foregroundStyle(model.status.contains("fehl") ? .orange : .green)
            }
            Spacer()
            if model.isRendering { ProgressView(value: model.renderProgress).frame(width: 180) }
            Button {
                Task { await model.export() }
            } label: {
                Label(model.isRendering ? "RENDERT" : "RENDERN", systemImage: "square.and.arrow.up")
                    .frame(width: 210, height: 48)
                    .background(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .disabled(model.isRendering)
        }
        .padding(12)
        .background(Color(red: 0.035, green: 0.055, blue: 0.065))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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

enum AudioTools {
    static func placeholderWaveform(count: Int = 360) -> [CGFloat] {
        (0..<count).map { index in
            CGFloat(max(0.08, min(1, abs(sin(Double(index) * 0.13)) * 0.65 + Double.random(in: 0.04...0.25))))
        }
    }

    static func waveform(url: URL, count: Int = 360) async -> [CGFloat] {
        await Task.detached(priority: .userInitiated) {
            do {
                let file = try AVAudioFile(forReading: url)
                guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else { return placeholderWaveform(count: count) }
                try file.read(into: buffer)
                guard let channels = buffer.floatChannelData else { return placeholderWaveform(count: count) }
                let frames = Int(buffer.frameLength)
                let stride = max(1, frames / count)
                var values: [CGFloat] = []
                for index in Swift.stride(from: 0, to: frames, by: stride) {
                    let end = min(frames, index + stride)
                    var sum: Float = 0
                    var n: Float = 0
                    for channel in 0..<Int(file.processingFormat.channelCount) {
                        for frame in index..<end {
                            let v = channels[channel][frame]
                            sum += v * v
                            n += 1
                        }
                    }
                    values.append(CGFloat(sqrt(sum / max(1, n))))
                }
                let maxValue = max(values.max() ?? 0.01, 0.01)
                return values.prefix(count).map { min(1, $0 / maxValue) }
            } catch {
                return placeholderWaveform(count: count)
            }
        }.value
    }
}

struct ExportSnapshot: Sendable {
    let size: CGSize
    let visualizerKind: VisualizerKind
    let opacity: Double
    let barCount: Int
    let waveHeight: Double
    let imageZoom: Double
    let imageRotation: Double
    let imageOffsetX: Double
    let imageOffsetY: Double
    let samples: [CGFloat]
}

enum Exporter {
    static func export(snapshot: ExportSnapshot, audioURL: URL, imageURL: URL, requestedName: String, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        let outputDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Movies/NALA-Exports")
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        let output = uniqueOutputURL(in: outputDir, stem: safeFileStem(requestedName), extension: "mp4")
        try? FileManager.default.removeItem(at: output)

        let asset = AVURLAsset(url: audioURL)
        let duration = max(1, CMTimeGetSeconds((try? await asset.load(.duration)) ?? CMTime(seconds: 8, preferredTimescale: 600)))
        let size = snapshot.size
        let fps = 30
        let writer = try AVAssetWriter(outputURL: output, fileType: .mp4)
        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 12_000_000,
                AVVideoExpectedSourceFrameRateKey: fps
            ]
        ])
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(size.width),
            kCVPixelBufferHeightKey as String: Int(size.height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ])
        writer.add(videoInput)
        let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 320_000
        ])
        if writer.canAdd(audioInput) { writer.add(audioInput) }
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        guard let image = NSImage(contentsOf: imageURL)?.cgImageValue else { throw NSError(domain: "NALA", code: 1, userInfo: [NSLocalizedDescriptionKey: "Bild konnte nicht geladen werden"]) }
        let samples = snapshot.samples
        let frameCount = Int(duration * Double(fps))
        for frame in 0..<frameCount {
            while !videoInput.isReadyForMoreMediaData { try await Task.sleep(nanoseconds: 2_000_000) }
            guard let pool = adaptor.pixelBufferPool else { continue }
            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
            guard let pixelBuffer else { continue }
            render(buffer: pixelBuffer, image: image, snapshot: snapshot, samples: samples, size: size)
            adaptor.append(pixelBuffer, withPresentationTime: CMTime(value: CMTimeValue(frame), timescale: CMTimeScale(fps)))
            if frame % fps == 0 { progress(Double(frame) / Double(frameCount)) }
        }
        videoInput.markAsFinished()
        try await appendAudio(asset: asset, input: audioInput, duration: duration)
        audioInput.markAsFinished()

        return try await withCheckedThrowingContinuation { continuation in
            writer.finishWriting {
                writer.status == .completed ? continuation.resume(returning: output) : continuation.resume(throwing: writer.error ?? NSError(domain: "NALA", code: 2))
            }
        }
    }

    static func safeFileStem(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = trimmed.isEmpty ? "NALA-Visualizer" : trimmed
        let illegal = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        let cleaned = fallback.components(separatedBy: illegal).joined(separator: "-")
        return cleaned.replacingOccurrences(of: #"[\s-]+"#, with: "-", options: .regularExpression)
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

    private static func appendAudio(asset: AVURLAsset, input: AVAssetWriterInput, duration: Double) async throws {
        guard let track = try await asset.loadTracks(withMediaType: .audio).first else { return }
        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(track: track, outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ])
        reader.add(output)
        reader.startReading()
        while let sample = output.copyNextSampleBuffer() {
            while !input.isReadyForMoreMediaData { try await Task.sleep(nanoseconds: 2_000_000) }
            if CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sample)) > duration { break }
            input.append(sample)
        }
    }

    private static func render(buffer: CVPixelBuffer, image: CGImage, snapshot: ExportSnapshot, samples: [CGFloat], size: CGSize) {
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer),
              let context = CGContext(data: base, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue) else { return }
        context.setFillColor(NSColor.black.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        let scale = max(size.width / CGFloat(image.width), size.height / CGFloat(image.height)) * CGFloat(snapshot.imageZoom)
        let imageSize = CGSize(width: CGFloat(image.width) * scale, height: CGFloat(image.height) * scale)
        let rect = CGRect(x: (size.width - imageSize.width) / 2 + CGFloat(snapshot.imageOffsetX) * size.width * 0.25, y: (size.height - imageSize.height) / 2 - CGFloat(snapshot.imageOffsetY) * size.height * 0.25, width: imageSize.width, height: imageSize.height)
        context.saveGState()
        context.translateBy(x: rect.midX, y: rect.midY)
        context.rotate(by: CGFloat(snapshot.imageRotation * .pi / 180))
        context.translateBy(x: 0, y: rect.height)
        context.scaleBy(x: 1, y: -1)
        context.draw(image, in: CGRect(x: -rect.width / 2, y: 0, width: rect.width, height: rect.height))
        context.restoreGState()
        let band = size.height * CGFloat(snapshot.waveHeight)
        let baseY = size.height - band * 0.42 - size.height * 0.03
        let colors = [NSColor.cyan.withAlphaComponent(snapshot.opacity), NSColor.systemPink.withAlphaComponent(snapshot.opacity), NSColor.systemBlue.withAlphaComponent(snapshot.opacity)]
        context.setShadow(offset: .zero, blur: 16, color: NSColor.cyan.withAlphaComponent(snapshot.opacity).cgColor)
        if snapshot.visualizerKind == .blockBars {
            let count = max(8, min(160, snapshot.barCount))
            let sampleStep = max(1, samples.count / count)
            let slot = size.width / CGFloat(count)
            for bar in 0..<count {
                let value = samples[min(samples.count - 1, bar * sampleStep)] * band
                let x = CGFloat(bar) * slot + slot * 0.14
                context.setFillColor(colors[bar % colors.count].cgColor)
                context.fill(CGRect(x: x, y: baseY - value, width: slot * 0.72, height: value))
                context.setFillColor(colors[(bar + 1) % colors.count].cgColor)
                context.fill(CGRect(x: x, y: baseY, width: slot * 0.72, height: value * 0.72))
            }
        } else {
            context.setLineWidth(max(1.2, size.width / 1400))
            let step = size.width / CGFloat(max(1, samples.count - 1))
            for (index, sample) in samples.enumerated() {
                let x = CGFloat(index) * step
                let h = sample * band
                context.setStrokeColor(colors[index % colors.count].cgColor)
                context.move(to: CGPoint(x: x, y: baseY - h * 0.5))
                context.addLine(to: CGPoint(x: x, y: baseY + h * 0.5))
                context.strokePath()
            }
        }
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
