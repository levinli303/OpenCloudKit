//
//  CKRecordTests.swift
//  
//
//  Created by Levin Li on 2020/10/13.
//

import XCTest
import Foundation
@testable import OpenCloudKit

class CKRecordTests: CKTest {
    static var recordType = "TestData"

    enum Constant {
        static let bytesValue = Data(repeating: 0, count: 10)
        static let bytesListValue = (0..<8).map({ Data(repeating: $0, count: 10) })
        static let stringValue = "string"
        static let stringListValue = ["string0", "string1", "string2"]
        static let int64Value: Int64 = 0
        static let int64ListValue: [Int64] = [0, 1, 2, 3]
        static let doubleValue: Double = 0.0
        static let doubleListValue: [Double] = [0.0, 1.0, 2.0, 3.0]
        static let dateValue: Date = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
            formatter.timeZone = TimeZone(abbreviation: "GMT")
            return formatter.date(from: "2000/01/01 01:01:01")!
        }()
        static let dateListValue: [Date] = [
            dateValue,
            dateValue.addingTimeInterval(60),
            dateValue.addingTimeInterval(120)
        ]
        static let locationValue: CKLocation = CKLocation(latitude: 0.0, longitude: 0.0)
        static let locationListValue: [CKLocation] = [
            CKLocation(latitude: 0.0, longitude: 0.0),
            CKLocation(latitude: 1.0, longitude: 2.0),
            CKLocation(latitude: 1.0, longitude: 2.0),
        ]
    }

    func testCreateRecord() {
        let db = CKContainer.default().publicCloudDatabase
        if db.account.isAnonymousAccount { return }
        let id = UUID().uuidString
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["bytes"] = Constant.bytesValue
        record["bytesList"] = Constant.bytesListValue
        record["string"] = Constant.stringValue
        record["stringList"] = Constant.stringListValue
        record["int64"] = Constant.int64Value
        record["int64List"] = Constant.int64ListValue
        record["double"] = Constant.doubleValue
        record["doubleList"] = Constant.doubleListValue
        record["date"] = Constant.dateValue
        record["dateList"] = Constant.dateListValue
        record["location"] = Constant.locationValue
        record["locationList"] = Constant.locationListValue
        let expectation = XCTestExpectation(description: "Wait for response")
        db.save(record) { record, error in
            XCTAssertNil(error)
            XCTAssertNotNil(record)

            let newRecord = record!
            XCTAssertEqual(newRecord["bytes"] as! Data, Constant.bytesValue)
            XCTAssertEqual(newRecord["bytesList"] as! [Data], Constant.bytesListValue)
            XCTAssertEqual(newRecord["string"] as! String, Constant.stringValue)
            XCTAssertEqual(newRecord["stringList"] as! [String], Constant.stringListValue)
            XCTAssertEqual(newRecord["int64"] as! Int64, Constant.int64Value)
            XCTAssertEqual(newRecord["int64List"] as! [Int64], Constant.int64ListValue)
            XCTAssertEqual(newRecord["double"] as! Double, Constant.doubleValue)
            XCTAssertEqual(newRecord["doubleList"] as! [Double], Constant.doubleListValue)
            XCTAssertEqual(newRecord["date"] as! Date, Constant.dateValue)
            XCTAssertEqual(newRecord["dateList"] as! [Date], Constant.dateListValue)
            XCTAssertEqual((newRecord["location"] as! CKLocation).coordinate, Constant.locationValue.coordinate)
            XCTAssertEqual((newRecord["locationList"] as! [CKLocation]).map { $0.coordinate }, Constant.locationListValue.map { $0.coordinate })
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func testFetchRecord() {
        let db = CKContainer.default().publicCloudDatabase
        let expectation = XCTestExpectation(description: "Wait for response")
        let recordID = CKRecord.ID(recordName: "E2F5C6D8-31F6-4A6D-B018-4C629DCB3FF3")
        db.fetch(withRecordID: recordID) { record, error in
            XCTAssertNil(error)
            XCTAssertNotNil(record)

            let newRecord = record!
            XCTAssertEqual(newRecord["string"] as! String, Constant.stringValue)
            XCTAssertEqual(newRecord["stringList"] as! [String], Constant.stringListValue)
            XCTAssertEqual(newRecord["int64"] as! Int64, Constant.int64Value)
            XCTAssertEqual(newRecord["int64List"] as! [Int64], Constant.int64ListValue)
            XCTAssertEqual(newRecord["double"] as! Double, Constant.doubleValue)
            XCTAssertEqual(newRecord["doubleList"] as! [Double], Constant.doubleListValue)
            XCTAssertEqual(newRecord["date"] as! Date, Constant.dateValue)
            XCTAssertEqual(newRecord["dateList"] as! [Date], Constant.dateListValue)
            XCTAssertEqual((newRecord["location"] as! CKLocation).coordinate, Constant.locationValue.coordinate)
            XCTAssertEqual((newRecord["locationList"] as! [CKLocation]).map { $0.coordinate }, Constant.locationListValue.map { $0.coordinate })
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func testFetchRecordWithAsset() {
        let db = CKContainer.default().publicCloudDatabase
        let expectation = XCTestExpectation(description: "Wait for response")
        let recordID = CKRecord.ID(recordName: "7301F079-0298-4DED-8948-8A1286C84653")
        db.fetch(withRecordID: recordID) { record, error in
            XCTAssertNil(error)
            XCTAssertNotNil(record)

            let newRecord = record!
            let asset = newRecord["asset"] as! CKAsset
            let assetContent = String(data: self.requestURL(asset.downloadURL!)!, encoding: .utf8)
            XCTAssertEqual(assetContent, "1\n")

            let assetList = newRecord["assetList"] as! [CKAsset]
            XCTAssertEqual(assetList.count, 4)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func testCreateRecordWithAsset() {
        let db = CKContainer.default().publicCloudDatabase
        if db.account.isAnonymousAccount { return }
        let id = UUID().uuidString
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["asset"] = CKAsset(fileURL: URL(fileURLWithPath: "asset1.txt"))
        record["assetList"] = [CKAsset(fileURL: URL(fileURLWithPath: "asset1.txt")), CKAsset(fileURL: URL(fileURLWithPath: "asset2.txt"))]
        let expectation = XCTestExpectation(description: "Wait for response")
        db.save(record) { record, error in
            XCTAssertNil(error)
            XCTAssertNotNil(record)

            let newRecord = record!
            let asset = newRecord["asset"] as! CKAsset
            let assetContent = String(data: self.requestURL(asset.downloadURL!)!, encoding: .utf8)
            XCTAssertEqual(assetContent, "1\n")

            let assetList = newRecord["assetList"] as! [CKAsset]
            XCTAssertEqual(assetList.count, 2)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func testCreateRecordAnonymous() {
        let db = CKContainer.default().publicCloudDatabase
        if !db.account.isAnonymousAccount { return }
        let id = UUID().uuidString
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["string"] = Constant.stringValue
        let expectation = XCTestExpectation(description: "Wait for response")
        db.save(record) { record, error in
            XCTAssertNil(record)
            XCTAssertNotNil(error)

            guard let error = error as? CKError else {
                XCTFail("An unknown type of error is returned, expected CKError")
                return
            }

            switch error {
            case .requestError(let error):
                XCTAssertEqual(error.serverErrorCode, .authenticationRequired)
            default:
                XCTFail("Incorrect CKError is returned, expected requestError")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func testFetchLimit() {
        let resultLimit = 1
        let db = CKContainer.default().publicCloudDatabase
        let query = CKQuery(recordType: Self.recordType, filters: [])
        let op = CKQueryOperation(query: query)
        op.resultsLimit = resultLimit
        var records: [CKRecord] = []
        op.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                records.append(record)
            case .failure(let error):
                XCTFail("Error occured on record match \(error)")
            }
        }
        let expectation = XCTestExpectation(description: "Wait for response")
        op.queryResultBlock = { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Error occured on completion \(error)")
            }
        }
        db.add(op)
        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(records.count, resultLimit)
    }

    func testDesiredKeys() {
        let db = CKContainer.default().publicCloudDatabase
        let recordID = CKRecord.ID(recordName: "043BB555-EA0D-487E-BCC4-257184A5078C")
        let reference = CKReference(recordID: recordID, action: .none)
        let query = CKQuery(recordType: Self.recordType, filters: [
            CKQueryFilter(fieldName: "___recordID", comparator: .equals, fieldValue: reference)
        ])
        let op = CKQueryOperation(query: query)
        op.resultsLimit = 1
        op.desiredKeys = ["string", "int64", "double"]
        var records: [CKRecord] = []
        op.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                records.append(record)
            case .failure(let error):
                XCTFail("Error occured on record match \(error)")
            }
        }
        let expectation = XCTestExpectation(description: "Wait for response")
        op.queryResultBlock = { result in
            switch result {
            case .success:
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Error occured on completion \(error)")
            }
        }
        db.add(op)
        wait(for: [expectation], timeout: 10)
        for record in records {
            XCTAssertNotNil(record["string"])
            XCTAssertNotNil(record["int64"])
            XCTAssertNotNil(record["double"])
            XCTAssertNil(record["stringList"])
            XCTAssertNil(record["int64List"])
            XCTAssertNil(record["doubleList"])
        }
    }

    func testFetchUnknownRecord() {
        let db = CKContainer.default().publicCloudDatabase
        let expectation = XCTestExpectation(description: "Wait for response")
        let recordID = CKRecord.ID(recordName: "DO-NOT-CREATE")
        db.fetch(withRecordID: recordID) { record, error in
            XCTAssertNil(record)
            XCTAssertNotNil(error)
            guard let error = error as? CKError else {
                XCTFail("An unknown type of error is returned, expected CKError")
                return
            }

            switch error {
            case .recordFetchError(let error):
                XCTAssertEqual(error.serverErrorCode, .notFound)
            default:
                XCTFail("Incorrect CKError is returned, expected recordFetchError")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func testDeleteUnknownRecord() {
        // This should succeed as the record never exists
        let db = CKContainer.default().publicCloudDatabase
        if db.account.isAnonymousAccount { return }
        let expectation = XCTestExpectation(description: "Wait for response")
        let recordID = CKRecord.ID(recordName: "DO-NOT-CREATE")
        db.delete(withRecordID: recordID) { record, error in
            XCTAssertNil(error)
            XCTAssertNotNil(record)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func testModifyAndDeleteUnknownRecord() {
        let db = CKContainer.default().publicCloudDatabase
        if db.account.isAnonymousAccount { return }
        let expectation1 = XCTestExpectation(description: "Wait for record fetch to finish")
        var existing: CKRecord?
        db.fetch(withRecordID: CKRecord.ID(recordName: "8BDA40C6-DB7C-BA3D-33AA-FF4C9B9D077A")) { record, error in
            XCTAssertNil(error)
            XCTAssertNotNil(record)
            existing = record
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 10)
        let recordToSave = existing!
        guard let recordIntValue = recordToSave["int64"] as? Int64 else {
            XCTFail("int64 field is missing on the record")
            return
        }
        let newValue = recordIntValue == .max ? Int64.min : recordIntValue + 1
        recordToSave["int64"] = newValue
        let nonExistingRecordID = CKRecord.ID(recordName: "DO-NOT-CREATE")
        let operation = CKModifyRecordsOperation(recordsToSave: [recordToSave], recordIDsToDelete: [nonExistingRecordID])
        operation.savePolicy = .ifServerRecordUnchanged
        var savedRecord: CKRecord?
        var deletedRecordID: CKRecord.ID?
        let expectation2 = XCTestExpectation(description: "Wait for record modify to finish")
        operation.perRecordSaveBlock = { recordID, result in
            XCTAssertEqual(recordID.recordName, recordToSave.recordID.recordName)
            switch result {
            case .success(let record):
                savedRecord = record
            case .failure(let error):
                XCTFail("Record modify failed with error \(error)")
            }
        }
        operation.perRecordDeleteBlock = { recordID, result in
            XCTAssertEqual(recordID.recordName, nonExistingRecordID.recordName)
            switch result {
            case .success:
                deletedRecordID = recordID
            case .failure(let error):
                XCTFail("Record delete failed with error \(error)")
            }
        }
        operation.modifyRecordsResultBlock = { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Overall operation failed with error \(error)")
            }
            expectation2.fulfill()
        }
        db.add(operation)
        wait(for: [expectation2], timeout: 10)
        XCTAssertEqual(savedRecord?["int64"] as? Int64, newValue)
        XCTAssertEqual(deletedRecordID?.recordName, nonExistingRecordID.recordName)
    }

    func testCreateRecordUnknownType() {
        let db = CKContainer.default().publicCloudDatabase
        if db.account.isAnonymousAccount { return }
        let expectation = XCTestExpectation(description: "Wait for response")
        let recordID = CKRecord.ID(recordName: "qrqwsnjjfsfsdf")
        db.save(CKRecord(recordType: "blah blah", recordID: recordID)) { record, error in
            XCTAssertNil(record)
            XCTAssertNotNil(error)
            guard let error = error as? CKError else {
                XCTFail("An unknown type of error is returned, expected CKError")
                return
            }

            switch error {
            case .recordFetchError(let error):
                XCTAssertEqual(error.serverErrorCode, .notFound)
            default:
                XCTFail("Incorrect CKError is returned, expected recordFetchError")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func testCreateExistingRecord() {
        let db = CKContainer.default().publicCloudDatabase
        if db.account.isAnonymousAccount { return }
        let expectation = XCTestExpectation(description: "Wait for response")
        let recordID = CKRecord.ID(recordName: "08099BD9-ED8C-4175-B528-3CFD363ECA2E")
        db.save(CKRecord(recordType: Self.recordType, recordID: recordID)) { record, error in
            XCTAssertNil(record)
            XCTAssertNotNil(error)
            guard let error = error as? CKError else {
                XCTFail("An unknown type of error is returned, expected CKError")
                return
            }

            switch error {
            case .recordFetchError(let error):
                XCTAssertEqual(error.serverErrorCode, .conflict)
            default:
                XCTFail("Incorrect CKError is returned, expected recordFetchError")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func testCurosr() {
        let resultLimit = 1
        let db = CKContainer.default().publicCloudDatabase
        let query = CKQuery(recordType: Self.recordType, filters: [])
        let op = CKQueryOperation(query: query)
        op.resultsLimit = resultLimit
        var records: [CKRecord] = []
        op.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                records.append(record)
            case .failure(let error):
                XCTFail("Error occured on record match \(error)")
            }
        }
        let expectation = XCTestExpectation(description: "Wait for response")
        op.queryResultBlock = { result in
            switch result {
            case .success(let cursor):
                guard let c = cursor else {
                    XCTFail("Cursor should be returned for this operation")
                    return
                }
                let continuedOperation = CKQueryOperation(cursor: c)
                continuedOperation.resultsLimit = resultLimit
                continuedOperation.recordMatchedBlock = { _, result in
                    switch result {
                    case .success(let record):
                        records.append(record)
                    case .failure(let error):
                        XCTFail("Error occured on record match \(error)")
                    }
                }
                continuedOperation.queryResultBlock = { result in
                    switch result {
                    case .success:
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Error occured on completion \(error)")
                    }
                }
                db.add(continuedOperation)
            case .failure(let error):
                XCTFail("Error occured on completion \(error)")
            }
        }
        db.add(op)
        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(records.count, resultLimit * 2)
    }

    func testNoCurosr() {
        let resultLimit = 1
        let db = CKContainer.default().publicCloudDatabase
        let reference = CKReference(recordID: CKRecord.ID(recordName: "043BB555-EA0D-487E-BCC4-257184A5078C"), action: .none)
        let query = CKQuery(recordType: Self.recordType, filters: [
            CKQueryFilter(fieldName: "___recordID", comparator: .equals, fieldValue: reference)
        ])
        let op = CKQueryOperation(query: query)
        op.resultsLimit = resultLimit
        var records: [CKRecord] = []
        op.recordMatchedBlock = { _, result in
            switch result {
            case .success(let record):
                records.append(record)
            case .failure(let error):
                XCTFail("Error occured on record match \(error)")
            }
        }
        let expectation = XCTestExpectation(description: "Wait for response")
        op.queryResultBlock = { result in
            switch result {
            case .success(let cursor):
                XCTAssertNil(cursor, "Cursor should not be returned for this operation")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Error occured on completion \(error)")
            }
        }
        db.add(op)
        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(records.count, 1)
    }

    func testFetchDefaultRecordZone() async {
        let db = CKContainer.default().publicCloudDatabase
        // Zone lookup is not allowed on anonymous account too
        if db.account.isAnonymousAccount { return }
        let expectation = XCTestExpectation(description: "Wait for response")
        db.fetch(withRecordZoneID: .default) { zone, error in
            XCTAssertNotNil(zone)
            XCTAssertNil(error)
            XCTAssertEqual(zone?.zoneID.zoneName, CKRecordZone.ID.defaultZoneName)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func testOperationCancellation() {
        let db = CKContainer.default().publicCloudDatabase
        let query = CKQuery(recordType: Self.recordType, filters: [])
        let op = CKQueryOperation(query: query)
        let expectation = XCTestExpectation(description: "Wait for response")
        op.queryResultBlock = { result in
            switch result {
            case .success:
                XCTFail("A cancelled task should fail")
            case .failure(let error):
                do {
                    throw error
                }
                catch CKError.operationCancelled {
                    expectation.fulfill()
                }
                catch {
                    XCTFail("A cancelled task should have error CKError.operationCancelled")
                }
            }
        }
        db.add(op)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
            op.cancel()
        }
        wait(for: [expectation], timeout: 10)
    }

    static var allTests = [
        ("testCreateRecord", testCreateRecord),
        ("testFetchRecord", testFetchRecord),
        ("testFetchRecordWithAsset", testFetchRecordWithAsset),
        ("testCreateRecordWithAsset", testCreateRecordWithAsset),
        ("testCreateRecordAnonymous", testCreateRecordAnonymous),
        ("testFetchLimit", testFetchLimit),
        ("testDesiredKeys", testDesiredKeys),
        ("testFetchUnknownRecord", testFetchUnknownRecord),
        ("testCreateRecordUnknownType", testCreateRecordUnknownType),
        ("testDeleteUnknownRecord", testDeleteUnknownRecord),
        ("testCreateExistingRecord", testCreateExistingRecord),
        ("testCreateExistingRecord", testCreateExistingRecord),
        ("testCurosr", testCurosr),
        ("testNoCurosr", testNoCurosr),
        ("testOperationCancellation", testOperationCancellation),
    ]
}
