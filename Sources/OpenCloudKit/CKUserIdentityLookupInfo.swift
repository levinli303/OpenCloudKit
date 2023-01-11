//
//  CKUserIdentity.LookupInfo.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 14/07/2016.
//
//

import Foundation

public final class CKUserIdentityLookupInfo : NSObject, NSSecureCoding, Sendable {
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

    public init(emailAddress: String?, phoneNumber: String?, userRecordID: CKRecord.ID?) {
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

    public static var supportsSecureCoding: Bool { return true }

    public required init?(coder: NSCoder) {
        userRecordID = coder.decodeObject(of: CKRecord.ID.self, forKey: "UserRecordName")
        phoneNumber = coder.decodeObject(of: NSString.self, forKey: "PhoneNumber") as String?
        emailAddress = coder.decodeObject(of: NSString.self, forKey: "EmailAddress") as String?
    }

    public func encode(with coder: NSCoder) {
        coder.encode(userRecordID, forKey: "UserRecordName")
        coder.encode(phoneNumber, forKey: "PhoneNumber")
        coder.encode(emailAddress, forKey: "EmailAddress")
    }
}

extension CKUserIdentity {
    public typealias LookupInfo = CKUserIdentityLookupInfo
}

extension CKUserIdentity.LookupInfo: CKCodable {
    convenience init?(dictionary: [String: Any]) {
        let emailAddress = dictionary["emailAddress"] as? String
        let phoneNumber = dictionary["phoneNumber"] as? String
        let userRecordID: CKRecord.ID?
        if let userRecordName = dictionary["userRecordName"] as? String {
            userRecordID = CKRecord.ID(recordName: userRecordName)
        } else {
            userRecordID = nil
        }

        self.init(emailAddress: emailAddress, phoneNumber: phoneNumber, userRecordID: userRecordID)
    }
    
    var dictionary: [String: Any] {
        var lookupInfo: [String: Any] = [:]
        lookupInfo["emailAddress"] = emailAddress
        lookupInfo["phoneNumber"] = phoneNumber
        lookupInfo["userRecordName"] = userRecordID?.recordName
        return lookupInfo
    }
}
