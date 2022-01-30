//
//  CKDiscoverAllUserIdentitiesOperation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 14/07/2016.
//
//

import Foundation

public class CKDiscoverAllUserIdentitiesOperation : CKOperation {
    var discoveredIdentities: [CKUserIdentity] = []

    public override init() {
        super.init()
    }

    public var userIdentityDiscoveredBlock: ((CKUserIdentity) -> Void)?

    public var discoverAllUserIdentitiesCompletionBlock: ((Error?) -> Void)?

    override func finishOnCallbackQueue(error: Error?) {
        self.discoverAllUserIdentitiesCompletionBlock?(error)

        super.finishOnCallbackQueue(error: error)
    }

    func discovered(userIdentity: CKUserIdentity){
        callbackQueue.async {
            self.userIdentityDiscoveredBlock?(userIdentity)
        }
    }

    override func performCKOperation() {
        let url = "\(databaseURL)/public/users/discover"

        urlSessionTask = CKWebRequest(container: operationContainer).request(withURL: url, parameters: nil) { [weak self] dictionary, error in
            guard let strongSelf = self else { return }

            var returnError = error

            defer {
                strongSelf.finish(error: returnError)
            }

            guard !strongSelf.isCancelled else { return }

            if error != nil {
                return
            }

            guard let userDictionaries = dictionary?["users"] as? [[String: Any]] else {
                returnError = CKPrettyError(code: .internalError, description: CKErrorStringFailedToParseServerResponse)
                return
            }

            // Process Records
            // Parse JSON into CKRecords
            for userDictionary in userDictionaries {
                if let userIdentity = CKUserIdentity(dictionary: userDictionary) {
                    strongSelf.discoveredIdentities.append(userIdentity)

                    // Call discovered callback
                    strongSelf.discovered(userIdentity: userIdentity)
                } else {
                    // Create Error
                    returnError = CKPrettyError(code: .partialFailure, description: CKErrorStringFailedToParseRecord)
                    return
                }
            }
        }
    }
}
