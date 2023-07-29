//
//  CKContainerConfig.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 14/07/2016.
//
//

import AsyncHTTPClient
import Foundation
import NIO

enum CKConfigError: Error {
    case failedInit
    case invalidJSON
}

public struct CKConfig {
    let containers: [CKContainerConfig]

    public init(containers: [CKContainerConfig]) {
        self.containers = containers
    }

    public init(container: CKContainerConfig) {
        self.containers = [container]
    }
}

public struct CKContainerConfig {
    public let containerIdentifier: String
    public let environment: CKEnvironment
    public let apiTokenAuth: String?
    public let webAuthToken: String?
    public var serverToServerKeyAuth: CKServerToServerKeyAuth?
    public var requestTimeout: TimeInterval?
    public var httpClient: HTTPClient?

    public init(containerIdentifier: String, environment: CKEnvironment, apiTokenAuth: String, webAuthToken: String? = nil, requestTimeout: TimeInterval? = nil, httpClient: HTTPClient? = nil) {
        self.containerIdentifier = containerIdentifier
        self.environment = environment
        self.apiTokenAuth = apiTokenAuth
        self.webAuthToken = webAuthToken
        self.serverToServerKeyAuth = nil
        self.requestTimeout = requestTimeout
        self.httpClient = httpClient
    }

    public init(containerIdentifier: String, environment: CKEnvironment, serverToServerKeyAuth: CKServerToServerKeyAuth, requestTimeout: TimeInterval? = nil, httpClient: HTTPClient? = nil) {
        self.containerIdentifier = containerIdentifier
        self.environment = environment
        self.apiTokenAuth = nil
        self.webAuthToken = nil
        self.serverToServerKeyAuth = serverToServerKeyAuth
        self.requestTimeout = requestTimeout
        self.httpClient = httpClient
    }
}

extension CKContainerConfig {
    var containerInfo: CKContainerInfo {
        return CKContainerInfo(containerID: containerIdentifier, environment: environment)
    }
}

public struct CKServerToServerKeyAuth {
    // A unique identifier for the key generated using CloudKit Dashboard. To create this key, read
    public let keyID: String

    //The pass phrase for the key.
    public let privateKeyPassPhrase: String?

    // DER data from the pem key
    public var privateKey: KeyData

    public init(keyID: String, privateKeyFile: String, privateKeyPassPhrase: String? = nil) throws {
        let privateKey = try KeyData(filePath: privateKeyFile)
        self.init(keyID: keyID, privateKey: privateKey, privateKeyPassPhrase: privateKeyPassPhrase)
    }

    public init(keyID: String, privateKey: KeyData, privateKeyPassPhrase: String? = nil) {
        self.keyID = keyID
        self.privateKey = privateKey
        self.privateKeyPassPhrase = privateKeyPassPhrase
    }
}
extension CKServerToServerKeyAuth:Equatable {}

public func ==(lhs: CKServerToServerKeyAuth, rhs: CKServerToServerKeyAuth) -> Bool {
    return lhs.keyID == rhs.keyID && lhs.privateKey == rhs.privateKey && lhs.privateKeyPassPhrase == rhs.privateKeyPassPhrase
}
