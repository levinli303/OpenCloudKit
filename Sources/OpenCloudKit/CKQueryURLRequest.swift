//
//  CKQueryURLRequest.swift
//  OpenCloudKit
//
//  Created by Ben Johnson on 26/07/2016.
//
//

import Foundation

class CKQueryURLRequest: CKURLRequest {
    var cursor: Data?
    var limit: Int
    let query: CKQuery
    var queryResponses: [[String: Any]] = []
    var requestedFields: [String]?
    var resultsCursor: Data?
    var zoneID: CKRecordZoneID?

    init(query: CKQuery, cursor: Data?, limit: Int, requestedFields: [String]?, zoneID: CKRecordZoneID?) {
        self.query = query
        self.cursor = cursor
        self.limit = limit
        self.requestedFields = requestedFields
        self.zoneID = zoneID

        super.init()

        self.path = "query"
        self.operationType = CKOperationRequestType.records

        // Setup Body Properties
        var parameters: [String: Any] = [:]

        let isZoneWide = false
        if let zoneID = zoneID, zoneID.zoneName != CKRecordZoneDefaultName {
            // Add ZoneID Dictionary to parameters
            parameters["zoneID"] = zoneID.dictionary
        }

        if limit > 0 {
            parameters["resultsLimit"] = limit
        }

        parameters["desiredKeys"] = requestedFields
        parameters["zoneWide"] = isZoneWide
        parameters["query"] = query.dictionary

        if let cursor = cursor {
            parameters["continuationMarker"] = cursor.base64EncodedString(options: [])
        }
        requestProperties = parameters
    }
}
