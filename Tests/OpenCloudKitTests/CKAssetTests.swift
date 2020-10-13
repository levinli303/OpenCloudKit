import XCTest
import Foundation
@testable import OpenCloudKit

class CKAssetTests: XCTestCase {
    override class func setUp() {
        super.setUp()

        FileManager.default.changeCurrentDirectoryPath(Constant.launchDirectory)
        CloudKitHelper.configure(containerID: Constant.containerID, keyID: Constant.serverKeyID, privateKeyFile: Constant.keyFilePath, environment: Constant.environment)
    }

    func testCreateRecordWithAsset() {
        let db = CKContainer.default().publicCloudDatabase
        let id = UUID().uuidString
        let record = CKRecord(recordType: "Quanzi", recordID: CKRecordID(recordName: id))
        record["content"] = "my test text" as CKRecordValue
        record["id"] = id as CKRecordValue
        record["type"] = 1 as CKRecordValue
        record["editor"] = "Developer" as CKRecordValue
        record["image"] = CKAsset(fileURL: URL(fileURLWithPath: "splash.png"))

        let expectation = XCTestExpectation(description: "ensureExecuteOnMainThread")
        db.save(record: record) { record, error in
            XCTAssertNil(error)
            XCTAssertNotNil(record)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }
}
