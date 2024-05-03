// swift-tools-version:5.9
import Foundation
import PackageDescription

import PackageDescription

/// Settings to be passed to swiftc for all targets.
let allTargetsSwiftSettings: [SwiftSetting] = [
  .unsafeFlags(["-warnings-as-errors"])
]


/// Dependencies for documentation extraction.

let docGenerationDependency: [Package.Dependency] =
  ProcessInfo.processInfo.environment["HYLO_ENABLE_DOC_GENERATION"] != nil
  ? [.package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.1.0")] : []

let package = Package(
    name: "HyloDoc",
    platforms: [
        .macOS(.v11)
    ],
    products: [
        .executable(name: "hdc", targets: ["hdc"]), // Hylo Documentation Compiler (hdc)
        .library(name: "FrontEnd", targets: ["DocExtractor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.4"),
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-collections.git",from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-format", branch: "release/5.9"),
        .package(url: "https://github.com/hylo-lang/hylo", branch: "main"),
        .package(url: "https://github.com/johnxnguyen/Down", from: "0.11.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .executableTarget(
            name: "hdc",
            dependencies: [
                "DocExtractor",
                "WebsiteGen",
            ],
            path: "Sources/CLI",
            exclude: ["module.md"],
            swiftSettings: allTargetsSwiftSettings),
        .target(
            name: "DocumentationDB",
            dependencies: [],
            exclude: ["module.md"],
            swiftSettings: allTargetsSwiftSettings),
        .target(
            name: "DocExtractor",
            dependencies: [
                "DocumentationDB",
                .product(name: "Down", package: "Down")
                // todo add this once Hylo exports the library properly: .product(name: "FrontEnd", package: "hylo"),
            ],
            exclude: ["module.md"],
            swiftSettings: allTargetsSwiftSettings),
        .target(
            name: "WebsiteGen",
            dependencies: ["DocExtractor", "DocumentationDB"],
            exclude: ["module.md"],
            swiftSettings: allTargetsSwiftSettings),
        .testTarget(
            name: "WebsiteGenTests",
            dependencies: ["WebsiteGen"],
            exclude: ["module.md"],
            swiftSettings: allTargetsSwiftSettings),
        .testTarget(
            name: "DocExtractorTests",
            dependencies: ["DocExtractor"],
            exclude: ["module.md"],
            swiftSettings: allTargetsSwiftSettings),
        .testTarget(
            name: "CLITests",
            dependencies: ["hdc"],
            exclude: ["module.md"],
            swiftSettings: allTargetsSwiftSettings),
    ]
)
