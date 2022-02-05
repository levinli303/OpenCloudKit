//
//  CKErrorCode.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 7/07/2016.
//
//

import Foundation

public struct CKRequestError: Decodable {
    public let reason: String?
    public let serverErrorCode: CKServerError
    public let retryAfter: TimeInterval?
    public let uuid: String?
    public let redirectURL: URL?
}

public enum CKError: Error {
    case operationCancelled
    case networkError(error: Error)
    case jsonError(error: Error)
    case ioError(error: Error)
    case keyMissing(key: String)
    case formatError(userInfo: [String: Any])
    case assetFileNotFound(url: URL)
    case conversionError(data: Any)

    case requestError(error: CKRequestError)
    case recordFetchError(error: CKRecordFetchError)
    case recordZoneFetchError(error: CKRecordZoneFetchError)
    case subscriptionFetchError(error: CKSubscriptionFetchError)
    case genericHTTPError(status: Int)
}
