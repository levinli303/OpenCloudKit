//
//  CKErrorCode.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 7/07/2016.
//
//

import Foundation

let CKErrorDomain: String = "CKErrorDomain"

enum CKErrorCode : Int {
    case internalError
    case partialFailure
    case networkUnavailable
    case networkFailure
    case badContainer
    case serviceUnavailable
    case requestRateLimited
    case missingEntitlement
    case notAuthenticated
    case permissionFailure
    case unknownItem
    case invalidArguments
    case resultsTruncated
    case serverRecordChanged
    case serverRejectedRequest
    case assetFileNotFound
    case assetFileModified
    case incompatibleVersion
    case constraintViolation
    case operationCancelled
    case changeTokenExpired
    case batchRequestFailed
    case zoneBusy
    case badDatabase
    case quotaExceeded
    case zoneNotFound
    case limitExceeded
    case userDeletedZone
    case tooManyParticipants
    case alreadyShared
    case referenceViolation
    case managedAccountRestricted
    case participantMayNeedVerification
}

extension CKErrorCode {
    static func errorCode(serverError: String) -> CKErrorCode? {
        switch(serverError) {
        case "ACCESS_DENIED":
            return .notAuthenticated
        case "ATOMIC_ERROR":
            return CKErrorCode.batchRequestFailed
        case "AUTHENTICATION_FAILED":
            return CKErrorCode.notAuthenticated
        case "AUTHENTICATION_REQUIRED":
            return CKErrorCode.permissionFailure
        case "BAD_REQUEST":
            return CKErrorCode.serverRejectedRequest
        case "CONFLICT":
            return CKErrorCode.changeTokenExpired
        case "EXISTS":
            return CKErrorCode.constraintViolation
        case "INTERNAL_ERROR":
            return CKErrorCode.internalError
        case "NOT_FOUND":
            return CKErrorCode.unknownItem
        case "QUOTA_EXCEEDED":
            return CKErrorCode.quotaExceeded
        case "THROTTLED":
            return CKErrorCode.requestRateLimited
        case "TRY_AGAIN_LATER":
            return CKErrorCode.internalError
        case "VALIDATING_REFERENCE_ERROR":
            return CKErrorCode.constraintViolation
        case "ZONE_NOT_FOUND":
            return CKErrorCode.zoneNotFound
        default:
            fatalError("Unknown  Server Error: \(serverError)")
        }
    }
}

extension CKErrorCode: CustomStringConvertible {
    var description: String {
        switch self {
        case .internalError:
            return "Internal Error"
        case .partialFailure:
            return "Partial Failure"
        case .networkUnavailable:
            return "Network Unavailable"
        case .networkFailure:
            return "Network Failure"
        case .badContainer:
            return "Bad Container"
        case .serviceUnavailable:
            return "Service Unavailable"
        case .requestRateLimited:
            return "Request Rate Limited"
        case .missingEntitlement:
            return "Missing Entitlement"
        case .notAuthenticated:
            return "Not Authenticated"
        case .permissionFailure:
            return "Permission Failure"
        case .unknownItem:
            return "Unknown Item"
        case .invalidArguments:
            return "Invalid Arguments"
        case .resultsTruncated:
            return "Results Truncated"
        case .serverRecordChanged:
            return "Server Record Changed"
        case .serverRejectedRequest:
            return "Server Rejected Request"
        case .assetFileNotFound:
            return "Asset File Not Found"
        case .assetFileModified:
            return "Asset File Modified"
        case .incompatibleVersion:
            return "Incompatible Version"
        case .constraintViolation:
            return "Constraint Violation"
        case .operationCancelled:
            return "Operation Cancelled"
        case .changeTokenExpired:
            return "Change Token Expired"
        case .batchRequestFailed:
            return "Batch Request Failed"
        case .zoneBusy:
            return "Zone Busy"
        case .badDatabase:
            return "Invalid Database For Operation"
        case .quotaExceeded:
            return "Quota Exceeded"
        case .zoneNotFound:
            return "Zone Not Found"
        case .limitExceeded:
            return "Limit Exceeded"
        case .userDeletedZone:
            return "User Deleted Zone"
        case .tooManyParticipants:
            return "Too Many Participants"
        case .alreadyShared:
            return "Already Shared"
        case .referenceViolation:
            return "Reference Violation"
        case .managedAccountRestricted:
            return "Managed Account Restricted"
        case .participantMayNeedVerification:
            return "Participant May Need Verification"
        }
    }
}

let CKErrorRetryAfterKey = "CKRetryAfter"
let CKErrorRedirectURLKey = "CKRedirectURL"
let CKPartialErrorsByItemIDKey = "CKPartialErrors"
let CKErrorStringFailedToParseServerResponse = "Failed to parse response from server"
let CKErrorStringFailedToResolveRecord = "Couldn't resolve record or record fetch error dictionary"
let CKErrorStringFailedToParseRecord = "Failed to parse record from server"
let CKErrorStringFailedToParseRecordZone = "Failed to parse record zone from server"
let CKErrorStringPartialErrorRecords = "Failed to modify some records"
let CKErrorStringPartialErrorSubscriptions = "Failed to modify some subscriptions"
let CKErrorStringAssetUploadWrongTokenNumber = "Failed to get correct number of tokens"
let CKErrorStringAssetUploadFailure = "Failed to upload asset"
