//
//  CKModifyRecordsOperation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 8/07/2016.
//
//

import Foundation

#if os(Linux)
import FoundationNetworking
#endif

public enum CKRecordSavePolicy : Int {
    case IfServerRecordUnchanged
    case ChangedKeys
    case AllKeys
}

let CKErrorRetryAfterKey = "CKRetryAfter"
let CKErrorRedirectURLKey = "CKRedirectURL"
let CKPartialErrorsByItemIDKey: String = "CKPartialErrors"

struct CKSubscriptionFetchErrorDictionary {

    static let subscriptionIDKey = "subscriptionID"

    static let reasonKey = "reason"

    static let serverErrorCodeKey = "serverErrorCode"

    static let redirectURLKey = "redirectURL"

    let subscriptionID: String

    let reason: String

    let serverErrorCode: String

    let redirectURL: String?

    init?(dictionary: [String: Any]) {
        guard
            let subscriptionID = dictionary[CKSubscriptionFetchErrorDictionary.subscriptionIDKey] as? String,
            let reason = dictionary[CKSubscriptionFetchErrorDictionary.reasonKey] as? String,
            let serverErrorCode = dictionary[CKSubscriptionFetchErrorDictionary.serverErrorCodeKey] as? String else {
            return nil
        }

        self.subscriptionID = subscriptionID
        self.reason = reason
        self.serverErrorCode = serverErrorCode
        self.redirectURL = dictionary[CKSubscriptionFetchErrorDictionary.redirectURLKey] as? String

    }
}

struct CKRecordFetchErrorDictionary {

    static let recordNameKey = "recordName"
    static let reasonKey = "reason"
    static let serverErrorCodeKey = "serverErrorCode"
    static let retryAfterKey = "retryAfter"
    static let uuidKey = "uuid"
    static let redirectURLKey = "redirectURL"

    let recordName: String?
    let reason: String
    let serverErrorCode: String
    let retryAfter: NSNumber?
    let uuid: String?
    let redirectURL: String?

    init?(dictionary: [String: Any]) {

        guard  let reason = dictionary[CKRecordFetchErrorDictionary.reasonKey] as? String,
               let serverErrorCode = dictionary[CKRecordFetchErrorDictionary.serverErrorCodeKey] as? String  else {
            return nil
        }

        self.recordName = dictionary[CKRecordFetchErrorDictionary.recordNameKey] as? String
        self.reason = reason
        self.serverErrorCode = serverErrorCode

        self.uuid = dictionary[CKRecordFetchErrorDictionary.uuidKey] as? String


        self.retryAfter = (dictionary[CKRecordFetchErrorDictionary.retryAfterKey] as? NSNumber)
        self.redirectURL = dictionary[CKRecordFetchErrorDictionary.redirectURLKey] as? String

    }
}

public class CKModifyRecordsOperation: CKDatabaseOperation {

    public override init() {
        super.init()
    }

    public convenience init(recordsToSave records: [CKRecord]?, recordIDsToDelete recordIDs: [CKRecordID]?) {
        self.init()

        recordsToSave = records
        recordIDsToDelete = recordIDs
    }

    public var savePolicy: CKRecordSavePolicy = .IfServerRecordUnchanged

    public var recordsToSave: [CKRecord]?

    public var recordIDsToDelete: [CKRecordID]?

    //var recordsByRecordIDs: [CKRecordID: CKRecord] = [:] // not sure what this is for yet

    /* Determines whether the batch should fail atomically or not. YES by default.
     This only applies to zones that support CKRecordZoneCapabilityAtomic. */
    public var isAtomic: Bool = false

    public var zoneID: CKRecordZoneID?

    /* Called repeatedly during transfer.
     It is possible for progress to regress when a retry is automatically triggered.
     Todo: still to be implemented
     */
    public var perRecordProgressBlock: ((CKRecord, Double) -> Swift.Void)?

    /* Called on success or failure for each record. */
    public var perRecordCompletionBlock: ((CKRecord?, Error?) -> Swift.Void)?

    private var recordErrors: [CKRecordID: Error] = [:]

    private var savedRecords: [CKRecord]?

    private var deletedRecordIDs: [CKRecordID]?

    /*  This block is called when the operation completes.
     The [NSOperation completionBlock] will also be called if both are set.
     If the error is CKErrorPartialFailure, the error's userInfo dictionary contains
     a dictionary of recordIDs to errors keyed off of CKPartialErrorsByItemIDKey.
     This call happens as soon as the server has
     seen all record changes, and may be invoked while the server is processing the side effects
     of those changes.
     */
    public var modifyRecordsCompletionBlock: (([CKRecord]?, [CKRecordID]?, Error?) -> Swift.Void)?

    override func finishOnCallbackQueue(error: Error?) {
        var error = error
        if(error == nil){
            // report any partial errors

            if(recordErrors.count > 0){
                error = CKPrettyError(code: CKErrorCode.partialFailure, userInfo: [NSLocalizedDescriptionKey: "Partial Failure", CKPartialErrorsByItemIDKey: recordErrors], description: "Failed to modify some records")
            }
        }

        // Call the final completionBlock
        self.modifyRecordsCompletionBlock?(savedRecords, deletedRecordIDs, error)

        self.modifyRecordsCompletionBlock = nil
        self.perRecordProgressBlock = nil
        self.perRecordCompletionBlock = nil

        super.finishOnCallbackQueue(error: error)
    }

    func completed(record: CKRecord?, error: Error?){
        callbackQueue.async {
            self.perRecordCompletionBlock?(record, error)
        }
    }

    func progressed(record: CKRecord, progress: Double){
        callbackQueue.async {
            self.perRecordProgressBlock?(record, progress)
        }
    }

    override func CKOperationShouldRun() throws {

        // todo validate recordsToSave

        // "An added share is being saved without its rootRecord (%@)"

        // "You can't save and delete the same record (%@) in a single operation"

        // "You can't delete the same record (%@) twice in a single operation"

        // "Unexpected recordID in property recordIDsToDelete passed to %@: %@"

    }

    override func performCKOperation() {
        trackAssetsToUpload { [weak self] in
            guard let strongSelf = self, !strongSelf.isCancelled else { return }

            strongSelf.modifyRecord()
        }
    }

    private func modifyRecord() {
        // Generate the CKOperation Web Service URL
        let request = CKModifyRecordsURLRequest(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete, isAtomic: isAtomic, database: database!, savePolicy: savePolicy, zoneID: zoneID)
        request.accountInfoProvider = CloudKit.shared.defaultAccount

        request.completionBlock = { [weak self] (result) in

            guard let strongSelf = self, !strongSelf.isCancelled else {
                return
            }

            switch result {
            case .error(let error):
                strongSelf.modifyRecordsCompletionBlock?(nil, nil, error.error)
            case .success(let dictionary):

                // Process Records
                if let recordsDictionary = dictionary["records"] as? [[String: Any]] {

                    strongSelf.savedRecords = [CKRecord]()
                    strongSelf.deletedRecordIDs = [CKRecordID]()
                    // Parse JSON into CKRecords
                    for recordDictionary in recordsDictionary {

                        if let record = CKRecord(recordDictionary: recordDictionary) {
                            // Append Record
                            //self.recordsByRecordIDs[record.recordID] = record
                            strongSelf.savedRecords?.append(record)

                            // Call RecordCallback
                            strongSelf.completed(record: record, error: nil)

                        } else if let recordFetchError = CKRecordFetchErrorDictionary(dictionary: recordDictionary) {

                            // Create Error
                            let error = NSError(domain: CKErrorDomain, code: CKErrorCode.partialFailure.rawValue, userInfo: [NSLocalizedDescriptionKey: recordFetchError.reason])
                            let recordName = recordDictionary["recordName"] as! String
                            let recordID = CKRecordID(recordName: recordName) // todo: get zone from dictionary

                            strongSelf.recordErrors[recordID] = error

                            // todo the original record should be passed in here, that is probably what the self.recordsByRecordIDs was for
                            strongSelf.completed(record: nil, error: error)
                        } else {

                            if let _ = recordDictionary["recordName"],
                               let _ = recordDictionary["deleted"] {

                                let recordName = recordDictionary["recordName"] as! String
                                let recordID = CKRecordID(recordName: recordName) // todo: get zone from dictionary
                                strongSelf.deletedRecordIDs?.append(recordID)


                            } else {
                                fatalError("Couldn't resolve record or record fetch error dictionary")
                            }
                        }
                    }
                }
            }

            // Mark operation as complete
            strongSelf.finish(error: nil)

        }

        request.performRequest()
    }

    private func trackAssetsToUpload(_ completion: @escaping () -> Void) {
        guard let records = recordsToSave else {
            completion()
            return
        }

        var assets = [(asset: CKAsset, uploadToken: CKAssetUploadToken)]()
        for record in records {
            for key in record.allKeys() {
                if let asset = record[key] as? CKAsset {
                    assets.append((asset, CKAssetUploadToken(recordType: record.recordType, fieldName: key, recordName: record.recordID.recordName)))
                }
            }
        }

        let assetsToUpload = assets.filter { $0.asset.fileURL.isFileURL }
        guard assetsToUpload.count > 0 else {
            completion()
            return
        }

        // Request asset upload tokens...
        let request = CKAssetUploadTokenURLRequest(assetsToUpload: assetsToUpload)
        request.accountInfoProvider = CloudKit.shared.defaultAccount
        request.zoneID = zoneID

        self.request = request
        request.completionBlock = { [weak self] (result) in
            guard let strongSelf = self, !strongSelf.isCancelled else { return }

            switch result {
            case .success(let dictionary):
                var assets = [(url: String, asset: CKAsset)]()

                guard let tokens = dictionary["tokens"] as? [[String: Any]] else {
                    strongSelf.finish(
                        error: NSError(
                            domain: CKErrorDomain,
                            code: CKErrorCode.internalError.rawValue,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to parse response from server"]
                        )
                    )
                    return
                }
                for (index, token) in tokens.enumerated() {
                    guard let url = token["url"] as? String else {
                        strongSelf.finish(
                            error: NSError(
                                domain: CKErrorDomain,
                                code: CKErrorCode.internalError.rawValue,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to parse response from server"]
                            )
                        )
                        return
                    }
                    assets.append((url, assetsToUpload[index].asset))
                }
                strongSelf.uploadAssets(assets, completion: completion)
            case .error(let error):
                strongSelf.finish(error: error.error)
            }
        }
        request.performRequest()
    }

    private func uploadAssets(_ assets: [(url: String, asset: CKAsset)], completion: @escaping () -> Void) {
        var currentAssetIndex = 0

        // Create payload for uploading
        func createUploaHTTPBody(_ data: Data) -> (Data, String) {
            let boundary = "----\(UUID().uuidString)"
            let mimeType = "application/octet-stream"

            var body = Data()
            let boundaryPrefix = "--\(boundary)\r\n"

            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"files\"; filename=\"file.file\"\r\n")
            body.appendString("Content-Type: \(mimeType)\r\n\r\n")
            /* File data */
            body.append(data)
            body.appendString("\r\n")
            body.appendString("--".appending(boundary.appending("--\r\n")))
            return (body, "multipart/form-data; boundary=\(boundary)")
        }

        func uploadCurrentAsset() {
            // Check if all asset are uploaded
            guard currentAssetIndex < assets.count else {
                completion()
                return
            }

            // Upload asset one by one
            let asset = assets[currentAssetIndex]
            let data = try! Data(contentsOf: asset.asset.fileURL)
            let (body, contentType) = createUploaHTTPBody(data)
            var request = URLRequest(url: URL(string: asset.url)!)
            request.httpMethod = "POST"
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            request.httpBody = body
            urlSessionTask = CKWebRequest(container: operationContainer).perform(request: request, completionHandler: { [weak self] result, error in
                guard let strongSelf = self, !strongSelf.isCancelled else { return }

                if error != nil {
                    strongSelf.finish(error: error)
                    return
                }

                guard let info = result?["singleFile"] as? [String: Any] else {
                    strongSelf.finish(error: NSError(domain: CKErrorDomain, code: CKErrorCode.internalError.rawValue, userInfo: [NSLocalizedDescriptionKey: "Cannot fetch token to upload asset"]))
                    return
                }

                assets[currentAssetIndex].asset.uploadInfo = info
                currentAssetIndex += 1
                uploadCurrentAsset()
            })
        }

        uploadCurrentAsset()
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}
