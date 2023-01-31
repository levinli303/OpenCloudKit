//
//  EVPDigestSign.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 10/07/2016.
//
//

import Foundation
import CCryptoBoringSSL

public enum MessageDigestError: Error {
    case unknownDigest
}

public final class MessageDigest {
    static var addedAllDigests = false
    let messageDigest: OpaquePointer

    public init(_ messageDigest: String) throws {
        if !MessageDigest.addedAllDigests {
            CCryptoBoringSSL_OpenSSL_add_all_digests()
            MessageDigest.addedAllDigests = true
        }

        guard let digest = CCryptoBoringSSL_EVP_get_digestbyname(messageDigest) else {
            throw MessageDigestError.unknownDigest
        }

        self.messageDigest = digest
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
        CCryptoBoringSSL_EVP_MD_CTX_free(context)
    }

    public init(_ messageDigest: MessageDigest) throws {
        let context: UnsafeMutablePointer<EVP_MD_CTX>! = CCryptoBoringSSL_EVP_MD_CTX_new()

        if CCryptoBoringSSL_EVP_DigestInit(context, messageDigest.messageDigest) == 0 {
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
            if CCryptoBoringSSL_EVP_DigestUpdate(context, buffer, data.count) == 0 {
                throw MessageDigestContextError.updateFailed
            }
        }
    }

    public func sign(keyData: KeyData, passPhrase: String? = nil) throws -> Data {
        // Load Private Key
        var length: UInt32 = 8192
        var signature = [UInt8](repeating: 0, count: Int(length))

        if CCryptoBoringSSL_EVP_SignFinal(context, &signature, &length, keyData.key) == 0 {
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
            #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
            mem = CCryptoBoringSSL_BIO_new_mem_buf(buffer, Int32(data.count))
            #else
            mem = CCryptoBoringSSL_BIO_new_mem_buf(buffer, ossl_ssize_t(data.count))
            #endif
            if mem != nil {
                pkey = CCryptoBoringSSL_PEM_read_bio_PrivateKey(mem, nil, nil, nil)
            }
        }
        if mem == nil || pkey == nil {
            throw MessageDigestContextError.privateKeyLoadFailed
        }
        bio = mem!
        key = pkey!
    }

    deinit {
        CCryptoBoringSSL_EVP_PKEY_free(key)
        CCryptoBoringSSL_BIO_free_all(bio)
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
            CCryptoBoringSSL_SHA256_Init(&ctx)
            CCryptoBoringSSL_SHA256_Update(&ctx, buffer, count)
            CCryptoBoringSSL_SHA256_Final(hash, &ctx)
            let data = Data(bytes: hash, count: Int(SHA256_DIGEST_LENGTH))
            hash.deallocate()
            return data
        }
    }
}
