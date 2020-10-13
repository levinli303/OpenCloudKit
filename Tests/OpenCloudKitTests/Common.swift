import XCTest
@testable import OpenCloudKit

class CloudKitHelper {
    class func configure(containerID: String, keyID: String, privateKeyFile: String, environment: CKEnvironment) {
        let serverKeyAuth = CKServerToServerKeyAuth(keyID: keyID, privateKeyFile: privateKeyFile)
        let defaultContainerConfig = CKContainerConfig(containerIdentifier: containerID, environment: environment, serverToServerKeyAuth: serverKeyAuth)
        let config = CKConfig(containers: [defaultContainerConfig])

        CloudKit.shared.configure(with: config)
    }
}

enum Constant {
    static let serverKeyID = "997f8348f290c1906471d8431286b39eba12e0778c948bef57438971932b9d3a"
    static let containerID = "iCloud.com.meowssage.Astroweather"
    static let keyFilePath = "eckey.pem"
    static let environment = CKEnvironment.production
    static let launchDirectory = "/Users/linfel/Developer/Personal/Astroweather/tlecreator"
}
