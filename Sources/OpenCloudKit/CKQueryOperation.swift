//
//  CKQueryOperation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 7/07/2016.
//
//

import Foundation

#if !os(iOS) && !os(macOS) && os(watchOS) && !os(tvOS)
import FoundationNetworking
#endif

public class CKQueryOperation: CKDatabaseOperation {
    public class var maximumResults: Int {
        return 0
    }

    public override init() {
        super.init()
    }
    
    public convenience init(query: CKQuery) {
        self.init()
        self.query = query
    }

    public convenience init(cursor: Cursor) {
        self.init()
        self.cursor = cursor
        self.query = cursor.query
        self.zoneID = cursor.zoneID
    }

    public var query: CKQuery?
    public var cursor: Cursor?

    public var zoneID: CKRecordZone.ID?
    public var resultsLimit: Int = CKQueryOperation.maximumResults
    public var desiredKeys: [CKRecord.FieldKey]?

    public var queryResultBlock: ((_ operationResult: Result<CKQueryOperation.Cursor?, Error>) -> Void)?
    public var recordMatchedBlock: ((_ recordID: CKRecord.ID, _ recordResult: Result<CKRecord, Error>) -> Void)?

    override func performCKOperation() {
        let db = database ?? CKContainer.default().publicCloudDatabase
        task = Task { [weak self] in
            do {
                let (recordResults, cursor) = try await db.records(matching: query!, inZoneWith: zoneID, desiredKeys: desiredKeys, resultsLimit: resultsLimit)
                guard let self = self else { return }
                for (recordID, recordResult) in recordResults {
                    self.callbackQueue.async {
                        self.recordMatchedBlock?(recordID, recordResult)
                    }
                }
                callbackQueue.async {
                    self.queryResultBlock?(.success(cursor))
                    self.finishOnCallbackQueue()
                }
            }
            catch {
                guard let self = self else { return }
                callbackQueue.async {
                    self.queryResultBlock?(.failure(error))
                    self.finishOnCallbackQueue()
                }
            }
        }
    }
}

extension CKDatabase {
    public func records(continuingMatchFrom queryCursor: CKQueryOperation.Cursor, desiredKeys: [CKRecord.FieldKey]? = nil, resultsLimit: Int = CKQueryOperation.maximumResults) async throws -> (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?) {
        return try await records(matching: queryCursor.query, inZoneWith: queryCursor.zoneID, desiredKeys: desiredKeys, resultsLimit: resultsLimit, continuationMarker: queryCursor.data)
    }

    public func records(matching query: CKQuery, inZoneWith zoneID: CKRecordZone.ID? = nil, desiredKeys: [CKRecord.FieldKey]? = nil, resultsLimit: Int = CKQueryOperation.maximumResults) async throws -> (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?) {
        return try await records(matching: query, inZoneWith: zoneID, desiredKeys: desiredKeys, resultsLimit: resultsLimit, continuationMarker: nil)
    }

    private func records(matching query: CKQuery, inZoneWith zoneID: CKRecordZone.ID?, desiredKeys: [CKRecord.FieldKey]?, resultsLimit: Int, continuationMarker: Data? = nil) async throws -> (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?) {
        let request = CKURLRequestBuilder(database: self, operationType: .records, path: "query")
            .setZone(zoneID)
            .setParameter(key: "continuationMarker", value: continuationMarker?.base64EncodedString(options: []))
            .setParameter(key: "resultsLimit", value: resultsLimit > 0 ? resultsLimit : nil)
            .setParameter(key: "desiredKeys", value: desiredKeys)
            .setParameter(key: "zoneWide", value: false)
            .setParameter(key: "query", value: query.dictionary)
            .build()

        let dictionary = try await CKURLRequestHelper.performURLRequest(request)

        // Process cursor
        var cursor: CKQueryOperation.Cursor? = nil
        if let base64ContinuationMarker = dictionary["continuationMarker"] as? String {
            if let continuationMarker = Data(base64Encoded: base64ContinuationMarker, options: []) {
                cursor = CKQueryOperation.Cursor(data: continuationMarker, query: query, zoneID: zoneID)
            }
        }

        var records = [(CKRecord.ID, Result<CKRecord, Error>)]()
        // Process records
        guard let recordsDictionary = dictionary["records"] as? [[String: Any]] else {
            throw CKError.conversionError
        }

        // Parse JSON into CKRecords
        for recordDictionary in recordsDictionary {
            if let record = CKRecord(recordDictionary: recordDictionary) {
                records.append((record.recordID, .success(record)))
            } else if let fetchError = CKRecordFetchError(dictionary: recordDictionary) {
                // Partial error
                records.append((CKRecord.ID(recordName: fetchError.recordName), .failure(CKError.recordFetchError(error: fetchError))))
            }  else {
                // Unknown error
                throw CKError.conversionError
            }
        }
        return (records, cursor)
    }
}
