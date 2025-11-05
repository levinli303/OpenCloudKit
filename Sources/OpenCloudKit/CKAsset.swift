//
//  CKAsset.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 16/07/2016.
//
//

import Foundation

public class CKAsset: NSObject, @unchecked Sendable {
    struct UploadInfo: Decodable {
        let size: Int64
        let receipt: String
        let fileChecksum: String
        let referenceChecksum: String?
        let wrappingKey: String?

        var dictionary: [String: Sendable] {
            var results: [String: Sendable] = [
                "size": size,
                "receipt": receipt,
                "fileChecksum": fileChecksum,
            ]
            results["referenceChecksum"] = referenceChecksum
            results["wrappingKey"] = wrappingKey
            return results
        }
    }

    public var fileURL : URL

    var recordKey: String?

    var uploaded: Bool = false

    var downloaded: Bool = false

    var recordID: CKRecord.ID?

    var downloadBaseURL: String?

    var downloadURL: URL? {
        if let downloadBaseURL = downloadBaseURL {
            return URL(string: downloadBaseURL)
        }
        return nil
    }

    public var size: UInt
    public var fileChecksum: String

    var uploadInfo: UploadInfo?

    public init(fileURL: URL) {
        self.fileURL = fileURL
        self.size = 0
        self.fileChecksum = ""
    }

    init?(dictionary: [String: Sendable]) {
        guard let downloadURL = dictionary["downloadURL"] as? String,
              let size = dictionary["size"] as? NSNumber,
              let fileChecksum = dictionary["fileChecksum"] as? String else {
            return nil
        }

        let downloadURLString = downloadURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!

        fileURL = URL(string: downloadURLString)!
        self.downloadBaseURL = downloadURLString
        self.size = size.uintValue
        self.fileChecksum = fileChecksum
        downloaded = false
    }
}

extension CKAsset: CustomDictionaryConvertible {
    public var dictionary: [String: Sendable] {
        return uploadInfo?.dictionary ?? [:]
    }
}
