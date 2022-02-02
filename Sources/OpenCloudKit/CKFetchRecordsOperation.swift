//
//  CKFetchRecordsOperation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 7/07/2016.
//
//

import Foundation

#if !os(iOS) && !os(macOS) && os(watchOS) && !os(tvOS)
import FoundationNetworking
#endif

public class CKFetchRecordsOperation: CKDatabaseOperation {
    public var fetchRecordsResultBlock: ((_ operationResult: Result<Void, Error>) -> Void)?
    public var perRecordResultBlock: ((_ recordID: CKRecord.ID, _ recordResult: Result<CKRecord, Error>) -> Void)?

    public override required init() {
        super.init()
    }

    public var recordIDs: [CKRecord.ID]?
    public var desiredKeys: [CKRecord.FieldKey]?

    public convenience init(recordIDs: [CKRecord.ID]) {
        self.init()
        self.recordIDs = recordIDs
    }

    override func performCKOperation() {
        let db = database ?? CKContainer.default().publicCloudDatabase
        task = Task { [weak self] in
            do {
                let recordResults = try await db.records(for: recordIDs ?? [], desiredKeys: desiredKeys)
                guard let self = self else { return }
                for (recordID, recordResult) in recordResults {
                    self.callbackQueue.async {
                        self.perRecordResultBlock?(recordID, recordResult)
                    }
                }
                callbackQueue.async {
                    self.fetchRecordsResultBlock?(.success(()))
                    self.finishOnCallbackQueue()
                }
            }
            catch {
                guard let self = self else { return }
                callbackQueue.async {
                    self.fetchRecordsResultBlock?(.failure(error))
                    self.finishOnCallbackQueue()
                }
            }
        }
    }
}

extension CKDatabase {
    public func records(for ids: [CKRecord.ID], desiredKeys: [CKRecord.FieldKey]? = nil) async throws -> [CKRecord.ID : Result<CKRecord, Error>] {
        let lookupRecords = ids.map { recordID -> [String: Any] in
            return ["recordName": recordID.recordName]
        }
        let request = CKURLRequestBuilder(database: self, operationType: .records, path: "lookup")
            .setParameter(key: "records", value: lookupRecords)
            .setParameter(key: "desiredKeys", value: desiredKeys)
            .build()

        let dictionary = try await CKURLRequestHelper.performURLRequest(request)
        var records = [CKRecord.ID: Result<CKRecord, Error>]()

        // Process records
        guard let recordsDictionary = dictionary["records"] as? [[String: Any]] else {
            throw CKError.keyMissing(key: "records")
        }

        // Parse JSON into CKRecords
        for recordDictionary in recordsDictionary {
            if let record = CKRecord(recordDictionary: recordDictionary) {
                records[record.recordID] = .success(record)
            } else if let fetchError = CKRecordFetchError(dictionary: recordDictionary) {
                // Partial error
                records[CKRecord.ID(recordName: fetchError.recordName)] = .failure(CKError.recordFetchError(error: fetchError))
            }  else {
                // Unknown error
                throw CKError.conversionError
            }
        }
        return records
    }
}
