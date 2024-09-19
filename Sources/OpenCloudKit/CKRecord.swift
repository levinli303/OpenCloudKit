//
//  CKRecord.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 6/07/2016.
//
//

import Foundation

public protocol CKRecordFieldProvider {
    var recordFieldDictionary: [String: Sendable] { get }
}
/*
extension CKRecordFieldProvider where Self: CustomDictionaryConvertible {
    public var recordFieldDictionary: [String: Sendable] {
        return ["value": self.dictionary]
    }
}
*/

public class CKRecord: NSObject, NSSecureCoding, @unchecked Sendable {
    public typealias RecordType = String
    public typealias FieldKey = String

    var values: [String: CKRecordValue] = [:]

    public let recordType: RecordType

    public let recordID: ID

    public var recordChangeTag: String?

    /* This is a User Record recordID, identifying the user that created this record. */
    public var creatorUserRecordID: ID?

    public var creationDate = Date()

    /* This is a User Record recordID, identifying the user that last modified this record. */
    public var lastModifiedUserRecordID: ID?

    public var modificationDate: Date?

    private var changedKeysSet = NSMutableSet()

    public var parent: CKRecord.Reference?

    public internal(set) var share: CKRecord.Reference?

    var shortGUID: String?

    public convenience init(recordType: String) {
        let UUID = UUID().uuidString
        self.init(recordType: recordType, recordID: ID(recordName: UUID))
    }

    public init(recordType: String, recordID: ID) {
        self.recordID = recordID
        self.recordType = recordType
    }

    public func object(forKey key: String) -> CKRecordValue? {
        return values[key]
    }

    public func setObject(_ object: CKRecordValue?, forKey key: String) {
        let containsKey = changedKeysSet.contains(key)


        if !containsKey {
            changedKeysSet.add(key)
        }

        switch object {
        case let asset as CKAsset:
            asset.recordID = self.recordID
        default:
            break
        }

        values[key] = object
    }

    public func allKeys() -> [String] {
       return Array(values.keys)
    }

    public subscript(key: String) -> CKRecordValue? {
        get {
            return object(forKey: key)
        }
        set(newValue) {
            setObject(newValue, forKey: key)
        }
    }

    public func changedKeys() -> [String] {
        return changedKeysSet.compactMap { $0 as? String }
    }


    override public var description: String {
        return "<\(type(of: self)): ; recordType = \(recordType);recordID = \(recordID); values = \(values)>"
    }

    public override var debugDescription: String {
        return"<\(type(of: self)); recordType = \(recordType);recordID = \(recordID); values = \(values)>"
    }

    init?(recordDictionary: [String: Sendable], zoneID: CKRecordZone.ID? = nil) {
        guard let recordName = recordDictionary[CKRecordDictionary.recordName] as? String, let recordType = recordDictionary[CKRecordDictionary.recordType] as? String else {
            return nil
        }

        let recordZoneID: CKRecordZone.ID
        if let zoneID = zoneID {
            recordZoneID = zoneID
        } else if let zoneIDDictionary = recordDictionary[CKRecordDictionary.zoneID] as? [String: Sendable] {
            // Parse ZoneID Dictionary into CKRecordZone.ID
            recordZoneID = CKRecordZone.ID(dictionary: zoneIDDictionary)!
        } else {
            recordZoneID = .default
        }

        self.recordID = ID(recordName: recordName, zoneID: recordZoneID)

        self.recordType = recordType

        // Parse Record Change Tag
        if let changeTag = recordDictionary[CKRecordDictionary.recordChangeTag] as? String {
            recordChangeTag = changeTag
        }

        // Parse Created Dictionary
        if let createdDictionary = recordDictionary[CKRecordDictionary.created] as? [String: Sendable], let created = CKRecordLog(dictionary: createdDictionary) {
            self.creatorUserRecordID = ID(recordName: created.userRecordName)
            self.creationDate = Date(timeIntervalSince1970: Double(created.timestamp) / 1000)
        }

        // Parse Modified Dictionary
        if let modifiedDictionary = recordDictionary[CKRecordDictionary.modified] as? [String: Sendable], let modified = CKRecordLog(dictionary: modifiedDictionary) {
            self.lastModifiedUserRecordID = ID(recordName: modified.userRecordName)
            self.modificationDate = Date(timeIntervalSince1970: Double(modified.timestamp) / 1000)
        }

        // Enumerate Fields
        if let fields = recordDictionary[CKRecordDictionary.fields] as? [String: [String: Sendable]] {
            for (key, fieldValue) in fields  {
                let value = CKRecord.getValue(forRecordField: fieldValue)
                values[key] = value
                if value == nil {
                    print("Type not recognized, field: \(key), recordName: \(recordName)")
                }
            }
        }

        if let parentReferenceDictionary = recordDictionary["parent"] as? [String: Sendable] {
            parent = CKRecord.Reference(dictionary: parentReferenceDictionary)
        }

        if let shareReferenceDictionary = recordDictionary["share"] as? [String: Sendable] {
            share = CKRecord.Reference(dictionary: shareReferenceDictionary)
        }

        shortGUID = recordDictionary["shortGUID"] as? String
    }

    public static var supportsSecureCoding: Bool { return true }

    public required init?(coder: NSCoder) {
        recordType = coder.decodeObject(of: NSString.self, forKey: "RecordType")! as String
        recordID = coder.decodeObject(of: ID.self, forKey: "RecordID")!
        recordChangeTag = coder.decodeObject(of: NSString.self, forKey: "ETag") as String?
        creatorUserRecordID = coder.decodeObject(of: ID.self, forKey: "CreatorUserRecordID")
        creationDate = coder.decodeObject(of: NSDate.self, forKey: "RecordCtime")! as Date
        lastModifiedUserRecordID = coder.decodeObject(of: ID.self, forKey: "LastModifiedUserRecordID")
        modificationDate = coder.decodeObject(of: NSDate.self, forKey: "RecordMtime") as Date?
        parent = coder.decodeObject(of: Reference.self, forKey: "ParentReference")
        share = coder.decodeObject(of: Reference.self, forKey: "ShareReference")
        shortGUID = coder.decodeObject(of: NSString.self, forKey: "ShortGUID") as String?
        changedKeysSet = coder.decodeObject(of: NSMutableSet.self, forKey: "ChangedKeySet") ?? NSMutableSet()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(recordType, forKey: "RecordType")
        coder.encode(recordID, forKey: "RecordID")
        coder.encode(recordChangeTag, forKey: "ETag")
        coder.encode(creatorUserRecordID, forKey: "CreatorUserRecordID")
        coder.encode(creationDate, forKey: "RecordCtime")
        coder.encode(lastModifiedUserRecordID, forKey: "LastModifiedUserRecordID")
        coder.encode(modificationDate, forKey: "RecordMtime")
        coder.encode(parent, forKey: "ParentReference")
        coder.encode(share, forKey: "ShareReference")
        coder.encode(shortGUID, forKey: "ShortGUID")
        coder.encode(changedKeysSet, forKey: "ChangedKeySet")
    }

    public func encodeSystemFields(with coder: NSCoder) {
        encode(with: coder)
    }
}

struct CKRecordDictionary {
    static let recordName = "recordName"
    static let recordType = "recordType"
    static let recordChangeTag = "recordChangeTag"
    static let fields = "fields"
    static let zoneID = "zoneID"
    static let modified = "modified"
    static let created = "created"
}

struct CKRecordFieldDictionary {
    static let value = "value"
    static let type = "type"
}

struct CKValueType {
    static let string = "STRING"
    static let data = "BYTES"
}

struct CKRecordLog {
    let timestamp: UInt64 // milliseconds
    let userRecordName: String
    let deviceID: String

    init?(dictionary: [String: Sendable]) {
        guard let timestamp = (dictionary["timestamp"] as? NSNumber)?.uint64Value, let userRecordName = dictionary["userRecordName"] as? String, let deviceID =  dictionary["deviceID"] as? String else {
            return nil
        }

        self.timestamp = timestamp
        self.userRecordName = userRecordName
        self.deviceID = deviceID
    }
}

extension CKRecord {
    static func process(number: NSNumber, type: String) -> CKRecordValue {
        switch(type) {
        case "TIMESTAMP":
            return NSDate(timeIntervalSince1970: number.doubleValue / 1000)
        default:
            return number
        }
    }

    static func getValue(forRecordField field: [String: Sendable]) -> CKRecordValue? {
        if  let value = field[CKRecordFieldDictionary.value],
            let type = field[CKRecordFieldDictionary.type] as? String {

            switch value {
            case let number as NSNumber:
                return process(number: number, type: type)

            case let intValue as Int:
                let number = NSNumber(value: intValue)
                return process(number: number, type: type)

            case let doubleValue as Double:
                let number = NSNumber(value: doubleValue)
                return process(number: number, type: type)

            case let dictionary as [String: Sendable]:
                switch type {

                case "LOCATION":
                    return CKLocation(dictionary: dictionary)
                case "ASSETID":
                    // size
                    // downloadURL
                    // fileChecksum
                    return CKAsset(dictionary: dictionary)
                case "REFERENCE":
                    return CKRecord.Reference(dictionary: dictionary)
                default:
                    fatalError("Type not supported")
                }

            case let boolean as Bool:
                return NSNumber(booleanLiteral: boolean)

            case let string as String:
                switch type {
                case CKValueType.string:
                    return string
                case CKValueType.data:
                    return Data(base64Encoded: string)
                default:
                    return string
                }

            case let array as [Sendable]:
                switch type {
                case "INT64_LIST":
                    return array as! [Int64]
                case "DOUBLE_LIST":
                    return array as! [Double]
                case "STRING_LIST":
                    return array as! [String]
                case "TIMESTAMP_LIST":
                    return (array as! [Double]).map { item -> Date in
                        return Date(timeIntervalSince1970: item / 1000)
                    }
                case "LOCATION_LIST":
                    return (array as! [[String: Sendable]]).map { item -> CKLocation in
                        return CKLocation(dictionary: item)
                    }
                case "REFERENCE_LIST":
                    return (array as! [[String: Sendable]]).map { item -> CKRecord.Reference in
                        return CKRecord.Reference(dictionary: item)!
                    }
                case "ASSETID_LIST":
                    return (array as! [[String: Sendable]]).map { item -> CKAsset in
                        return CKAsset(dictionary: item)!
                    }
                case "BYTES_LIST":
                    return (array as! [String]).map { item -> Data in
                        return Data(base64Encoded: item)!
                    }
                case "UNKNOWN_LIST":
                    // UNKNOWN_LIST is an empty list, but here we cannot be sure
                    // what we should give back to the caller, return an empty
                    // array of any type will suffice
                    return [String]()
                default:
                    fatalError("List type of \(type) not supported")
                }

            default:
                return nil
            }
        } else {
            return nil
        }
    }
}

public protocol CKRecordValue : CKRecordFieldProvider, Sendable {
    static var typeName: String? { get }
    var dictionaryValue: Sendable { get }
}

extension CKRecordValue {
    public var recordFieldDictionary: [String: Sendable] {
        if let type = Self.typeName {
            return ["value": dictionaryValue, "type": type]
        }
        return ["value": dictionaryValue]
    }
}

private protocol CKRecordValueType: CKRecordValue {
    associatedtype MappedType
    associatedtype TransformedType: Sendable

    var valueProvider: MappedType { get }
    func transform(_ value: MappedType) -> TransformedType
}

extension CKRecordValueType {
    public var dictionaryValue: Sendable {
        return transform(valueProvider)
    }
}

private protocol CKRecordValueString: CKRecordValueType where MappedType == String, TransformedType == String {}

extension CKRecordValueString {
    public static var typeName: String? { return "STRING" }

    public func transform(_ value: MappedType) -> TransformedType {
        return value
    }
}

private protocol CKRecordValueInt64: CKRecordValueType where MappedType == Int64, TransformedType == Int64 {}

extension CKRecordValueInt64 {
    public static var typeName: String? { return "INT64" }

    public func transform(_ value: MappedType) -> TransformedType {
        return value
    }
}

private protocol CKRecordValueDouble: CKRecordValueType where MappedType == Double, TransformedType == Double {}

extension CKRecordValueDouble {
    public static var typeName: String? { return "DOUBLE" }

    public func transform(_ value: MappedType) -> TransformedType {
        return value
    }
}

private protocol CKRecordValueDate: CKRecordValueType where MappedType == Date, TransformedType == Int64 {}

extension CKRecordValueDate {
    public static var typeName: String? { return "TIMESTAMP" }

    public func transform(_ value: MappedType) -> TransformedType {
        return Int64(value.timeIntervalSince1970 * 1000)
    }
}

private protocol CKRecordValueData: CKRecordValueType where MappedType == Data, TransformedType == String {}

extension CKRecordValueData {
    public static var typeName: String? { return "BYTES" }

    public func transform(_ value: MappedType) -> TransformedType {
        return value.base64EncodedString()
    }
}

private protocol CKRecordValueAsset: CKRecordValueType where MappedType == [String: Sendable], TransformedType == [String: Sendable] {}

extension CKRecordValueAsset {
    public static var typeName: String? { return "ASSETID" }

    public func transform(_ value: MappedType) -> TransformedType {
        return value
    }
}

private protocol CKRecordValueReference: CKRecordValueType where MappedType == [String: Sendable], TransformedType == [String: Sendable] {}

extension CKRecordValueReference {
    public static var typeName: String? { return "REFERENCE" }

    public func transform(_ value: MappedType) -> TransformedType {
        return value
    }
}

private protocol CKRecordValueLocation: CKRecordValueType where MappedType == CKLocation, TransformedType == [String: Sendable] {}

extension CKRecordValueLocation {
    public static var typeName: String? { return "LOCATION" }

    public func transform(_ value: MappedType) -> TransformedType {
        return value.dictionary
    }
}

extension NSString: CKRecordValueString, @unchecked Sendable {
    public var valueProvider: String { return self as String }
}

extension String: CKRecordValueString {
    public var valueProvider: String { self }
}

extension Int64: CKRecordValueInt64 {
    public var valueProvider: Int64 { return Int64(self) }
}
extension Int32: CKRecordValueInt64 {
    public var valueProvider: Int64 { return Int64(self) }
}

extension Int16: CKRecordValueInt64 {
    public var valueProvider: Int64 { return Int64(self) }
}

extension Int8: CKRecordValueInt64 {
    public var valueProvider: Int64 { return Int64(self) }
}

extension Int: CKRecordValueInt64 {
    public var valueProvider: Int64 { return Int64(self) }
}

extension UInt64: CKRecordValueInt64 {
    public var valueProvider: Int64 { return Int64(self) }
}

extension UInt32: CKRecordValueInt64 {
    public var valueProvider: Int64 { return Int64(self) }
}

extension UInt16: CKRecordValueInt64 {
    public var valueProvider: Int64 { return Int64(self) }
}

extension UInt8: CKRecordValueInt64 {
    public var valueProvider: Int64 { return Int64(self) }
}

extension UInt: CKRecordValueInt64 {
    public var valueProvider: Int64 { return Int64(self) }
}

extension Bool: CKRecordValueInt64 {
    public var valueProvider: Int64 { return self ? 1 : 0 }
}

extension Double: CKRecordValueDouble {
    public var valueProvider: Double { return Double(self) }
}

extension Float: CKRecordValueDouble {
    public var valueProvider: Double { return Double(self) }
}

extension NSDate: CKRecordValueDate {
    public var valueProvider: Date { return self as Date }
}

extension Date: CKRecordValueDate {
    public var valueProvider: Date { return self }
}

extension NSData : CKRecordValueData, @unchecked Sendable {
    public var valueProvider: Data { return self as Data }
}

extension Data : CKRecordValueData {
    public var valueProvider: Data { return self }
}

extension CKAsset: CKRecordValueAsset {
    public var valueProvider: [String: Sendable] {
        return dictionary
    }
}

extension CKRecord.Reference: CKRecordValueReference {
    public var valueProvider: [String: Sendable] {
        return dictionary
    }
}

extension CKLocation: CKRecordValueLocation {
    public var valueProvider: CKLocation {
        return self
    }
}

extension NSNumber: CKRecordValue {
    public static var typeName: String? { return nil }
    public var dictionaryValue: Sendable { return self }
}

extension Array: CKRecordFieldProvider, CKRecordValue where Element: CKRecordValue {
    public static var typeName: String? {
        if let firstItemTypeName = Element.typeName {
            return "\(firstItemTypeName)_LIST"
        }
        return nil
    }

    public var dictionaryValue: Sendable {
        return map { $0.dictionaryValue }
    }
}
