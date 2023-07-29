//
//  CKServerRequestAuth.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 11/07/2016.
//
//

import Foundation

struct CKServerRequestAuth {
    static let ISO8601DateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"

        return dateFormatter
    }()

    static let CKRequestKeyIDHeaderKey = "X-Apple-CloudKit-Request-KeyID"
    static let CKRequestDateHeaderKey =  "X-Apple-CloudKit-Request-ISO8601Date"
    static let CKRequestSignatureHeaderKey = "X-Apple-CloudKit-Request-SignatureV1"

    static let globalLock = NSLock()

    let requestDate: String
    let signature: String

    init?(requestBody: Data, urlPath: String, privateKey: KeyData) {
        self.requestDate = CKServerRequestAuth.ISO8601DateFormatter.string(from: Date())
        if let signature = CKServerRequestAuth.signature(requestDate: requestDate, requestBody: requestBody, urlSubpath: urlPath, privateKey: privateKey) {
            self.signature = signature
        } else {
            return nil
        }
    }

    static func sign(data: Data, privateKey: KeyData) -> Data? {
        var finalData: Data?
        globalLock.lock()
        do {
            let ecsda = try MessageDigest("sha256WithRSAEncryption")
            let digestContext =  try MessageDigestContext(ecsda)

            try digestContext.update(data)

            finalData = try digestContext.sign(keyData: privateKey)
        } catch {
            print("Error signing request: \(error)")
        }
        globalLock.unlock()
        return finalData
    }

    static func rawPayload(withRequestDate requestDate: String, requestBody: Data, urlSubpath: String) -> String {
        let bodyHash = requestBody.sha256
        let hashedBody = bodyHash.base64EncodedString(options: [])
        return "\(requestDate):\(hashedBody):\(urlSubpath)"
    }

    static func signature(requestDate: String, requestBody: Data, urlSubpath: String, privateKey: KeyData) -> String? {

        let rawPayloadString = rawPayload(withRequestDate: requestDate, requestBody: requestBody, urlSubpath: urlSubpath)
        let requestData = rawPayloadString.data(using: String.Encoding.utf8)!

        let signedData = sign(data: requestData, privateKey: privateKey)
        return signedData?.base64EncodedString(options: [])
    }

    static func authenticateServer(for data: Data, path: String, withServerToServerKeyAuth auth: CKServerToServerKeyAuth) -> [(String, String)]? {
        return authenticateServer(for: data, path: path, serverKeyID: auth.keyID, privateKey: auth.privateKey)
    }

    static func authenticateServer(for data: Data, path: String, serverKeyID: String, privateKey: KeyData) -> [(String, String)]? {
        guard let auth = CKServerRequestAuth(requestBody: data, urlPath: path, privateKey: privateKey) else {
            return nil
        }

        var headers = [(String, String)]()
        headers.append((CKRequestKeyIDHeaderKey, serverKeyID))
        headers.append((CKRequestDateHeaderKey, auth.requestDate))
        headers.append((CKRequestSignatureHeaderKey, auth.signature))
        return headers
    }
}

