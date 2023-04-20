//
//  CKShareMetadata.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 16/10/16.
//
//

import Foundation

public struct CKShortGUID {
    
    public let value: String
    
    public let shouldFetchRootRecord: Bool
    
    public  let rootRecordDesiredKeys: [CKRecord.FieldKey]?
    
    public var dictionary: [String: Sendable] {
        return ["value": value, "shouldFetchRootRecord": shouldFetchRootRecord]
    }
    
    public init(value: String, shouldFetchRootRecord: Bool, rootRecordDesiredKeys: [CKRecord.FieldKey]? = nil) {
        self.value = value
        self.shouldFetchRootRecord = shouldFetchRootRecord
        self.rootRecordDesiredKeys = rootRecordDesiredKeys
    }
    
}

open class CKShareMetadata  {
    
    init() {
        
        containerIdentifier = ""
        
    }
    
    open var containerIdentifier: String
    
    open var share: CKShare?
    
    open var rootRecordID: CKRecord.ID?
    
    /* These properties reflect the participant properties of the user invoking CKFetchShareMetadataOperation */
    open var participantRole: CKShare.ParticipantRole = .unknown
    
    open var participantStatus: CKShare.ParticipantAcceptanceStatus = .unknown
    
    open var participantPermission: CKShare.ParticipantPermission = CKShare.ParticipantPermission.unknown
    
    
    open var ownerIdentity: CKUserIdentity?
    
    
    /* This is only present if the share metadata was returned from a CKFetchShareMetadataOperation with shouldFetchRootRecord set to YES */
    open var rootRecord: CKRecord?
    
    init?(dictionary:[String: Sendable]) {
        /*
        if let dictionary = CKFetchErrorDictionary(dictionary: dictionary) {
            return nil
        }
        */
        
        containerIdentifier = dictionary["containerIdentifier"] as! String
        
        let rootRecordName = dictionary["rootRecordName"] as! String
        
        let zoneID = CKRecordZone.ID(dictionary: dictionary["zoneID"] as! [String: Sendable])!
        
        rootRecordID = CKRecord.ID(recordName: rootRecordName, zoneID: zoneID)
        
        // Set participant type
        let rawParticipantType = dictionary["participantType"] as! String
        participantRole = CKShare.ParticipantRole(string: rawParticipantType)!
        
        // Set participant permission 
        if let rawParticipantPermission = dictionary["participantPermission"] as? String, let permission = CKShare.ParticipantPermission(string: rawParticipantPermission) {
            participantPermission = permission
        }
        

        // Set status
        if let rawParticipantStatus = dictionary["participantStatus"] as? String, let status = CKShare.ParticipantAcceptanceStatus(string: rawParticipantStatus) {
            participantStatus = status
        }

        
        if let ownerIdentityDictionary = dictionary["ownerIdentity"] as? [String: Sendable] {
            ownerIdentity = CKUserIdentity(dictionary: ownerIdentityDictionary)
        }
        
        // Set root record if available
        if let rootRecordDictionary = dictionary["rootRecord"] as? [String: Sendable] {
            rootRecord = CKRecord(recordDictionary: rootRecordDictionary, zoneID: zoneID)
        }
        
    }
}
