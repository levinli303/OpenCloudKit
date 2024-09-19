//
//  CKDatabase.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 6/07/2016.
//
//

import Foundation

extension CKDatabase {
    public enum Scope: Int, CustomStringConvertible {
        case `public` = 1
        case `private`
        case  shared

        public var description: String {
            switch(self) {
            case .private:
                return "private"
            case .public:
                return "public"
            case .shared:
                return "shared"
            }
        }
    }
}

enum CKRecordOperation: String, Sendable {
    case query
    case lookup
    case modify
    case changes
    case resolve
    case accept
}

enum CKModifyOperation: String, Sendable {
    case create
    case update
    case forceUpdate
    case replace
    case forceReplace
    case delete
    case forceDelete
}

public class CKDatabase: @unchecked Sendable {
    weak var container: CKContainer!

    public let scope: Scope

    init(container: CKContainer, scope: Scope) {
        self.container = container
        self.scope = scope
    }
}
