//
//  CKRecordZone.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 15/07/2016.
//
//

import Foundation

public class CKServerChangeToken : NSObject {
    let data: Data

    init(base64EncodedString: String) {
        self.data = Data(base64Encoded: base64EncodedString)!
        super.init()
    }
}

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

    public convenience init(zoneID: CKRecordZone.ID) {
        self.init(zoneID: zoneID, serverChangeToken: nil)
    }

    public init(zoneID: CKRecordZone.ID, serverChangeToken: CKServerChangeToken?) {
        self.zoneID = zoneID
        self.changeToken = serverChangeToken
        super.init()
    }

    public let zoneID: CKRecordZone.ID
    let changeToken: CKServerChangeToken?

    /* Capabilities are not set until a record zone is saved */
    public var capabilities: CKRecordZone.Capabilities = CKRecordZone.Capabilities(rawValue: 0)
}

extension CKRecordZone {
    convenience init?(dictionary: [String: Any]) {
        guard let zoneIDDictionary = dictionary["zoneID"] as? [String: Any], let zoneID = CKRecordZone.ID(dictionary: zoneIDDictionary) else {
            return nil
        }

        let changeToken: CKServerChangeToken?
        if let syncToken = dictionary["syncToken"] as? String {
            changeToken = CKServerChangeToken(base64EncodedString: syncToken)
        } else {
            changeToken = nil
        }

        self.init(zoneID: zoneID, serverChangeToken: changeToken)

        if let isAtomic = dictionary["atomic"] as? Bool , isAtomic {
            capabilities.formUnion(.atomic)
        }
        if let isEligibleForZoneShare = dictionary["isEligibleForZoneShare"] as? Bool, isEligibleForZoneShare {
            capabilities.formUnion(.sharing)
        }
        if changeToken != nil {
            capabilities.formUnion(.fetchChanges)
        }
    }

    var dictionary: [String: Any] {
        var dictionary: [String: Any] = ["zoneID": zoneID.dictionary]
        if let token = changeToken {
            dictionary["syncToken"] = token.data.base64EncodedString(options: [])
        }
        return dictionary
    }
}
