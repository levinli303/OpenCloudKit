//
//  CKUserIdentity.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 14/07/2016.
//
//

import Foundation

public class CKUserIdentity : NSObject {
    // This is the lookupInfo you passed in to CKDiscoverUserIdentitiesOperation or CKFetchShareParticipantsOperation
    public let lookupInfo: CKUserIdentity.LookupInfo?
    public let nameComponents: CKPersonNameComponentsType?
    public let userRecordID: CKRecord.ID?
    public let hasiCloudAccount: Bool

    public init(userRecordID: CKRecord.ID) {
        self.userRecordID = userRecordID
        self.lookupInfo = nil
        hasiCloudAccount = false
        nameComponents = nil
        super.init()
    }

    init?(dictionary: [String: Any]) {
        if let lookUpInfoDictionary = dictionary["lookupInfo"] as? [String: Any], let lookupInfo = LookupInfo(dictionary: lookUpInfoDictionary) {
            self.lookupInfo = lookupInfo
        } else {
            self.lookupInfo = nil
        }

        if let userRecordName = dictionary["userRecordName"] as? String {
            self.userRecordID = CKRecord.ID(recordName: userRecordName)
        } else {
            self.userRecordID = nil
        }

        if let nameComponentsDictionary = dictionary["nameComponents"] as? [String: Any] {
            self.nameComponents = CKPersonNameComponents(dictionary: nameComponentsDictionary)
        } else {
            self.nameComponents = nil
        }
        self.hasiCloudAccount = false
        
        super.init()
    }
}
