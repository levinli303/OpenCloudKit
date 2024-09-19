import AsyncHTTPClient
import XCTest
@testable import OpenCloudKit

import NIO

#if canImport(CoreLocation)
import CoreLocation

typealias CKRecord = OpenCloudKit.CKRecord
typealias CKContainer = OpenCloudKit.CKContainer
typealias CKRecordValue = OpenCloudKit.CKRecordValue
typealias CKAsset = OpenCloudKit.CKAsset

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.longitude == rhs.longitude && lhs.latitude == rhs.latitude
    }
}
#endif

extension CKDatabase {
    var account: CKAccount {
        return CloudKit.shared.account(forContainer: container)!
    }
}

class CKTest: XCTestCase {
    enum Constant {
        static let containerID = "iCloud.bilgisayar.CKDemo"
        static let token = "6e6d25238b580815a6be02c46803b53f86e7c065a97290726a5cbc8f0ee62917"
        static let environment = CKEnvironment.development
        static let requestTimeout = TimeAmount.seconds(10)
    }

    private class CloudKitHelper {
        class func configure(containerID: String, token: String, environment: CKEnvironment) {
            let defaultContainerConfig = CKContainerConfig(containerIdentifier: containerID, environment: environment, apiTokenAuth: token)
            let config = CKConfig(containers: [defaultContainerConfig])

            CloudKit.shared.configure(with: config)
        }
    }

    override class func setUp() {
        super.setUp()

        FileManager.default.changeCurrentDirectoryPath(Bundle.module.resourcePath!)
        CloudKitHelper.configure(containerID: Constant.containerID, token: Constant.token, environment: Constant.environment)
    }

    func requestURL(_ url: URL) async throws -> Data? {
        let client: HTTPClient = .shared
        var urlRequest = HTTPClientRequest(url: url.absoluteString)
        urlRequest.method = .GET

        var response: HTTPClientResponse!
        do {
            response = try await client.execute(urlRequest, timeout: Constant.requestTimeout)
        } catch {
            if Task.isCancelled {
                throw CKError.operationCancelled
            }
            throw CKError.networkError(error: error)
        }

        var data = Data()
        do {
            for try await buffer in response.body {
                data.append(contentsOf: buffer.readableBytesView)
            }
        } catch {
            if Task.isCancelled {
                throw CKError.operationCancelled
            }
            throw CKError.networkError(error: error)
        }

        if response.status.code >= 400 {
            if let requestError = try? JSONDecoder().decode(CKRequestError.self, from: data) {
                throw CKError.requestError(error: requestError)
            }
            // Indicates an error, but we do not know how to parse the error
            // throw generic error instead
            throw CKError.genericHTTPError(status: response.status.code)
        }
        return data
    }
}
