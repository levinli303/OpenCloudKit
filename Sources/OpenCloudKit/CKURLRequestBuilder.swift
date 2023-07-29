//
//  CKURLRequestBuilder.swift
//  
//
//  Created by Levin Li on 2022/1/30.
//

import AsyncHTTPClient
import Foundation
import NIO
import NIOHTTP1

enum CKOperationRequestType: String {
    case records
    case assets
    case zones
    case users
    case lookup
    case subscriptions
    case tokens
    case changes
}

struct CKServerInfo {
    static let path = "https://api.apple-cloudkit.com"
    static let version = "1"
}

class Request {
    let request: HTTPClientRequest
    let timeout: TimeInterval?
    let eventLoopGroup: EventLoopGroup?

    init(request: HTTPClientRequest, timeout: TimeInterval?, eventLoopGroup: EventLoopGroup?) {
        self.request = request
        self.timeout = timeout
        self.eventLoopGroup = eventLoopGroup
    }
}

class CKURLRequestBuilder {
    let account: CKAccount
    let url: URL
    var requestProperties: [String: Sendable] = [:]
    var requestContentType: String = "application/json; charset=utf-8"
    var requestHTTPMethod: HTTPMethod = .POST
    var requestData: Data?
    let requestTimeout: TimeInterval?
    let eventLoopGroup: EventLoopGroup?

    init(account: CKAccount, serverType: CKServerType, scope: CKDatabase.Scope?, operationType: CKOperationRequestType, path: String, requestTimeout: TimeInterval?, eventLoopGroup: EventLoopGroup?) {
        var baseURL = URL(string: CKServerInfo.path)!
        baseURL.appendPathComponent(serverType.urlComponent)
        baseURL.appendPathComponent(CKServerInfo.version)
        baseURL.appendPathComponent(account.containerInfo.containerID)
        baseURL.appendPathComponent(account.containerInfo.environment.rawValue)
        if let databaseScope = scope {
            baseURL.appendPathComponent(databaseScope.description)
        }
        baseURL.appendPathComponent(operationType.rawValue)
        baseURL.appendPathComponent(path)

        var queryItems = [String]()
        switch account.accountType {
        case .server:
            break
        case .anoymous, .primary:
            queryItems.append("ckAPIToken=\(account.cloudKitAuthToken ?? "")")
            // https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html#//apple_ref/doc/uid/TP40015240-CH24-SW1
            if let icloudAuthToken = account.webAuthToken {
                queryItems.append("ckWebAuthToken=\(icloudAuthToken.replacingOccurrences(of: "+", with: "%2B").replacingOccurrences(of: "/", with: "%2F").replacingOccurrences(of: "=", with: "%3D"))")
            }
        }
        if !queryItems.isEmpty {
            baseURL = URL(string: "\(baseURL.absoluteString)?\(queryItems.joined(separator: "&"))")!
        }
        self.account = account
        self.url = baseURL
        self.requestTimeout = requestTimeout
        self.eventLoopGroup = eventLoopGroup
    }

    convenience init(database: CKDatabase, operationType: CKOperationRequestType, path: String) {
        let config = CloudKit.shared.containerConfig(forContainer: database.container)
        self.init(
            account: CloudKit.shared.account(forContainer: database.container)!,
            serverType: .database,
            scope: database.scope,
            operationType: operationType,
            path: path,
            requestTimeout: config?.requestTimeOut,
            eventLoopGroup: config?.eventLoopGroup
        )
    }

    init(url: URL, database: CKDatabase) {
        self.url = url
        self.account = CloudKit.shared.account(forContainer: database.container)!
        let config = CloudKit.shared.containerConfig(forContainer: database.container)
        self.requestTimeout = config?.requestTimeOut
        self.eventLoopGroup = config?.eventLoopGroup
    }

    func setZone(_ zoneID: CKRecordZoneID?) -> CKURLRequestBuilder {
        requestProperties["zoneID"] = zoneID?.dictionary
        return self
    }

    func setContentType(_ contentType: String) -> CKURLRequestBuilder {
        requestContentType = contentType
        return self
    }

    func setData(_ data: Data) -> CKURLRequestBuilder {
        requestData = data
        return self
    }

    func setHTTPMethod(_ httpMethod: HTTPMethod) -> CKURLRequestBuilder {
        requestHTTPMethod = httpMethod
        return self
    }

    func setParameter(key: String, value: Sendable?) -> CKURLRequestBuilder {
        requestProperties[key] = value
        return self
    }

    func build() -> Request {
        var urlRequest = HTTPClientRequest(url: url.absoluteString)
        urlRequest.method = requestHTTPMethod
        var requestHeaders = [(String, String)]()
        requestHeaders.append(("Content-Type", requestContentType))
        let data: Data
        if let requestData {
            data = requestData
        }  else if !requestProperties.isEmpty {
            data = try! JSONSerialization.data(withJSONObject: requestProperties, options: [])
        } else {
            data = Data()
        }
        if let serverAccount = account as? CKServerAccount, let authHeaders = CKServerRequestAuth.authenticateServer(for: data, path: url.path, withServerToServerKeyAuth: serverAccount.serverToServerAuth) {
            requestHeaders.append(contentsOf: authHeaders)
        }
        urlRequest.headers = HTTPHeaders(requestHeaders)
        urlRequest.body = .bytes(data)
        return Request(request: urlRequest, timeout: requestTimeout, eventLoopGroup: eventLoopGroup)
    }
}

class CKURLRequestHelper {
    private static func _performURLRequest(_ request: Request) async throws -> Data {
        let eventLoopGroupProvider: HTTPClient.EventLoopGroupProvider
        if let eventLoopGroup = request.eventLoopGroup {
            eventLoopGroupProvider = .shared(eventLoopGroup)
        } else {
            eventLoopGroupProvider = .createNew
        }
        let client = HTTPClient(eventLoopGroupProvider: eventLoopGroupProvider)
        let result: Result<Data, Error>
        do {
            result = .success(try await _performURLRequest(request, client: client))
        } catch {
            result = .failure(error)
        }

        try? await client.shutdown()

        switch result {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }

    private static func _performURLRequest(_ request: Request, client: HTTPClient) async throws -> Data {
        let seconds = request.timeout ?? 60
        var response: HTTPClientResponse!
        do {
            response = try await client.execute(request.request, timeout: .seconds(Int64(seconds)))
        } catch {
            if Task.isCancelled {
                throw CKError.operationCancelled
            }
            throw CKError.networkError(error: error)
        }

        var data = Data()
        do {
            for try await buffer in response.body {
                data.append(contentsOf: buffer.readableBytesView)
            }
        } catch {
            if Task.isCancelled {
                throw CKError.operationCancelled
            }
            throw CKError.networkError(error: error)
        }

        if response.status.code >= 400 {
            if let requestError = try? JSONDecoder().decode(CKRequestError.self, from: data) {
                throw CKError.requestError(error: requestError)
            }
            // Indicates an error, but we do not know how to parse the error
            // throw generic error instead
            throw CKError.genericHTTPError(status: response.status.code)
        }
        return data
    }

    static func performURLRequest(_ request: Request) async throws -> [String: Sendable] {
        let data = try await _performURLRequest(request)
        var jsonObject: Any!
        do {
            jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        }
        catch {
            throw CKError.jsonError(error: error)
        }

        guard let dictionary = jsonObject as? [String: Sendable] else {
            throw CKError.conversionError(data: data)
        }

        return dictionary
    }

    static func performURLRequest<Response: Decodable>(_ request: Request) async throws -> Response {
        let data = try await _performURLRequest(request)
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        }
        catch {
            throw CKError.jsonError(error: error)
        }
    }
}
