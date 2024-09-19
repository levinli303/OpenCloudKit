//
//  CKCompatorType.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 19/07/2016.
//
//

import Foundation

public enum CKCompatorType: String, Sendable {
    case equals = "EQUALS"
    case notEquals = "NOT_EQUALS"
    case lessThan = "LESS_THAN"
    case lessThanOrEquals = "LESS_THAN_OR_EQUALS"
    case greaterThan = "GREATER_THAN"
    case greaterThanOrEquals = "GREATER_THAN_OR_EQUALS"
    case near = "NEAR"
    case containsAllTokens = "CONTAINS_ALL_TOKENS"
    case `in` = "IN"
    case notIn = "NOT_IN"
    case containsAnyTokens = "CONTAINS_ANY_TOKENS"
    case listContains = "LIST_CONTAINS"
    case notListContains = "NOT_LIST_CONTAINS"
    case notListContainsAny = "NOT_LIST_CONTAINS_ANY"
    case beginsWith = "BEGINS_WITH"
    case notBeginsWith = "NOT_BEGINS_WITH"
    case listMemberBeginsWith = "LIST_MEMBER_BEGINS_WITH"
    case notListMemberBeginsWith = "NOT_LIST_MEMBER_BEGINS_WITH"
    case listContainsAll = "LIST_CONTAINS_ALL"
    case notListContainsAll = "NOT_LIST_CONTAINS_ALL"

    init?(expression: String) {
        switch expression {
        case "==":
            self = .equals
        case "!=":
            self = .notEquals
        case "<":
            self = .lessThan
        case "<=":
            self = .lessThanOrEquals
        case ">":
            self = .greaterThan
        case ">=":
            self  = .greaterThanOrEquals
        default:
            return nil
        }
    }
}
