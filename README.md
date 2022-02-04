# OpenCloudKit
An open source framework for CloudKit written in Swift and inspired by Apple's CloudKit framework.
OpenCloudKit is backed by CloudKit Web Services and is designed to allow easy CloudKit integration into Swift Servers whilst being familiar for developers who have experience with CloudKit on Apple's platforms.

## Features

- [x] Fully featured wrapper around CloudKit Web Services
- [x] Same API as Apple's CloudKit
- [x] Supports all major operations supported by Apple’s CloudKit Framework
- [x] Server-to-Server Key Auth Support

# Installation

## Swift Package Manager
Add the following to dependencies in your `Package.swift`.
```swift
.Package(url: "https://github.com/BennyKJohnson/OpenCloudKit.git", majorVersion: 0, minor: 5)
```
Or create the 'Package.swift' file for your project and add the following:
```swift
import PackageDescription

let package = Package(
	dependencies: [
		.Package(url: "https://github.com/BennyKJohnson/OpenCloudKit.git", majorVersion: 0, minor: 5),
	]
)
```

# Getting Started
## Configure OpenCloudKit
Configuring OpenCloudKit is similar to configuring CloudKitJS. Use the `CloudKit.shared.configure(with: CKConfig)` method to config OpenCloudKit with a `CKConfig` instance.
### Configuration
Server to Server
```swift
let serverKeyAuth = CKServerToServerKeyAuth(keyID: "[KEY ID]", privateKeyFile: "eckey.pem")
let defaultContainerConfig = CKContainerConfig(containerIdentifier: "[CONTAINER ID]", environment: .development, serverToServerKeyAuth: serverKeyAuth)
let config = CKConfig(containers: [defaultContainerConfig])

CloudKit.shared.configure(with: config)
```
API Token
```swift
let serverKeyAuth = CKServerToServerKeyAuth(keyID: "[KEY ID]", privateKeyFile: "eckey.pem")
let defaultContainerConfig = CKContainerConfig(containerIdentifier: "[CONTAINER ID]", environment: .development, apiTokenAuth: "[API TOKEN]", webAuthToken: "[WEB AUTH TOKEN]")

CloudKit.shared.configure(with: config)
```
## Working with OpenCloudKit
Get the database in your app’s default container
```swift
let container = CKContainer.default()
let database = container.publicCloudDatabase
```

### Creating a record
```swift
let movieRecord = CKRecord(recordType: "Movie")
movieRecord["title"] = "Finding Dory"
movieRecord["directors"] = ["Andrew Stanton", "Angus MacLane"]
```
### Saving a record
```swift
database.save(record: movieRecord) { (movieRecord, error) in
    if let savedRecord = movieRecord {
        // Insert Successfully saved record code

    } else if let error = error {
        // Insert error handling
    }
}
```
