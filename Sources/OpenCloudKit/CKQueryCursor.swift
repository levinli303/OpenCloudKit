//
//  CKQueryCursor.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 7/07/2016.
//
//

import Foundation

public class CKQueryCursor: NSObject {
    var data: Data

    var zoneID: CKRecordZoneID

    init(data: Data, zoneID: CKRecordZoneID) {
        
        self.data = data
        self.zoneID = zoneID
        
        super.init()
    }
}
