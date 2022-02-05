//
//  CKLocationSortDescriptor.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 20/07/2016.
//
//

import Foundation

public class CKLocationSortDescriptor: NSSortDescriptor {
    public init(key: String, relativeLocation: CKLocation) {
        self.relativeLocation = relativeLocation
        super.init(key: key, ascending: true)
    }

    #if !canImport(FoundationNetworking)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    #endif

    public var relativeLocation: CKLocation
}
