//
//  CKRecordZone.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 15/07/2016.
//
//

import Foundation

extension CKRecordZone {
    public struct Capabilities : OptionSet {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        /* This zone supports CKFetchRecordChangesOperation */
        public static var fetchChanges: Capabilities = Capabilities(rawValue: 1)

        /* Batched changes to this zone happen atomically */
        public static var atomic: Capabilities = Capabilities(rawValue: 2)

        /* Records in this zone can be shared */
        public static var sharing: Capabilities = Capabilities(rawValue: 4)
    }
}

public class CKRecordZone : NSObject {
    public class func `default`() -> CKRecordZone {
        return CKRecordZone(zoneID: .default)
    }

    public convenience init(zoneName: String) {
        let zoneID = CKRecordZoneID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
        self.init(zoneID: zoneID)
    }

    public init(zoneID: CKRecordZone.ID) {
        self.zoneID = zoneID
        super.init()
    }

    public let zoneID: CKRecordZone.ID

    /* Capabilities are not set until a record zone is saved */
    public var capabilities: CKRecordZone.Capabilities = CKRecordZone.Capabilities(rawValue: 0)
}

extension CKRecordZone {
    convenience init?(dictionary: [String: Any]) {
        guard let zoneIDDictionary = dictionary["zoneID"] as? [String: Any], let zoneID = CKRecordZone.ID(dictionary: zoneIDDictionary) else {
            return nil
        }

        self.init(zoneID: zoneID)

        if let isAtomic = dictionary["atomic"] as? Bool , isAtomic {
            capabilities = CKRecordZone.Capabilities.atomic
        }
    }

    var dictionary: [String: Any] {
        return ["zoneID": zoneID.dictionary]
    }
}
