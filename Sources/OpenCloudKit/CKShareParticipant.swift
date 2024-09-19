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

public enum CKShareParticipantRole : Int, CustomStringConvertible {
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

extension CKShare {
    public typealias Participant = CKShareParticipant
    public typealias ParticipantPermission = CKShareParticipantPermission
    public typealias ParticipantRole = CKShareParticipantRole
    public typealias ParticipantAcceptanceStatus = CKShareParticipantAcceptanceStatus
}

public class CKShareParticipant: NSObject, NSSecureCoding, @unchecked Sendable {
    public var userIdentity: CKUserIdentity
    
    /* The default participant type is CKShareParticipantTypePrivateUser. */
    public var role: CKShareParticipantRole = .privateUser
    
    public var acceptanceStatus: CKShareParticipantAcceptanceStatus = .unknown
    
    /* The default permission for a new participant is CKShareParticipantPermissionReadOnly. */
    public var permission: CKShareParticipantPermission = .readOnly
    
    init(userIdentity: CKUserIdentity) {
        self.userIdentity = userIdentity
    }
    
    convenience init?(dictionary: [String: Sendable]) {
        guard let userIdentityDictionary = dictionary["userIdentity"] as? [String: Sendable], let identity = CKUserIdentity(dictionary: userIdentityDictionary) else {
            return nil
        }
        
        self.init(userIdentity: identity)
        
        if let rawType = dictionary["type"] as? String, let userType = CKShareParticipantRole(string: rawType) {
            role = userType
        }
        
        if let rawAcceptanceStatus = dictionary["acceptanceStatus"] as? String, let status = CKShareParticipantAcceptanceStatus(string: rawAcceptanceStatus) {
            acceptanceStatus = status
        }
        
        if let rawPermission = dictionary["permission"] as? String, let permission = CKShareParticipantPermission(string: rawPermission) {
            self.permission = permission
        }
    }

    public static var supportsSecureCoding: Bool { return true }

    public func encode(with coder: NSCoder) {
        coder.encode(userIdentity, forKey: "UserIdentity")
        coder.encode(role.rawValue, forKey: "Role")
        coder.encode(acceptanceStatus.rawValue, forKey: "AcceptanceStatus")
        coder.encode(permission.rawValue, forKey: "Permission")
    }

    public required init?(coder: NSCoder) {
        userIdentity = coder.decodeObject(of: CKUserIdentity.self, forKey: "UserIdentity")!
        role = CKShareParticipantRole(rawValue: coder.decodeInteger(forKey: "Role"))!
        acceptanceStatus = CKShareParticipantAcceptanceStatus(rawValue: coder.decodeInteger(forKey: "AcceptanceStatus"))!
        permission = CKShareParticipantPermission(rawValue: coder.decodeInteger(forKey: "Permission"))!
    }

    var dictionary: [String: Sendable] {
        return [
            "type": "\(role)",
            "permission": "\(permission)",
            "acceptanceStatus": "\(acceptanceStatus)",
            "userIdentity": userIdentity.dictionary
        ]
    }
}
