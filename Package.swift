// swift-tools-version:5.8
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
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.7.1"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.22.1")
    ],
    targets: [
        .target(name: "OpenCloudKit", dependencies: [
            .product(name: "AsyncHTTPClient", package: "async-http-client"),
            .product(name: "Crypto", package: "swift-crypto"),
        ]),
        .target(name: "CloudKitCodable", dependencies: [
            .target(name: "OpenCloudKit"),
        ]),
        .testTarget(
            name: "OpenCloudKitTests",
            dependencies: [
                .target(name: "OpenCloudKit"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ],
            resources: [.copy("asset1.txt"), .copy("asset2.txt")]
        ),
    ]
)
