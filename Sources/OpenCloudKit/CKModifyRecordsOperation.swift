//
//  CKModifyRecordsOperation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 8/07/2016.
//
//

import Foundation
import NIOHTTP1

struct CKSubscriptionFetchErrorDictionary {
    static let subscriptionIDKey = "subscriptionID"
    static let reasonKey = "reason"
    static let serverErrorCodeKey = "serverErrorCode"
    static let redirectURLKey = "redirectURL"

    let subscriptionID: String
    let reason: String?
    let serverErrorCode: String
    let redirectURL: URL?

    init?(dictionary: [String: Sendable]) {
        guard
            let subscriptionID = dictionary[CKSubscriptionFetchErrorDictionary.subscriptionIDKey] as? String,
            let reason = dictionary[CKSubscriptionFetchErrorDictionary.reasonKey] as? String,
            let serverErrorCode = dictionary[CKSubscriptionFetchErrorDictionary.serverErrorCodeKey] as? String else {
            return nil
        }

        self.subscriptionID = subscriptionID
        self.reason = reason
        self.serverErrorCode = serverErrorCode
        if let urlString = dictionary[CKSubscriptionFetchErrorDictionary.redirectURLKey] as? String {
            self.redirectURL = URL(string: urlString)
        } else {
            self.redirectURL = nil
        }
    }
}

public struct CKRecordFetchError: Sendable {
    static let recordNameKey = "recordName"
    static let reasonKey = "reason"
    static let serverErrorCodeKey = "serverErrorCode"
    static let retryAfterKey = "retryAfter"
    static let uuidKey = "uuid"
    static let redirectURLKey = "redirectURL"

    public let recordName: String
    public let reason: String
    public let serverErrorCode: CKServerError
    public let retryAfter: TimeInterval?
    public let uuid: String?
    public let redirectURL: URL?

    init?(dictionary: [String: Sendable]) {
        guard let recordName = dictionary[CKRecordFetchError.recordNameKey] as? String,
              let reason = dictionary[CKRecordFetchError.reasonKey] as? String,
              let serverErrorCode = dictionary[CKRecordFetchError.serverErrorCodeKey] as? String,
              let errorCode = CKServerError(rawValue: serverErrorCode) else {
            return nil
        }

        self.recordName = recordName
        self.reason = reason
        self.serverErrorCode = errorCode

        self.uuid = dictionary[CKRecordFetchError.uuidKey] as? String

        self.retryAfter = dictionary[CKRecordFetchError.retryAfterKey] as? TimeInterval
        if let urlString = dictionary[CKRecordFetchError.redirectURLKey] as? String {
            self.redirectURL = URL(string: urlString)
        } else {
            self.redirectURL = nil
        }
    }
}

private class ModifyOperation {
    var recordsToSave: [CKRecord] = []
    var recordIDsToDelete: [CKRecord.ID] = []
}

public class CKModifyRecordsOperation: CKDatabaseOperation, @unchecked Sendable {
    public enum RecordSavePolicy : Int {
        case ifServerRecordUnchanged
        case changedKeys
        case allKeys
    }

    public override init() {
        super.init()
    }

    public convenience init(recordsToSave records: [CKRecord]?, recordIDsToDelete recordIDs: [CKRecord.ID]?) {
        self.init()

        recordsToSave = records
        recordIDsToDelete = recordIDs
    }

    public var savePolicy: RecordSavePolicy = .ifServerRecordUnchanged

    public var recordsToSave: [CKRecord]?
    public var recordIDsToDelete: [CKRecord.ID]?

    /* Determines whether the batch should fail atomically or not. YES by default.
     This only applies to zones that support CKRecordZoneCapabilityAtomic. */
    public var isAtomic: Bool = false

    public var modifyRecordsResultBlock: ((_ operationResult: Result<Void, Error>) -> Void)?
    public var perRecordSaveBlock: ((_ recordID: CKRecord.ID, _ saveResult: Result<CKRecord, Error>) -> Void)?
    public var perRecordDeleteBlock: ((_ recordID: CKRecord.ID, _ deleteResult: Result<Void, Error>) -> Void)?

    override func performCKOperation() {
        let db = database ?? CKContainer.default().publicCloudDatabase
        task = Task {
            weak var weakSelf = self
            let isAtomic = self.isAtomic
            let savePolicy = self.savePolicy
            do {
                var sorted = [CKRecordZone.ID: ModifyOperation]()
                for recordToSave in recordsToSave ?? [] {
                    let zoneID = recordToSave.recordID.zoneID
                    if let existing = sorted[zoneID] {
                        existing.recordsToSave.append(recordToSave)
                    } else {
                        let operation = ModifyOperation()
                        operation.recordsToSave = [recordToSave]
                        sorted[zoneID] = operation
                    }
                }

                for recordIDToDelete in recordIDsToDelete ?? [] {
                    let zoneID = recordIDToDelete.zoneID
                    if let existing = sorted[zoneID] {
                        existing.recordIDsToDelete.append(recordIDToDelete)
                    } else {
                        let operation = ModifyOperation()
                        operation.recordIDsToDelete = [recordIDToDelete]
                        sorted[zoneID] = operation
                    }
                }

                for (zoneID, operation) in sorted {
                    let (saveResults, deleteResults) = try await db.modifyRecords(saving: operation.recordsToSave, deleting: operation.recordIDsToDelete, savePolicy: savePolicy, atomically: isAtomic, inZoneWith: zoneID)

                    guard let self = weakSelf, !self.isCancelled else {
                        throw CKError.operationCancelled
                    }

                    for (recordID, result) in saveResults {
                        self.callbackQueue.async {
                            self.perRecordSaveBlock?(recordID, result)
                        }
                    }
                    for (recordID, result) in deleteResults {
                        self.callbackQueue.async {
                            self.perRecordDeleteBlock?(recordID, result)
                        }
                    }
                }

                self.callbackQueue.async {
                    self.modifyRecordsResultBlock?(.success(()))
                    self.finishOnCallbackQueue()
                }
            }
            catch {
                guard let self = weakSelf else { return }

                self.callbackQueue.async {
                    self.modifyRecordsResultBlock?(.failure(error))
                    self.finishOnCallbackQueue()
                }
            }
        }
    }
}


extension CKDatabase {
    private struct AssetUploadTokenResponse: Decodable {
        let recordName: String
        let fieldName: String
        let url: URL
    }

    private struct AssetUploadTokensResponse: Decodable {
        let tokens: [AssetUploadTokenResponse]
    }

    private struct AssetUploadToken {
        let recordType: String
        let fieldName: String
        let recordName: String?

        var dictionary: [String: Sendable] {
            var dictionary: [String: Sendable] = [
                "recordType": recordType,
                "fieldName": fieldName
            ]
            if let recordName = recordName {
                dictionary["recordName"] = recordName
            }
            return dictionary
        }
    }

    private struct AssetToUpload {
        let asset: CKAsset
        let uploadToken: AssetUploadToken
    }

    private struct AssetUploadURL {
        let asset: CKAsset
        let url: URL
    }

    private struct RecordDeleteResponse {
        let recordID: CKRecord.ID
        let deleted: Bool

        init?(dictionary: [String: Sendable]) {
            guard let recordName = dictionary["recordName"] as? String, let deleted = dictionary["deleted"] as? Bool else {
                return nil
            }
            self.recordID = CKRecord.ID(recordName: recordName)
            self.deleted = deleted
        }
    }

    private struct AssetUploadResponse: Decodable {
        let singleFile: CKAsset.UploadInfo
    }

    public func modifyRecords(saving recordsToSave: [CKRecord], deleting recordIDsToDelete: [CKRecord.ID], savePolicy: CKModifyRecordsOperation.RecordSavePolicy = .ifServerRecordUnchanged, atomically: Bool = true) async throws -> (saveResults: [CKRecord.ID : Result<CKRecord, Error>], deleteResults: [CKRecord.ID : Result<Void, Error>]) {
        var sorted = [CKRecordZone.ID: ModifyOperation]()
        for recordToSave in recordsToSave {
            let zoneID = recordToSave.recordID.zoneID
            if let existing = sorted[zoneID] {
                existing.recordsToSave.append(recordToSave)
            } else {
                let operation = ModifyOperation()
                operation.recordsToSave = [recordToSave]
                sorted[zoneID] = operation
            }
        }

        for recordIDToDelete in recordIDsToDelete {
            let zoneID = recordIDToDelete.zoneID
            if let existing = sorted[zoneID] {
                existing.recordIDsToDelete.append(recordIDToDelete)
            } else {
                let operation = ModifyOperation()
                operation.recordIDsToDelete = [recordIDToDelete]
                sorted[zoneID] = operation
            }
        }

        weak var weakSelf = self

        var saveResults = [CKRecord.ID: Result<CKRecord, Error>]()
        var deleteResults = [CKRecord.ID: Result<Void, Error>]()
        for (zoneID, operation) in sorted {
            guard let self = weakSelf else {
                throw CKError.operationCancelled
            }

            let (newSaveResults, newDeleteResults) = try await self.modifyRecords(saving: operation.recordsToSave, deleting: operation.recordIDsToDelete, savePolicy: savePolicy, atomically: atomically, inZoneWith: zoneID)
            for (recordID, saveResult) in newSaveResults {
                saveResults[recordID] = saveResult
            }
            for (recordID, deleteResult) in newDeleteResults {
                deleteResults[recordID] = deleteResult
            }
        }

        return (saveResults, deleteResults)
    }

    func modifyRecords(saving recordsToSave: [CKRecord], deleting recordIDsToDelete: [CKRecord.ID], savePolicy: CKModifyRecordsOperation.RecordSavePolicy, atomically: Bool, inZoneWith zoneID: CKRecordZone.ID) async throws -> (saveResults: [CKRecord.ID : Result<CKRecord, Error>], deleteResults: [CKRecord.ID : Result<Void, Error>]) {
        let assetsInfo = assetsInfoForUpload(recordsToSave: recordsToSave, savePolicy: savePolicy)

        try await uploadAssets(assetsInfo: assetsInfo, inZoneWith: zoneID)
        if Task.isCancelled {
            throw CKError.operationCancelled
        }

        let modifyOperationDictionaryArray = modifyRecordOperationsDictionary(recordsToSave: recordsToSave, savePolicy: savePolicy, recordIDsToDelete: recordIDsToDelete)

        // Only custom zones support atomic action
        let atomicSupported = zoneID.zoneName != CKRecordZone.ID.defaultZoneName
        let request = CKURLRequestBuilder(database: self, operationType: .records, path: "modify")
            .setZone(zoneID)
            .setParameter(key: "atomic", value: atomicSupported && atomically)
            .setParameter(key: "operations", value: modifyOperationDictionaryArray)
            .build()
        let dictionary = try await CKURLRequestHelper.performURLRequest(request)
        // Process records
        guard let recordsDictionary = dictionary["records"] as? [[String: Sendable]] else {
            throw CKError.keyMissing(key: "records")
        }

        var saveResults = [CKRecord.ID: Result<CKRecord, Error>]()
        var deleteResults = [CKRecord.ID: Result<Void, Error>]()
        for (index, recordDictionary) in recordsDictionary.enumerated() {
            if let fetchError = CKRecordFetchError(dictionary: recordDictionary) {
                // Partial error
                let recordID = CKRecord.ID(recordName: fetchError.recordName)
                let error = CKError.recordFetchError(error: fetchError)
                if index < recordsToSave.count {
                    saveResults[recordID] = .failure(error)
                } else {
                    deleteResults[recordID] = .failure(error)
                }
            } else if let deleteResponse = RecordDeleteResponse(dictionary: recordDictionary), deleteResponse.deleted {
                deleteResults[deleteResponse.recordID] = .success(())
            } else if let record = CKRecord(recordDictionary: recordDictionary, zoneID: zoneID) {
                saveResults[record.recordID] = .success(record)
            } else {
                // Unknown error
                throw CKError.formatError(userInfo: recordDictionary)
            }
        }
        return (saveResults, deleteResults)
    }

    private func uploadAssets(assetsInfo: [AssetToUpload], inZoneWith zoneID: CKRecordZone.ID) async throws {
        guard !assetsInfo.isEmpty else { return }

        // If there is a non local URL in assets, then fails
        if let firstNonLocalURL = assetsInfo.first(where: { !$0.asset.fileURL.isFileURL })?.asset.fileURL {
            throw CKError.assetFileNotFound(url: firstNonLocalURL)
        }

        let tokens = try await getAssetUploadToken(tokens: assetsInfo.map({ $0.uploadToken }), inZoneWith: zoneID)
        if Task.isCancelled {
            throw CKError.operationCancelled
        }

        var uploadURLs = [AssetUploadURL]()
        for (index, token) in tokens.enumerated() {
            // TODO: need to validate recordName/recordType
            uploadURLs.append(AssetUploadURL(asset: assetsInfo[index].asset, url: token.url))
        }

        for uploadURL in uploadURLs {
            try await uploadAsset(uploadURL)

            if Task.isCancelled {
                throw CKError.operationCancelled
            }
        }
    }

    private func uploadAsset(_ uploadURL: AssetUploadURL) async throws {
        let data: Data!
        do {
            data = try Data(contentsOf: uploadURL.asset.fileURL)
        }
        catch {
            throw CKError.ioError(error: error)
        }

        if Task.isCancelled {
            throw CKError.operationCancelled
        }

        // Create payload for uploading
        func createUploaHTTPBody(_ data: Data) -> (Data, String) {
            let boundary = "----\(UUID().uuidString)"
            let mimeType = "application/octet-stream"

            var body = Data()
            let boundaryPrefix = "--\(boundary)\r\n"

            func appendString(_ string: String) {
                let data = string.data(using: .utf8)
                body.append(data!)
            }

            appendString(boundaryPrefix)
            appendString("Content-Disposition: form-data; name=\"files\"; filename=\"file.file\"\r\n")
            appendString("Content-Type: \(mimeType)\r\n\r\n")
            /* File data */
            body.append(data)
            appendString("\r\n")
            appendString("--".appending(boundary.appending("--\r\n")))
            return (body, "multipart/form-data; boundary=\(boundary)")
        }

        let (body, contentType) = createUploaHTTPBody(data)
        let request = CKURLRequestBuilder(url: uploadURL.url, database: self)
            .setHTTPMethod(.POST)
            .setContentType(contentType)
            .setData(body)
            .build()

        let uploadResponse: AssetUploadResponse = try await CKURLRequestHelper.performURLRequest(request)
        if Task.isCancelled {
            throw CKError.operationCancelled
        }

        uploadURL.asset.uploadInfo = uploadResponse.singleFile
    }

    private func getAssetUploadToken(tokens: [AssetUploadToken], inZoneWith zoneID: CKRecordZone.ID) async throws -> [AssetUploadTokenResponse] {
        // Request asset upload tokens...
        let request = CKURLRequestBuilder(database: self, operationType: .assets, path: "upload")
            .setZone(zoneID)
            .setParameter(key: "tokens", value: tokens.map({ $0.dictionary }))
            .build()

        let assetTokenResponse: AssetUploadTokensResponse = try await CKURLRequestHelper.performURLRequest(request)
        return assetTokenResponse.tokens
    }

    private func modifyRecordOperationsDictionary(recordsToSave: [CKRecord], savePolicy: CKModifyRecordsOperation.RecordSavePolicy, recordIDsToDelete: [CKRecord.ID]) -> [[String: Sendable]] {
        var operationsDictionaryArray: [[String: Sendable]] = []
        let saveOperations = recordsToSave.map({ (record) -> [String: Sendable] in
            let operationType: String

            let fields: [String]
            var recordDictionary: [String: Sendable] = ["recordType": record.recordType, "recordName": record.recordID.recordName]
            if let recordChangeTag = record.recordChangeTag {
                if savePolicy == .ifServerRecordUnchanged {
                    operationType = "update"
                } else {
                    operationType = "forceUpdate"
                }

                // Set Operation Type to Replace
                if savePolicy == .allKeys {
                    fields =  record.allKeys()
                } else {
                    fields = record.changedKeys()
                }
                recordDictionary["recordChangeTag"] = recordChangeTag
            } else {
                // Create new record
                fields = record.allKeys()
                operationType = "create"
            }

            var fieldsDictionary = [String: Sendable]()
            for key in fields {
                if let value = record.object(forKey: key) {
                    fieldsDictionary[key] = value.recordFieldDictionary
                } else {
                    // Provide empty value for nil cases
                    fieldsDictionary[key] = [String: String]()
                }
            }

            recordDictionary["zoneID"] = record.recordID.zoneID.dictionary

            recordDictionary["fields"] = fieldsDictionary
            if let parent = record.parent {
                recordDictionary["parent"] = ["recordName": parent.recordID.recordName]
            }

            if let share = record.share {
                if let shortGUID = record.shortGUID {
                    recordDictionary["shortGUID"] = shortGUID
                    recordDictionary["share"] = ["recordName": share.recordID.recordName]
                } else {
                    recordDictionary["createShortGUID"] = true
                }
            }

            if let shareRecord = record as? CKShare {
                if let forRecord = shareRecord.forRecord {
                    var dictionary = [String: Sendable]()
                    dictionary["recordName"] = forRecord.recordID.recordName
                    dictionary["recordChangeTag"] = forRecord.recordChangeTag
                    recordDictionary["forRecord"] = dictionary
                }
                recordDictionary["publicPermission"] = "\(shareRecord.publicPermission)"
                recordDictionary["participants"] = shareRecord.participants.map({ $0.dictionary })
            }

            let operationDictionary: [String: Sendable] = ["operationType": operationType, "record": recordDictionary]
            return operationDictionary
        })
        operationsDictionaryArray += saveOperations

        let deleteOperations = recordIDsToDelete.map({ (recordID) -> [String: Sendable] in
            let operationDictionary: [String: Sendable] = [
                "operationType": "forceDelete",
                "record": [
                    "recordName": recordID.recordName,
                    "zoneID": recordID.zoneID.dictionary
                ] as [String: Sendable]
            ]

            return operationDictionary
        })
        operationsDictionaryArray += deleteOperations

        return operationsDictionaryArray
    }

    private func assetsInfoForUpload(recordsToSave: [CKRecord], savePolicy: CKModifyRecordsOperation.RecordSavePolicy) -> [AssetToUpload] {
        var assetInfos = [AssetToUpload]()

        for record in recordsToSave {
            let fields: [String]
            if record.recordChangeTag != nil {
                if savePolicy == .allKeys {
                    fields =  record.allKeys()
                } else {
                    fields = record.changedKeys()
                }
            } else {
                // Create new record with all fields
                fields = record.allKeys()
            }

            for key in fields {
                if let value = record.object(forKey: key) {
                    if let asset = value as? CKAsset {
                        assetInfos.append(AssetToUpload(asset: asset, uploadToken: AssetUploadToken(recordType: record.recordType, fieldName: key, recordName: record.recordID.recordName)))
                    } else if let assets = value as? [CKAsset] {
                        for asset in assets {
                            assetInfos.append(AssetToUpload(asset: asset, uploadToken: AssetUploadToken(recordType: record.recordType, fieldName: key, recordName: record.recordID.recordName)))
                        }
                    }
                }
            }
        }
        return assetInfos
    }
}
