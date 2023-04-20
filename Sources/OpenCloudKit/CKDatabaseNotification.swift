//
//  CKDatabaseNotification.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 20/1/17.
//
//

import Foundation

public class CKDatabaseNotification : CKNotification {
    public var databaseScope: CKDatabase.Scope = .public

    override init(fromRemoteNotificationDictionary notificationDictionary: [AnyHashable: Sendable]) {
        super.init(fromRemoteNotificationDictionary: notificationDictionary)

        notificationType = .database

        if let ckDictionary = notificationDictionary["ck"] as? [String: Sendable] {
            if let metDictionary = ckDictionary["met"] as? [String: Sendable] {
                // Set database scope
                if let dbs = metDictionary["dbs"] as? NSNumber, let scope = CKDatabase.Scope(rawValue: dbs.intValue)  {
                    databaseScope = scope
                }

                // Set Subscription ID
                if let sid = metDictionary["sid"] as? String {
                    subscriptionID = sid
                }
            }
        }
    }
}
