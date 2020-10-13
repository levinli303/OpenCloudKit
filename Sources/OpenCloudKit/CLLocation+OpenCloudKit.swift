//
//  CLLocation+OpenCloudKit.swift
//  OpenCloudKit
//
//  Created by Benjamin Johnson on 20/07/2016.
//
//
#if !os(Linux)
import CoreLocation

extension CLLocationCoordinate2D: CKLocationCoordinate2DType {}

extension CLLocation: CKLocationType {
    public var valueProvider: CKLocation {
        return CKLocation(coordinate: CKLocationCoordinate2D(latitude: coordinateType.latitude, longitude: coordinate.latitude), altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: course, speed: speed, timestamp: timestamp)
    }

    public var coordinateType: CKLocationCoordinate2DType {
        return coordinate
    }
}
#endif
