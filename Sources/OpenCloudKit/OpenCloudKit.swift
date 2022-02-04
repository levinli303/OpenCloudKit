

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
            return CKServerAccount(containerInfo: containerConfig.containerInfo, keyID: serverAuth.keyID, privateKey: serverAuth.privateKey)
        } else if let apiTokenAuth = containerConfig.apiTokenAuth {
            // Anoymous Account
            return CKAccount(type: .anoymous, containerInfo: containerConfig.containerInfo, cloudKitAuthToken: apiTokenAuth, webAuthToken: containerConfig.webAuthToken)
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
        // TODO:
    }
}

public protocol OpenCloudKitDelegate: AnyObject {
    func didRecieveRemoteNotification(_ notification:CKNotification)
    func didFailToRegisterForRemoteNotifications(withError error: Error)
    func didRegisterForRemoteNotifications(withToken token: Data)
}

extension CKRecord.ID {
    var isDefaultName: Bool {
        return recordName == CKRecordZone.ID.defaultZoneName
    }
}

public extension CKRecordZone {
    typealias ID = CKRecordZoneID
}

public class CKRecordZoneID: NSObject, NSSecureCoding {
    /* The default zone has no capabilities */
    public static let `default`: CKRecordZone.ID = CKRecordZoneID(zoneName: defaultZoneName, ownerName: CKCurrentUserDefaultName)
    public static let defaultZoneName: String = "_defaultZone"

    public init(zoneName: String, ownerName: String) {
        self.zoneName = zoneName
        self.ownerName = ownerName
        super.init()
    }

    public let zoneName: String

    public let ownerName: String

    convenience public required init?(dictionary: [String: Any]) {
        guard let zoneName = dictionary["zoneName"] as? String else {
            return nil
        }

        let ownerName = dictionary["ownerRecordName"] as? String ?? CKCurrentUserDefaultName
        self.init(zoneName: zoneName, ownerName: ownerName)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CKRecordZoneID else { return false }
        return self.zoneName == other.zoneName && self.ownerName == other.ownerName
    }

    public required convenience init?(coder: NSCoder) {
        let zoneName = coder.decodeObject(of: NSString.self, forKey: "zoneName")
        let ownerName = coder.decodeObject(of: NSString.self, forKey: "ownerName")
        self.init(zoneName: zoneName! as String, ownerName: ownerName! as String)
    }

    public func encode(with coder: NSCoder) {
        coder.encode(zoneName, forKey: "zoneName")
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

        if ownerName != CKCurrentUserDefaultName {
            zoneIDDictionary["ownerRecordName"] = ownerName
        }

        return zoneIDDictionary
    }
}












