//
//  CKModifyRecordZonesOperation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 15/07/2016.
//
//

import Foundation

public class CKModifyRecordZonesOperation : CKDatabaseOperation {
    public override init() {
        super.init()
    }

    public convenience init(recordZonesToSave: [CKRecordZone]?, recordZoneIDsToDelete: [CKRecordZone.ID]?) {
        self.init()
        self.recordZonesToSave = recordZonesToSave
        self.recordZoneIDsToDelete = recordZoneIDsToDelete
    }

    public var recordZonesToSave: [CKRecordZone]?

    public var recordZoneIDsToDelete: [CKRecordZone.ID]?

    var recordZoneErrors: [CKRecordZone.ID: NSError] = [:]

    var recordZonesByZoneIDs:[CKRecordZone.ID: CKRecordZone] = [:]

    /*  This block is called when the operation completes.
     The [NSOperation completionBlock] will also be called if both are set.
     If the error is CKErrorPartialFailure, the error's userInfo dictionary contains
     a dictionary of recordZoneIDs to errors keyed off of CKPartialErrorsByItemIDKey.
     This call happens as soon as the server has
     seen all record changes, and may be invoked while the server is processing the side effects
     of those changes.
     */
    public var modifyRecordZonesCompletionBlock: (([CKRecordZone]?, [CKRecordZone.ID]?, Error?) -> Swift.Void)?

    func zoneOperations() -> [[String: Any]] {

        var operationDictionaries: [[String: Any]] = []
        if let recordZonesToSave = recordZonesToSave {
            let saveOperations = recordZonesToSave.map({ (zone) -> [String: Any] in

                let operation: [String: Any] = [
                    "operationType": "create",
                    "zone": ["zoneID": zone.zoneID.dictionary] as Any
                ]

                return operation
            })

            operationDictionaries.append(contentsOf: saveOperations)
        }

        if let recordZoneIDsToDelete = recordZoneIDsToDelete {
            let deleteOperations = recordZoneIDsToDelete.map({ (zoneID) -> [String: Any] in

                let operation: [String: Any] = [
                    "operationType": "delete",
                    "zone": ["zoneID": zoneID.dictionary] as Any
                ]

                return operation
            })

            operationDictionaries.append(contentsOf: deleteOperations)
        }

        return operationDictionaries
    }

    override func finishOnCallbackQueue(error: Error?) {
        var error = error
        if(error == nil){
            if self.recordZoneErrors.count > 0 {
                error = CKPrettyError(code: CKErrorCode.partialFailure, userInfo: [CKPartialErrorsByItemIDKey: recordZoneErrors], description: "Failed to modify some zones")
            }
        }

        // Call the final completionBlock
        self.modifyRecordZonesCompletionBlock?(Array(self.recordZonesByZoneIDs.values), self.recordZoneIDsToDelete, error)

        super.finishOnCallbackQueue(error: error)
    }

    override func performCKOperation() {

        let url = "\(databaseURL)/zones/modify"
        let zoneOperations = self.zoneOperations()

        let request: [String: Any] = ["operations": zoneOperations]

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
                    strongSelf.recordZonesByZoneIDs[zone.zoneID] = zone
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
