//
//  CKRecordTests.swift
//  
//
//  Created by Levin Li on 2020/10/13.
//

import XCTest
import Foundation
@testable import OpenCloudKit

#if os(iOS) || os(macOS)
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

class CKRecordTests: CKTest {
    static var recordType = "TestData"

    enum Constant {
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
        let id = UUID().uuidString
        let recordID = CKRecordID(recordName: id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["string"] = Constant.stringValue as CKRecordValue
        record["stringList"] = Constant.stringListValue as CKRecordValue
        record["int64"] = Constant.int64Value as CKRecordValue
        record["int64List"] = Constant.int64ListValue as CKRecordValue
        record["double"] = Constant.doubleValue as CKRecordValue
        record["doubleList"] = Constant.doubleListValue as CKRecordValue
        record["date"] = Constant.dateValue as CKRecordValue
        record["dateList"] = Constant.dateListValue as CKRecordValue
        record["location"] = Constant.locationValue as CKRecordValue
        record["locationList"] = Constant.locationListValue as CKRecordValue
        let expectation = XCTestExpectation(description: "Wait for response")
        db.save(record: record) { record, error in
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

    func testFetchRecord() {
        let db = CKContainer.default().publicCloudDatabase
        let expectation = XCTestExpectation(description: "Wait for response")
        let recordID = CKRecordID(recordName: "E2F5C6D8-31F6-4A6D-B018-4C629DCB3FF3")
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
        let recordID = CKRecordID(recordName: "7301F079-0298-4DED-8948-8A1286C84653")
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
        let id = UUID().uuidString
        let recordID = CKRecordID(recordName: id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["asset"] = CKAsset(fileURL: URL(fileURLWithPath: "asset1.txt")) as CKRecordValue
        record["assetList"] = [CKAsset(fileURL: URL(fileURLWithPath: "asset1.txt")), CKAsset(fileURL: URL(fileURLWithPath: "asset2.txt"))] as CKRecordValue
        let expectation = XCTestExpectation(description: "Wait for response")
        db.save(record: record) { record, error in
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

    func testFetchLimit() {
        let resultLimit = 1
        let db = CKContainer.default().publicCloudDatabase
        let query = CKQuery(recordType: Self.recordType, filters: [])
        let op = CKQueryOperation(query: query)
        op.resultsLimit = resultLimit
        var records: [CKRecord] = []
        op.recordFetchedBlock = { record in
            records.append(record)
        }
        let expectation = XCTestExpectation(description: "Wait for response")
        op.queryCompletionBlock = { _, _ in
            expectation.fulfill()
        }
        db.add(op)
        wait(for: [expectation], timeout: 10)
        XCTAssertEqual(records.count, resultLimit)
    }

    func testDesiredKeys() {
        let db = CKContainer.default().publicCloudDatabase
        let recordID = CKRecordID(recordName: "043BB555-EA0D-487E-BCC4-257184A5078C")
        let reference = CKReference(recordID: recordID, action: .none)
        let query = CKQuery(recordType: Self.recordType, filters: [
            CKQueryFilter(fieldName: "___recordID", comparator: .equals, fieldValue: reference)
        ])
        let op = CKQueryOperation(query: query)
        op.resultsLimit = 1
        op.desiredKeys = ["string", "int64", "double"]
        var records: [CKRecord] = []
        op.recordFetchedBlock = { record in
            records.append(record)
        }
        let expectation = XCTestExpectation(description: "Wait for response")
        op.queryCompletionBlock = { _, _ in
            expectation.fulfill()
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
        let recordID = CKRecordID(recordName: "DO-NOT-CREATE")
        db.fetch(withRecordID: recordID) { record, error in
            XCTAssertNil(record)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func testDeleteUnknownRecord() {
        let db = CKContainer.default().publicCloudDatabase
        let expectation = XCTestExpectation(description: "Wait for response")
        let recordID = CKRecordID(recordName: "DO-NOT-CREATE")
        db.delete(withRecordID: recordID) { record, error in
            XCTAssertNil(error)
            XCTAssertNotNil(record)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func testCreateRecordUnknownType() {
        let db = CKContainer.default().publicCloudDatabase
        let expectation = XCTestExpectation(description: "Wait for response")
        let recordID = CKRecordID(recordName: "qrqwsnjjfsfsdf")
        db.save(record: CKRecord(recordType: "blah blah", recordID: recordID)) { record, error in
            XCTAssertNil(record)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    func testCreateExistingRecord() {
        let db = CKContainer.default().publicCloudDatabase
        let expectation = XCTestExpectation(description: "Wait for response")
        let recordID = CKRecordID(recordName: "08099BD9-ED8C-4175-B528-3CFD363ECA2E")
        db.save(record: CKRecord(recordType: Self.recordType, recordID: recordID)) { record, error in
            XCTAssertNil(record)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }

    static var allTests = [
        ("testCreateRecord", testCreateRecord),
        ("testFetchRecord", testFetchRecord),
        ("testFetchRecordWithAsset", testFetchRecordWithAsset),
        ("testCreateRecordWithAsset", testCreateRecordWithAsset),
        ("testFetchLimit", testFetchLimit),
        ("testDesiredKeys", testDesiredKeys),
        ("testFetchUnknownRecord", testFetchUnknownRecord),
        ("testCreateRecordUnknownType", testCreateRecordUnknownType),
        ("testDeleteUnknownRecord", testDeleteUnknownRecord),
        ("testCreateExistingRecord", testCreateExistingRecord),
        ("testCreateExistingRecord", testCreateExistingRecord),
    ]
}
