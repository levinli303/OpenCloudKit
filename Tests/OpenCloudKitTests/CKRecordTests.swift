//
//  CKRecordTests.swift
//  
//
//  Created by Levin Li on 2020/10/13.
//

import XCTest
import Foundation
@testable import OpenCloudKit

class CKRecordTests: CKTest, @unchecked Sendable {
    static let recordType = "TestData"

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

    func testCreateRecord() async throws {
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
        let (saveResults, deleteResults) = try await db.modifyRecords(saving: [record], deleting: [])
        XCTAssertEqual(saveResults.count, 1)
        XCTAssertEqual(deleteResults.count, 0)
        let saveResult = saveResults.first!.value
        let newRecord = try saveResult.get()

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
    }

    func testFetchRecord() async throws {
        let db = CKContainer.default().publicCloudDatabase
        let recordID = CKRecord.ID(recordName: "E2F5C6D8-31F6-4A6D-B018-4C629DCB3FF3")
        let recordResults = try await db.records(for: [recordID])
        XCTAssertEqual(recordResults.count, 1)
        let recordResult = recordResults.first!.value
        let newRecord = try recordResult.get()
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
    }

    func testFetchRecordWithAsset() async throws {
        let db = CKContainer.default().publicCloudDatabase
        let recordID = CKRecord.ID(recordName: "7301F079-0298-4DED-8948-8A1286C84653")
        let recordResults = try await db.records(for: [recordID])
        XCTAssertEqual(recordResults.count, 1)
        let recordResult = recordResults.first!.value
        let newRecord = try recordResult.get()

        let asset = newRecord["asset"] as! CKAsset
        let assetContent = try await String(data: self.requestURL(asset.downloadURL!)!, encoding: .utf8)
        XCTAssertEqual(assetContent, "1\n")

        let assetList = newRecord["assetList"] as! [CKAsset]
        XCTAssertEqual(assetList.count, 4)
    }

    func testCreateRecordWithAsset() async throws {
        let db = CKContainer.default().publicCloudDatabase
        if db.account.isAnonymousAccount { return }
        let id = UUID().uuidString
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["asset"] = CKAsset(fileURL: URL(fileURLWithPath: "asset1.txt"))
        record["assetList"] = [CKAsset(fileURL: URL(fileURLWithPath: "asset1.txt")), CKAsset(fileURL: URL(fileURLWithPath: "asset2.txt"))]
        let (saveResults, deleteResults) = try await db.modifyRecords(saving: [record], deleting: [])
        XCTAssertEqual(saveResults.count, 1)
        XCTAssertEqual(deleteResults.count, 0)
        let saveResult = saveResults.first!.value
        let newRecord = try saveResult.get()
        let asset = newRecord["asset"] as! CKAsset
        let assetContent = try await String(data: self.requestURL(asset.downloadURL!)!, encoding: .utf8)
        XCTAssertEqual(assetContent, "1\n")

        let assetList = newRecord["assetList"] as! [CKAsset]
        XCTAssertEqual(assetList.count, 2)
    }

    func testCreateRecordAnonymous() async throws {
        let db = CKContainer.default().publicCloudDatabase
        if !db.account.isAnonymousAccount { return }
        let id = UUID().uuidString
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["string"] = Constant.stringValue
        do {
            let (_, _) = try await db.modifyRecords(saving: [record], deleting: [])
            XCTFail("This operation should fail")
        } catch {
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
        }
    }

    func testFetchLimit() async throws {
        let resultLimit = 1
        let db = CKContainer.default().publicCloudDatabase
        let query = CKQuery(recordType: Self.recordType, filters: [
            CKQueryFilter(fieldName: "queryableString", comparator: .equals, fieldValue: "DO-NOT-DELETE")
        ])
        let (matchedResults, _) = try await db.records(matching: query, resultsLimit: resultLimit)
        XCTAssertEqual(matchedResults.count, resultLimit)
        let (_, recordResult) = matchedResults[0]
        XCTAssertNoThrow(try recordResult.get())
    }

    func testDesiredKeys() async throws {
        let db = CKContainer.default().publicCloudDatabase
        let recordID = CKRecord.ID(recordName: "043BB555-EA0D-487E-BCC4-257184A5078C")
        let reference = CKRecord.Reference(recordID: recordID, action: .none)
        let query = CKQuery(recordType: Self.recordType, filters: [
            CKQueryFilter(fieldName: "___recordID", comparator: .equals, fieldValue: reference)
        ])
        let (matchedResults, _) = try await db.records(matching: query, desiredKeys: ["string", "int64", "double"], resultsLimit: 1)
        XCTAssertEqual(matchedResults.count, 1)
        let (_, recordResult) = matchedResults[0]
        let record = try recordResult.get()
        XCTAssertNotNil(record["string"])
        XCTAssertNotNil(record["int64"])
        XCTAssertNotNil(record["double"])
        XCTAssertNil(record["stringList"])
        XCTAssertNil(record["int64List"])
        XCTAssertNil(record["doubleList"])
    }

    func testFetchUnknownRecord() async throws {
        let db = CKContainer.default().publicCloudDatabase
        let recordID = CKRecord.ID(recordName: "DO-NOT-CREATE")
        let recordResults = try await db.records(for: [recordID])
        XCTAssertEqual(recordResults.count, 1)
        let recordResult = recordResults.first!.value
        switch recordResult {
        case .success:
            XCTFail("This operation should fail")
        case .failure(let error):
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
        }
    }

    func testDeleteUnknownRecord() async throws {
        // This should succeed as the record never exists
        let db = CKContainer.default().publicCloudDatabase
        if db.account.isAnonymousAccount { return }
        let recordID = CKRecord.ID(recordName: "DO-NOT-CREATE")
        let (saveResults, deleteResults) = try await db.modifyRecords(saving: [], deleting: [recordID])
        XCTAssertEqual(saveResults.count, 0)
        XCTAssertEqual(deleteResults.count, 1)
        let deleteResult = deleteResults.first!.value
        XCTAssertNoThrow(try deleteResult.get())
    }

    func testModifyAndDeleteUnknownRecord() async throws {
        let db = CKContainer.default().publicCloudDatabase
        if db.account.isAnonymousAccount { return }
        let recordResults = try await db.records(for: [CKRecord.ID(recordName: "8BDA40C6-DB7C-BA3D-33AA-FF4C9B9D077A")])
        XCTAssertEqual(recordResults.count, 1)
        let recordResult = recordResults.first!.value
        let existing = try recordResult.get()
        let recordToSave = existing
        guard let recordIntValue = recordToSave["int64"] as? Int64 else {
            XCTFail("int64 field is missing on the record")
            return
        }
        let newValue = recordIntValue == .max ? Int64.min : recordIntValue + 1
        recordToSave["int64"] = newValue
        let nonExistingRecordID = CKRecord.ID(recordName: "DO-NOT-CREATE")
        let (saveResults, deleteResults) = try await db.modifyRecords(saving: [recordToSave], deleting: [nonExistingRecordID])
        XCTAssertEqual(saveResults.count, 1)
        XCTAssertEqual(deleteResults.count, 1)
        let saveResult = saveResults.first!.value
        let (deletedRecordID, deleteResult) = deleteResults.first!

        switch saveResult {
        case .success(let record):
            XCTAssertEqual(record["int64"] as? Int64, newValue)
        case .failure(let error):
            XCTFail("Record modify failed with error \(error)")
        }

        switch deleteResult {
        case .success:
            XCTAssertEqual(deletedRecordID.recordName, nonExistingRecordID.recordName)
        case .failure(let error):
            XCTFail("Record delete failed with error \(error)")
        }
    }

    func testCreateRecordUnknownType() async throws {
        let db = CKContainer.default().publicCloudDatabase
        if db.account.isAnonymousAccount { return }
        let recordID = CKRecord.ID(recordName: "qrqwsnjjfsfsdf")
        let record = CKRecord(recordType: "blah blah", recordID: recordID)
        let (saveResults, deleteResults) = try await db.modifyRecords(saving: [record], deleting: [])
        XCTAssertEqual(saveResults.count, 1)
        XCTAssertEqual(deleteResults.count, 0)
        let saveResult = saveResults.first!.value

        switch saveResult {
        case .success:
            XCTFail("A cancelled task should fail")
        case .failure(let error):
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
        }
    }

    func testCreateExistingRecord() async throws {
        let db = CKContainer.default().publicCloudDatabase
        if db.account.isAnonymousAccount { return }
        let recordID = CKRecord.ID(recordName: "08099BD9-ED8C-4175-B528-3CFD363ECA2E")
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        let (saveResults, deleteResults) = try await db.modifyRecords(saving: [record], deleting: [])
        XCTAssertEqual(saveResults.count, 1)
        XCTAssertEqual(deleteResults.count, 0)
        let saveResult = saveResults.first!.value

        switch saveResult {
        case .success:
            XCTFail("A cancelled task should fail")
        case .failure(let error):
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
        }
    }

    func testCurosr() async throws {
        let resultLimit = 1
        let db = CKContainer.default().publicCloudDatabase
        let query = CKQuery(recordType: Self.recordType, filters: [
            CKQueryFilter(fieldName: "queryableString", comparator: .equals, fieldValue: "DO-NOT-DELETE")
        ])
        let (recordResults, optionalCursor) = try await db.records(matching: query, resultsLimit: resultLimit)
        XCTAssertEqual(recordResults.count, 1)
        let (_, recordResult) = recordResults[0]
        XCTAssertNoThrow(try recordResult.get())

        let cursor = try XCTUnwrap(optionalCursor)
        let (moreRecordResults, _) = try await db.records(continuingMatchFrom: cursor, resultsLimit: resultLimit)
        XCTAssertEqual(moreRecordResults.count, 1)
        let (_, moreRecordResult) = moreRecordResults[0]
        XCTAssertNoThrow(try moreRecordResult.get())
    }

    func testNoCurosr() async throws {
        let resultLimit = 1
        let db = CKContainer.default().publicCloudDatabase
        let reference = CKRecord.Reference(recordID: CKRecord.ID(recordName: "043BB555-EA0D-487E-BCC4-257184A5078C"), action: .none)
        let query = CKQuery(recordType: Self.recordType, filters: [
            CKQueryFilter(fieldName: "___recordID", comparator: .equals, fieldValue: reference)
        ])
        let (recordResults, optionalCursor) = try await db.records(matching: query, resultsLimit: resultLimit)
        XCTAssertEqual(recordResults.count, 1)
        let (_, recordResult) = recordResults[0]
        XCTAssertNoThrow(try recordResult.get())

        XCTAssertNil(optionalCursor)
    }

    static let allTests = [
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
    ]
}
