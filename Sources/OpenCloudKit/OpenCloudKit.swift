import NIO
import Foundation

public enum CKEnvironment: String, Sendable {
    case development
    case production
}

enum CKOperationType: Sendable {
    case create
    case update
    case replace
    case forceReplace
}

public class CloudKit: @unchecked Sendable {
    public private(set) var containers: [CKContainerConfig] = []
    public static let shared = CloudKit()

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
}

public extension CKRecordZone {
    typealias ID = CKRecordZoneID
}

public final class CKRecordZoneID: NSObject, NSSecureCoding, Sendable {
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

    convenience public required init?(dictionary: [String: Sendable]) {
        guard let zoneName = dictionary["zoneName"] as? String else {
            return nil
        }

        let ownerName = dictionary["ownerRecordName"] as? String ?? CKCurrentUserDefaultName
        self.init(zoneName: zoneName, ownerName: ownerName)
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(zoneName)
        hasher.combine(ownerName)
        return hasher.finalize()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CKRecordZoneID else { return false }
        return self.zoneName == other.zoneName && self.ownerName == other.ownerName
    }

    public required convenience init?(coder: NSCoder) {
        let zoneName = coder.decodeObject(of: NSString.self, forKey: "ZoneName")
        let ownerName = coder.decodeObject(of: NSString.self, forKey: "OwnerName")
        self.init(zoneName: zoneName! as String, ownerName: ownerName! as String)
    }

    public func encode(with coder: NSCoder) {
        coder.encode(zoneName, forKey: "ZoneName")
        coder.encode(ownerName, forKey: "OwnerName")
    }

    public static var supportsSecureCoding: Bool {
        return true
    }
}

extension CKRecordZoneID: CKCodable {
    var dictionary: [String: Sendable] {
        var zoneIDDictionary: [String: Sendable] = [
            "zoneName": zoneName
        ]

        if ownerName != CKCurrentUserDefaultName {
            zoneIDDictionary["ownerRecordName"] = ownerName
        }

        return zoneIDDictionary
    }
}
