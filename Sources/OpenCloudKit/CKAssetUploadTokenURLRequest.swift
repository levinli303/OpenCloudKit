//
//  CKAssetUploadTokenURLRequest.swift
//
//
//  Created by Levin Li on 2020/10/13.
//

import Foundation

struct CKAssetUploadToken: Encodable {
    let recordType: String
    let fieldName: String
    let recordName: String?

    var dictionary: [String: Any] {
        var dictionary: [String: Any] = [
            "recordType": recordType,
            "fieldName": fieldName
        ]
        if let recordName = recordName {
            dictionary["recordName"] = recordName
        }
        return dictionary
    }
}

class CKAssetUploadTokenURLRequest: CKURLRequest {
    var assetsToUpload: [(asset: CKAsset, uploadToken: CKAssetUploadToken)]

    var zoneID: CKRecordZone.ID?

    func operationsDictionary() -> [[String: Any]] {
        return assetsToUpload.map({ $0.uploadToken.dictionary })
    }

    init(assetsToUpload: [(asset: CKAsset, uploadToken: CKAssetUploadToken)]) {

        self.assetsToUpload = assetsToUpload

        super.init()

        var properties: [String: Any] = [:]
        if let zoneID = zoneID {
            properties["zoneID"] = zoneID.dictionary
        }
        properties["tokens"] = operationsDictionary()
        self.operationType = .assets
        self.path = "upload"
        self.requestProperties = properties
    }
}
