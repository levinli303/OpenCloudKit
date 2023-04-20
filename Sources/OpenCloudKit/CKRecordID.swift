//
//  CKRecordID.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 6/07/2016.
//
//

import Foundation

public extension CKRecord {
    typealias ID = CKRecordID
}

extension CKRecord.ID {
    var isDefaultName: Bool {
        return recordName == CKRecordZone.ID.defaultZoneName
    }
}

public final class CKRecordID: NSObject, NSSecureCoding, Sendable {
    public convenience init(recordName: String) {
        self.init(recordName: recordName, zoneID: CKRecordZoneID.default)
    }

    public init(recordName: String, zoneID: CKRecordZone.ID) {
        self.recordName = recordName
        self.zoneID = zoneID
    }

    public let recordName: String
    public let zoneID: CKRecordZone.ID

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(recordName)
        hasher.combine(zoneID)
        return hasher.finalize()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CKRecordID else { return false }
        return self.recordName == other.recordName && self.zoneID == other.zoneID
    }

    public required convenience init?(coder: NSCoder) {
        let recordName = coder.decodeObject(of: NSString.self, forKey: "RecordName")
        let zoneID = coder.decodeObject(of: CKRecordZone.ID.self, forKey: "ZoneID")
        self.init(recordName: recordName! as String, zoneID: zoneID!)
    }

    public func encode(with coder: NSCoder) {
        coder.encode(recordName, forKey: "RecordName")
        coder.encode(zoneID, forKey: "ZoneID")
    }

    public static var supportsSecureCoding: Bool {
        return true
    }
}

extension CKRecord.ID {
    convenience init?(recordDictionary: [String: Sendable]) {
        guard let recordName = recordDictionary[CKRecordDictionary.recordName] as? String,
            let zoneIDDictionary = recordDictionary[CKRecordDictionary.zoneID] as? [String: Sendable]
            else {
                return nil
        }

        // Parse ZoneID Dictionary into CKRecordZone.ID
        let zoneID = CKRecordZone.ID(dictionary: zoneIDDictionary)!
        self.init(recordName: recordName, zoneID: zoneID)
    }
}
