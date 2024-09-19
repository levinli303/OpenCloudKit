//
//  CKModifySubscriptionsOperation.swift
//  OpenCloudKit
//
//  Created by Ben Johnson on 12/07/2016.
//
//

import Foundation

public struct CKSubscriptionFetchError: Sendable {
    static let subscriptionIDKey = "subscriptionID"
    static let reasonKey = "reason"
    static let serverErrorCodeKey = "serverErrorCode"
    static let retryAfterKey = "retryAfter"
    static let uuidKey = "uuid"
    static let redirectURLKey = "redirectURL"

    public let subscriptionID: CKSubscription.ID
    public let reason: String?
    public let serverErrorCode: CKServerError
    public let retryAfter: TimeInterval?
    public let uuid: String?
    public let redirectURL: URL?

    init?(dictionary: [String: Sendable]) {
        guard let subscriptionID = dictionary[CKSubscriptionFetchError.subscriptionIDKey] as? CKSubscription.ID,
              let reason = dictionary[CKSubscriptionFetchError.reasonKey] as? String,
              let serverErrorCode = dictionary[CKSubscriptionFetchError.serverErrorCodeKey] as? String,
              let errorCode = CKServerError(rawValue: serverErrorCode) else {
            return nil
        }

        self.subscriptionID = subscriptionID
        self.reason = reason
        self.serverErrorCode = errorCode

        self.uuid = dictionary[CKSubscriptionFetchError.uuidKey] as? String

        self.retryAfter = dictionary[CKSubscriptionFetchError.retryAfterKey] as? TimeInterval
        if let urlString = dictionary[CKSubscriptionFetchError.redirectURLKey] as? String {
            self.redirectURL = URL(string: urlString)
        } else {
            self.redirectURL = nil
        }
    }
}

extension CKDatabase {
    private struct SubscriptionDeleteResponse {
        let subscriptionID: CKSubscription.ID
        let deleted: Bool

        init?(dictionary: [String: Sendable]) {
            guard let subscriptionID = dictionary["subscriptionID"] as? CKSubscription.ID, let deleted = dictionary["deleted"] as? Bool else {
                return nil
            }
            self.subscriptionID = subscriptionID
            self.deleted = deleted
        }
    }

    public func modifySubscriptions(saving subscriptionsToSave: [CKSubscription], deleting subscriptionIDsToDelete: [CKSubscription.ID]) async throws -> (saveResults: [CKSubscription.ID : Result<CKSubscription, Error>], deleteResults: [CKSubscription.ID : Result<Void, Error>]) {
        let modifyOperationDictionaryArray = modifySubscriptionOperationsDictionary(subscriptionsToSave: subscriptionsToSave, subscriptionIDsToDelete: subscriptionIDsToDelete)
        let request = CKURLRequestBuilder(database: self, operationType: .subscriptions, path: "modify")
            .setParameter(key: "operations", value: modifyOperationDictionaryArray)
            .build()
        let dictionary = try await CKURLRequestHelper.performURLRequest(request)

        // Process subscriptions
        guard let subscriptionsDictionary = dictionary["subscriptions"] as? [[String: Sendable]] else {
            throw CKError.keyMissing(key: "subscriptions")
        }

        var saveResults = [CKSubscription.ID: Result<CKSubscription, Error>]()
        var deleteResults = [CKSubscription.ID: Result<Void, Error>]()
        for (index, subscriptionDictionary) in subscriptionsDictionary.enumerated() {
            if let fetchError = CKSubscriptionFetchError(dictionary: subscriptionDictionary) {
                // Partial error
                let subscriptionID = fetchError.subscriptionID
                if index < subscriptionsToSave.count {
                    saveResults[subscriptionID] = .failure(CKError.subscriptionFetchError(error: fetchError))
                } else {
                    deleteResults[subscriptionID] = .failure(CKError.subscriptionFetchError(error: fetchError))
                }
            } else if let deleteResponse = SubscriptionDeleteResponse(dictionary: subscriptionDictionary), deleteResponse.deleted {
                deleteResults[deleteResponse.subscriptionID] = .success(())
            } else if let subscription = CKSubscription(dictionary: subscriptionDictionary) {
                saveResults[subscription.subscriptionID] = .success(subscription)
            } else {
                // Unknown error
                throw CKError.formatError(userInfo: subscriptionDictionary)
            }
        }
        return (saveResults, deleteResults)
    }

    private func modifySubscriptionOperationsDictionary(subscriptionsToSave: [CKSubscription], subscriptionIDsToDelete: [CKSubscription.ID]) -> [[String: Sendable]] {

        var operationDictionaryArray: [[String: Sendable]] = []
        let saveOperations = subscriptionsToSave.map({ (subscription) -> [String: Sendable] in
            let operation: [String: Sendable] = [
                "operationType": "create",
                "subscription": ["subscriptionID": subscription.subscriptionID]
            ]

            return operation
        })
        operationDictionaryArray += saveOperations

        let deleteOperations = subscriptionIDsToDelete.map({ (subscriptionID) -> [String: Sendable] in
            let operation: [String: Sendable] = [
                "operationType": "delete",
                "subscription": ["subscriptionID": subscriptionID]
            ]

            return operation
        })
        operationDictionaryArray += deleteOperations

        return operationDictionaryArray
    }
}
