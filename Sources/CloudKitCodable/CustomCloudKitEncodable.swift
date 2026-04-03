//
//  CustomCloudKitEncodable.swift
//  CloudKitCodable
//
//  Created by Guilherme Rambo on 11/05/18.
//  Copyright © 2018 Guilherme Rambo. All rights reserved.
//

import Foundation
import OpenCloudKit

internal let _CKSystemFieldsKeyName = "cloudKitSystemFields"
internal let _CKIdentifierKeyName = "cloudKitIdentifier"

public protocol CloudKitRecordRepresentable {
    var cloudKitSystemFields: Data? { get }
    var cloudKitRecordType: String { get }
    var cloudKitIdentifier: String { get }
}

public struct CKAssetDownloadInfo: Decodable, Sendable {
    public let url: URL
    public let size: UInt
    public let fileChecksum: String
}

public struct CKReferenceInfo: Decodable, Sendable {
    public let recordName: String
}

extension CloudKitRecordRepresentable {
    public var cloudKitRecordType: String {
        return String(describing: type(of: self))
    }

    public var cloudKitIdentifier: String {
        return UUID().uuidString
    }
}

public protocol CustomCloudKitEncodable: CloudKitRecordRepresentable & Encodable {

}

public protocol CustomCloudKitDecodable: CloudKitRecordRepresentable & Decodable {

}

public protocol CustomCloudKitCodable: CustomCloudKitEncodable & CustomCloudKitDecodable { }
