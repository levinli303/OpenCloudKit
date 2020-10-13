//
//  CKWebRequest.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 6/07/2016.
//
//

import Foundation

#if os(Linux)
import FoundationNetworking
#endif

class CKWebRequest {
    private static let jsonContentType = "application/json; charset=UTF-8"
    var currentWebAuthToken: String?

    let containerConfig: CKContainerConfig

    init(containerConfig: CKContainerConfig) {
        self.containerConfig = containerConfig
    }

    convenience init(container: CKContainer) {
        self.init(containerConfig: CloudKit.shared.containerConfig(forContainer: container)!)
    }

    var authQueryItems: [URLQueryItem]? {
        if let apiTokenAuth = containerConfig.apiTokenAuth {
            var queryItems: [URLQueryItem] = []

            let apiTokenQueryItem = URLQueryItem(name: "ckAPIToken", value: apiTokenAuth)
            queryItems.append(apiTokenQueryItem)

            if let currentWebAuthToken = currentWebAuthToken {
                let webAuthTokenQueryItem = URLQueryItem(name: "ckWebAuthToken", value: currentWebAuthToken)
                queryItems.append(webAuthTokenQueryItem)
            }
            return queryItems
        } else {
            return nil
        }
    }

    var serverToServerKeyAuth: CKServerToServerKeyAuth? {
        return containerConfig.serverToServerKeyAuth
    }

    func ckError(forNetworkError networkError: Error) -> NSError {
        let networkError = networkError as NSError
        let userInfo = networkError.userInfo
        let errorCode: CKErrorCode

        switch networkError.code {
        case NSURLErrorNotConnectedToInternet:
            errorCode = .networkUnavailable
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
            errorCode = .serviceUnavailable
        default:
            errorCode = .networkFailure
        }

        let error = NSError(domain: CKErrorDomain, code: errorCode.rawValue, userInfo: userInfo)
        return error
    }

    func ckError(forServerResponseDictionary dictionary: [String: Any]) -> NSError {
        if let recordFetchError = CKRecordFetchErrorDictionary(dictionary: dictionary) {
            let errorCode = CKErrorCode.errorCode(serverError: recordFetchError.serverErrorCode)!

            var userInfo: NSErrorUserInfoType  = [:]
            userInfo["redirectURL"] = recordFetchError.redirectURL
            userInfo[NSLocalizedDescriptionKey] = recordFetchError.reason
            userInfo[CKErrorRetryAfterKey] = recordFetchError.retryAfter
            userInfo["uuid"] = recordFetchError.uuid
            return NSError(domain: CKErrorDomain, code: errorCode.rawValue, userInfo: userInfo)
        }
        return NSError(domain: CKErrorDomain, code: CKErrorCode.internalError.rawValue, userInfo: NSErrorUserInfoType())
    }

    func perform(request: URLRequest, completionHandler: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask? {
        let session = URLSession.shared
        let requestCompletionHandler: (Data?, URLResponse?, Error?) -> Void = { data, response, networkError in
            if let networkError = networkError {
                let error = self.ckError(forNetworkError: networkError)
                completionHandler(nil, error)
            } else if let data = data {
                do {
                    let dataString = String(data: data, encoding: .utf8)
                    CloudKit.debugPrint(dataString as Any)
                    let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                    let httpResponse = response as! HTTPURLResponse
                    if httpResponse.statusCode >= 400 {
                        // Error occurred
                        let error = self.ckError(forServerResponseDictionary: dictionary)
                        completionHandler(nil, error)
                    } else {
                        completionHandler(dictionary, nil)
                    }
                } catch let error {
                    completionHandler(nil, error)
                }
            }
        }
        let task = session.dataTask(with: request, completionHandler: requestCompletionHandler)
        task.resume()
        return task
    }

    func urlRequest(with url: URL, data: Data? = nil, contentType: String) -> URLRequest? {
        // Build URL
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        components?.queryItems = authQueryItems
        CloudKit.debugPrint(components?.path as Any)
        guard let requestURL = components?.url else {
            return nil
        }

        var urlRequest = URLRequest(url: requestURL)
        if let data = data {
            urlRequest.httpBody = data
            urlRequest.httpMethod = "POST"
        } else {
            let jsonData: Data = try! JSONSerialization.data(withJSONObject: NSDictionary(), options: [])
            urlRequest.httpBody = jsonData
            urlRequest.httpMethod = "GET"
        }

        if let serverToServerKeyAuth = serverToServerKeyAuth {
            if let signedRequest  = CKServerRequestAuth.authenicateServer(forRequest: urlRequest, withServerToServerKeyAuth: serverToServerKeyAuth) {
                urlRequest = signedRequest
            }
        }

        urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("\(urlRequest.httpBody?.count ?? 0)", forHTTPHeaderField: "Content-Length")
        return urlRequest
    }

    func urlRequest(with url: URL, parameters: [String: Any]? = nil) -> URLRequest? {
        if let parameters = parameters {
            let jsonData: Data = try! JSONSerialization.data(withJSONObject: parameters, options: [])
            return urlRequest(with: url, data: jsonData, contentType: CKWebRequest.jsonContentType)
        }
        return urlRequest(with: url, data: nil, contentType: CKWebRequest.jsonContentType)
    }

    func request(withURL url: String, parameters: [String: Any]?, completion: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask? {
        // Build URL
        var components = URLComponents(string: url)
        components?.queryItems = authQueryItems
        CloudKit.debugPrint(components?.path as Any)
        guard let requestURL = components?.url else { return nil }

        guard let req = urlRequest(with: requestURL, parameters: parameters) else { return nil }
        return perform(request: req, completionHandler: completion)
    }

    func request(withURL url: String, data: Data?, contentType: String, completion: @escaping ([String: Any]?, Error?) -> Void) -> URLSessionTask? {
        // Build URL
        var components = URLComponents(string: url)
        components?.queryItems = authQueryItems
        CloudKit.debugPrint(components?.path as Any)

        guard let requestURL = components?.url else { return nil }
        guard let req = urlRequest(with: requestURL, data: data, contentType: contentType) else { return nil }

        return perform(request: req, completionHandler: completion)
    }
}
