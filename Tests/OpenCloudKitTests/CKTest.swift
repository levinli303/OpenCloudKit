import XCTest
@testable import OpenCloudKit

#if !os(iOS) && !os(macOS) && os(watchOS) && !os(tvOS)
import FoundationNetworking
#endif

class CKTest: XCTestCase {
    enum Constant {
        static let serverKeyID = "374fcb3cd8dde079ce34c523d67507b66ea778d0bdd94bf9411fb05649d67492"
        static let containerID = "iCloud.bilgisayar.CKDemo"
        static let keyFilePath = "eckey.pem"
        static let environment = CKEnvironment.development
    }

    private class CloudKitHelper {
        class func configure(containerID: String, keyID: String, privateKeyFile: String, environment: CKEnvironment) {
            let serverKeyAuth = try! CKServerToServerKeyAuth(keyID: keyID, privateKeyFile: privateKeyFile)
            let defaultContainerConfig = CKContainerConfig(containerIdentifier: containerID, environment: environment, serverToServerKeyAuth: serverKeyAuth)
            let config = CKConfig(containers: [defaultContainerConfig])

            CloudKit.shared.configure(with: config)
        }
    }

    override class func setUp() {
        super.setUp()

        FileManager.default.changeCurrentDirectoryPath(Bundle.module.resourcePath!)
        CloudKitHelper.configure(containerID: Constant.containerID, keyID: Constant.serverKeyID, privateKeyFile: Constant.keyFilePath, environment: Constant.environment)
    }

    func requestURL(_ url: URL) -> Data? {
        let expectation = XCTestExpectation(description: "Waiting for download to finish")
        var resultData: Data?
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            resultData = data
            expectation.fulfill()
        }
        task.resume()
        wait(for: [expectation], timeout: 10.0)
        return resultData
    }
}
