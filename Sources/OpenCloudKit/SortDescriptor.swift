//
//  SortDescriptor.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 1/10/16.
//
//

import Foundation

#if canImport(FoundationNetworking)
public typealias NSSortDescriptor = SortDescriptor

open class SortDescriptor: NSObject {
    open var key: String?
    open var ascending: Bool

    public init(key: String?, ascending: Bool) {
        self.key = key
        self.ascending = ascending
    }
}
#endif
