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
    case cancellation
    case networkError(error: Error)
    case jsonError(error: Error)

    case requestError(error: CKRequestError)
    case recordFetchError(error: CKRecordFetchError)
    case recordZoneFetchError(error: CKRecordZoneFetchError)
    case subscriptionFetchError(error: CKSubscriptionFetchError)

    case conversionError

    case keyMissing(key: String)

    case genericHTTPError(status: Int)
    case tokenCountIncorrect

    case assetNotFound
    case assetReadError

    case noOperationNeeded
}
