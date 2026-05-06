// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "NALA-AudiO-ViZuLiZeR",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "NALA-AudiO-ViZuLiZeR", targets: ["NALAAudioViZuLiZeR"])
    ],
    targets: [
        .executableTarget(name: "NALAAudioViZuLiZeR", path: "Sources/NALAAudioViZuLiZeR")
    ]
)
