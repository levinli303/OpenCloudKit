//
//  CKQueryOperation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 7/07/2016.
//
//

import Foundation

public class CKQueryOperation: CKDatabaseOperation, @unchecked Sendable {
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
        task = Task {
            weak var weakSelf = self
            do {
                let result: (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?)
                if let queryCursor = cursor {
                    result = try await db.records(continuingMatchFrom: queryCursor, desiredKeys: desiredKeys, resultsLimit: resultsLimit)
                } else {
                    result = try await db.records(matching: query!, inZoneWith: zoneID, desiredKeys: desiredKeys, resultsLimit: resultsLimit)
                }

                guard let self = weakSelf, !self.isCancelled else {
                    throw CKError.operationCancelled
                }

                for (recordID, recordResult) in result.matchResults {
                    self.callbackQueue.async {
                        self.recordMatchedBlock?(recordID, recordResult)
                    }
                }

                self.callbackQueue.async {
                    self.queryResultBlock?(.success(result.queryCursor))
                    self.finishOnCallbackQueue()
                }
            }
            catch {
                guard let self = weakSelf else { return }

                self.callbackQueue.async {
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

    public func perform(_ query: CKQuery, inZoneWith zoneID: CKRecordZone.ID?) async throws -> [CKRecord] {
        // Ignoring cursor
        let (results, _) = try await records(matching: query, inZoneWith: zoneID)
        var records = [CKRecord]()
        for (_, result) in results {
            switch result {
            case .success(let record):
                records.append(record)
            case .failure(let error):
                // Should we just fail on partial failure?
                throw error
            }
        }
        return records
    }

    private func records(matching query: CKQuery, inZoneWith zoneID: CKRecordZone.ID?, desiredKeys: [CKRecord.FieldKey]?, resultsLimit: Int, continuationMarker: Data? = nil) async throws -> (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?) {
        let request = CKURLRequestBuilder(database: self, operationType: .records, path: "query")
            .setZone(zoneID)
            .setParameter(key: "continuationMarker", value: continuationMarker?.base64EncodedString(options: []))
            .setParameter(key: "resultsLimit", value: resultsLimit > 0 ? resultsLimit : nil)
            .setParameter(key: "desiredKeys", value: desiredKeys)
            .setParameter(key: "zoneWide", value: zoneID == nil)
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
        guard let recordsDictionary = dictionary["records"] as? [[String: Sendable]] else {
            throw CKError.keyMissing(key: "records")
        }

        // Parse JSON into CKRecords
        for recordDictionary in recordsDictionary {
            if let fetchError = CKRecordFetchError(dictionary: recordDictionary) {
                // Partial error
                records.append((CKRecord.ID(recordName: fetchError.recordName), .failure(CKError.recordFetchError(error: fetchError))))
            } else if let record = CKRecord(recordDictionary: recordDictionary, zoneID: zoneID) {
                records.append((record.recordID, .success(record)))
            } else {
                // Unknown error
                throw CKError.formatError(userInfo: recordDictionary)
            }
        }
        return (records, cursor)
    }

    public func perform(_ query: CKQuery, inZoneWith zoneID: CKRecordZone.ID?, completionHandler: @escaping ([CKRecord]?, Error?) -> Void) {
        Task {
            do {
                completionHandler(try await perform(query, inZoneWith: zoneID), nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }
}
