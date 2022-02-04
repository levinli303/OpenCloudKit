import XCTest
@testable import OpenCloudKit

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(CoreLocation)
import CoreLocation

typealias CKRecord = OpenCloudKit.CKRecord
typealias CKContainer = OpenCloudKit.CKContainer
typealias CKRecordValue = OpenCloudKit.CKRecordValue
typealias CKAsset = OpenCloudKit.CKAsset

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.longitude == rhs.longitude && lhs.latitude == rhs.latitude
    }
}
#endif

extension CKDatabase {
    var account: CKAccount {
        return CloudKit.shared.account(forContainer: container)!
    }
}

class CKTest: XCTestCase {
    enum Constant {
        static let containerID = "iCloud.bilgisayar.CKDemo"
        static let token = "6e6d25238b580815a6be02c46803b53f86e7c065a97290726a5cbc8f0ee62917"
        static let environment = CKEnvironment.development
    }

    private class CloudKitHelper {
        class func configure(containerID: String, token: String, environment: CKEnvironment) {
            let defaultContainerConfig = CKContainerConfig(containerIdentifier: containerID, environment: environment, apiTokenAuth: token, apnsEnvironment: nil)
            let config = CKConfig(containers: [defaultContainerConfig])

            CloudKit.shared.configure(with: config)
        }
    }

    override class func setUp() {
        super.setUp()

        FileManager.default.changeCurrentDirectoryPath(Bundle.module.resourcePath!)
        CloudKitHelper.configure(containerID: Constant.containerID, token: Constant.token, environment: Constant.environment)
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
