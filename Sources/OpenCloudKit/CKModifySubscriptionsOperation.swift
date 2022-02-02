//
//  CKModifySubscriptionsOperation.swift
//  OpenCloudKit
//
//  Created by Ben Johnson on 12/07/2016.
//
//

import Foundation

#if !os(iOS) && !os(macOS) && os(watchOS) && !os(tvOS)
import FoundationNetworking
#endif

public struct CKSubscriptionFetchError {
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

    init?(dictionary: [String: Any]) {
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

public class CKModifySubscriptionsOperation : CKDatabaseOperation {
    public init(subscriptionsToSave: [CKSubscription]?, subscriptionIDsToDelete: [String]?) {
        super.init()

        self.subscriptionsToSave = subscriptionsToSave
        self.subscriptionIDsToDelete = subscriptionIDsToDelete
    }

    public var subscriptionsToSave: [CKSubscription]?
    public var subscriptionIDsToDelete: [String]?

    public var modifySubscriptionsResultBlock: ((_ operationResult: Result<Void, Error>) -> Void)?
    public var perSubscriptionDeleteBlock: ((_ subscriptionID: CKSubscription.ID, _ deleteResult: Result<Void, Error>) -> Void)?
    public var perSubscriptionSaveBlock: ((_ subscriptionID: CKSubscription.ID, _ saveResult: Result<CKSubscription, Error>) -> Void)?

    override func performCKOperation() {
        let db = database ?? CKContainer.default().publicCloudDatabase
        task = Task { [weak self] in
            do {
                let (saveResults, deleteResults) = try await db.modifySubscriptions(saving: subscriptionsToSave ?? [], deleting: subscriptionIDsToDelete ?? [])
                guard let self = self else { return }

                for (subscriptionID, result) in saveResults {
                    callbackQueue.async {
                        self.perSubscriptionSaveBlock?(subscriptionID, result)
                    }
                }

                for (subscriptionID, result) in deleteResults {
                    callbackQueue.async {
                        self.perSubscriptionDeleteBlock?(subscriptionID, result)
                    }
                }

                callbackQueue.async {
                    self.modifySubscriptionsResultBlock?(.success(()))
                    self.finishOnCallbackQueue()
                }
            }
            catch {
                guard let self = self else { return }

                callbackQueue.async {
                    self.modifySubscriptionsResultBlock?(.failure(error))
                    self.finishOnCallbackQueue()
                }
            }
        }
    }
}

extension CKDatabase {
    private struct SubscriptionDeleteResponse {
        let subscriptionID: CKSubscription.ID
        let deleted: Bool

        init?(dictionary: [String: Any]) {
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
        guard let subscriptionsDictionary = dictionary["subscriptions"] as? [[String: Any]] else {
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
            } else if let deleteResponse = SubscriptionDeleteResponse(dictionary: subscriptionDictionary) {
                // Can deleted be false here?
                deleteResults[deleteResponse.subscriptionID] = .success(())
            } else if let subscription = CKSubscription(dictionary: subscriptionDictionary) {
                saveResults[subscription.subscriptionID] = .success(subscription)
            } else {
                // Unknown error
                throw CKError.conversionError
            }
        }
        return (saveResults, deleteResults)
    }

    private func modifySubscriptionOperationsDictionary(subscriptionsToSave: [CKSubscription], subscriptionIDsToDelete: [CKSubscription.ID]) -> [[String: Any]] {

        var operationDictionaryArray: [[String: Any]] = []
        let saveOperations = subscriptionsToSave.map({ (subscription) -> [String: Any] in
            let operation: [String: Any] = [
                "operationType": "create",
                "subscription": ["subscriptionID": subscription.subscriptionID]
            ]

            return operation
        })
        operationDictionaryArray += saveOperations

        let deleteOperations = subscriptionIDsToDelete.map({ (subscriptionID) -> [String: Any] in
            let operation: [String: Any] = [
                "operationType": "delete",
                "subscription": ["subscriptionID": subscriptionID]
            ]

            return operation
        })
        operationDictionaryArray += deleteOperations

        return operationDictionaryArray
    }
}
