//
//  CKAccount.swift
//  OpenCloudKit
//
//  Created by Ben Johnson on 27/07/2016.
//
//

import Foundation

public enum CKAccountType: Sendable {
    case primary
    case anoymous
    case server
}

public class CKAccount: @unchecked Sendable {
    let accountType: CKAccountType

    var isAnonymousAccount: Bool {
        return accountType == .anoymous && webAuthToken == nil
    }

    var isServerAccount: Bool {
        return accountType == .server
    }

    let containerInfo: CKContainerInfo

    let webAuthToken: String?

    let cloudKitAuthToken: String?

    init(type: CKAccountType, containerInfo: CKContainerInfo, cloudKitAuthToken: String?, webAuthToken: String?) {
        self.accountType = type
        self.containerInfo = containerInfo
        self.cloudKitAuthToken = cloudKitAuthToken
        self.webAuthToken = webAuthToken
    }
}

public class CKServerAccount: CKAccount, @unchecked Sendable {
    let serverToServerAuth: CKServerToServerKeyAuth

    init(containerInfo: CKContainerInfo, serverToServerAuth: CKServerToServerKeyAuth) {
        self.serverToServerAuth = serverToServerAuth
        super.init(type: .server, containerInfo: containerInfo, cloudKitAuthToken: nil, webAuthToken: nil)
    }

    convenience init(containerInfo: CKContainerInfo, keyID: String, privateKeyFile: String, passPhrase: String? = nil) throws {
        let keyAuth = try CKServerToServerKeyAuth(keyID: keyID, privateKeyFile: privateKeyFile, privateKeyPassPhrase: passPhrase)
        self.init(containerInfo: containerInfo, serverToServerAuth: keyAuth)
    }

    convenience init(containerInfo: CKContainerInfo, keyID: String, privateKey: KeyData, passPhrase: String? = nil) {
        let keyAuth = CKServerToServerKeyAuth(keyID: keyID, privateKey: privateKey, privateKeyPassPhrase: passPhrase)
        self.init(containerInfo: containerInfo, serverToServerAuth: keyAuth)
    }
}
