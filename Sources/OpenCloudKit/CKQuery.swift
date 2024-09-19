//
//  CKQuery.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 6/07/2016.
//
//

import Foundation

private struct CKQueryDictionary {
    static let recordType = "recordType"
    static let filterBy = "filterBy"
    static let sortBy = "sortBy"
}

private struct CKSortDescriptorDictionary {
    static let fieldName = "fieldName"
    static let ascending = "ascending"
    static let relativeLocation = "relativeLocation"
}

public class CKQuery: CKCodable, @unchecked Sendable {
    public let recordType: String

    let filters: [CKQueryFilter]
    
    public init(recordType: String, filters: [CKQueryFilter]) {
        self.recordType = recordType
        self.filters = filters
    }
    
    public var sortDescriptors: [NSSortDescriptor] = []
    
    // Returns a Dictionary Representation of a Query Dictionary
    var dictionary: [String: Sendable] {
        var queryDictionary: [String: Sendable] = ["recordType": recordType]
        
        queryDictionary["filterBy"] = filters.map({ (filter) -> [String: Sendable] in
            return filter.dictionary
        })
        
        // Create Sort Descriptor Dictionaries
        queryDictionary["sortBy"] = sortDescriptors.compactMap { (sortDescriptor) -> [String: Sendable]? in
            
            if let fieldName = sortDescriptor.key {
                var sortDescriptionDictionary: [String: Sendable] =  [:]
                sortDescriptionDictionary[CKSortDescriptorDictionary.fieldName] = fieldName
                sortDescriptionDictionary[CKSortDescriptorDictionary.ascending] = NSNumber(value: sortDescriptor.ascending)

                if let locationSortDescriptor = sortDescriptor as? CKLocationSortDescriptor {
                    sortDescriptionDictionary[CKSortDescriptorDictionary.relativeLocation] = locationSortDescriptor.relativeLocation.recordFieldDictionary
                }
                
                return sortDescriptionDictionary
               
            } else {
                return nil
            }
        }
        
        return queryDictionary
    }
}
