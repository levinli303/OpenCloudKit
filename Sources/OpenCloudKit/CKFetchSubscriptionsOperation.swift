//
//  CKFetchSubscriptionsOperation.swift
//  OpenCloudKit
//
//  Created by Ben Johnson on 13/07/2016.
//
//

import Foundation
import NIOHTTP1

extension CKDatabase {
    public func subscriptions(for ids: [CKSubscription.ID]) async throws -> [CKSubscription.ID : Result<CKSubscription, Error>] {
        let request = CKURLRequestBuilder(database: self, operationType: .subscriptions, path: "lookup")
            .setParameter(key: "subscriptions", value: ids)
            .build()

        let dictionary = try await CKURLRequestHelper.performURLRequest(request)
        var subscriptions = [CKSubscription.ID: Result<CKSubscription, Error>]()

        // Process subscriptions
        guard let subscriptionsDictionary = dictionary["subscriptions"] as? [[String: Sendable]] else {
            throw CKError.keyMissing(key: "subscriptions")
        }

        // Parse JSON into CKSubscription
        for subscriptionDictionary in subscriptionsDictionary {
            if let fetchError = CKSubscriptionFetchError(dictionary: subscriptionDictionary) {
                // Partial error
                subscriptions[fetchError.subscriptionID] = .failure(CKError.subscriptionFetchError(error: fetchError))
            } else if let subscription = CKSubscription(dictionary: subscriptionDictionary) {
                subscriptions[subscription.subscriptionID] = .success(subscription)
            } else {
                // Unknown error
                throw CKError.formatError(userInfo: subscriptionDictionary)
            }
        }
        return subscriptions
    }

    public func allSubscriptions() async throws -> [CKSubscription] {
        let request = CKURLRequestBuilder(database: self, operationType: .subscriptions, path: "list")
            .setHTTPMethod(.GET)
            .build()

        let dictionary = try await CKURLRequestHelper.performURLRequest(request)
        var subscriptions = [CKSubscription]()

        // Process subscriptions
        guard let subscriptionsDictionary = dictionary["subscriptions"] as? [[String: Sendable]] else {
            throw CKError.keyMissing(key: "subscriptions")
        }

        // Parse JSON into CKSubscription
        for subscriptionDictionary in subscriptionsDictionary {
            if let subscription = CKSubscription(dictionary: subscriptionDictionary) {
                subscriptions.append(subscription)
            } else {
                // Unknown error
                throw CKError.formatError(userInfo: subscriptionDictionary)
            }
        }
        return subscriptions
    }
}
