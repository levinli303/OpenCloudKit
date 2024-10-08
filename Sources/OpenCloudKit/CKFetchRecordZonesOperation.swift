//
//  CKFetchRecordZonesOperation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 15/07/2016.
//
//

import Foundation
import NIOHTTP1

public class CKFetchRecordZonesOperation : CKDatabaseOperation, @unchecked Sendable {
    public static func fetchAllRecordZonesOperation() -> CKFetchRecordZonesOperation {
        return CKFetchRecordZonesOperation()
    }

    public override required init() {
        self.recordZoneIDs = nil
        super.init()
    }

    public init(recordZoneIDs zoneIDs: [CKRecordZone.ID]) {
        self.recordZoneIDs = zoneIDs
        super.init()
    }

    public var recordZoneIDs : [CKRecordZone.ID]?

    public var fetchRecordZonesResultBlock: ((_ operationResult: Result<Void, Error>) -> Void)?
    public var perRecordZoneResultBlock: ((_ recordZoneID: CKRecordZone.ID, _ recordZoneResult: Result<CKRecordZone, Error>) -> Void)?

    override func performCKOperation() {
        let db = database ?? CKContainer.default().publicCloudDatabase
        task = Task {
            weak var weakSelf = self
            if let ids = recordZoneIDs {
                do {
                    let zoneResults = try await db.recordZones(for: ids)

                    guard let self = weakSelf, !self.isCancelled else {
                        throw CKError.operationCancelled
                    }

                    for (zoneID, zoneResult) in zoneResults {
                        self.callbackQueue.async {
                            self.perRecordZoneResultBlock?(zoneID, zoneResult)
                        }
                    }

                    self.callbackQueue.async {
                        self.fetchRecordZonesResultBlock?(.success(()))
                        self.finishOnCallbackQueue()
                    }
                }
                catch {
                    guard let self = weakSelf else { return }

                    self.callbackQueue.async {
                        self.fetchRecordZonesResultBlock?(.failure(error))
                        self.finishOnCallbackQueue()
                    }
                }
            }
            else {
                do {
                    let zoneResults = try await db.allRecordZones()

                    guard let self = weakSelf, !self.isCancelled else {
                        throw CKError.operationCancelled
                    }

                    for zone in zoneResults {
                        self.callbackQueue.async {
                            self.perRecordZoneResultBlock?(zone.zoneID, .success(zone))
                        }
                    }

                    self.callbackQueue.async {
                        self.fetchRecordZonesResultBlock?(.success(()))
                        self.finishOnCallbackQueue()
                    }
                }
                catch {
                    guard let self = weakSelf else { return }

                    self.callbackQueue.async {
                        self.fetchRecordZonesResultBlock?(.failure(error))
                        self.finishOnCallbackQueue()
                    }
                }
            }
        }
    }
}

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
