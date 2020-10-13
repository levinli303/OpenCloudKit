//
//  CKQuery.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 6/07/2016.
//
//

import Foundation

struct CKQueryDictionary {
    static let recordType = "recordType"
    static let filterBy = "filterBy"
    static let sortBy = "sortBy"
}

struct CKSortDescriptorDictionary {
    static let fieldName = "fieldName"
    static let ascending = "ascending"
    static let relativeLocation = "relativeLocation"
}

public class CKQuery: CKCodable {
    
    public var recordType: String
    
    public var predicate: NSPredicate
    
    let filters: [CKQueryFilter]
    
    public init(recordType: String, predicate: NSPredicate) {
        self.recordType = recordType
        self.predicate = predicate
        self.filters = CKPredicate(predicate: predicate).filters()
    }
    
    public init(recordType: String, filters: [CKQueryFilter]) {
        self.recordType = recordType
        self.filters = filters
        self.predicate = NSPredicate(value: true)
    }
    
    public var sortDescriptors: [NSSortDescriptor] = []
    
    // Returns a Dictionary Representation of a Query Dictionary
    var dictionary: [String: Any] {
        
        var queryDictionary: [String: Any] = ["recordType": recordType]
        
        queryDictionary["filterBy"] = filters.map({ (filter) -> [String: Any] in
            return filter.dictionary
        })
        
        // Create Sort Descriptor Dictionaries
        queryDictionary["sortBy"] = sortDescriptors.compactMap { (sortDescriptor) -> [String: Any]? in
            
            if let fieldName = sortDescriptor.key {
                var sortDescriptionDictionary: [String: Any] =  [:]
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
