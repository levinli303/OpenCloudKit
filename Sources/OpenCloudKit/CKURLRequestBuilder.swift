//
//  CKURLRequestBuilder.swift
//  
//
//  Created by Levin Li on 2022/1/30.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum CKOperationRequestType: String {
    case records
    case assets
    case zones
    case users
    case lookup
    case subscriptions
    case tokens
}

struct CKServerInfo {
    static let path = "https://api.apple-cloudkit.com"
    static let version = "1"
}

class CKURLRequestBuilder {
    let account: CKAccount
    let url: URL
    var requestProperties: [String: Any] = [:]
    var requestContentType: String = "application/json; charset=utf-8"
    var requestHTTPMethod: String = "POST"
    var requestData: Data?
    let requestTimeout: TimeInterval?

    init(account: CKAccount, serverType: CKServerType, scope: CKDatabase.Scope?, operationType: CKOperationRequestType, path: String, requestTimeout: TimeInterval?) {
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
    }

    convenience init(database: CKDatabase, operationType: CKOperationRequestType, path: String) {
        self.init(account: CloudKit.shared.account(forContainer: database.container)!, serverType: .database, scope: database.scope, operationType: operationType, path: path, requestTimeout: CloudKit.shared.containerConfig(forContainer: database.container)?.requestTimeOut)
    }

    init(url: URL, database: CKDatabase) {
        self.url = url
        self.account = CloudKit.shared.account(forContainer: database.container)!
        self.requestTimeout = CloudKit.shared.containerConfig(forContainer: database.container)?.requestTimeOut
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

    func setHTTPMethod(_ httpMethod: String) -> CKURLRequestBuilder {
        requestHTTPMethod = httpMethod
        return self
    }

    func setParameter(key: String, value: Any?) -> CKURLRequestBuilder {
        requestProperties[key] = value
        return self
    }

    func build() -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = requestHTTPMethod
        urlRequest.addValue(requestContentType, forHTTPHeaderField: "Content-Type")
        if let data = requestData {
            urlRequest.httpBody = data
        }  else if !requestProperties.isEmpty {
            let jsonData = try! JSONSerialization.data(withJSONObject: requestProperties, options: [])
            urlRequest.httpBody = jsonData
        }
        if let serverAccount = account as? CKServerAccount {
            if let signedRequest = CKServerRequestAuth.authenicateServer(forRequest: urlRequest, withServerToServerKeyAuth: serverAccount.serverToServerAuth) {
                urlRequest = signedRequest
            }
        }
        if let requestTimeout = requestTimeout {
            urlRequest.timeoutInterval = requestTimeout
        }
        return urlRequest
    }
}

class CKURLRequestHelper {
    private static var shareURLSession = URLSession(configuration: .default)

    private static func _performURLRequest(_ request: URLRequest) async throws -> Data {
        var dataResponseTuple: (data: Data, response: URLResponse)!
        do {
            dataResponseTuple = try await shareURLSession.data(for: request, delegate: nil)
        } catch {
            if Task.isCancelled {
                throw CKError.cancellation
            }
            throw CKError.networkError(error: error)
        }

        let httpResponse = dataResponseTuple.response as! HTTPURLResponse
        if httpResponse.statusCode >= 400 {
            if let requestError = try? JSONDecoder().decode(CKRequestError.self, from: dataResponseTuple.data) {
                throw CKError.requestError(error: requestError)
            }
            // Indicates an error, but we do not know how to parse the error
            // throw generic error instead
            throw CKError.genericHTTPError(status: httpResponse.statusCode)
        }
        let data = dataResponseTuple.data
        return data
    }

    static func performURLRequest(_ request: URLRequest) async throws -> [String: Any] {
        let data = try await _performURLRequest(request)
        var jsonObject: Any!
        do {
            jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        }
        catch {
            throw CKError.jsonError(error: error)
        }

        guard let dictionary = jsonObject as? [String: Any] else {
            throw CKError.conversionError
        }

        return dictionary
    }

    static func performURLRequest<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let data = try await _performURLRequest(request)
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        }
        catch {
            throw CKError.jsonError(error: error)
        }
    }
}

#if canImport(FoundationNetworking)
// swift-corelibs-foundation still has not integrated concurrency support for Linux yet...
extension URLSession {
    func data(for request: URLRequest, delegate: URLSessionDelegate?) async throws -> (data: Data, response: URLResponse) {
        return try await withCheckedThrowingContinuation { continuation in
            dataTask(with: request, completionHandler: { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (data!, response!))
                }
            }).resume()
        }
    }
}
#endif
