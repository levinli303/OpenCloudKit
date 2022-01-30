//
//  CKFetchRecordZonesOperation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 15/07/2016.
//
//

import Foundation

public class CKFetchRecordZonesOperation : CKDatabaseOperation {
    public class func fetchAllRecordZonesOperation() -> Self {
        return self.init()
    }

    public override required init() {
        self.recordZoneIDs = nil
        super.init()
    }

    public init(recordZoneIDs zoneIDs: [CKRecordZone.ID]) {
        self.recordZoneIDs = zoneIDs
        super.init()
    }

    var isFetchAllRecordZonesOperation: Bool = false

    var recordZoneIDs : [CKRecordZone.ID]?

    var recordZoneErrors: [CKRecordZone.ID: NSError] = [:]

    public var recordZoneByZoneID: [CKRecordZone.ID: CKRecordZone] = [:]

    /*  This block is called when the operation completes.
     The [NSOperation completionBlock] will also be called if both are set.
     If the error is CKErrorPartialFailure, the error's userInfo dictionary contains
     a dictionary of zoneIDs to errors keyed off of CKPartialErrorsByItemIDKey.
     */
    public var fetchRecordZonesCompletionBlock: (([CKRecordZone.ID : CKRecordZone]?, Error?) -> Swift.Void)?

    override func finishOnCallbackQueue(error: Error?) {
        var error = error
        if error == nil {
            if self.recordZoneErrors.count > 0 {
                error = CKPrettyError(code: .partialFailure, userInfo: [CKPartialErrorsByItemIDKey: self.recordZoneErrors], description: CKErrorStringFailedToParseRecordZone)
            }
        }
        // Call the final completionBlock
        self.fetchRecordZonesCompletionBlock?(self.recordZoneByZoneID, error)

        super.finishOnCallbackQueue(error: error)
    }

    override func performCKOperation() {
        let url: String
        let request: [String: Any]?

        if let recordZoneIDs = recordZoneIDs {
            url = "\(databaseURL)/zones/lookup"
            let zones =  recordZoneIDs.map({ (zoneID) -> [String: Any] in
                return zoneID.dictionary
            })

            request = ["zones": zones]
        } else {
            url = "\(databaseURL)/zones/list"
            request = nil
        }

        urlSessionTask = CKWebRequest(container: operationContainer).request(withURL: url, parameters: request) { [weak self] dictionary, error in
            guard let strongSelf = self else { return }

            var returnError = error

            defer {
                strongSelf.finish(error: returnError)
            }

            guard !strongSelf.isCancelled else { return }

            if error != nil {
                return
            }

            guard let zoneDictionaries = dictionary?["zones"] as? [[String: Any]] else {
                returnError = CKPrettyError(code: .internalError, description: CKErrorStringFailedToParseServerResponse)
                return
            }

            // Parse JSON into CKRecords
            for zoneDictionary in zoneDictionaries {

                if let zone = CKRecordZone(dictionary: zoneDictionary) {
                    strongSelf.recordZoneByZoneID[zone.zoneID] = zone
                } else if let fetchError = CKFetchErrorDictionary<CKRecordZone.ID>(dictionary: zoneDictionary) {
                    let error = CKPrettyError(fetchError: fetchError)
                    strongSelf.recordZoneErrors[fetchError.identifier] = error
                } else {
                    returnError = CKPrettyError(code: .partialFailure, description: CKErrorStringFailedToParseRecordZone)
                    return
                }
            }
        }
    }
}
