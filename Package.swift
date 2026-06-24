// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MarkdownStudio",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MarkdownStudio", targets: ["MarkdownStudio"])
    ],
    targets: [
        .target(name: "MarkdownStudioCore"),
        .executableTarget(
            name: "MarkdownStudio",
            dependencies: ["MarkdownStudioCore"],
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "MarkdownStudioCoreTests",
            dependencies: ["MarkdownStudioCore"]
        )
    ]
)
