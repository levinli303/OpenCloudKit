//
//  EVPDigestSign.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 10/07/2016.
//
//

import Foundation
import COpenSSL

public enum MessageDigestError: Error {
    case unknownDigest
}

public final class MessageDigest {
    static var addedAllDigests = false
    let messageDigest: UnsafeMutablePointer<EVP_MD>

    public init(_ messageDigest: String) throws {
        if !MessageDigest.addedAllDigests {
            #if !os(Linux)
            OpenSSL_add_all_digests()
            #endif
            MessageDigest.addedAllDigests = true
        }

        guard let messageDigest = messageDigest.withCString({EVP_get_digestbyname($0)}) else {
            throw MessageDigestError.unknownDigest
        }

        self.messageDigest = UnsafeMutablePointer(mutating: messageDigest)
    }
}

public enum MessageDigestContextError: Error {
    case initializationFailed
    case updateFailed
    case signFailed
    case privateKeyLoadFailed
}

public final class MessageDigestContext {
    let context: UnsafeMutablePointer<EVP_MD_CTX>

    deinit {
        #if !os(Linux)
        EVP_MD_CTX_destroy(context)
        #else
        EVP_MD_CTX_free(context)
        #endif
    }

    public init(_ messageDigest: MessageDigest) throws {
        #if !os(Linux)
        let context: UnsafeMutablePointer<EVP_MD_CTX>! = EVP_MD_CTX_create()
        #else
        let context: UnsafeMutablePointer<EVP_MD_CTX>! = EVP_MD_CTX_new()
        #endif

        if EVP_DigestInit(context, messageDigest.messageDigest) == 0 {
            throw MessageDigestContextError.initializationFailed
        }

        guard let c = context else {
            throw MessageDigestContextError.initializationFailed
        }

        self.context = c
    }

    public func update(_ data: Data) throws {
        try data.withUnsafeBytes { dataBytes in
            let buffer: UnsafePointer<UInt8> = dataBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
            if EVP_DigestUpdate(context, buffer, data.count) == 0 {
                throw MessageDigestContextError.updateFailed
            }
        }
    }

    public func sign(keyData: KeyData, passPhrase: String? = nil) throws -> Data {
        // Load Private Key
        var length: UInt32 = 8192
        var signature = [UInt8](repeating: 0, count: Int(length))

        if EVP_SignFinal(context, &signature, &length, keyData.key) == 0 {
            throw MessageDigestContextError.signFailed
        }

        let signatureBytes = Array(signature.prefix(upTo: Int(length)))
        return Data(bytes: signatureBytes, count: signatureBytes.count)
    }
}

public class KeyData: Equatable {
    fileprivate var bio: UnsafeMutablePointer<BIO>
    fileprivate var key: UnsafeMutablePointer<EVP_PKEY>

    init(filePath: String) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        var mem: UnsafeMutablePointer<BIO>?
        var pkey: UnsafeMutablePointer<EVP_PKEY>?
        data.withUnsafeBytes { dataBytes in
            let buffer: UnsafePointer<UInt8> = dataBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
            mem = BIO_new_mem_buf(buffer, Int32(data.count))
            if mem != nil {
                pkey = PEM_read_bio_PrivateKey(mem, nil, nil, nil)
            }
        }
        if mem == nil || pkey == nil {
            throw MessageDigestContextError.privateKeyLoadFailed
        }
        bio = mem!
        key = pkey!
    }

    deinit {
        EVP_PKEY_free(key)
        BIO_free_all(bio)
    }

    public static func == (lhs: KeyData, rhs: KeyData) -> Bool {
        return lhs.bio == rhs.bio && lhs.key == rhs.key
    }
}

extension Data {
    var sha256: Data {
        let hash = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(SHA256_DIGEST_LENGTH))
        return withUnsafeBytes { dataBytes in
            let buffer: UnsafePointer<UInt8> = dataBytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
            var ctx = SHA256_CTX()
            SHA256_Init(&ctx)
            SHA256_Update(&ctx, buffer, count)
            SHA256_Final(hash, &ctx)
            let data = Data(bytes: hash, count: Int(SHA256_DIGEST_LENGTH))
            hash.deallocate()
            return data
        }
    }
}
