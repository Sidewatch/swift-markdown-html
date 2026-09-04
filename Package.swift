// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MarkdownHTML",
    platforms: [.macOS(.v14)],
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
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(name: "MarkdownHTMLTests", dependencies: ["MarkdownHTML"], path: "Tests"),
    ]
)
