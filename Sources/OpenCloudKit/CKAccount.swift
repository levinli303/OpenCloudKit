//
//  CKAccount.swift
//  OpenCloudKit
//
//  Created by Ben Johnson on 27/07/2016.
//
//

import Foundation

public enum CKAccountType {
    case primary
    case anoymous
    case server
}

public class CKAccount {
    let accountType: CKAccountType

    var isAnonymousAccount: Bool {
        return accountType == .anoymous
    }

    var isServerAccount: Bool {
        return accountType == .server
    }

    var containerInfo: CKContainerInfo

    public var iCloudAuthToken: String?

    let cloudKitAuthToken: String?

    init(type: CKAccountType, containerInfo: CKContainerInfo, cloudKitAuthToken: String?) {
        self.accountType = type
        self.containerInfo = containerInfo
        self.cloudKitAuthToken = cloudKitAuthToken
    }

    init(containerInfo: CKContainerInfo,cloudKitAuthToken: String, iCloudAuthToken: String) {
        self.accountType = .primary
        self.containerInfo = containerInfo
        self.iCloudAuthToken = iCloudAuthToken
        self.cloudKitAuthToken = cloudKitAuthToken
    }
}

public class CKServerAccount: CKAccount {
    let serverToServerAuth: CKServerToServerKeyAuth

    init(containerInfo: CKContainerInfo, serverToServerAuth: CKServerToServerKeyAuth) {
        self.serverToServerAuth = serverToServerAuth
        super.init(type: .server, containerInfo: containerInfo, cloudKitAuthToken: nil)
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
