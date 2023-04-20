//
//  CKShare.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 16/10/16.
//
//

import Foundation

public let CKShareRecordType = "cloudkit.share"

public class CKShare : CKRecord {
    var forRecord: CKRecord?

    /* When saving a newly created CKShare, you must save the share and its rootRecord in the same CKModifyRecordsOperation batch. */
    public convenience init(rootRecord: CKRecord) {
        self.init(rootRecord: rootRecord, share: CKRecord.ID(recordName: UUID().uuidString, zoneID: rootRecord.recordID.zoneID))
    }
    
    public init(rootRecord: CKRecord, share shareID: CKRecord.ID) {
        let owner = CKShare.Participant(userIdentity: CKUserIdentity(userRecordID: CKRecord.ID(recordName: CKCurrentUserDefaultName, zoneID: CKRecordZoneID.default)))
        owner.permission = .readWrite
        owner.acceptanceStatus = .accepted
        owner.role = .owner
        self.forRecord = rootRecord
        self.owner = owner
        super.init(recordType: CKShareRecordType, recordID: shareID)
        self.participants = [owner]
        rootRecord.share = CKRecord.Reference(recordID: shareID, action: .none)
    }
    
    public init?(dictionary: [String: Sendable], zoneID: CKRecordZone.ID?) {
        guard let rawPublicPermission = dictionary["publicPermission"] as? String, let permission = CKShare.ParticipantPermission(string: rawPublicPermission) else {
            return nil
        }

        guard let rawPerticipants = dictionary["participants"] as? [[String: Sendable]] else { return nil }
        guard let rawOwner = dictionary["owner"] as? [String: Sendable], let ownerParticipant = CKShare.Participant(dictionary: rawOwner) else { return nil }

        self.owner = ownerParticipant
        self.forRecord = nil

        super.init(recordDictionary: dictionary, zoneID: zoneID)

        var participants = [CKShare.Participant]()
        for rawParticipant in rawPerticipants {
            guard let participant = CKShare.Participant(dictionary: rawParticipant) else {
                return nil
            }
            participants.append(participant)
        }

        self.participants = participants
        self.publicPermission = permission
    }
    
    public required init?(coder: NSCoder) {
        let owner = coder.decodeObject(of: CKShare.Participant.self, forKey: "Owner")!
        forRecord = coder.decodeObject(of: CKRecord.self, forKey: "ForRecord")
        publicPermission = CKShare.ParticipantPermission(rawValue: coder.decodeInteger(forKey: "PublicPermission"))!
        participants = (coder.decodeObject(of: NSArray.self, forKey: "Participants") as? [CKShare.Participant]) ?? [owner]
        self.owner = owner
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)

        coder.encode(owner, forKey: "Owner")
        coder.encode(forRecord, forKey: "ForRecord")
        coder.encode(publicPermission.rawValue, forKey: "PublicPermission")
        coder.encode(participants, forKey: "Participants")
    }

    /*
     Shares with publicPermission more permissive than CKShare.ParticipantPermissionNone can be joined by any user with access to the share's shareURL.
     This property defines what permission those users will have.
     By default, public permission is CKShare.ParticipantPermissionNone.
     Changing the public permission to CKShare.ParticipantPermissionReadOnly or CKShare.ParticipantPermissionReadWrite will result in all pending participants being removed.  Already-accepted participants will remain on the share.
     Changing the public permission to CKShare.ParticipantPermissionNone will result in all participants being removed from the share.  You may subsequently choose to call addParticipant: before saving the share, those participants will be added to the share. */
    public var publicPermission: CKShare.ParticipantPermission = .none
    
    
    /* A URL that can be used to invite participants to this share. Only available after share record has been saved to the server.  This url is stable, and is tied to the rootRecord.  That is, if you share a rootRecord, delete the share, and re-share the same rootRecord via a newly created share, that newly created share's url will be identical to the prior share's url */
    public var url: URL? {
        if let shortGUID = shortGUID {
            let CKShareBaseURL = URL(string: "https://www.icloud.com/share/")!
            return CKShareBaseURL.appendingPathComponent("\(shortGUID)#\(recordID.zoneID.zoneName)")
        } else {
            return nil
        }
    }

    /* The participants array will contain all participants on the share that the current user has permissions to see.
     At the minimum that will include the owner and the current user. */
    public var participants: [CKShare.Participant]  = []
    
    /* Convenience methods for fetching special users from the participant array */
    public let owner: CKShare.Participant

    public var currentUserParticipant: CKShare.Participant? {
        return nil
    }

    /*
     If a participant with a matching userIdentity already exists, then that existing participant's properties will be updated; no new participant will be added.
     In order to modify the list of participants, a share must have publicPermission set to CKShare.ParticipantPermissionNone.  That is, you cannot mix-and-match private users and public users in the same share.
     Only certain participant types may be added via this API, see the comments around CKShare.ParticipantType
     */
    public func addParticipant(_ participant: CKShare.Participant) {
        if let existing = participants.first(where: { $0.userIdentity == participant.userIdentity }) {
            // Update info
            existing.acceptanceStatus = participant.acceptanceStatus
            existing.permission = participant.permission
            existing.role = participant.role
            existing.userIdentity = participant.userIdentity
        } else if publicPermission == .none {
            participants.append(participant)
        }
    }
    
    public func removeParticipant(_ participant: CKShare.Participant) {
        if let existingIndex = participants.firstIndex(where: { $0.userIdentity == participant.userIdentity }) {
            participants.remove(at: existingIndex)
        }
    }
}
