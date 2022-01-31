//
//  CKErrorResponse.swift
//  
//
//  Created by Levin Li on 2022/1/31.
//

import Foundation

// https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/ErrorCodes.html#//apple_ref/doc/uid/TP40015240-CH4-SW1
enum CKServerError: String, Error, Decodable {
    case accessDenied = "ACCESS_DENIED"
    case atomicError = "ATOMIC_ERROR"
    case authenticationFailed = "AUTHENTICATION_FAILED"
    case authenticationRequired = "AUTHENTICATION_REQUIRED"
    case badRequest = "BAD_REQUEST"
    case conflict = "CONFLICT"
    case exists = "EXISTS"
    case internalError = "INTERNAL_ERROR"
    case notFound = "NOT_FOUND"
    case quotaExceeded = "QUOTA_EXCEEDED"
    case throttled = "THROTTLED"
    case tryAgainLater = "TRY_AGAIN_LATER"
    case validatingReferenceError = "VALIDATING_REFERENCE_ERROR"
    case zoneNotFound = "ZONE_NOT_FOUND"
}

extension CKServerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "You don’t have permission to access the endpoint, record, zone, or database."
        case .atomicError:
            return "An atomic batch operation failed."
        case .authenticationFailed:
            return "Authentication was rejected."
        case .authenticationRequired:
            return "The request requires authentication but none was provided."
        case .badRequest:
            return "The request was not valid."
        case .conflict:
            return "The recordChangeTag value expired. (Retry the request with the latest tag.)"
        case .exists:
            return "The resource that you attempted to create already exists."
        case .internalError:
            return "An internal error occurred."
        case .notFound:
            return "The resource was not found."
        case .quotaExceeded:
            return "If accessing the public database, you exceeded the app’s quota. If accessing the private database, you exceeded the user’s iCloud quota."
        case .throttled:
            return "The request was throttled. Try the request again later."
        case .tryAgainLater:
            return "An internal error occurred. Try the request again."
        case .validatingReferenceError:
            return "The request violates a validating reference constraint."
        case .zoneNotFound:
            return "The zone specified in the request was not found."
        }
    }
}
