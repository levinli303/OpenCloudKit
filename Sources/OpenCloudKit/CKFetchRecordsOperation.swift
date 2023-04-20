//
//  CKFetchRecordsOperation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 7/07/2016.
//
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private class FetchOperation {
    var recordIDs: [CKRecord.ID] = []
}

public class CKFetchRecordsOperation: CKDatabaseOperation, @unchecked Sendable {
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

        task = Task {
            var sorted = [CKRecordZone.ID: FetchOperation]()
            for recordID in recordIDs ?? [] {
                let zoneID = recordID.zoneID
                if let existing = sorted[zoneID] {
                    existing.recordIDs.append(recordID)
                } else {
                    let operation = FetchOperation()
                    operation.recordIDs = [recordID]
                    sorted[zoneID] = operation
                }
            }
            let desiredKeys = self.desiredKeys

            weak var weakSelf = self
            do {
                for (zoneID, operation) in sorted {
                    let recordResults = try await db.records(for: operation.recordIDs, desiredKeys: desiredKeys, inZoneWith: zoneID)

                    guard let self = weakSelf, !self.isCancelled else {
                        throw CKError.operationCancelled
                    }

                    for (recordID, recordResult) in recordResults {
                        self.callbackQueue.async {
                            self.perRecordResultBlock?(recordID, recordResult)
                        }
                    }
                }

                self.callbackQueue.async {
                    self.fetchRecordsResultBlock?(.success(()))
                    self.finishOnCallbackQueue()
                }
            }
            catch {
                guard let self = weakSelf else { return }
                self.callbackQueue.async {
                    self.fetchRecordsResultBlock?(.failure(error))
                    self.finishOnCallbackQueue()
                }
            }
        }
    }
}

extension CKDatabase {
    public func records(for ids: [CKRecord.ID], desiredKeys: [CKRecord.FieldKey]? = nil) async throws -> [CKRecord.ID : Result<CKRecord, Error>] {
        var sorted = [CKRecordZone.ID: FetchOperation]()
        for recordID in ids {
            let zoneID = recordID.zoneID
            if let existing = sorted[zoneID] {
                existing.recordIDs.append(recordID)
            } else {
                let operation = FetchOperation()
                operation.recordIDs = [recordID]
                sorted[zoneID] = operation
            }
        }

        weak var weakSelf = self

        var results = [CKRecord.ID: Result<CKRecord, Error>]()
        for (zoneID, operation) in sorted {
            guard let self = weakSelf else {
                throw CKError.operationCancelled
            }

            let newResults = try await self.records(for: operation.recordIDs, desiredKeys: desiredKeys, inZoneWith: zoneID)
            for (recordID, result) in newResults {
                results[recordID] = result
            }
        }

        return results
    }

    public func records(for ids: [CKRecord.ID], desiredKeys: [CKRecord.FieldKey]?, inZoneWith zoneID: CKRecordZone.ID) async throws -> [CKRecord.ID : Result<CKRecord, Error>] {
        let lookupRecords = ids.map { recordID -> [String: Sendable] in
            return ["recordName": recordID.recordName]
        }
        let request = CKURLRequestBuilder(database: self, operationType: .records, path: "lookup")
            .setZone(zoneID)
            .setParameter(key: "records", value: lookupRecords)
            .setParameter(key: "desiredKeys", value: desiredKeys)
            .build()

        let dictionary = try await CKURLRequestHelper.performURLRequest(request)
        var records = [CKRecord.ID: Result<CKRecord, Error>]()

        // Process records
        guard let recordsDictionary = dictionary["records"] as? [[String: Sendable]] else {
            throw CKError.keyMissing(key: "records")
        }

        // Parse JSON into CKRecords
        for recordDictionary in recordsDictionary {
            if let fetchError = CKRecordFetchError(dictionary: recordDictionary) {
                // Partial error
                records[CKRecord.ID(recordName: fetchError.recordName, zoneID: zoneID)] = .failure(CKError.recordFetchError(error: fetchError))
            } else if let record = CKRecord(recordDictionary: recordDictionary, zoneID: zoneID) {
                records[record.recordID] = .success(record)
            } else {
                // Unknown error
                throw CKError.formatError(userInfo: recordDictionary)
            }
        }
        return records
    }
}
