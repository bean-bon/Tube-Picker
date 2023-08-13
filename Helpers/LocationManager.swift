//
//  LocationManager.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 26/07/2023.
//

import Foundation
import MapKit
import CoreLocation

class LocationManager: NSObject, ObservableObject {
    
    private var locationManager = CLLocationManager()
    private var locations: [CLLocation] = []
    
    private var locationSuccessCallbacks: [() -> ()] = []
    
    @Published var currentLocation: CLLocationCoordinate2D? = nil
    @Published var isAuthorisedForLocationUsage: Bool = false
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func registerSuccessCallback(callback: @escaping () -> ()) {
        self.locationSuccessCallbacks.append(callback)
    }
 
    func isAuthorised() -> Bool {
        return [.authorizedAlways, .authorizedWhenInUse].contains(locationManager.authorizationStatus)
    }
    
    func requestLocationData() {
        if locationManager.authorizationStatus != .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
    }
        
}

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .restricted, .denied:
            locationManager.stopUpdatingLocation()
            isAuthorisedForLocationUsage = false
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startMonitoringSignificantLocationChanges()
            locationSuccessCallbacks.forEach({ $0() })
            self.currentLocation = locationManager.location?.coordinate
            isAuthorisedForLocationUsage = true
        default:
            print("Location auth value: \(manager.authorizationStatus)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locations = locations
        self.currentLocation = locations.last?.coordinate
    }
    
}

extension CLLocationCoordinate2D {
    func haversineDistance(_ otherCoordinates: CLLocationCoordinate2D?) -> Double? {
        guard let other: CLLocationCoordinate2D = otherCoordinates
        else { return nil }
        let earthRadius: Double = 6371e3
        let radianLat1 = self.latitude * .pi / 180
        let radianLat2 = other.latitude * .pi / 180
        let latitudeDifference = (other.latitude - self.latitude) * .pi / 180
        let longitudeDifference = (other.longitude - self.longitude) * .pi / 180
        let a = pow(sin(latitudeDifference / 2), 2) + cos(radianLat1) *
            cos(radianLat2) * sin(longitudeDifference / 2) * sin(latitudeDifference / 2)
        let c = atan2(sqrt(a), sqrt(1 - a))
        return earthRadius * c
    }
}

extension MKCoordinateRegion: Equatable {
    public static func ==(lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        return lhs.center == rhs.center && lhs.span == rhs.span
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension MKCoordinateSpan: Equatable {
    public static func ==(lhs: MKCoordinateSpan, rhs: MKCoordinateSpan) -> Bool {
        return lhs.latitudeDelta == rhs.latitudeDelta && lhs.longitudeDelta == rhs.longitudeDelta
    }
}
