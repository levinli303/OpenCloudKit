//
//  CKQueryCursor.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 7/07/2016.
//
//

import Foundation

public extension CKQueryOperation {
    final class Cursor: NSObject, Sendable {
        let data: Data
        let query: CKQuery
        let zoneID: CKRecordZone.ID?

        init(data: Data, query: CKQuery, zoneID: CKRecordZone.ID?) {
            self.data = data
            self.zoneID = zoneID
            self.query = query
            super.init()
        }
    }
}
