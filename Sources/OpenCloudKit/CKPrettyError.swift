//
//  CKPrettyError.swift
//  OpenCloudKit
//
//  Created by Ben Johnson on 29/07/2016.
//
//

import Foundation

typealias NSErrorUserInfoType = [String: Any]

extension NSError {
    public convenience init(error: Error) {
        var userInfo: [String : Any] = [:]
        var code: Int = 0

        // Retrieve custom userInfo information.
        if let customUserInfoError = error as? CustomNSError {
            userInfo = customUserInfoError.errorUserInfo
            code = customUserInfoError.errorCode
        }

        if let localizedError = error as? LocalizedError {
            if let description = localizedError.errorDescription {
                userInfo[NSLocalizedDescriptionKey] = description
            }

            if let reason = localizedError.failureReason {
                userInfo[NSLocalizedFailureReasonErrorKey] = reason
            }

            if let suggestion = localizedError.recoverySuggestion {
                userInfo[NSLocalizedRecoverySuggestionErrorKey] = suggestion
            }

            if let helpAnchor = localizedError.helpAnchor {
                userInfo[NSHelpAnchorErrorKey] = helpAnchor
            }
        }

        if let recoverableError = error as? RecoverableError {
            userInfo[NSLocalizedRecoveryOptionsErrorKey] = recoverableError.recoveryOptions
            //   userInfo[NSRecoveryAttempterErrorKey] = recoverableError
        }
        self.init(domain: "OpenCloudKit", code: code, userInfo: userInfo)
    }
}

enum CKError {
    case network(Error)
    case server([String: Any])
    case parse(Error)
    
    var error: NSError {
        switch  self {
        case .network(let networkError):
            return ckError(forNetworkError: NSError(error: networkError))
        case .server(let dictionary):
            return ckError(forServerResponseDictionary: dictionary)
        case .parse(let parseError):
            let error = NSError(error: parseError)
            return CKPrettyError(code: .internalError, userInfo: error.userInfo)
        }
    }
    
    func ckError(forNetworkError networkError: NSError) -> NSError {
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
        
        let error = CKPrettyError(code: errorCode, userInfo: userInfo)
        return error
    }
    
    func ckError(forServerResponseDictionary dictionary: [String: Any]) -> NSError {
        if let recordFetchError = CKRecordFetchErrorDictionary(dictionary: dictionary) {
            return CKPrettyError(recordFetchError: recordFetchError)
        } else {
            let userInfo = [:] as NSErrorUserInfoType
            return CKPrettyError(code: .internalError, userInfo: userInfo)
        }
    }
}

class CKPrettyError: NSError {
    convenience init<T: CKFetchErrorDictionaryIdentifier>(fetchError: CKFetchErrorDictionary<T>) {
        let errorCode = CKErrorCode.errorCode(serverError: fetchError.serverErrorCode)!

        var userInfo: NSErrorUserInfoType = ["serverErrorCode": fetchError.serverErrorCode]
        if let redirectURL = fetchError.redirectURL {
            userInfo[CKErrorRedirectURLKey] = redirectURL
        }
        if let retryAfter = fetchError.retryAfter {
            userInfo[CKErrorRetryAfterKey] = retryAfter as NSNumber
        }

        self.init(errorCode, userInfo: userInfo, error: nil, path: nil, URL: nil, description: fetchError.reason)
    }

    convenience init(subscriptionFetchError: CKSubscriptionFetchErrorDictionary) {
        let errorCode = CKErrorCode.errorCode(serverError: subscriptionFetchError.serverErrorCode)!

        var userInfo: NSErrorUserInfoType = [:]
        userInfo[CKErrorRedirectURLKey] = subscriptionFetchError.redirectURL

        self.init(errorCode, userInfo: userInfo, error: nil, path: nil, URL: nil, description: subscriptionFetchError.reason)
    }

    convenience init(recordFetchError: CKRecordFetchErrorDictionary) {
        let errorCode = CKErrorCode.errorCode(serverError: recordFetchError.serverErrorCode)!

        var userInfo: NSErrorUserInfoType = [:]

        userInfo[CKErrorRedirectURLKey] = recordFetchError.redirectURL
        userInfo[CKErrorRetryAfterKey] = recordFetchError.retryAfter
        userInfo["uuid"] = recordFetchError.uuid

        self.init(errorCode, userInfo: userInfo, error: nil, path: nil, URL: nil, description: recordFetchError.reason)
    }

    convenience init(code: CKErrorCode) {
        self.init(code, userInfo: nil, error: nil, path: nil, URL: nil, description: code.description)
    }

    convenience init(code: CKErrorCode, userInfo: NSErrorUserInfoType) {
        self.init(code, userInfo: userInfo, error: nil, path: nil, URL: nil, description: code.description)
    }
    
    convenience init(code: CKErrorCode, description: String) {
        self.init(code, userInfo: nil, error: nil, path: nil, URL: nil, description: description)
    }
    
    convenience init(code: CKErrorCode, userInfo: NSErrorUserInfoType, description: String) {
        self.init(code, userInfo: userInfo, error: nil, path: nil, URL: nil, description: description)
    }
    
    init(_ code: CKErrorCode, userInfo: NSErrorUserInfoType?, error: Error?, path: String?, URL: URL?, description: String?){
        var userInfo = userInfo
        
        if description != nil {
            if userInfo == nil {
                userInfo = NSErrorUserInfoType()
            }
            userInfo?[NSLocalizedDescriptionKey] = description;
            userInfo?["CKErrorDescription"] = description;
        }
        
        super.init(domain: CKErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    //override var description: String{
        //<CKError 0x618000240c60: "Operation Cancelled" (20); "Operation <TestOperation: 0x7f876f405ea0; operationID=1644E6818C660C6E, stateFlags=executing|cancelled, qos=Utility> was cancelled before it started">
    //}
    
    override public var description: String {
        // \(withUnsafePointer(to: self))
        let errorDescription = CKErrorCode(rawValue: self.code)?.description ?? ""
        return "<CKError: \"\(errorDescription)\" (\(self.code)); \(self.userInfo)"
    }
}
