//
//  CKRecordZone.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 15/07/2016.
//
//

import Foundation

public final class CKServerChangeToken : NSObject, NSSecureCoding, Sendable {
    let data: Data

    init(base64EncodedString: String) {
        self.data = Data(base64Encoded: base64EncodedString)!
        super.init()
    }

    public static var supportsSecureCoding: Bool { return true }

    public func encode(with coder: NSCoder) {
        coder.encode(data, forKey: "Data")
    }

    public required init?(coder: NSCoder) {
        data = coder.decodeObject(of: NSData.self, forKey: "Data")! as Data
    }
}

extension CKRecordZone {
    public struct Capabilities : OptionSet, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        /* This zone supports CKFetchRecordChangesOperation */
        public static let fetchChanges: Capabilities = Capabilities(rawValue: 1)

        /* Batched changes to this zone happen atomically */
        public static let atomic: Capabilities = Capabilities(rawValue: 2)

        /* Records in this zone can be shared */
        public static let sharing: Capabilities = Capabilities(rawValue: 4)
    }
}

public final class CKRecordZone : NSObject, NSSecureCoding, Sendable {
    public class func `default`() -> CKRecordZone {
        return CKRecordZone(zoneID: .default)
    }

    public convenience init(zoneName: String) {
        let zoneID = CKRecordZoneID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
        self.init(zoneID: zoneID)
    }

    public convenience init(zoneID: CKRecordZone.ID) {
        self.init(zoneID: zoneID, serverChangeToken: nil, capabilities: Capabilities(rawValue: 0))
    }

    init(zoneID: CKRecordZone.ID, serverChangeToken: CKServerChangeToken?, capabilities: CKRecordZone.Capabilities) {
        self.zoneID = zoneID
        self.changeToken = serverChangeToken
        self.capabilities = capabilities
        super.init()
    }

    public let zoneID: CKRecordZone.ID
    let changeToken: CKServerChangeToken?

    /* Capabilities are not set until a record zone is saved */
    public let capabilities: CKRecordZone.Capabilities

    public static var supportsSecureCoding: Bool { return true }

    public func encode(with coder: NSCoder) {
        coder.encode(zoneID, forKey: "ZoneID")
        coder.encode(changeToken, forKey: "ChangeToken")
        coder.encode(capabilities.rawValue, forKey: "Capabilities")
    }

    public required init?(coder: NSCoder) {
        zoneID = coder.decodeObject(of: CKRecordZone.ID.self, forKey: "ZoneID")!
        changeToken = coder.decodeObject(of: CKServerChangeToken.self, forKey: "ChangeToken")
        capabilities = CKRecordZone.Capabilities(rawValue: UInt(coder.decodeInteger(forKey: "Capabilities")))
    }
}

extension CKRecordZone {
    convenience init?(dictionary: [String: Sendable]) {
        guard let zoneIDDictionary = dictionary["zoneID"] as? [String: Sendable], let zoneID = CKRecordZone.ID(dictionary: zoneIDDictionary) else {
            return nil
        }

        let changeToken: CKServerChangeToken?
        if let syncToken = dictionary["syncToken"] as? String {
            changeToken = CKServerChangeToken(base64EncodedString: syncToken)
        } else {
            changeToken = nil
        }

        var capabilities = Capabilities(rawValue: 0)
        if let isAtomic = dictionary["atomic"] as? Bool , isAtomic {
            capabilities.formUnion(.atomic)
        }
        if let isEligibleForZoneShare = dictionary["isEligibleForZoneShare"] as? Bool, isEligibleForZoneShare {
            capabilities.formUnion(.sharing)
        }
        if changeToken != nil {
            capabilities.formUnion(.fetchChanges)
        }

        self.init(zoneID: zoneID, serverChangeToken: changeToken, capabilities: capabilities)
    }

    var dictionary: [String: Sendable] {
        var dictionary: [String: Sendable] = ["zoneID": zoneID.dictionary]
        if let token = changeToken {
            dictionary["syncToken"] = token.data.base64EncodedString(options: [])
        }
        return dictionary
    }
}
