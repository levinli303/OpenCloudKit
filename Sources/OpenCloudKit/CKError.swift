//
//  CKErrorCode.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 7/07/2016.
//
//

import Foundation

public struct CKRequestError: Decodable, Sendable {
    public let reason: String?
    public let serverErrorCode: CKServerError
    public let retryAfter: TimeInterval?
    public let uuid: String?
    public let redirectURL: URL?
}

public enum CKError: Error, Sendable {
    case operationCancelled
    case networkError(error: Error)
    case jsonError(error: Error)
    case ioError(error: Error)
    case keyMissing(key: String)
    case formatError(userInfo: [String: Sendable])
    case assetFileNotFound(url: URL)
    case conversionError(data: Data)

    case requestError(error: CKRequestError)
    case recordFetchError(error: CKRecordFetchError)
    case recordZoneFetchError(error: CKRecordZoneFetchError)
    case subscriptionFetchError(error: CKSubscriptionFetchError)
    case genericHTTPError(status: UInt)
}

extension CKError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .operationCancelled:
            return "The operation has been cancelled."
        case .networkError(let error):
            return "Network error, underlying error: \(error)."
        case .jsonError(let error):
            return "JSON (de)serialization error, underlying error: \(error)."
        case .ioError(let error):
            return "File IO error, underlying error: \(error)."
        case .keyMissing(let key):
            return "\(key) is missing."
        case .formatError(let userInfo):
            return "The response is in an incorrect format: \(userInfo)."
        case .assetFileNotFound(let url):
            return "The expected asset file is not found in \(url)."
        case .conversionError(let data):
            return "Deserialization error, data in base64 format: \(data.base64EncodedString())."
        case .requestError(let error):
            return "Request error, underlying error: \(error)."
        case .recordFetchError(let error):
            return "Error fetching record, underlying error: \(error)."
        case .recordZoneFetchError(let error):
            return "Error fetching record zone, underlying error: \(error)."
        case .subscriptionFetchError(let error):
            return "Error fetching subscription, underlying error: \(error)."
        case .genericHTTPError(let status):
            return "HTTP error, status code: \(status)."
        }
    }
}
