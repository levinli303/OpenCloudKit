// swift-tools-version:4.1
import PackageDescription

let package = Package(
    name: "OpenCloudKit",
    products: [
    	.library(name: "OpenCloudKit", targets: ["OpenCloudKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/HeartedApp/clibressl.git", from: "1.0.2"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.0.0"),
    ],
    targets: [
    	.target(name: "OpenCloudKit", dependencies: [
    		"CLibreSSL",
    		"CryptoSwift",
    	])
    ]
)
