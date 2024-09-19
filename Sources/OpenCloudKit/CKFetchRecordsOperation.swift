//
//  CKFetchRecordsOperation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 7/07/2016.
//
//

import Foundation

private class FetchOperation {
    var recordIDs: [CKRecord.ID] = []
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
