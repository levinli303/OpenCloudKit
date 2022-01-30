//
//  CKFetchErrorDictionary.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 15/07/2016.
//
//

import Foundation

protocol CKFetchErrorDictionaryIdentifier {
    init?(dictionary: [String: Any])

    static var identifierKey: String { get }
}

extension CKRecordZone.ID: CKFetchErrorDictionaryIdentifier {
    @nonobjc static let identifierKey = "zoneID"
}

// TODO: Fix error handling
struct CKErrorDictionary {
    let reason: String
    let serverErrorCode: String
    let retryAfter: NSNumber?
    let redirectURL: String?
    let uuid: String

    init?(dictionary: [String: Any]) {
        guard
            let uuid = dictionary["uuid"] as? String,
            let reason = dictionary[CKRecordFetchErrorDictionary.reasonKey] as? String,
            let serverErrorCode = dictionary[CKRecordFetchErrorDictionary.serverErrorCodeKey] as? String
        else {
            return nil
        }

        self.uuid = uuid
        self.reason = reason
        self.serverErrorCode = serverErrorCode

        self.retryAfter = (dictionary[CKRecordFetchErrorDictionary.retryAfterKey] as? NSNumber)
        self.redirectURL = dictionary[CKRecordFetchErrorDictionary.redirectURLKey] as? String
    }
}

struct CKFetchErrorDictionary<T: CKFetchErrorDictionaryIdentifier> {
    let identifier: T
    let reason: String
    let serverErrorCode: String
    let retryAfter: NSNumber?
    let redirectURL: String?

    init?(dictionary: [String: Any]) {
        guard
            let identifier = T(dictionary: dictionary[T.identifierKey] as? [String: Any] ?? [:]),
            let reason = dictionary[CKRecordFetchErrorDictionary.reasonKey] as? String,
            let serverErrorCode = dictionary[CKRecordFetchErrorDictionary.serverErrorCodeKey] as? String
        else {
            return nil
        }

        self.identifier = identifier
        self.reason = reason
        self.serverErrorCode = serverErrorCode

        self.retryAfter = (dictionary[CKRecordFetchErrorDictionary.retryAfterKey] as? NSNumber)
        self.redirectURL = dictionary[CKRecordFetchErrorDictionary.redirectURLKey] as? String
    }
}
