//
//  CKErrorCode.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 7/07/2016.
//
//

import Foundation

struct CKRequestError: Decodable {
    let reason: String?
    let serverErrorCode: CKServerError
    let retryAfter: TimeInterval?
    let uuid: String?
    let redirectURL: String?
}

enum CKError: Error {
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
