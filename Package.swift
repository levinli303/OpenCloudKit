// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "OpenCloudKit",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "OpenCloudKit", targets: ["OpenCloudKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio-ssl", from: "2.10.0")
    ],
    targets: [
        .target(name: "OpenCloudKit", dependencies: [
            .product(name: "NIOSSL", package: "swift-nio-ssl")
        ]),
        .testTarget(
            name: "OpenCloudKitTests",
            dependencies: ["OpenCloudKit"],
            resources: [.copy("eckey.pem"), .copy("asset1.txt"), .copy("asset2.txt")]
        ),
    ]
)
