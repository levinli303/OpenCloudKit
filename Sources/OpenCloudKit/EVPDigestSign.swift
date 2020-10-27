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
    case privateKeyNotFound
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

    public func sign(privateKeyURL: String, passPhrase: String? = nil) throws -> Data {
        // Load Private Key
        let privateKeyFilePointer = BIO_new_file(privateKeyURL, "r")
        guard let privateKeyFile = privateKeyFilePointer else {
            throw MessageDigestContextError.privateKeyNotFound
        }

        guard let privateKey  = PEM_read_bio_PrivateKey(privateKeyFile, nil, nil, nil) else {
            throw MessageDigestContextError.privateKeyLoadFailed
        }

        if ERR_peek_error() != 0 {
            throw MessageDigestContextError.signFailed
        }

        var length: UInt32 = 8192
        var signature = [UInt8](repeating: 0, count: Int(length))

        if EVP_SignFinal(context, &signature, &length, privateKey) == 0 {
            throw MessageDigestContextError.signFailed
        }

        EVP_PKEY_free(privateKey)
        BIO_free_all(privateKeyFilePointer)

        let signatureBytes = Array(signature.prefix(upTo: Int(length)))

        return Data(bytes: signatureBytes, count: signatureBytes.count)
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
