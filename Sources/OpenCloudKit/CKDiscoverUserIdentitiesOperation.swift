//
//  CKDiscoverUserIdentitiesOperation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 14/07/2016.
//
//

import Foundation

public class CKDiscoverUserIdentitiesOperation : CKOperation {
    public override init() {
        userIdentityLookupInfos = []
        super.init()
    }

    public convenience init(userIdentityLookupInfos: [CKUserIdentityLookupInfo]) {
        self.init()
        self.userIdentityLookupInfos = userIdentityLookupInfos
    }

    public var userIdentityLookupInfos: [CKUserIdentityLookupInfo]

    public var userIdentityDiscoveredBlock: ((CKUserIdentity, CKUserIdentityLookupInfo) -> Void)?

    public var discoverUserIdentitiesCompletionBlock: ((Error?) -> Void)?

    override func finishOnCallbackQueue(error: Error?) {
        self.discoverUserIdentitiesCompletionBlock?(error)
        super.finishOnCallbackQueue(error: error)
    }

    func discovered(userIdentity: CKUserIdentity, lookupInfo: CKUserIdentityLookupInfo){
        callbackQueue.async {
            self.userIdentityDiscoveredBlock?(userIdentity, lookupInfo)
        }
    }

    override func performCKOperation() {

        let url = "\(databaseURL)/public/users/discover"
        let lookUpInfos = userIdentityLookupInfos.map { (lookupInfo) -> [String: Any] in
            return lookupInfo.dictionary
        }

        let request: [String: Any] = ["lookupInfos": lookUpInfos as Any]

        urlSessionTask = CKWebRequest(container: operationContainer).request(withURL: url, parameters: request) { [weak self] (dictionary, error) in
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
                if let userIdenity = CKUserIdentity(dictionary: userDictionary) {
                    // Call RecordCallback
                    strongSelf.discovered(userIdentity: userIdenity, lookupInfo: userIdenity.lookupInfo!)
                } else {
                    // Create Error
                    returnError = CKPrettyError(code: .partialFailure, description: CKErrorStringFailedToParseRecord)
                    // Call RecordCallback
                    return
                }
            }
        }
    }
}
