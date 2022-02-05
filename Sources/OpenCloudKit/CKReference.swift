//
//  CKReference.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 27/08/2016.
//
//

import Foundation

extension CKRecord {
    public enum ReferenceAction : UInt {
        case none
        case deleteSelf

        public init?(value: String) {
            switch value {
            case "NONE", "VALIDATE":
                self = .none
            case "DELETE_SELF":
                self = .deleteSelf
            default:
                return nil
            }
        }
    }
}

extension CKRecord.ReferenceAction: CustomStringConvertible {
    public var description: String {
        switch self {
        case .none:
            return "NONE"
        case .deleteSelf:
            return "DELETE_SELF"
        }
    }
}

public class CKReference: NSObject, NSSecureCoding {
    /* It is acceptable to relate two records that have not yet been uploaded to the server, but those records must be uploaded to the server in the same operation.
     If a record references a record that does not exist on the server and is not in the current save operation it will result in an error. */
    public init(recordID: CKRecord.ID, action: CKRecord.ReferenceAction) {
        self.recordID = recordID
        self.referenceAction = action
    }

    public convenience init(record: CKRecord, action: CKRecord.ReferenceAction) {
        self.init(recordID: record.recordID, action: action)
    }

    public let referenceAction: CKRecord.ReferenceAction

    public let recordID: CKRecord.ID

    public required convenience init?(coder: NSCoder) {
        let recordID = coder.decodeObject(of: CKRecord.ID.self, forKey: "recordID")
        let referenceAction = coder.decodeInt64(forKey: "referenceAction")
        self.init(recordID: recordID!, action: CKRecord.ReferenceAction(rawValue: UInt(referenceAction))!)
    }

    public func encode(with coder: NSCoder) {
        coder.encode(recordID, forKey: "recordID")
        coder.encode(referenceAction.rawValue, forKey: "referenceAction")
    }

    public static var supportsSecureCoding: Bool {
        return true
    }
}

extension CKRecord {
    public typealias Reference = CKReference
}

extension CKRecord.Reference {
    convenience init?(dictionary: [String: Any]) {
        guard let recordName = dictionary["recordName"] as? String else {
            return nil
        }

        let action: CKRecord.ReferenceAction
        if let actionValue = dictionary["action"] as? String, let actionType = CKRecord.ReferenceAction(value: actionValue) {
            action = actionType
        } else {
            action = .none
        }

        let recordID: CKRecord.ID
        if let zoneDictionary = dictionary["zoneID"] as? [String: Any],
            let zoneID = CKRecordZone.ID(dictionary: zoneDictionary) {
            recordID = CKRecord.ID(recordName: recordName, zoneID: zoneID)
        } else {
           recordID = CKRecord.ID(recordName: recordName)
        }

        self.init(recordID: recordID, action: action)
    }

    var dictionary: [String: Any] {
        let dict: [String: Any] = ["recordName": recordID.recordName, "zoneID": recordID.zoneID.dictionary, "action": referenceAction.description]
        return dict
    }
}
