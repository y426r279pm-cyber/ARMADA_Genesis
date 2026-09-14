// swift-tools-version: 5.9
import PackageDescription

// BridgeKit holds everything generated from the prototype plus the model layer.
// The app targets (macOS, iPadOS) sit above it and are added in phase 1.
let package = Package(
    name: "Bridge",
    defaultLocalization: "en",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "BridgeKit", targets: ["BridgeKit"])
    ],
    targets: [
        .target(
            name: "BridgeKit",
            resources: [
                .process("Resources/Colors.xcassets"),
                .process("Resources/Localizable.xcstrings"),
                .copy("Resources/Seed.json"),
            ]
        ),
        .testTarget(
            name: "BridgeKitTests",
            dependencies: ["BridgeKit"],
            resources: [.copy("Fixtures/ChainFixture.json")]
        ),
    ]
)
