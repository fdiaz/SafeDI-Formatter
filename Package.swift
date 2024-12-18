// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SafeDI-Formatter",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .macCatalyst(.v13),
    .visionOS(.v1),
  ],
  products: [
    .executable(name: "safedi-formatter", targets: ["CLI"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    .package(
      url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0"),
  ],
  targets: [
    .executableTarget(
      name: "CLI",
      dependencies: [
        "SDFCore",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    .target(
      name: "SDFCore",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
      ],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
    .testTarget(
      name: "SDFCoreTests",
      dependencies: ["SDFCore"],
      swiftSettings: [.swiftLanguageMode(.v6)]
    ),
  ]
)
