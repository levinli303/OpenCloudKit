//
//  CKPersonNameComponents.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 19/07/2016.
//
//

import Foundation

public struct CKPersonNameComponents {

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
}

extension CKPersonNameComponents {
    public init?(dictionary: [String: Any]) {

        namePrefix = dictionary["namePrefix"] as? String
        givenName = dictionary["givenName"] as? String
        familyName = dictionary["familyName"] as? String
        nickname = dictionary["nickname"] as? String
        nameSuffix = dictionary["nameSuffix"] as? String
        middleName = dictionary["middleName"] as? String
        // phoneticRepresentation
    }

    var dictionary: [String: Any] {
        var dictionary = [String: Any]()

        dictionary["namePrefix"] = namePrefix
        dictionary["givenName"] = givenName
        dictionary["familyName"] = familyName
        dictionary["nickname"] = nickname
        dictionary["nameSuffix"] = nameSuffix
        dictionary["middleName"] = middleName

        return dictionary
    }
}
