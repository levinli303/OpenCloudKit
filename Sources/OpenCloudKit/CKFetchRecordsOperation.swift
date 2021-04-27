//
//  CKFetchRecordsOperation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 7/07/2016.
//
//

import Foundation

public class CKFetchRecordsOperation: CKDatabaseOperation {
    var isFetchCurrentUserOperation = false

    var recordErrors: [CKRecordID: Error] = [:] // todo use this for partial errors

    var shouldFetchAssetContent: Bool = false

    var recordIDsToRecords: [CKRecordID: CKRecord] = [:]

    /* Called repeatedly during transfer. */
    public var perRecordProgressBlock: ((CKRecordID, Double) -> Void)?

    /* Called on success or failure for each record. */
    public var perRecordCompletionBlock: ((CKRecord?, CKRecordID?, Error?) -> Void)?

    /*  This block is called when the operation completes.
     The [NSOperation completionBlock] will also be called if both are set.
     If the error is CKErrorPartialFailure, the error's userInfo dictionary contains
     a dictionary of recordIDs to errors keyed off of CKPartialErrorsByItemIDKey.
     */
    public var fetchRecordsCompletionBlock: (([CKRecordID : CKRecord]?, Error?) -> Void)?

    public class func fetchCurrentUserRecord() -> Self {
        let operation = self.init()
        operation.isFetchCurrentUserOperation = true

        return operation
    }

    public override required init() {
        super.init()
    }

    public var recordIDs: [CKRecordID]?

    public var desiredKeys: [String]?

    public convenience init(recordIDs: [CKRecordID]) {
        self.init()
        self.recordIDs = recordIDs
    }

    override func finishOnCallbackQueue(error: Error?) {
        var error = error
        if error == nil {
            // report any partial errors
            if recordErrors.count > 0 {
                error = CKPrettyError(code: CKErrorCode.partialFailure, userInfo: [CKPartialErrorsByItemIDKey: recordErrors], description: CKErrorStringPartialErrorRecords)
            }
        }

        fetchRecordsCompletionBlock?(recordIDsToRecords, error)

        perRecordProgressBlock = nil
        fetchRecordsCompletionBlock = nil
        perRecordCompletionBlock = nil

        super.finishOnCallbackQueue(error: error)
    }

    func completed(record: CKRecord?, recordID: CKRecordID?, error: Error?){
        callbackQueue.async {
            self.perRecordCompletionBlock?(record, recordID, error)
        }
    }

    func progressed(recordID: CKRecordID, progress: Double){
        callbackQueue.async {
            self.perRecordProgressBlock?(recordID, progress)
        }
    }

    override func performCKOperation() {
        // Generate the CKOperation Web Service URL
        let url = "\(operationURL)/records/\(CKRecordOperation.lookup)"

        var request: [String: Any] = [:]
        let lookupRecords = recordIDs?.map { (recordID) -> [String: Any] in
            return ["recordName": recordID.recordName]
        }

        request["records"] = lookupRecords

        urlSessionTask = CKWebRequest(container: operationContainer).request(withURL: url, parameters: request) { [weak self] dictionary, error in
            guard let strongSelf = self else { return }

            var returnError = error

            defer {
                strongSelf.finish(error: returnError)
            }

            guard !strongSelf.isCancelled else { return }

            guard let dictionary = dictionary,
                  let recordsDictionary = dictionary["records"] as? [[String: Any]],
                  error == nil else {
                return
            }

            // Process Records
            // Parse JSON into CKRecords
            for (index, recordDictionary) in recordsDictionary.enumerated() {
                // Call Progress Block, this is hacky support and not the callbacks intented purpose
                let progress = Double(index + 1) / Double((strongSelf.recordIDs!.count))
                let recordID = strongSelf.recordIDs![index]
                strongSelf.progressed(recordID: recordID, progress: progress)

                if let record = CKRecord(recordDictionary: recordDictionary, recordID: recordID) {
                    strongSelf.recordIDsToRecords[record.recordID] = record

                    // Call per record callback, not to be confused with finished
                    strongSelf.completed(record: record, recordID: record.recordID, error: nil)

                } else if let recordFetchError = CKRecordFetchErrorDictionary(dictionary: recordDictionary) {
                    // Create Error
                    let error = CKPrettyError(recordFetchError: recordFetchError)
                    // TODO: which zone?
                    let recordID = CKRecordID(recordName: recordFetchError.recordName!)

                    strongSelf.recordErrors[recordID] = error

                    strongSelf.completed(record: nil, recordID: recordID, error: error)
                } else {
                    returnError = CKPrettyError(code: .partialFailure, description: CKErrorStringFailedToResolveRecord)
                    return
                }
            }
        }
    }
}
