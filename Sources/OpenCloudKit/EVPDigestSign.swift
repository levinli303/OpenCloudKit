//
//  EVPDigestSign.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 10/07/2016.
//
//

import Foundation
import Crypto

public class KeyData {
    private let key: P256.Signing.PrivateKey

    func signature(for data: Data) throws -> Data {
        return try key.signature(for: SHA256.hash(data: data)).derRepresentation
    }

    init(filePath: String) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        key = try P256.Signing.PrivateKey(pemRepresentation: String(data: data, encoding: .utf8) ?? "")
    }
}

extension Data {
    var sha256: Data {
        let digest = SHA256.hash(data: self)
        return digest.data
    }
}

extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }
}
