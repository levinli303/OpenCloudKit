//
//  CKQueryFilter.swift
//  OpenCloudKit
//
//  Created by Ben Johnson on 26/07/2016.
//
//

import Foundation

public struct CKLocationBound: Sendable {
    let radius: CKLocationDistance
}

public struct CKQueryFilter: Equatable, Sendable {
    let fieldName: String
    let type: CKCompatorType
    let fieldValue: CKRecordValue
    let bounds: CKLocationBound?
    
    public init(fieldName: String, comparator: CKCompatorType, fieldValue: CKRecordValue, distance: CKLocationDistance? = nil) {
        self.fieldName = fieldName
        self.type = comparator
        self.fieldValue = fieldValue
        if let distance = distance {
            self.bounds = CKLocationBound(radius: distance)
        } else {
            self.bounds = nil
        }
    }
}

extension CKQueryFilter: CKCodable {
    
    public var dictionary: [String: Sendable] {
        var filterDictionary: [String: Sendable] = [
            "comparator": type.rawValue,
            "fieldName": fieldName,
            "fieldValue": fieldValue.recordFieldDictionary
        ]
        
        if let bounds = bounds {
            filterDictionary["distance"] = NSNumber(value: bounds.radius)
        }
        
        return filterDictionary
    }
}

public func ==(lhs: CKQueryFilter, rhs: CKQueryFilter) -> Bool {
   
    return lhs.fieldName == rhs.fieldName && lhs.type == rhs.type
}
