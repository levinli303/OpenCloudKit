//
//  CKDiscoverUserIdentitiesOperation.swift
//  
//
//  Created by Levin Li on 2022/2/4.
//

import Foundation
import NIOHTTP1

public class CKDiscoverUserIdentitiesOperation: CKOperation, @unchecked Sendable {
    public var userIdentityDiscoveredBlock: ((CKUserIdentity, CKUserIdentity.LookupInfo) -> Void)?
    public var discoverUserIdentitiesResultBlock: ((_ operationResult: Result<Void, Error>) -> Void)?

    public var userIdentityLookupInfos: [CKUserIdentity.LookupInfo] = []

    private override init() {
        super.init()
    }

    public convenience init(userIdentityLookupInfos: [CKUserIdentity.LookupInfo]) {
        self.init()
        self.userIdentityLookupInfos = userIdentityLookupInfos
    }

    override func performCKOperation() {
        task = Task {
            weak var weakSelf = self
            do {
                let results = try await operationContainer.userIdentities(forLookupInfos: userIdentityLookupInfos)

                guard let self = weakSelf, !self.isCancelled else {
                    throw CKError.operationCancelled
                }

                for result in results {
                    self.callbackQueue.async {
                        self.userIdentityDiscoveredBlock?(result.userIdentity, result.lookupInfo)
                    }
                }

                self.callbackQueue.async {
                    self.discoverUserIdentitiesResultBlock?(.success(()))
                    self.finishOnCallbackQueue()
                }
            }
            catch {
                guard let self = weakSelf else { return }

                self.callbackQueue.async {
                    self.discoverUserIdentitiesResultBlock?(.failure(error))
                    self.finishOnCallbackQueue()
                }
            }
        }
    }
}

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

    public func discoverUserIdentity(withEmailAddress email: String, completionHandler: @escaping (CKUserIdentity?, Error?) -> Void) {
        Task {
            do {
                completionHandler(try await userIdentity(forEmailAddress: email), nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }

    public func discoverUserIdentity(withPhoneNumber phoneNumber: String, completionHandler: @escaping (CKUserIdentity?, Error?) -> Void) {
        Task {
            do {
                completionHandler(try await userIdentity(forPhoneNumber: phoneNumber), nil)
            } catch {
                completionHandler(nil, error)
            }
        }
    }

    public func discoverUserIdentity(withUserRecordID userRecordID: CKRecord.ID, completionHandler: @escaping (CKUserIdentity?, Error?) -> Void) {
        Task {
            do {
                completionHandler(try await userIdentity(forUserRecordID: userRecordID), nil)
            } catch {
                completionHandler(nil, error)
            }
        }
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
