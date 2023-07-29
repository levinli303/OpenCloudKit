//
//  CKRecordZoneTests.swift
//  
//
//  Created by Levin Li on 2022/2/2.
//

import XCTest
import Foundation
@testable import OpenCloudKit

class CKRecordZoneTests: CKTest {
    func testFetchDefaultRecordZone() {
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

    static var allTests = [
        ("testFetchDefaultRecordZone", testFetchDefaultRecordZone),
    ]
}
