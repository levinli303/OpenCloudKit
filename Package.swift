// swift-tools-version:4.1
import PackageDescription

let package = Package(
    name: "OpenCloudKit",
    products: [
    	.library(name: "OpenCloudKit", targets: ["OpenCloudKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jsorge/clibressl.git", from: "1.0.1"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "0.11.0"),
    ],
    targets: [
    	.target(name: "OpenCloudKit", dependencies: [
    		"CLibreSSL",
    		"CryptoSwift",
    	])
    ]
)
