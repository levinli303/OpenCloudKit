//
//  CKRecordZoneTests.swift
//  
//
//  Created by Levin Li on 2022/2/2.
//

import XCTest
import Foundation
@testable import OpenCloudKit

final class CKRecordZoneTests: CKTest, @unchecked Sendable {
    func testFetchDefaultRecordZone() async throws {
        let db = CKContainer.default().publicCloudDatabase
        // Zone lookup is not allowed on anonymous account too
        if db.account.isAnonymousAccount { return }
        let results = try await db.recordZones(for: [.default])
        XCTAssertEqual(results.count, 1)
        let zoneResult = results.first!.value
        let zone = try zoneResult.get()
        XCTAssertEqual(zone.zoneID.zoneName, CKRecordZone.ID.defaultZoneName)
    }

    static let allTests = [
        ("testFetchDefaultRecordZone", testFetchDefaultRecordZone),
    ]
}
