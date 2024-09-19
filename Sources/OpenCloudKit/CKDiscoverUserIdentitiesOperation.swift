//
//  CKDiscoverUserIdentitiesOperation.swift
//  
//
//  Created by Levin Li on 2022/2/4.
//

import Foundation
import NIOHTTP1

extension CKContainer {
    public func userIdentity(forEmailAddress email: String) async throws -> CKUserIdentity? {
        let results = try await userIdentities(forLookupInfos: [CKUserIdentity.LookupInfo(emailAddress: email)])
        return results.first?.userIdentity
    }

    public func userIdentity(forPhoneNumber phoneNumber: String) async throws -> CKUserIdentity? {
        let results = try await userIdentities(forLookupInfos: [CKUserIdentity.LookupInfo(phoneNumber: phoneNumber)])
        return results.first?.userIdentity
    }

    public func userIdentity(forUserRecordID userRecordID: CKRecord.ID) async throws -> CKUserIdentity? {
        let results = try await userIdentities(forLookupInfos: [CKUserIdentity.LookupInfo(userRecordID: userRecordID)])
        return results.first?.userIdentity
    }

    func userIdentities(forLookupInfos lookupInfos: [CKUserIdentity.LookupInfo]) async throws -> [(lookupInfo: CKUserIdentity.LookupInfo, userIdentity: CKUserIdentity)] {
        let request = CKURLRequestBuilder(database: publicCloudDatabase, operationType: .users, path: "discover")
            .setParameter(key: "lookupInfos", value: lookupInfos.map({ $0.dictionary }))
            .setHTTPMethod(.POST)
            .build()

        let dictionary = try await CKURLRequestHelper.performURLRequest(request)

        // Process user identities
        guard let userIdentityDictionaries = dictionary["users"] as? [[String: Sendable]] else {
            throw CKError.keyMissing(key: "users")
        }

        var results = [(lookupInfo: CKUserIdentity.LookupInfo, userIdentity: CKUserIdentity)]()
        for userIdentityDictionary in userIdentityDictionaries {
            if let userIdentity = CKUserIdentity(dictionary: userIdentityDictionary), let lookupInfo = userIdentity.lookupInfo {
                results.append((lookupInfo, userIdentity))
            } else {
                // Format for partial error?
                throw CKError.formatError(userInfo: userIdentityDictionary)
            }
        }
        return results
    }
}
