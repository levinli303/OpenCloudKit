// swift-tools-version:4.1
import PackageDescription

#if os(Linux)
    let cOpenSSLRepo = "https://github.com/PerfectlySoft/Perfect-COpenSSL-Linux.git"
#else
    let cOpenSSLRepo = "https://github.com/PerfectlySoft/Perfect-COpenSSL.git"
#endif

let package = Package(
    name: "OpenCloudKit",
    products: [
    	.library(name: "OpenCloudKit", targets: ["OpenCloudKit"]),
    ],
    dependencies: [
        .package(url: cOpenSSLRepo, from: "4.0.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "0.11.0"),
    ],
    targets: [
    	.target(name: "OpenCloudKit", dependencies: [
    		"COpenSSL",
    		"CryptoSwift",
    	])
    ]
)
