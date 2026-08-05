// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MarkdownHTML",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "MarkdownHTML", targets: ["MarkdownHTML"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-markdown.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "MarkdownHTML",
            dependencies: [.product(name: "Markdown", package: "swift-markdown")],
            path: "Sources",
            swiftSettings: [.unsafeFlags(["-strict-concurrency=complete"])]
        ),
        .testTarget(name: "MarkdownHTMLTests", dependencies: ["MarkdownHTML"], path: "Tests"),
    ]
)
