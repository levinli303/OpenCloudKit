

import Foundation

public enum CKEnvironment: String {
    case development
    case production
}

enum CKOperationType {
    case create
    case update
    case replace
    case forceReplace
}

public class CloudKit {

    public var environment: CKEnvironment = .development

    public private(set) var containers: [CKContainerConfig] = []

    public static let shared = CloudKit()

    // Temporary property to allow for debugging via console
    public var verbose: Bool = false

    public weak var delegate: OpenCloudKitDelegate?

    var pushConnections: [CKPushConnection] = []

    private init() {}

    public func configure(with configuration: CKConfig) {
        self.containers = configuration.containers
    }

    func containerConfig(forContainer container: CKContainer) -> CKContainerConfig? {
        return containers.first(where: { (config) -> Bool in
            return config.containerIdentifier == container.containerIdentifier
        })
    }

    func account(forContainerConfig containerConfig: CKContainerConfig) -> CKAccount? {
        if let serverAuth = containerConfig.serverToServerKeyAuth {
            // Server Account
            return CKServerAccount(containerInfo: containerConfig.containerInfo, keyID: serverAuth.keyID, privateKeyFile: serverAuth.privateKeyFile)
        } else if let apiTokenAuth = containerConfig.apiTokenAuth {
            // Anoymous Account
            return CKAccount(type: .anoymous, containerInfo: containerConfig.containerInfo, cloudKitAuthToken: apiTokenAuth)
        }
        return nil
    }

    func account(forContainer container: CKContainer) -> CKAccount? {
        guard let containerConfig = containerConfig(forContainer: container) else {
            return nil
        }
        return account(forContainerConfig: containerConfig)
    }

    static func debugPrint(_ items: Any...) {
        if shared.verbose {
            print(items)
        }
    }

    func createPushConnection(for url: URL) {
        let connection = CKPushConnection(url: url)
        connection.callBack = {
            (notification) in

            self.delegate?.didRecieveRemoteNotification(notification)
        }

        pushConnections.append(connection)
    }

    public func registerForRemoteNotifications() {

        // Setup Create Token Operation
        let createTokenOperation = CKTokenCreateOperation(apnsEnvironment: environment)
        createTokenOperation.createTokenCompletionBlock = {
            (info, error) in

            if let info = info {
                // Register Token
                let registerOperation = CKRegisterTokenOperation(apnsEnvironment: info.apnsEnvironment, apnsToken: info.apnsToken)
                registerOperation.registerTokenCompletionBlock = {
                    (tokenInfo, error) in

                    if let error = error {
                        // Notify delegate of error when registering for notifications
                        self.delegate?.didFailToRegisterForRemoteNotifications(withError: error)
                    } else if let info = tokenInfo {
                        // Notify Delegate
                        self.delegate?.didRegisterForRemoteNotifications(withToken: info.apnsToken)

                        // Start connection with token
                        self.createPushConnection(for: info.webcourierURL)


                    }
                }
                registerOperation.start()

            } else if let error = error {
                // Notify delegate of error when registering for notifications
                self.delegate?.didFailToRegisterForRemoteNotifications(withError: error)

            }
        }

        createTokenOperation.start()
    }


}

public protocol OpenCloudKitDelegate: class {

    func didRecieveRemoteNotification(_ notification:CKNotification)

    func didFailToRegisterForRemoteNotifications(withError error: Error)

    func didRegisterForRemoteNotifications(withToken token: Data)

}

extension CKRecordID {
    var isDefaultName: Bool {
        return recordName == CKRecordZoneDefaultName
    }
}


public class CKRecordZoneID: NSObject, NSSecureCoding {

    public init(zoneName: String, ownerName: String) {
        self.zoneName = zoneName
        self.ownerName = ownerName
        super.init()

    }

    public let zoneName: String

    public let ownerName: String

    convenience public required init?(dictionary: [String: Any]) {
        guard let zoneName = dictionary["zoneName"] as? String, let ownerName = dictionary["ownerRecordName"] as? String else {
            return nil
        }

        self.init(zoneName: zoneName, ownerName: ownerName)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CKRecordZoneID else { return false }
        return self.zoneName == other.zoneName && self.ownerName == other.ownerName
    }


    public required convenience init?(coder: NSCoder) {
        let zoneName = coder.decodeObject(of: NSString.self, forKey: "ZoneName")
        let ownerName = coder.decodeObject(of: NSString.self, forKey: "ownerName")
        self.init(zoneName: zoneName! as String, ownerName: ownerName! as String)
    }

    public func encode(with coder: NSCoder) {
        coder.encode(zoneName, forKey: "ZoneName")
        coder.encode(ownerName, forKey: "ownerName")
    }

    public static var supportsSecureCoding: Bool {
        return true
    }
}

extension CKRecordZoneID: CKCodable {
    var dictionary: [String: Any] {
        var zoneIDDictionary: [String: Any] = [
            "zoneName": zoneName
        ]

        if ownerName != CKRecordZoneIDDefaultOwnerName {
            zoneIDDictionary["ownerRecordName"] = ownerName
        }

        return zoneIDDictionary
    }
}












