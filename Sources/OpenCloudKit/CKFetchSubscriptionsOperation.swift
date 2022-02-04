//
//  CKFetchSubscriptionsOperation.swift
//  OpenCloudKit
//
//  Created by Ben Johnson on 13/07/2016.
//
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class CKFetchSubscriptionsOperation : CKDatabaseOperation {
    public override required init() {
        super.init()
    }

    public static func fetchAllSubscriptionsOperation() -> CKFetchSubscriptionsOperation {
        return CKFetchSubscriptionsOperation()
    }

    public convenience init(subscriptionIDs: [CKSubscription.ID]) {
        self.init()
        self.subscriptionIDs = subscriptionIDs
    }

    public var subscriptionIDs: [CKSubscription.ID]?
    public var fetchSubscriptionsResultBlock: ((_ operationResult: Result<Void, Error>) -> Void)?
    public var perSubscriptionResultBlock: ((_ subscriptionID: CKSubscription.ID, _ subscriptionResult: Result<CKSubscription, Error>) -> Void)?

    override func performCKOperation() {
        let db = database ?? CKContainer.default().publicCloudDatabase
        task = Task { [weak self] in
            if let ids = subscriptionIDs {
                do {
                    let subscriptionResults = try await db.subscriptions(for: ids)
                    guard let self = self else { return }
                    for (subscriptionID, subscriptionResult) in subscriptionResults {
                        self.callbackQueue.async {
                            self.perSubscriptionResultBlock?(subscriptionID, subscriptionResult)
                        }
                    }
                    self.callbackQueue.async {
                        self.fetchSubscriptionsResultBlock?(.success(()))
                        self.finishOnCallbackQueue()
                    }
                }
                catch {
                    guard let self = self else { return }
                    self.callbackQueue.async {
                        self.fetchSubscriptionsResultBlock?(.failure(error))
                        self.finishOnCallbackQueue()
                    }
                }
            }
            else {
                do {
                    let subscriptionResults = try await db.allSubscriptions()
                    guard let self = self else { return }
                    for subscription in subscriptionResults {
                        self.callbackQueue.async {
                            self.perSubscriptionResultBlock?(subscription.subscriptionID, .success(subscription))
                        }
                    }
                    self.callbackQueue.async {
                        self.fetchSubscriptionsResultBlock?(.success(()))
                        self.finishOnCallbackQueue()
                    }
                }
                catch {
                    guard let self = self else { return }
                    self.callbackQueue.async {
                        self.fetchSubscriptionsResultBlock?(.failure(error))
                        self.finishOnCallbackQueue()
                    }
                }
            }
        }
    }
}

extension CKDatabase {
    public func subscriptions(for ids: [CKSubscription.ID]) async throws -> [CKSubscription.ID : Result<CKSubscription, Error>] {
        let request = CKURLRequestBuilder(database: self, operationType: .subscriptions, path: "lookup")
            .setParameter(key: "subscriptions", value: ids)
            .build()

        let dictionary = try await CKURLRequestHelper.performURLRequest(request)
        var subscriptions = [CKSubscription.ID: Result<CKSubscription, Error>]()

        // Process subscriptions
        guard let subscriptionsDictionary = dictionary["subscriptions"] as? [[String: Any]] else {
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
                throw CKError.conversionError
            }
        }
        return subscriptions
    }

    public func allSubscriptions() async throws -> [CKSubscription] {
        let request = CKURLRequestBuilder(database: self, operationType: .subscriptions, path: "list")
            .setHTTPMethod("GET")
            .build()

        let dictionary = try await CKURLRequestHelper.performURLRequest(request)
        var subscriptions = [CKSubscription]()

        // Process subscriptions
        guard let subscriptionsDictionary = dictionary["subscriptions"] as? [[String: Any]] else {
            throw CKError.keyMissing(key: "subscriptions")
        }

        // Parse JSON into CKSubscription
        for subscriptionDictionary in subscriptionsDictionary {
            if let subscription = CKSubscription(dictionary: subscriptionDictionary) {
                subscriptions.append(subscription)
            } else {
                // Unknown error
                throw CKError.conversionError
            }
        }
        return subscriptions
    }
}
