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
    // On-device inference. Commented out because the adapter in
    // Sources/BridgeKit/Core/MLXEngine.swift was written without a compiler to
    // check it against, and MLX's module names and signatures move between
    // versions. Uncomment, resolve, and verify the four calls in that file —
    // nothing else in BridgeKit references MLX.
    //
    // dependencies: [
    //     .package(url: "https://github.com/ml-explore/mlx-swift-examples", from: "2.0.0"),
    // ],
    targets: [
        .target(
            name: "BridgeKit",
            // dependencies: [
            //     .product(name: "MLXLLM", package: "mlx-swift-examples"),
            //     .product(name: "MLXLMCommon", package: "mlx-swift-examples"),
            // ],
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
