//
//  UIViewComplement.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 26/07/2023.
//

import UIKit
import MapKit

//protocol StationMarkerAnnotationViewDelegate: AnyObject {
//    func didTapGesture(for annotation: MKAnnotation)
//}
//
//class StationMarkerAnnotationView: MKMarkerAnnotationView {
//    
//    weak var delegate: StationMarkerAnnotationViewDelegate?
//    
//    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
//        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
//        canShowCallout = true
//        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapGesture(_:)))
//        self.addGestureRecognizer(tap)
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    @objc func didTapGesture(_ gesture: UITapGestureRecognizer) {
//        let location = gesture.location(in: self)
//        // Ignore tap if on view, but not the annotation.
//        if bounds.contains(location) { return }
//        delegate?.didTapGesture(for: annotation!)
//    }
//    
//}
//
//fileprivate class NavigationTapGestureDelegate: StationMarkerAnnotationViewDelegate {
//    
//    private let onTapGesture: (any Station) -> ()
//    
//    init(onTapGesture: @escaping (any Station) -> Void) {
//        self.onTapGesture = onTapGesture
//    }
//    
//    func didTapGesture(for annotation: MKAnnotation) {
//        guard let stopPointAnnotation = annotation as? StationAnnotation
//        else { return }
//        onTapGesture(stopPointAnnotation.station)
//    }
//    
//}
//
//extension UIKitMapView {
//    class Coordinator: NSObject, MKMapViewDelegate {
//        
//        private let annotationDelegate: StationMarkerAnnotationViewDelegate
//        
//        init(onAnnotationTapGesture: @escaping (any Station) -> ()) {
//            self.annotationDelegate = NavigationTapGestureDelegate(onTapGesture: onAnnotationTapGesture)
//        }
//        
//        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//            guard let stationAnnotation = annotation as? StationAnnotation
//            else { return nil }
//            var view = StationMarkerAnnotationView()
//            let colour = StopPointMetaData.lookupUIKitModeColour(stationAnnotation.station.getMode())
//            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: stationAnnotation.station.getMode().rawValue) as? StationMarkerAnnotationView {
//                view = dequeuedView
//            } else {
//                view = StationMarkerAnnotationView(annotation: stationAnnotation, reuseIdentifier: stationAnnotation.station.getMode().rawValue)
//            }
//            view.markerTintColor = colour
//            view.glyphImage = UIImage(systemName: "train.side.front.car")
//            view.clusteringIdentifier = stationAnnotation.station.getMode().rawValue
//            view.delegate = annotationDelegate
//            return view
//        }
//    }
//}
//
//class MapViewDelegate: NSObject, MKMapViewDelegate {
//    
//    private let annotationDelegate: StationMarkerAnnotationViewDelegate
//    
//    init(onAnnotationTapGesture: @escaping (any Station) -> ()) {
//        self.annotationDelegate = NavigationTapGestureDelegate(onTapGesture: onAnnotationTapGesture)
//    }
//    
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        guard let stationAnnotation = annotation as? StationAnnotation
//        else { return nil }
//        var view = StationMarkerAnnotationView()
//        let colour = StopPointMetaData.lookupUIKitModeColour(stationAnnotation.station.getMode())
//        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: stationAnnotation.station.getMode().rawValue) as? StationMarkerAnnotationView {
//            view = dequeuedView
//        } else {
//            view = StationMarkerAnnotationView(annotation: stationAnnotation, reuseIdentifier: stationAnnotation.station.getMode().rawValue)
//        }
//        view.markerTintColor = colour
//        view.glyphImage = UIImage(systemName: "train.side.front.car")
//        view.clusteringIdentifier = stationAnnotation.station.getMode().rawValue
//        view.delegate = annotationDelegate
//        return view
//    }
//}

struct StationAnnotation: Identifiable {
        
    let id = UUID()
    let station: any Station
    let title: String?
    let coordinate: CLLocationCoordinate2D
    
    init(station: any Station, title: String, coordinate: CLLocationCoordinate2D) {
        self.station = station
        self.title = title
        self.coordinate = coordinate
    }
    
}
