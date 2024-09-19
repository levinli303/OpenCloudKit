//
//  CKContainer.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 6/07/2016.
//
//

import Foundation
import NIOHTTP1

public var CKCurrentUserDefaultName: String {
    return "__defaultOwner__"
}

public class CKContainer: @unchecked Sendable {
    static nonisolated(unsafe) var containerFactories = [String: CKContainer]()
    private static let containerLock = NSLock()

    public let containerIdentifier: String

    private init(containerIdentifier: String) {
        self.containerIdentifier = containerIdentifier
    }

    public class func get(_ containerIdentifier: String) -> CKContainer {
        containerLock.lock()
        if let existing = containerFactories[containerIdentifier] {
            containerLock.unlock()
            return existing
        }
        let container = CKContainer(containerIdentifier: containerIdentifier)
        containerFactories[containerIdentifier] = container
        containerLock.unlock()
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
}

extension CKContainer {
    public func userRecordID() async throws -> CKRecord.ID {
        let request = CKURLRequestBuilder(database: publicCloudDatabase, operationType: .users, path: "caller")
            .setHTTPMethod(.GET)
            .build()

        let dictionary = try await CKURLRequestHelper.performURLRequest(request)

        // Process records
        guard let recordName = dictionary["userRecordName"] as? String else {
            throw CKError.keyMissing(key: "userRecordName")
        }
        return CKRecord.ID(recordName: recordName)
    }
}
