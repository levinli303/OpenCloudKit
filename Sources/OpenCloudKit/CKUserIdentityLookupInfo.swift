//
//  CKUserIdentityLookupInfo.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 14/07/2016.
//
//

import Foundation

public class CKUserIdentityLookupInfo : NSObject {
    
    public init(emailAddress: String) {
        self.emailAddress = emailAddress
        self.phoneNumber = nil
        self.userRecordID = nil
    }
    
    public init(phoneNumber: String) {
        self.emailAddress = nil
        self.phoneNumber = phoneNumber
        self.userRecordID = nil
    }
    
    public init(userRecordID: CKRecord.ID) {
        self.emailAddress = nil
        self.phoneNumber = nil
        self.userRecordID = userRecordID
    }
    
    public init(emailAddress: String, phoneNumber: String, userRecordID: CKRecord.ID) {
        self.emailAddress = emailAddress
        self.phoneNumber = phoneNumber
        self.userRecordID = userRecordID
    }
    
    public class func lookupInfos(withEmails emails: [String]) -> [CKUserIdentityLookupInfo] {
        return emails.map({ (email) -> CKUserIdentityLookupInfo in
            return CKUserIdentityLookupInfo(emailAddress: email)
        })
    }
    
    public class func lookupInfos(withPhoneNumbers phoneNumbers: [String]) -> [CKUserIdentityLookupInfo] {
        return phoneNumbers.map({ (phoneNumber) -> CKUserIdentityLookupInfo in
            return CKUserIdentityLookupInfo(phoneNumber: phoneNumber)
        })
    }
    
    public class func lookupInfos(with recordIDs: [CKRecord.ID]) -> [CKUserIdentityLookupInfo] {
        return recordIDs.map({ (recordID) -> CKUserIdentityLookupInfo in
            return CKUserIdentityLookupInfo(userRecordID: recordID)
        })
    }
    
    public let emailAddress: String?
    
    public let phoneNumber: String?
    
    public let userRecordID: CKRecord.ID?
}

extension CKUserIdentityLookupInfo: CKCodable {
    convenience init?(dictionary: [String: Any]) {
        
        guard let emailAddress = dictionary["emailAddress"] as? String,
        let phoneNumber = dictionary["phoneNumber"] as? String,
        let userRecordName = dictionary["userRecordName"] as? String else {
                return nil
        }
        
        self.init(emailAddress: emailAddress, phoneNumber: phoneNumber, userRecordID: CKRecord.ID(recordName: userRecordName))
    }
    
    var dictionary: [String: Any] {
        var lookupInfo: [String: Any] = [:]
        lookupInfo["emailAddress"] = emailAddress
        lookupInfo["phoneNumber"] = phoneNumber
        lookupInfo["userRecordName"] = userRecordID?.recordName
        
        return lookupInfo
    }
}
