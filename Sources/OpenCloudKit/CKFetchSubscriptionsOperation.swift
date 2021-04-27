//
//  CKFetchSubscriptionsOperation.swift
//  OpenCloudKit
//
//  Created by Ben Johnson on 13/07/2016.
//
//

import Foundation

public class CKFetchSubscriptionsOperation : CKDatabaseOperation {
    public var subscriptionErrors : [String : NSError] = [:]

    public var subscriptionsIDToSubscriptions: [String: CKSubscription] = [:]

    public override required init() {
        super.init()
    }

    public class func fetchAllSubscriptionsOperation() -> Self {
        let operation = self.init()
        return operation
    }

    public convenience init(subscriptionIDs: [String]) {
        self.init()
        self.subscriptionIDs = subscriptionIDs
    }

    public var subscriptionIDs: [String]?

    /*  This block is called when the operation completes.
     The [NSOperation completionBlock] will also be called if both are set.
     If the error is CKErrorPartialFailure, the error's userInfo dictionary contains
     a dictionary of subscriptionID to errors keyed off of CKPartialErrorsByItemIDKey.
     */
    public var fetchSubscriptionCompletionBlock: (([String : CKSubscription]?, Error?) -> Void)?

    override func finishOnCallbackQueue(error: Error?) {
        var error = error
        if error == nil {
            if subscriptionErrors.count > 0 {
                error = CKPrettyError(code: .partialFailure, userInfo: [CKPartialErrorsByItemIDKey: subscriptionErrors], description: CKErrorStringPartialErrorSubscriptions)
            }
        }
        self.fetchSubscriptionCompletionBlock?(subscriptionsIDToSubscriptions, error)

        super.finishOnCallbackQueue(error: error)
    }

    override func performCKOperation() {

        let url = "\(operationURL)/subscriptions/lookup"

        var request: [String: Any] = [:]
        if let subscriptionIDs = subscriptionIDs {

            request["subscriptions"] = subscriptionIDs
        }


        urlSessionTask = CKWebRequest(container: operationContainer).request(withURL: url, parameters: request) { [weak self] dictionary, networkError in
            guard let strongSelf = self else { return }

            var returnError = networkError

            defer {
                strongSelf.finish(error: returnError)
            }

            guard !strongSelf.isCancelled else { return }

            if networkError == nil { return }

            guard let subscriptionsDictionary = dictionary?["subscriptions"] as? [[String: Any]] else {
                returnError = CKPrettyError(code: .internalError, description: CKErrorStringFailedToParseServerResponse)
                return
            }

            // Parse JSON into CKRecords
            for subscriptionDictionary in subscriptionsDictionary {
                if let subscription = CKSubscription(dictionary: subscriptionDictionary) {
                    // Append Record
                    strongSelf.subscriptionsIDToSubscriptions[subscription.subscriptionID] = subscription

                } else if let subscriptionFetchError = CKSubscriptionFetchErrorDictionary(dictionary: subscriptionDictionary) {
                    let error = CKPrettyError(subscriptionFetchError: subscriptionFetchError)
                    strongSelf.subscriptionErrors[subscriptionFetchError.subscriptionID] = error
                } else {
                    returnError = CKPrettyError(code: .partialFailure, description: CKErrorStringFailedToParseRecord)
                    return
                }
            }
        }
        urlSessionTask?.resume()
    }
}
