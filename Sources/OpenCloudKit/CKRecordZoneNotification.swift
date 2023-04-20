//
//  CKRecordZoneNotification.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 20/1/17.
//
//

import Foundation

public class CKRecordZoneNotification : CKNotification {
    public var recordZoneID: CKRecordZone.ID?
    public var databaseScope: CKDatabase.Scope = .public
    
    override init(fromRemoteNotificationDictionary notificationDictionary: [AnyHashable: Sendable]) {
        super.init(fromRemoteNotificationDictionary: notificationDictionary)

        notificationType = CKNotificationType.recordZone

        if let cloudDictionary = notificationDictionary["ck"] as? [String: Sendable] {
            if let zoneDictionary = cloudDictionary["fet"] as? [String: Sendable] {
                // Set RecordZoneID
                if let zoneName = zoneDictionary["zid"] as? String {
                    let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)
                    recordZoneID = zoneID
                }
                
                // Set Database Scope
                if let dbs = zoneDictionary["dbs"] as? NSNumber, let scope = CKDatabase.Scope(rawValue: dbs.intValue) {
                    databaseScope = scope
                }
                
                // Set Subscription ID
                if let sid = zoneDictionary["sid"] as? String {
                    subscriptionID = sid
                }
            }
        }
    }
}
