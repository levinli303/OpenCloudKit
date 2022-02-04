// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "OpenCloudKit",
    platforms: [
        .macOS("12.0"), .iOS("15.0"), .watchOS("8.0"), .tvOS("15.0")
    ],
    products: [
        .library(name: "OpenCloudKit", targets: ["OpenCloudKit"]),
        .library(name: "CloudKitCodable", targets: ["CloudKitCodable"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "3.0.0"),
    ],
    targets: [
        .target(name: "OpenCloudKit", dependencies: [
            .product(name: "Crypto", package: "swift-crypto"),
        ]),
        .target(name: "CloudKitCodable", dependencies: [
            .target(name: "OpenCloudKit"),
        ]),
        .testTarget(
            name: "OpenCloudKitTests",
            dependencies: ["OpenCloudKit"],
            resources: [.copy("asset1.txt"), .copy("asset2.txt")]
        ),
    ]
)
