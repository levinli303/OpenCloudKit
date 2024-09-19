//
//  CKAccountStatus.swift
//  OpenCloudKit
//
//  Created by Ben Johnson on 17/10/16.
//
//

public enum CKAccountStatus : Int, Sendable {
    case couldNotDetermine
    case available
    case restricted
    case noAccount
    case temporarilyUnavailable
}
