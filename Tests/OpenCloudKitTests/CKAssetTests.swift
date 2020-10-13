import XCTest
import Foundation
@testable import OpenCloudKit

class CKAssetTests: XCTestCase {
    override class func setUp() {
        super.setUp()

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
        record["image"] = CKAsset(fileURL: URL(fileURLWithPath: "temp.jpg"))

        let expectation = XCTestExpectation(description: "Wait for finish")
        db.save(record: record) { record, error in
            XCTAssertNil(error)
            XCTAssertNotNil(record)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func testFetchRecordWithAsset() {
        let recordID = "3A5DDE96-0C61-46DE-BB8F-EBC2D4B08A14"
        let db = CKContainer.default().publicCloudDatabase
        let query = CKQuery(
            recordType: "Quanzi",
            filters: [CKQueryFilter(fieldName: "id", comparator: .equals, fieldValue: recordID)]
        )
        let op = CKQueryOperation(query: query)
        op.resultsLimit = 1
        var records = [CKRecord]()
        var error: Error?
        let expectation = XCTestExpectation(description: "Wait for finish")
        op.recordFetchedBlock = { record in
            records.append(record)
        }
        op.queryCompletionBlock = { cursor, e in
            error = e
            expectation.fulfill()
        }
        db.add(op)
        wait(for: [expectation], timeout: 10)
        XCTAssertNil(error)
        XCTAssertEqual(records.count, 1)
    }

    static var allTests = [
        ("testCreateRecordWithAsset", testCreateRecordWithAsset),
        ("testFetchRecordWithAsset", testFetchRecordWithAsset),
    ]
}
