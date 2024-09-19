//
//  CKFetchRecordZonesOperation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 15/07/2016.
//
//

import Foundation
import NIOHTTP1

extension CKDatabase {
    public func recordZones(for ids: [CKRecordZone.ID]) async throws -> [CKRecordZone.ID: Result<CKRecordZone, Error>] {
        let lookupRecords = ids.map { zoneID -> [String: Sendable] in
            return zoneID.dictionary
        }
        let request = CKURLRequestBuilder(database: self, operationType: .zones, path: "lookup")
            .setParameter(key: "zones", value: lookupRecords)
            .build()

        let dictionary = try await CKURLRequestHelper.performURLRequest(request)
        var zones = [CKRecordZone.ID: Result<CKRecordZone, Error>]()

        // Process records
        guard let zonesDictionary = dictionary["zones"] as? [[String: Sendable]] else {
            throw CKError.keyMissing(key: "zones")
        }

        // Parse JSON into CKRecordZone
        for zoneDictionary in zonesDictionary {
            if let fetchError = CKRecordZoneFetchError(dictionary: zoneDictionary) {
                // Partial error
                zones[fetchError.zoneID] = .failure(CKError.recordZoneFetchError(error: fetchError))
            } else if let zone = CKRecordZone(dictionary: zoneDictionary) {
                zones[zone.zoneID] = .success(zone)
            } else {
                // Unknown error
                throw CKError.formatError(userInfo: zoneDictionary)
            }
        }
        return zones
    }

    public func allRecordZones() async throws -> [CKRecordZone] {
        let request = CKURLRequestBuilder(database: self, operationType: .zones, path: "list")
            .setHTTPMethod(.GET)
            .build()

        let dictionary = try await CKURLRequestHelper.performURLRequest(request)
        var zones = [CKRecordZone]()

        // Process record zones
        guard let zonesDictionary = dictionary["zones"] as? [[String: Sendable]] else {
            throw CKError.keyMissing(key: "zones")
        }

        // Parse JSON into CKRecordZone
        for zoneDictionary in zonesDictionary {
            if let zone = CKRecordZone(dictionary: zoneDictionary) {
                zones.append(zone)
            } else {
                // Unknown error
                throw CKError.formatError(userInfo: zoneDictionary)
            }
        }
        return zones
    }
}
