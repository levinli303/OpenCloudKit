//
//  CKPersonNameComponents.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 19/07/2016.
//
//

import Foundation

public class CKPersonNameComponents: NSObject, NSSecureCoding {
    /* Pre-nominal letters denoting title, salutation, or honorific, e.g. Dr., Mr. */
    public var namePrefix: String?

    /* Name bestowed upon an individual by one's parents, e.g. Johnathan */
    public var givenName: String?

    /* Secondary given name chosen to differentiate those with the same first name, e.g. Maple  */
    public var middleName: String?

    /* Name passed from one generation to another to indicate lineage, e.g. Appleseed  */
    public var familyName: String?

    /* Post-nominal letters denoting degree, accreditation, or other honor, e.g. Esq., Jr., Ph.D. */
    public var nameSuffix: String?

    /* Name substituted for the purposes of familiarity, e.g. "Johnny"*/
    public var nickname: String?

    /* Each element of the phoneticRepresentation should correspond to an element of the original PersonNameComponents instance.
     The phoneticRepresentation of the phoneticRepresentation object itself will be ignored. nil by default, must be instantiated.
     */

    public static var supportsSecureCoding: Bool { return true }

    public func encode(with coder: NSCoder) {
        coder.encode(namePrefix, forKey: "NamePrefix")
        coder.encode(givenName, forKey: "GivenName")
        coder.encode(familyName, forKey: "FamilyName")
        coder.encode(nickname, forKey: "Nickname")
        coder.encode(nameSuffix, forKey: "NameSuffix")
        coder.encode(middleName, forKey: "MiddleName")
    }

    public required init?(coder: NSCoder) {
        namePrefix = coder.decodeObject(of: NSString.self, forKey: "NamePrefix") as String?
        givenName = coder.decodeObject(of: NSString.self, forKey: "GivenName") as String?
        familyName = coder.decodeObject(of: NSString.self, forKey: "FamilyName") as String?
        nickname = coder.decodeObject(of: NSString.self, forKey: "Nickname") as String?
        nameSuffix = coder.decodeObject(of: NSString.self, forKey: "NameSuffix") as String?
        middleName = coder.decodeObject(of: NSString.self, forKey: "MiddleName") as String?
    }

    public init?(dictionary: [String: Sendable]) {

        namePrefix = dictionary["namePrefix"] as? String
        givenName = dictionary["givenName"] as? String
        familyName = dictionary["familyName"] as? String
        nickname = dictionary["nickname"] as? String
        nameSuffix = dictionary["nameSuffix"] as? String
        middleName = dictionary["middleName"] as? String
        // phoneticRepresentation
    }

    var dictionary: [String: Sendable] {
        var dictionary = [String: Sendable]()

        dictionary["namePrefix"] = namePrefix
        dictionary["givenName"] = givenName
        dictionary["familyName"] = familyName
        dictionary["nickname"] = nickname
        dictionary["nameSuffix"] = nameSuffix
        dictionary["middleName"] = middleName

        return dictionary
    }
}
