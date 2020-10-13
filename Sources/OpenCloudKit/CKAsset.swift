//
//  CKAsset.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 16/07/2016.
//
//

import Foundation

public class CKAsset: NSObject {
    
    public var fileURL : URL
    
    var recordKey: String?
    
    var uploaded: Bool = false
    
    var downloaded: Bool = false
    
    var recordID: CKRecordID?
    
    var downloadBaseURL: String?
        
    var downloadURL: URL? {
        get {
            if let downloadBaseURL = downloadBaseURL {
                return URL(string: downloadBaseURL)!
            } else {
                return nil
            }
        }
    }
    
    var size: UInt?
    
    var hasSize: Bool {
        return size != nil
    }
    
    var uploadReceipt: String?

    var uploadInfo: [String: Any]?
    
    public init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    init?(dictionary: [String: Any]) {
        
        guard
        let downloadURL = dictionary["downloadURL"] as? String,
        let size = dictionary["size"] as? NSNumber
        else  {
            return nil
        }
       
        let downloadURLString = downloadURL.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!

        fileURL = URL(string: downloadURLString)!
        self.downloadBaseURL = downloadURL
        self.size = size.uintValue
        downloaded = false

    }
}

extension CKAsset: CustomDictionaryConvertible {
    public var dictionary: [String: Any] {
        return uploadInfo ?? [:]
    }
}
