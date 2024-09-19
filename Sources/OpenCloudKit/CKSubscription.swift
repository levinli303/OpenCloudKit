//
//  CKSubscription.swift
//  OpenCloudKit
//
//  Created by Ben Johnson on 12/07/2016.
//
//

import Foundation

public protocol CustomDictionaryConvertible {
    var dictionary: [String: Sendable] { get }
}

public class CKSubscription: NSObject, @unchecked Sendable {
    public enum SubscriptionType : Int, CustomStringConvertible, Sendable {
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

    public typealias ID = String

    public let subscriptionID: ID
    public let subscriptionType: SubscriptionType
    public var notificationInfo: NotificationInfo?

    init(subscriptionID: String, subscriptionType: SubscriptionType) {
        self.subscriptionID = subscriptionID
        self.subscriptionType = subscriptionType
    }
    
    init?(dictionary: [String: Sendable]) {
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
    public var subscriptionDictionary: [String: Sendable] {
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


extension CKQuerySubscription {
    public struct Options : OptionSet {
        public var rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static var firesOnRecordCreation: Options { return Options(rawValue: 1) }
        public static var firesOnRecordUpdate: Options { return Options(rawValue: 2)  }
        public static var firesOnRecordDeletion: Options { return Options(rawValue: 4)  }
        public static var firesOnce: Options {  return Options(rawValue: 8) }

        var firesOnArray: [String] {
            var array: [String] = []
            if contains(Options.firesOnRecordCreation) {
                array.append("create")
            }

            if contains(Options.firesOnRecordUpdate) {
                array.append("update")
            }

            if contains(Options.firesOnRecordDeletion) {
                array.append("delete")
            }

            return array
        }
    }
}


public class CKQuerySubscription : CKSubscription, @unchecked Sendable {
    public convenience init(recordType: String, filters: [CKQueryFilter], options querySubscriptionOptions: Options) {
        let subscriptionID = UUID().uuidString
        self.init(recordType: recordType, filters: filters, subscriptionID: subscriptionID, options: querySubscriptionOptions)
    }
    
    public init(recordType: String, filters: [CKQueryFilter], subscriptionID: String, options querySubscriptionOptions: Options) {
        self.filters = filters
        self.recordType = recordType
        self.querySubscriptionOptions = querySubscriptionOptions
        super.init(subscriptionID: subscriptionID, subscriptionType: SubscriptionType.query)
    }
    
    /* The record type that this subscription watches */
    public let recordType: String
    /* Filters that determines when the subscription fires. */
    public var filters: [CKQueryFilter]
    /* Optional property.  If set, a query subscription is scoped to only record changes in the indicated zone. */
    public var zoneID: CKRecordZone.ID?
    public let querySubscriptionOptions: Options
}

extension CKQuerySubscription {
     public var dictionary: [String: Sendable] {
        let query = CKQuery(recordType: recordType, filters: filters)
        var subscription: [String: Sendable] =  ["subscriptionID": subscriptionID,
                "subscriptionType": subscriptionType.description,
                "query": query.dictionary,
                "firesOn": querySubscriptionOptions.firesOnArray]
        if querySubscriptionOptions.contains(.firesOnce) {
            subscription["firesOnce"] = NSNumber(value: true)
        }
        if let notificationInfo = notificationInfo {
            subscription["notificationInfo"] = notificationInfo.dictionary
        }
        return subscription
    }
}

public class CKRecordZoneSubscription : CKSubscription, @unchecked Sendable {
    public convenience init(zoneID: CKRecordZone.ID) {
        let subscriptionID = UUID().uuidString
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
    var dictionary: [String: Sendable] {
        var subscription: [String: Sendable] =  [
            "subscriptionID": subscriptionID,
            "subscriptionType": subscriptionType.description,
            "zoneID": zoneID.dictionary
        ]

        if let notificationInfo = notificationInfo {
            subscription["notificationInfo"] = notificationInfo.dictionary
        }
        return subscription
    }
}

public extension CKSubscription {
    struct NotificationInfo {
        public let alertBody: String?
        public let alertLocalizationKey: String?
        public let alertLocalizationArgs: [String]?
        public let alertActionLocalizationKey: String?
        public let alertLaunchImage: String?
        public let soundName: String?
        public let desiredKeys: [CKRecord.FieldKey]?
        public let shouldBadge: Bool = false
        public let shouldSendContentAvailable: Bool = false
        public let category: String?
    }
}

extension CKSubscription.NotificationInfo {
    var dictionary: [String: Sendable] {
        var notificationInfo: [String: Sendable] = [:]
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

