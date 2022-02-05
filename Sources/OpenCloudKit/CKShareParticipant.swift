//
//  CKShareParticipant.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 16/10/16.
//
//

import Foundation

public enum CKShareParticipantAcceptanceStatus : Int, CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "UNKNOWN"
        case .pending:
            return "PENDING"
        case .accepted:
            return "ACCEPTED"
        case .removed:
            return "REMOVED"
        }
    }

    case unknown
    case pending
    case accepted
    case removed
    
    init?(string: String) {
        switch string {
        case "UNKNOWN":
            self = .unknown
        case "PENDING":
            self = .pending
        case "ACCEPTED":
            self = .accepted
        case "REMOVED":
            self = .removed
        default:
            return nil
        }
    }
}

public enum CKShareParticipantPermission : Int, CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "UNKNOWN"
        case .none:
            return "NONE"
        case .readOnly:
            return "READ_ONLY"
        case .readWrite:
            return "READ_WRITE"
        }
    }

    case unknown
    case none
    case readOnly
    case readWrite
    
    init?(string: String) {
        switch string {
        case "READ_WRITE":
            self = .readWrite
        case "NONE":
            self = .none
        case "READ_ONLY":
            self = .readOnly
        case "UNKNOWN":
            self = .unknown
        default:
            return nil
        }
    }
}

public enum CKShareParticipantType : Int, CustomStringConvertible {
    case unknown
    case owner
    case privateUser
    case publicUser
    case administrator
    
    init?(string: String) {
        switch string {
        case "OWNER":
            self = .owner
        case "USER":
            self = .privateUser
        case "PUBLIC_USER":
            self = .publicUser
        case "UNKNOWN":
            self = .unknown
        case "ADMINISTRATOR":
            self = .administrator
        default:
            fatalError("Unknown type \(string)")
        }
    }

    public var description: String {
        switch self {
        case .unknown:
            return "UNKNOWN"
        case .owner:
            return "OWNER"
        case .privateUser:
            return "USER"
        case .publicUser:
            return "PUBLIC_USER"
        case .administrator:
            return "ADMINISTRATOR"
        }
    }
}

public class CKShareParticipant: NSObject {
    public var userIdentity: CKUserIdentity
    
    /* The default participant type is CKShareParticipantTypePrivateUser. */
    public var type: CKShareParticipantType = .privateUser
    
    public var acceptanceStatus: CKShareParticipantAcceptanceStatus = .unknown
    
    /* The default permission for a new participant is CKShareParticipantPermissionReadOnly. */
    public var permission: CKShareParticipantPermission = .readOnly
    
    init(userIdentity: CKUserIdentity) {
        self.userIdentity = userIdentity
    }
    
    convenience init?(dictionary: [String: Any]) {
        guard let userIdentityDictionary = dictionary["userIdentity"] as? [String: Any], let identity = CKUserIdentity(dictionary: userIdentityDictionary) else {
            return nil
        }
        
        self.init(userIdentity: identity)
        
        if let rawType = dictionary["type"] as? String, let userType = CKShareParticipantType(string: rawType) {
            type = userType
        }
        
        if let rawAcceptanceStatus = dictionary["acceptanceStatus"] as? String, let status = CKShareParticipantAcceptanceStatus(string: rawAcceptanceStatus) {
            acceptanceStatus = status
        }
        
        if let rawPermission = dictionary["permission"] as? String, let permission = CKShareParticipantPermission(string: rawPermission) {
            self.permission = permission
        }
    }


    var dictionary: [String: Any] {
        return [
            "type": "\(type)",
            "permission": "\(permission)",
            "acceptanceStatus": "\(acceptanceStatus)",
            "userIdentity": userIdentity.dictionary
        ]
    }
}
