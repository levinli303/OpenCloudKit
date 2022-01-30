//
//  CKModifyRecordsURLRequest.swift
//  OpenCloudKit
//
//  Created by Ben Johnson on 27/07/2016.
//
//

import Foundation

class CKModifyRecordsURLRequest: CKURLRequest {
    var recordsToSave: [CKRecord]?

    var recordIDsToDelete: [CKRecord.ID]?

    var recordsByRecordIDs: [CKRecord.ID: CKRecord] = [:]

    var atomic: Bool = true

    // var sendAllFields: Bool

    var savePolicy: CKRecordSavePolicy

    init(recordsToSave: [CKRecord]?, recordIDsToDelete: [CKRecord.ID]?, isAtomic: Bool, database: CKDatabase, savePolicy: CKRecordSavePolicy, zoneID: CKRecordZone.ID?) {
        self.recordsToSave = recordsToSave
        self.recordIDsToDelete = recordIDsToDelete
        self.atomic = isAtomic
        self.savePolicy = savePolicy
        super.init()

        self.databaseScope = database.scope

        self.path = "modify"
        self.operationType = CKOperationRequestType.records

        // Setup Body Properties
        var parameters: [String: Any] = [:]

        if database.scope == .public {
            parameters["atomic"] = NSNumber(value: false)
        } else {
            parameters["atomic"] = NSNumber(value: isAtomic)
        }

        parameters["operations"] = operationsDictionary()

        if let zoneID = zoneID {
            parameters["zoneID"] = zoneID.dictionary
        }
        requestProperties = parameters
    }

    func operationsDictionary() -> [[String: Any]] {
        var operationsDictionaryArray: [[String: Any]] = []

        if let recordIDsToDelete = recordIDsToDelete {
            let deleteOperations = recordIDsToDelete.map({ (recordID) -> [String: Any] in
                let operationDictionary: [String: Any] = [
                    "operationType": "forceDelete",
                    "record":(["recordName":recordID.recordName] as [String: Any]) as Any
                ]

                return operationDictionary
            })
            operationsDictionaryArray.append(contentsOf: deleteOperations)
        }
        if let recordsToSave = recordsToSave {
            let saveOperations = recordsToSave.map({ (record) -> [String: Any] in

                let operationType: String
                let fieldsDictionary: [String: Any]

                //record.dictionary
                var recordDictionary: [String: Any] = ["recordType": record.recordType, "recordName": record.recordID.recordName]
                if let recordChangeTag = record.recordChangeTag {

                    if savePolicy == .IfServerRecordUnchanged {
                        operationType = "update"
                    } else {
                        operationType = "forceUpdate"
                    }

                    // Set Operation Type to Replace
                    if savePolicy == .AllKeys {
                        fieldsDictionary = record.fieldsDictionary(forKeys: record.allKeys())
                    } else {
                        fieldsDictionary = record.fieldsDictionary(forKeys: record.changedKeys())
                    }

                    recordDictionary["recordChangeTag"] = recordChangeTag
                } else {
                    // Create new record
                    fieldsDictionary = record.fieldsDictionary(forKeys: record.allKeys())
                    operationType = "create"
                }

                recordDictionary["fields"] = fieldsDictionary
                if let parent = record.parent {
                    recordDictionary["createShortGUID"] = NSNumber(value: 1)
                    recordDictionary["parent"] = ["recordName": parent.recordID.recordName]
                }

                let operationDictionary: [String: Any] = ["operationType": operationType, "record": recordDictionary]
                return operationDictionary
            })

            operationsDictionaryArray.append(contentsOf: saveOperations)
        }

        return operationsDictionaryArray
    }
}
