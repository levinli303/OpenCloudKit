// swift-tools-version:5.5
import PackageDescription

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
let dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-crypto.git", .exact("2.0.5")),
]
#else
let dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-crypto.git", "2.2.4" ..< "3.0.0"),
]
#endif

let package = Package(
    name: "OpenCloudKit",
    platforms: [
        .macOS("12.0"), .iOS("15.0"), .watchOS("8.0"), .tvOS("15.0")
    ],
    products: [
        .library(name: "OpenCloudKit", targets: ["OpenCloudKit"]),
        .library(name: "CloudKitCodable", targets: ["CloudKitCodable"]),
    ],
    dependencies: dependencies + [
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0")
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
            dependencies: ["OpenCloudKit"],
            resources: [.copy("asset1.txt"), .copy("asset2.txt")]
        ),
    ]
)
