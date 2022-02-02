//
//  CKDatabase.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 6/07/2016.
//
//

import Foundation

extension CKDatabase {
    public enum Scope: Int, CustomStringConvertible {
        case `public` = 1
        case `private`
        case  shared

        public var description: String {
            switch(self) {
            case .private:
                return "private"
            case .public:
                return "public"
            case .shared:
                return "shared"
            }
        }
    }
}

enum CKRecordOperation: String {
    case query
    case lookup
    case modify
    case changes
    case resolve
    case accept
}

enum CKModifyOperation: String {
    case create
    case update
    case forceUpdate
    case replace
    case forceReplace
    case delete
    case forceDelete
}

public class CKDatabase {
    weak var container: CKContainer!

    public let scope: Scope

    let operationQueue = OperationQueue()

    init(container: CKContainer, scope: Scope) {
        self.container = container
        self.scope = scope
    }

    public func add(_ operation: CKDatabaseOperation) {
        operation.database = self
        operation.container = container
        // Add to queue
        operationQueue.addOperation(operation)
    }

    private func schedule(operation: CKDatabaseOperation) {
        operation.database = self
        operation.queuePriority = .veryHigh
        operation.qualityOfService = .userInitiated
        operationQueue.addOperation(operation)
    }
}

extension CKDatabase {
    /* Records convenience methods */
    public func fetch(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
        let fetchRecordOperation = CKFetchRecordsOperation(recordIDs: [recordID])
        fetchRecordOperation.database = self
        var recordResult: Result<CKRecord, Error>?
        fetchRecordOperation.perRecordResultBlock = { _, result in
            recordResult = result
        }
        fetchRecordOperation.fetchRecordsResultBlock = { result in
            switch result {
            case .success:
                switch recordResult! {
                case .success(let record):
                    completionHandler(record, nil)
                case .failure(let error):
                    completionHandler(nil, error)
                }
            case .failure(let error):
                completionHandler(nil, error)
            }
        }

        schedule(operation: fetchRecordOperation)
    }

    public func save(record: CKRecord, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
        let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
        operation.database = self
        var recordResult: Result<CKRecord, Error>?
        operation.perRecordSaveBlock = { _, result in
            recordResult = result
        }
        operation.modifyRecordsResultBlock = { result in
            switch result {
            case .success:
                switch recordResult! {
                case .success(let record):
                    completionHandler(record, nil)
                case .failure(let error):
                    completionHandler(nil, error)
                }
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
        schedule(operation: operation)
    }

    public func delete(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord.ID?, Error?) -> Void) {
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [recordID])
        operation.database = self
        var recordResult: Result<Void, Error>?
        operation.perRecordDeleteBlock = { _, result in
            recordResult = result
        }
        operation.modifyRecordsResultBlock = { result in
            switch result {
            case .success:
                switch recordResult! {
                case .success:
                    completionHandler(recordID, nil)
                case .failure(let error):
                    completionHandler(nil, error)
                }
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
        schedule(operation: operation)
    }

    /* Zones convenience methods */
    public func fetchAll(completionHandler: @escaping ([CKRecordZone]?, Error?) -> Void) {
        let operation = CKFetchRecordZonesOperation.fetchAllRecordZonesOperation()
        operation.database = self
        var zoneResult = [CKRecordZone]()
        operation.perRecordZoneResultBlock = { _, result in
            switch result {
            case .success(let zone):
                zoneResult.append(zone)
            case .failure:
                // FIXME: the fetch all opertaion should never fail
                break
            }
        }
        operation.fetchRecordZonesResultBlock = { result in
            switch result {
            case .success:
                completionHandler(zoneResult, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }

        schedule(operation: operation)
    }

    public func fetch(withRecordZoneID zoneID: CKRecordZone.ID, completionHandler: @escaping (CKRecordZone?, Error?) -> Void) {
        let operation = CKFetchRecordZonesOperation(recordZoneIDs: [zoneID])
        operation.database = self
        var zoneResult: Result<CKRecordZone, Error>?
        operation.perRecordZoneResultBlock = { _, result in
            zoneResult = result
        }
        operation.fetchRecordZonesResultBlock = { result in
            switch result {
            case .success:
                switch zoneResult! {
                case .success(let zone):
                    completionHandler(zone, nil)
                case .failure(let error):
                    completionHandler(nil, error)
                }
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
        schedule(operation: operation)
    }

    public func save(_ zone: CKRecordZone, completionHandler: @escaping (CKRecordZone?, Error?) -> Void) {
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
        operation.database = self
        var zoneResult: Result<CKRecordZone, Error>?
        operation.perRecordZoneSaveBlock = { _, result in
            zoneResult = result
        }
        operation.modifyRecordZonesResultBlock = { result in
            switch result {
            case .success:
                switch zoneResult! {
                case .success(let zone):
                    completionHandler(zone, nil)
                case .failure(let error):
                    completionHandler(nil, error)
                }
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
        schedule(operation: operation)
    }

    public func delete(withRecordZoneID zoneID: CKRecordZone.ID, completionHandler: @escaping (CKRecordZone.ID?, Error?) -> Void) {
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: nil, recordZoneIDsToDelete: [zoneID])
        operation.database = self
        var zoneResult: Result<Void, Error>?
        operation.perRecordZoneDeleteBlock = { _, result in
            zoneResult = result
        }
        operation.modifyRecordZonesResultBlock = { result in
            switch result {
            case .success:
                switch zoneResult! {
                case .success:
                    completionHandler(zoneID, nil)
                case .failure(let error):
                    completionHandler(nil, error)
                }
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
        schedule(operation: operation)
    }

    /* Subscriptions convenience methods */
    public func fetchAll(completionHandler: @escaping ([CKSubscription]?, Error?) -> Void) {
        let operation = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
        operation.database = self
        var subscriptionResult = [CKSubscription]()
        operation.perSubscriptionResultBlock = { _, result in
            switch result {
            case .success(let subscription):
                subscriptionResult.append(subscription)
            case .failure:
                // FIXME: the fetch all opertaion should never fail
                break
            }
        }
        operation.fetchSubscriptionsResultBlock = { result in
            switch result {
            case .success:
                completionHandler(subscriptionResult, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }

        schedule(operation: operation)
    }

    public func fetch(withSubscriptionID subscriptionID: CKSubscription.ID, completionHandler: @escaping (CKSubscription?, Error?) -> Void) {
        let operation = CKFetchSubscriptionsOperation(subscriptionIDs: [subscriptionID])
        operation.database = self
        var subscriptionResult: Result<CKSubscription, Error>?
        operation.perSubscriptionResultBlock = { _, result in
            subscriptionResult = result
        }
        operation.fetchSubscriptionsResultBlock = { result in
            switch result {
            case .success:
                switch subscriptionResult! {
                case .success(let subscription):
                    completionHandler(subscription, nil)
                case .failure(let error):
                    completionHandler(nil, error)
                }
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
        schedule(operation: operation)
    }

    public func save(_ subscription: CKSubscription, completionHandler: @escaping (CKSubscription?, Error?) -> Void) {
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
        operation.database = self
        var subscriptionResult: Result<CKSubscription, Error>?
        operation.perSubscriptionSaveBlock = { _, result in
            subscriptionResult = result
        }
        operation.modifySubscriptionsResultBlock = { result in
            switch result {
            case .success:
                switch subscriptionResult! {
                case .success(let subscription):
                    completionHandler(subscription, nil)
                case .failure(let error):
                    completionHandler(nil, error)
                }
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
        schedule(operation: operation)
    }

    public func delete(withSubscriptionID subscriptionID: CKSubscription.ID, completionHandler: @escaping (String?, Error?) -> Void) {
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: nil, subscriptionIDsToDelete: [subscriptionID])
        operation.database = self
        var subscriptionResult: Result<Void, Error>?
        operation.perSubscriptionDeleteBlock = { _, result in
            subscriptionResult = result
        }
        operation.modifySubscriptionsResultBlock = { result in
            switch result {
            case .success:
                switch subscriptionResult! {
                case .success:
                    completionHandler(subscriptionID, nil)
                case .failure(let error):
                    completionHandler(nil, error)
                }
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
        schedule(operation: operation)
    }
}
