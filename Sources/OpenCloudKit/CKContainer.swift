//
//  CKContainer.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 6/07/2016.
//
//

import Foundation

#if !os(iOS) && !os(macOS) && os(watchOS) && !os(tvOS)
import FoundationNetworking
#endif

public var CKCurrentUserDefaultName: String {
    return "__defaultOwner__"
}

public class CKContainer {
    static var containerFactories = [String: CKContainer]()

    private let convenienceOperationQueue = OperationQueue()
    public let containerIdentifier: String

    private init(containerIdentifier: String) {
        self.containerIdentifier = containerIdentifier
    }

    public class func get(_ containerIdentifier: String) -> CKContainer {
        if let existing = containerFactories[containerIdentifier] {
            return existing
        }
        let container = CKContainer(containerIdentifier: containerIdentifier)
        containerFactories[containerIdentifier] = container
        return container
    }

    public class func `default`() -> CKContainer {
        // Get Default Container
        return get(CloudKit.shared.containers.first!.containerIdentifier)
    }

    public lazy var publicCloudDatabase: CKDatabase = {
        return CKDatabase(container: self, scope: .public)
    }()

    public lazy var privateCloudDatabase: CKDatabase = {
        return CKDatabase(container: self, scope: .private)
    }()

    public lazy var sharedCloudDatabase: CKDatabase = {
        return CKDatabase(container: self, scope: .shared)
    }()

    var isRegisteredForNotifications: Bool {
        return false
    }

    func registerForNotifications() {}

    public func accountStatus() async throws -> CKAccountStatus {
        guard let account = CloudKit.shared.account(forContainer: self) else {
            return .couldNotDetermine
        }

        if account.isServerAccount {
            // Server account always available
            return .available
        }

        if account.webAuthToken == nil {
            // Anonymous account with no web auth token
            return .noAccount
        }

        // Web auth token available, still need to verify if it is valid
        return .available
    }

    public func accountStatus(completionHandler: @escaping (CKAccountStatus, Error?) -> Void) {
        Task {
            do {
                completionHandler(try await accountStatus(), nil)
            } catch {
                completionHandler(.couldNotDetermine, error)
            }
        }
    }

    public func database(with databaseScope: CKDatabase.Scope) -> CKDatabase {
        switch databaseScope {
        case .public:
            return publicCloudDatabase
        case .private:
            return privateCloudDatabase
        case .shared:
            return sharedCloudDatabase
        }
    }

    private func schedule(convenienceOperation: CKOperation) {
        convenienceOperation.queuePriority = .veryHigh
        convenienceOperation.qualityOfService = .userInitiated

        add(convenienceOperation)
    }

    public func add(_ operation: CKOperation) {
        if operation is CKDatabaseOperation {
            fatalError("CKDatabaseOperations must be submitted to a CKDatabase")
        } else {
            operation.container = self
            convenienceOperationQueue.addOperation(operation)
        }
    }
}

extension CKContainer {
    public func fetchUserRecordID(completionHandler: @escaping (CKRecord.ID?, Error?) -> Void) {
        Task {
            do {
                completionHandler(try await userRecordID(), nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }

    public func userRecordID() async throws -> CKRecord.ID {
        let request = CKURLRequestBuilder(database: publicCloudDatabase, operationType: .users, path: "caller")
            .setHTTPMethod("GET")
            .build()

        let dictionary = try await CKURLRequestHelper.performURLRequest(request)

        // Process records
        guard let recordName = dictionary["userRecordName"] as? String else {
            throw CKError.keyMissing(key: "userRecordName")
        }
        return CKRecord.ID(recordName: recordName)
    }
}
