// swift-tools-version:5.10
import CompilerPluginSupport
import Foundation
import PackageDescription

/// Settings to be passed to swiftc for all targets.

let allTargetsSwiftSettings: [SwiftSetting] = [
  .unsafeFlags(["-warnings-as-errors"])
]

/// Dependencies for documentation extraction.

let docGenerationDependency: [Package.Dependency] =
  ProcessInfo.processInfo.environment["HYLO_ENABLE_DOC_GENERATION"] != nil
  ? [.package(url: "https://github.com/apple/swift-docc-plugin.git", from: "1.1.0")] : []

/// Dependencies for documentation extraction.

let package = Package(
  name: "HyloDoc",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .executable(name: "hdc", targets: ["hdc"])  // Hylo Documentation Compiler (hdc)
    //.library(name: "FrontEnd", targets: ["DocExtractor"]), without this XCode can create a build process
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.4.0"),
    .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-format", branch: "release/5.10"),
    // .package(url: "https://github.com/hylo-lang/hylo", branch: "main"),
    .package(
      url: "https://github.com/tothambrus11/hylo.git",
      branch: "expose-lookup-through-typed-program2"),
    .package(url: "https://github.com/objecthub/swift-markdownkit.git", from: "1.1.8"),
    .package(url: "https://github.com/pavel-trafimuk/Stencil", branch: "master"),
    .package(url: "https://github.com/tid-kijyun/Kanna.git", from: "5.2.2"),
    .package(url: "https://github.com/apple/swift-syntax.git", branch: "release/5.10"),

    // Web server for preview:

    // A server-side Swift web framework.
    // Non-blocking, event-driven networking for Swift. Used for custom executors
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .executableTarget(
      name: "hdc",
      dependencies: [
        "CLI"
      ],
      path: "Sources/hdc",
      swiftSettings: allTargetsSwiftSettings),
    .target(
      name: "HDCUtils",
      dependencies: [
        "HyloStandardLibrary",
        "HDCMacros",
        .product(name: "FrontEnd", package: "hylo"),
      ],
      swiftSettings: allTargetsSwiftSettings),
    .target(
      name: "CLI",
      dependencies: [
        "DocExtractor",
        "WebsiteGen",
        "HyloStandardLibrary",
        .product(name: "FrontEnd", package: "hylo"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "NIOCore", package: "swift-nio"),
        .product(name: "NIOPosix", package: "swift-nio"),
      ],
      path: "Sources/CLI",
      exclude: ["module.md"],
      swiftSettings: allTargetsSwiftSettings),
    .target(
      name: "DocumentationDB",
      dependencies: [
        "HDCUtils",
        .product(name: "FrontEnd", package: "hylo"),
        .product(name: "MarkdownKit", package: "swift-markdownkit"),
      ],
      exclude: ["module.md"],
      swiftSettings: allTargetsSwiftSettings),
    .target(
      name: "DocExtractor",
      dependencies: [
        "DocumentationDB",
        .product(name: "MarkdownKit", package: "swift-markdownkit"),
        .product(name: "FrontEnd", package: "hylo"),
        // todo add this once Hylo exports the library properly: .product(name: "FrontEnd", package: "hylo"),
      ],
      exclude: ["module.md"],
      swiftSettings: allTargetsSwiftSettings),
    .target(
      name: "WebsiteGen",
      dependencies: [
        "DocExtractor",
        "DocumentationDB",
        .product(name: "DequeModule", package: "swift-collections"),
        .product(name: "Stencil", package: "stencil"),
      ],
      exclude: ["module.md"],
      resources: [.copy("Resources/")],
      swiftSettings: allTargetsSwiftSettings),
    .macro(
      name: "HDCMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ],
      swiftSettings: allTargetsSwiftSettings),
    .testTarget(
      name: "WebsiteGenTests",
      dependencies: [
        "WebsiteGen",
        "HyloStandardLibrary",
        "TestUtils",
        "Kanna",
      ],
      exclude: ["module.md"],
      swiftSettings: allTargetsSwiftSettings),
    .testTarget(
      name: "DocExtractorTests",
      dependencies: [
        "DocExtractor",
        "HyloStandardLibrary",
        "TestUtils",
      ],
      exclude: ["module.md"],
      swiftSettings: allTargetsSwiftSettings),
    .testTarget(
      name: "DocumentationDBTests",
      dependencies: ["DocumentationDB", "TestUtils"],
      exclude: ["module.md"],
      swiftSettings: allTargetsSwiftSettings),
    .testTarget(
      name: "CLITests",
      dependencies: ["hdc", "TestUtils"],
      exclude: ["module.md"],
      swiftSettings: allTargetsSwiftSettings),
    .testTarget(
      name: "TestUtils",
      dependencies: [
        "DocumentationDB",
        .product(name: "FrontEnd", package: "hylo"),
      ],
      exclude: [],
      swiftSettings: allTargetsSwiftSettings),
    .testTarget(
      name: "HDCMacrosTests",
      dependencies: [
        "HDCMacros",
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ],
      swiftSettings: allTargetsSwiftSettings),
    .testTarget(
      name: "HDCUtilsTests",
      dependencies: [
        "HDCUtils",
        "TestUtils",
        .product(name: "FrontEnd", package: "hylo"),
      ],
      path: "Tests/HDCUtilsTests",
      swiftSettings: allTargetsSwiftSettings),
    .target(
      name: "HyloStandardLibrary",
      dependencies: [.product(name: "FrontEnd", package: "hylo")],
      path: "Sources/StandardLibrary",
      resources: [.copy("Sources")],
      swiftSettings: allTargetsSwiftSettings
    ),
  ]
)
