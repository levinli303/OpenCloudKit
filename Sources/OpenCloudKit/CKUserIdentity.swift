//
//  CKUserIdentity.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 14/07/2016.
//
//

import Foundation

public final class CKUserIdentity : NSObject, NSSecureCoding, @unchecked Sendable {
    // This is the lookupInfo you passed in to CKDiscoverUserIdentitiesOperation or CKFetchShareParticipantsOperation
    public let lookupInfo: CKUserIdentity.LookupInfo?
    public let nameComponents: CKPersonNameComponents?
    public let userRecordID: CKRecord.ID?
    public let hasiCloudAccount: Bool

    public init(userRecordID: CKRecord.ID) {
        self.userRecordID = userRecordID
        self.lookupInfo = nil
        hasiCloudAccount = false
        nameComponents = nil
        super.init()
    }

    init?(dictionary: [String: Sendable]) {
        if let lookUpInfoDictionary = dictionary["lookupInfo"] as? [String: Sendable], let lookupInfo = LookupInfo(dictionary: lookUpInfoDictionary) {
            self.lookupInfo = lookupInfo
        } else {
            self.lookupInfo = nil
        }

        if let userRecordName = dictionary["userRecordName"] as? String {
            self.userRecordID = CKRecord.ID(recordName: userRecordName)
        } else {
            self.userRecordID = nil
        }

        if let nameComponentsDictionary = dictionary["nameComponents"] as? [String: Sendable] {
            self.nameComponents = CKPersonNameComponents(dictionary: nameComponentsDictionary)
        } else {
            self.nameComponents = nil
        }
        self.hasiCloudAccount = false
        
        super.init()
    }

    public static var supportsSecureCoding: Bool { return true }

    public func encode(with coder: NSCoder) {
        coder.encode(lookupInfo, forKey: "LookupInfo")
        coder.encode(userRecordID, forKey: "UserRecordID")
        coder.encode(nameComponents, forKey: "NameComponents")
        coder.encode(hasiCloudAccount, forKey: "HasiCloudAccount")
    }

    public required init?(coder: NSCoder) {
        lookupInfo = coder.decodeObject(of: LookupInfo.self, forKey: "LookupInfo")
        userRecordID = coder.decodeObject(of: CKRecord.ID.self, forKey: "UserRecordID")
        nameComponents = coder.decodeObject(of: CKPersonNameComponents.self, forKey: "NameComponents")
        hasiCloudAccount = coder.decodeBool(forKey: "HasiCloudAccount")
    }

    var dictionary: [String: Sendable] {
        var dictionary = [String: Sendable]()
        dictionary["userRecordName"] = userRecordID?.recordName
        dictionary["lookupInfo"] = lookupInfo?.dictionary
        dictionary["nameComponents"] = nameComponents?.dictionary
        return dictionary
    }
}
