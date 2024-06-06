// swift-tools-version:5.10
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
    .executable(name: "hdc", targets: ["hdc"]),  // Hylo Documentation Compiler (hdc)
    //.library(name: "FrontEnd", targets: ["DocExtractor"]), without this XCode can create a build process
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.4.0"),
    .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-format", branch: "release/5.10"),
    // .package(url: "https://github.com/hylo-lang/hylo", branch: "main"),
    .package(url: "https://github.com/tothambrus11/hylo.git", branch: "publish-lookup-functions"),
    .package(url: "https://github.com/objecthub/swift-markdownkit.git", from: "1.1.8"),
    .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.15.1"),
    .package(url: "https://github.com/sersoft-gmbh/path-wrangler", from: "2.0.0"),
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
      name: "CLI",
      dependencies: [
        "DocExtractor",
        "WebsiteGen",
        "StandardLibraryCore",
        .product(name: "FrontEnd", package: "hylo"),
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ],
      path: "Sources/CLI",
      exclude: ["module.md"],
      swiftSettings: allTargetsSwiftSettings),
    .target(
      name: "DocumentationDB",
      dependencies: [
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
        .product(name: "PathWrangler", package: "path-wrangler"),
      ],
      exclude: ["module.md"],
      resources: [.copy("Resources/")],
      swiftSettings: allTargetsSwiftSettings),
    .testTarget(
      name: "WebsiteGenTests",
      dependencies: ["WebsiteGen", "StandardLibraryCore"],
      exclude: ["module.md"],
      swiftSettings: allTargetsSwiftSettings),
    .testTarget(
      name: "DocExtractorTests",
      dependencies: ["DocExtractor", "StandardLibraryCore"],
      exclude: ["module.md"],
      swiftSettings: allTargetsSwiftSettings),
    .testTarget(
      name: "DocumentationDBTests",
      dependencies: ["DocumentationDB"],
      exclude: ["module.md"],
      swiftSettings: allTargetsSwiftSettings),
    .testTarget(
      name: "CLITests",
      dependencies: ["hdc"],
      exclude: ["module.md"],
      swiftSettings: allTargetsSwiftSettings),
    .target(
      name: "StandardLibraryCore",
      dependencies: [.product(name: "FrontEnd", package: "hylo")],
      resources: [.copy("StandardLibraryCoreResource")],
      swiftSettings: allTargetsSwiftSettings
    ),
  ]
)
