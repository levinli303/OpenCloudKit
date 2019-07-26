//
//  CKRecordID.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 6/07/2016.
//
//

import Foundation

public class CKRecordID: NSObject, NSCoding {
    
    public convenience init(recordName: String) {
        let defaultZone = CKRecordZoneID(zoneName: "_defaultZone", ownerName: "_defaultOwner")
        self.init(recordName: recordName, zoneID: defaultZone)
    }
    
    public init(recordName: String, zoneID: CKRecordZoneID) {
        
        self.recordName = recordName
        self.zoneID = zoneID
        
    }
    
    public let recordName: String
    
    public var zoneID: CKRecordZoneID
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CKRecordID else { return false }
        return self.recordName == other.recordName && self.zoneID == other.zoneID
    }

    public required convenience init?(coder: NSCoder) {
        let recordName = coder.decodeObject(of: NSString.self, forKey: "RecordName")
        let zoneID = coder.decodeObject(of: CKRecordZoneID.self, forKey: "ZoneID")
        self.init(recordName: recordName! as String, zoneID: zoneID!)
    }

    public func encode(with coder: NSCoder) {
        coder.encode(recordName, forKey: "RecordName")
        coder.encode(zoneID, forKey: "ZoneID")
    }
}

extension CKRecordID {
    
    convenience init?(recordDictionary: [String: Any]) {
        
        guard let recordName = recordDictionary[CKRecordDictionary.recordName] as? String,
            let zoneIDDictionary = recordDictionary[CKRecordDictionary.zoneID] as? [String: Any]
            else {
                return nil
        }
        
        // Parse ZoneID Dictionary into CKRecordZoneID
        let zoneID = CKRecordZoneID(dictionary: zoneIDDictionary)!
        self.init(recordName: recordName, zoneID: zoneID)
    }
    
}
