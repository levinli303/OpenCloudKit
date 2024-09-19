//
//  CKModifyRecordZonesOperation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 15/07/2016.
//
//

import Foundation

public struct CKRecordZoneFetchError: Sendable {
    static let zoneIDKey = "zoneID"
    static let reasonKey = "reason"
    static let serverErrorCodeKey = "serverErrorCode"
    static let retryAfterKey = "retryAfter"
    static let uuidKey = "uuid"
    static let redirectURLKey = "redirectURL"

    public let zoneID: CKRecordZone.ID
    public let reason: String?
    public let serverErrorCode: CKServerError
    public let retryAfter: TimeInterval?
    public let uuid: String?
    public let redirectURL: URL?

    init?(dictionary: [String: Sendable]) {
        guard let zoneIDDictionary = dictionary[CKRecordZoneFetchError.zoneIDKey] as? [String: Sendable],
              let zoneID = CKRecordZone.ID(dictionary: zoneIDDictionary),
              let reason = dictionary[CKRecordZoneFetchError.reasonKey] as? String,
              let serverErrorCode = dictionary[CKRecordZoneFetchError.serverErrorCodeKey] as? String,
              let errorCode = CKServerError(rawValue: serverErrorCode) else {
            return nil
        }

        self.zoneID = zoneID
        self.reason = reason
        self.serverErrorCode = errorCode

        self.uuid = dictionary[CKRecordZoneFetchError.uuidKey] as? String

        self.retryAfter = dictionary[CKRecordZoneFetchError.retryAfterKey] as? TimeInterval
        if let urlString = dictionary[CKRecordZoneFetchError.redirectURLKey] as? String {
            self.redirectURL = URL(string: urlString)
        } else {
            self.redirectURL = nil
        }
    }
}

extension CKDatabase {
    private struct RecordZoneDeleteResponse {
        let zoneID: CKRecordZone.ID
        let deleted: Bool

        init?(dictionary: [String: Sendable]) {
            guard let zoneIDDictionary = dictionary["zoneID"] as? [String: Sendable], let zoneID = CKRecordZone.ID(dictionary: zoneIDDictionary), let deleted = dictionary["deleted"] as? Bool else {
                return nil
            }
            self.zoneID = zoneID
            self.deleted = deleted
        }
    }

    public func modifyRecordZones(saving recordZonesToSave: [CKRecordZone], deleting recordZoneIDsToDelete: [CKRecordZone.ID]) async throws -> (saveResults: [CKRecordZone.ID : Result<CKRecordZone, Error>], deleteResults: [CKRecordZone.ID : Result<Void, Error>]) {
        let modifyOperationDictionaryArray = modifyZoneOperationsDictionary(recordZonesToSave: recordZonesToSave, recordZoneIDsToDelete: recordZoneIDsToDelete)
        let request = CKURLRequestBuilder(database: self, operationType: .zones, path: "modify")
            .setParameter(key: "operations", value: modifyOperationDictionaryArray)
            .build()
        let dictionary = try await CKURLRequestHelper.performURLRequest(request)

        // Process zones
        guard let zonesDictionary = dictionary["zones"] as? [[String: Sendable]] else {
            throw CKError.keyMissing(key: "zones")
        }

        var saveResults = [CKRecordZone.ID: Result<CKRecordZone, Error>]()
        var deleteResults = [CKRecordZone.ID: Result<Void, Error>]()
        for (index, zoneDictionary) in zonesDictionary.enumerated() {
            if let fetchError = CKRecordZoneFetchError(dictionary: zoneDictionary) {
                // Partial error
                let zoneID = fetchError.zoneID
                if index < recordZonesToSave.count {
                    saveResults[zoneID] = .failure(CKError.recordZoneFetchError(error: fetchError))
                } else {
                    deleteResults[zoneID] = .failure(CKError.recordZoneFetchError(error: fetchError))
                }
            } else if let deleteResponse = RecordZoneDeleteResponse(dictionary: zoneDictionary), deleteResponse.deleted {
                deleteResults[deleteResponse.zoneID] = .success(())
            } else if let zone = CKRecordZone(dictionary: zoneDictionary) {
                saveResults[zone.zoneID] = .success(zone)
            } else {
                // Unknown error
                throw CKError.formatError(userInfo: zoneDictionary)
            }
        }
        return (saveResults, deleteResults)
    }

    private func modifyZoneOperationsDictionary(recordZonesToSave: [CKRecordZone], recordZoneIDsToDelete: [CKRecordZone.ID]) -> [[String: Sendable]] {

        var operationDictionaryArray: [[String: Sendable]] = []
        let saveOperations = recordZonesToSave.map({ (zone) -> [String: Sendable] in
            let operation: [String: Sendable] = [
                "operationType": "create",
                "zone": ["zoneID": zone.zoneID.dictionary]
            ]

            return operation
        })
        operationDictionaryArray += saveOperations

        let deleteOperations = recordZoneIDsToDelete.map({ (zoneID) -> [String: Sendable] in
            let operation: [String: Sendable] = [
                "operationType": "delete",
                "zone": ["zoneID": zoneID.dictionary]
            ]

            return operation
        })
        operationDictionaryArray += deleteOperations

        return operationDictionaryArray
    }
}
