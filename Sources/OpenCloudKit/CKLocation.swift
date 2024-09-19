//
//  CKLocation.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 19/07/2016.
//
//

import Foundation

#if canImport(CoreLocation)
import CoreLocation

// Use built-in CLLocation as CKLocation
public typealias CKLocation = CLLocation
public typealias CKLocationCoordinate2D = CLLocationCoordinate2D
public typealias CKLocationDegrees = CLLocationDegrees
public typealias CKLocationDistance = CLLocationDistance
public typealias CKLocationAccuracy = CLLocationAccuracy
public typealias CKLocationSpeed = CLLocationSpeed
public typealias CKLocationDirection = CLLocationDirection

#else

public typealias CKLocationDegrees = Double
public typealias CKLocationDistance = Double
public typealias CKLocationAccuracy = Double
public typealias CKLocationSpeed = Double
public typealias CKLocationDirection = Double

public struct CKLocationCoordinate2D: Equatable, Sendable {
    public var latitude: CKLocationDegrees

    public var longitude: CKLocationDegrees

    public init() {
        latitude = 0
        longitude = 0
    }

    public init(latitude: CKLocationDegrees, longitude: CKLocationDegrees) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public func ==(lhs: CKLocationCoordinate2D, rhs: CKLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}

public class CKLocation: NSObject, Sendable {
    public init(latitude: CKLocationDegrees, longitude: CKLocationDegrees) {
        self.coordinate = CKLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.altitude = 0
        self.horizontalAccuracy = -1
        self.verticalAccuracy = -1
        self.timestamp = Date()
        self.speed = -1
        self.course = -1
    }

    public init(coordinate: CKLocationCoordinate2D, altitude: CKLocationDistance, horizontalAccuracy hAccuracy: CKLocationAccuracy, verticalAccuracy vAccuracy: CKLocationAccuracy, timestamp: Date) {
        self.coordinate = coordinate
        self.altitude = altitude
        self.horizontalAccuracy = hAccuracy
        self.verticalAccuracy = vAccuracy
        self.timestamp = timestamp

        self.speed = -1
        self.course = -1
    }

    public init(coordinate: CKLocationCoordinate2D, altitude: CKLocationDistance, horizontalAccuracy hAccuracy: CKLocationAccuracy, verticalAccuracy vAccuracy: CKLocationAccuracy, course: CKLocationDirection, speed: CKLocationSpeed, timestamp: Date) {
        self.coordinate = coordinate
        self.altitude = altitude
        self.horizontalAccuracy = hAccuracy
        self.verticalAccuracy = vAccuracy
        self.course = course
        self.speed = speed
        self.timestamp = timestamp
    }

    public let coordinate: CKLocationCoordinate2D
    public let altitude: CKLocationDistance
    public let horizontalAccuracy: CKLocationAccuracy
    public let verticalAccuracy: CKLocationAccuracy
    public let course: CKLocationDirection
    public let speed: CKLocationSpeed
    public let timestamp: Date

    public override var description: String {
        return "<\(coordinate.latitude),\(coordinate.longitude)> +/- \(horizontalAccuracy)m (speed \(speed) mps / course \(course))"
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CKLocation else { return false }
        guard coordinate == other.coordinate, altitude == other.altitude else { return false }
        guard (horizontalAccuracy < 0 && other.horizontalAccuracy < 0) || horizontalAccuracy == other.horizontalAccuracy else { return false }
        guard (verticalAccuracy < 0 && other.verticalAccuracy < 0) || verticalAccuracy == other.verticalAccuracy else { return false }
        guard (course < 0 && other.course < 0) || course == other.course else { return false }
        guard (speed < 0 && other.speed < 0) || speed == other.speed else { return false }
        return true
    }
}

#endif

extension CKLocation {
    var dictionary: [String: Sendable] {
        return [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
            "horizontalAccuracy": horizontalAccuracy,
            "verticalAccuracy": verticalAccuracy,
            "altitude": altitude,
            "speed": speed,
            "course": course,
            // CKWebServicesReference doesn't say if this should be seconds or milliseconds, assuming millis since thats what TIMESTAMP uses.
            "timestamp": UInt64(timestamp.timeIntervalSince1970 * 1000)
        ]
    }

    convenience init(dictionary: [String: Sendable]) {
        let latitude = (dictionary["latitude"] as? Double) ?? -1
        let longitude = (dictionary["longitude"] as? Double) ?? -1
        let horizontalAccuracy = (dictionary["horizontalAccuracy"] as? Double) ?? -1
        let verticalAccuracy = (dictionary["verticalAccuracy"] as? Double) ?? -1
        let altitude = (dictionary["altitude"] as? Double) ?? -1
        let speed = (dictionary["speed"] as? Double) ?? -1
        let course = (dictionary["course"] as? Double) ?? -1
        let timestamp = (dictionary["timestamp"] as? Double) ?? -1
        self.init(coordinate: CKLocationCoordinate2D(latitude: latitude, longitude: longitude), altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: course, speed: speed, timestamp: Date(timeIntervalSince1970: timestamp / 1000))
    }
}
