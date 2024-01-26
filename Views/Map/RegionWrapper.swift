//
//  RegionWrapper.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 07/09/2023.
//

import MapKit
import SwiftUI

class RegionWrapper: ObservableObject {
    
    @Published var updateFlag = false
    
    private var _region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: CLLocationDegrees(floatLiteral: 51.501028),
            longitude: CLLocationDegrees(floatLiteral: -0.125435)),
        span: MKCoordinateSpan(
            latitudeDelta: CLLocationDegrees(floatLiteral: 0.01),
            longitudeDelta: CLLocationDegrees(floatLiteral: 0.01)))
    
    var region: Binding<MKCoordinateRegion> {
        Binding(
            get: { self._region },
            set: { self._region = $0 }
        )
    }
    
}
