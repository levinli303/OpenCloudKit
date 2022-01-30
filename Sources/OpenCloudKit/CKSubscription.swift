//
//  CKSubscription.swift
//  OpenCloudKit
//
//  Created by Ben Johnson on 12/07/2016.
//
//

import Foundation

public protocol CustomDictionaryConvertible {
    var dictionary: [String: Any] { get }
}

public class CKSubscription: NSObject {
    public enum SubscriptionType : Int, CustomStringConvertible {
        case query
        case recordZone

        public var description: String {
            switch self {
            case .query:
                return "query"
            case .recordZone:
                return "zone"
            }
        }
    }

    public let subscriptionID: String
    public let subscriptionType: SubscriptionType
    public var notificationInfo: NotificationInfo?

    init(subscriptionID: String, subscriptionType: SubscriptionType) {
        self.subscriptionID = subscriptionID
        self.subscriptionType = subscriptionType
    }
    
    init?(dictionary: [String: Any]) {
        guard let subscriptionID = dictionary["subscriptionID"] as? String,
        let subscriptionTypeValue = dictionary["subscriptionType"] as? String else {
            return nil
        }

        self.subscriptionID = subscriptionID

        let subscriptionType: SubscriptionType
        switch(subscriptionTypeValue) {
        case "zone":
            subscriptionType = .recordZone
        default:
            subscriptionType = .query
        }

        self.subscriptionType = subscriptionType
    }
}

extension CKSubscription {
    public var subscriptionDictionary: [String : Any] {
        switch self {
        case let querySub as CKQuerySubscription where self.subscriptionType == .query:
            return querySub.dictionary
        case let recordZoneSubscript as CKRecordZoneSubscription where self.subscriptionType == .recordZone:
            return recordZoneSubscript.dictionary
        default:
            return [:]
        }
    }
}

public struct CKQuerySubscriptionOptions : OptionSet {
    public var rawValue: UInt
    
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    public static var firesOnRecordCreation: CKQuerySubscriptionOptions { return CKQuerySubscriptionOptions(rawValue: 1) }
    
    public static var firesOnRecordUpdate: CKQuerySubscriptionOptions { return CKQuerySubscriptionOptions(rawValue: 2)  }
    
    public static var firesOnRecordDeletion: CKQuerySubscriptionOptions { return CKQuerySubscriptionOptions(rawValue: 4)  }
    
    public static var firesOnce: CKQuerySubscriptionOptions {  return CKQuerySubscriptionOptions(rawValue: 8) }
    
    var firesOnArray: [String] {
        var array: [String] = []
        if contains(CKQuerySubscriptionOptions.firesOnRecordCreation) {
            array.append("create")
        }
        
        if contains(CKQuerySubscriptionOptions.firesOnRecordUpdate) {
            array.append("update")
        }
        
        if contains(CKQuerySubscriptionOptions.firesOnRecordDeletion) {
            array.append("delete")
        }
        
        return array
    }
}

public class CKQuerySubscription : CKSubscription {
    
    public convenience init(recordType: String, predicate: NSPredicate, options querySubscriptionOptions: CKQuerySubscriptionOptions) {
        
        let subscriptionID = NSUUID().uuidString
        self.init(recordType: recordType, predicate: predicate, subscriptionID: subscriptionID, options: querySubscriptionOptions)
    }
    
    public init(recordType: String, predicate: NSPredicate, subscriptionID: String, options querySubscriptionOptions: CKQuerySubscriptionOptions) {
        
        self.predicate = predicate
        
        self.recordType = recordType
        
        self.querySubscriptionOptions = querySubscriptionOptions
        
        super.init(subscriptionID: subscriptionID, subscriptionType: SubscriptionType.query)
        
       
    }
    
    /* The record type that this subscription watches */
    public let recordType: String
    
    /* A predicate that determines when the subscription fires. */
    public var predicate: NSPredicate
    
    /* Optional property.  If set, a query subscription is scoped to only record changes in the indicated zone. */
    public var zoneID: CKRecordZone.ID?
    
    public let querySubscriptionOptions: CKQuerySubscriptionOptions
    
}


extension CKQuerySubscription {
     public var dictionary: [String: Any] {
        
        let query = CKQuery(recordType: recordType, predicate: predicate)
       
        var subscription: [String: Any] =  ["subscriptionID": subscriptionID,
                "subscriptionType": subscriptionType.description,
                "query": query.dictionary as Any,
                "firesOn": querySubscriptionOptions.firesOnArray]
        if querySubscriptionOptions.contains(CKQuerySubscriptionOptions.firesOnce) {
            subscription["firesOnce"] = NSNumber(value: true)
        }
        
        if let notificationInfo = notificationInfo {
            subscription["notificationInfo"] = notificationInfo.dictionary
        }
    
        return subscription
    }
}

public class CKRecordZoneSubscription : CKSubscription {
    public convenience init(zoneID: CKRecordZone.ID) {
        let subscriptionID = NSUUID().uuidString
        self.init(zoneID: zoneID, subscriptionID: subscriptionID)
    }
    
    public init(zoneID: CKRecordZone.ID, subscriptionID: String) {
        self.zoneID = zoneID

        super.init(subscriptionID: subscriptionID, subscriptionType: SubscriptionType.recordZone)
    }
    
    public let zoneID: CKRecordZone.ID
    public var recordType: String?
}

public extension CKRecordZoneSubscription {
    var dictionary: [String: Any] {
        var subscription: [String: Any] =  [
            "subscriptionID": subscriptionID,
            "subscriptionType": subscriptionType.description,
            "zoneID": zoneID.dictionary as Any
        ]

        if let notificationInfo = notificationInfo {
            subscription["notificationInfo"] = notificationInfo.dictionary
        }
        return subscription
    }
}

public extension CKSubscription {
    class NotificationInfo : NSObject {
        public var alertBody: String?
        public var alertLocalizationKey: String?
        public var alertLocalizationArgs: [String]?
        public var alertActionLocalizationKey: String?
        public var alertLaunchImage: String?
        public var soundName: String?
        public var desiredKeys: [CKRecord.FieldKey]?
        public var shouldBadge: Bool = false
        public var shouldSendContentAvailable: Bool = false
        public var category: String?
    }
}

extension CKSubscription.NotificationInfo {
    var dictionary: [String: Any] {
        var notificationInfo: [String: Any] = [:]
        notificationInfo[CKNotificationInfoDictionary.alertBodyKey] = alertBody
        notificationInfo[CKNotificationInfoDictionary.alertLocalizationKey] = alertLocalizationKey
        notificationInfo[CKNotificationInfoDictionary.alertLocalizationArgsKey] = alertLocalizationArgs
        notificationInfo[CKNotificationInfoDictionary.alertActionLocalizationKeyKey] = alertActionLocalizationKey
        notificationInfo[CKNotificationInfoDictionary.alertLaunchImageKey] = alertLaunchImage
        notificationInfo[CKNotificationInfoDictionary.soundName] = soundName
        notificationInfo[CKNotificationInfoDictionary.shouldBadge] = NSNumber(value: shouldBadge)
        notificationInfo[CKNotificationInfoDictionary.shouldSendContentAvailable] = NSNumber(value: shouldSendContentAvailable)
        return notificationInfo
    }
}

struct CKNotificationInfoDictionary {
    static let alertBodyKey = "alertBody"
    static let alertLocalizationKey = "alertLocalizationKey"
    static let alertLocalizationArgsKey = "alertLocalizationArgs"
    static let alertActionLocalizationKeyKey = "alertActionLocalizationKey"
    static let alertLaunchImageKey = "alertLaunchImage"
    static let soundName = "soundName"
    static let shouldBadge = "shouldBadge"
    static let shouldSendContentAvailable = "shouldSendContentAvailable"
}

