// swift-tools-version:5.3
import PackageDescription

#if os(Linux)
    let cOpenSSLRepo = "https://github.com/PerfectlySoft/Perfect-COpenSSL-Linux.git"
#else
    let cOpenSSLRepo = "https://github.com/PerfectlySoft/Perfect-COpenSSL.git"
#endif

let package = Package(
    name: "OpenCloudKit",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(name: "OpenCloudKit", targets: ["OpenCloudKit"]),
    ],
    dependencies: [
        .package(name: "COpenSSL", url: cOpenSSLRepo, from: "4.0.2")
    ],
    targets: [
        .target(name: "OpenCloudKit", dependencies: [
            .product(name: "COpenSSL", package: "COpenSSL")
        ]),
        .testTarget(
            name: "OpenCloudKitTests",
            dependencies: ["OpenCloudKit"]
        ),
    ]
)
