//
//  MapView.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 26/07/2023.
//

import SwiftUI
import MapKit
import CoreLocation

class MapViewModel: ObservableObject {
    
    @Published var positionReset: Bool
    @Published var markerPoints: [StationAnnotation]
    @Published var busStops: [StationAnnotation]
    var mirroredRegion: MKCoordinateRegion
    private var updateTask: Task<Void, any Error>
    
    static let defaultLocation = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: CLLocationDegrees(floatLiteral: 51.501028),
            longitude: CLLocationDegrees(floatLiteral: -0.125435)),
        span: MKCoordinateSpan(
            latitudeDelta: CLLocationDegrees(floatLiteral: 0.01),
            longitudeDelta: CLLocationDegrees(floatLiteral: 0.01)))
    
    init() {
        self.positionReset = false
        self.markerPoints = []
        self.busStops = []
        self.mirroredRegion = MapViewModel.defaultLocation
        self.updateTask = Task {}
    }
    
    func startReloadTask() {
        updateTask.cancel()
        self.updateTask = Task {
            try await Task.sleep(nanoseconds: UInt64(5e8))
            if !Task.isCancelled {
                await self.reloadBusStops()
            }
        }
    }
    
    @MainActor
    private func reloadBusStops() async {
        let busStopPoints = await APIHandler.shared.busStopsInRadius(latitude: mirroredRegion.center.latitude, longitude: mirroredRegion.center.longitude, radius: 350)
        busStops = busStopPoints.map {
            StationAnnotation(
                station: $0,
                title: $0.name,
                coordinate: CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)
            )
        }
    }
    
}

struct MapView: View {
    
    @Environment(\.colorScheme) private var scheme
    
    @EnvironmentObject private var stationData: StationData
    @EnvironmentObject private var lineStatus: LineStatusDataManager
    @ObservedObject private var viewModel: MapViewModel
    @ObservedObject private var locationManager: LocationManager
    
    @State var hasLoadedPreviously: Bool = false
    @State var coordinateRegion: MKCoordinateRegion = MapViewModel.defaultLocation
    
    init(mapViewModel: MapViewModel, locationManager: LocationManager) {
        self.viewModel = mapViewModel
        self.locationManager = locationManager
    }
    
    var body: some View {
        StationDataLoadingView {
            NavigationView {
                ZStack(alignment: .center) {
                    Map(coordinateRegion: $coordinateRegion,
                        showsUserLocation: true,
                        annotationItems: checkSpan(delta: 0.05) ? viewModel.markerPoints + viewModel.busStops : []) { marker in
                        MapAnnotation(coordinate: marker.coordinate) {
                            NavigationLink {
                                JourneyBoard(station: marker.station)
                                    .environmentObject(lineStatus)
                                    .navigationBarTitleDisplayMode(.large)
                            } label: {
                                VStack {
                                    if marker.station.getMode() == .bus {
                                        let castStation = marker.station as? BusStop
                                        BusStopCircle(
                                            stopLetter: castStation!.stopIndicator,
                                            rawBearing: castStation!.bearing,
                                            circleRadius: 30
                                        )
                                    } else {
                                        Circle()
                                            .foregroundStyle(StopPointMetaData.lookupModeColour(marker.station.getMode()))
                                            .frame(width: 30, height: 30)
                                        if checkSpan(delta: 0.05) {
                                            let outlineStrokeColour: Color = scheme == .dark ? .black : .white
                                            Text(marker.station.name)
                                                .fontWeight(.bold)
                                                .foregroundStyle(scheme == .dark ? .white : .black)
                                                .shadow(color: outlineStrokeColour, radius: 1)
                                                .shadow(color: outlineStrokeColour, radius: 1)
                                                .shadow(color: outlineStrokeColour, radius: 1)
                                                .shadow(color: outlineStrokeColour, radius: 1)
                                                .shadow(color: outlineStrokeColour, radius: 1)
                                                .shadow(color: outlineStrokeColour, radius: 1)
                                                .shadow(color: outlineStrokeColour, radius: 1)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .edgesIgnoringSafeArea(.top)
                    .safeAreaInset(edge: .top, alignment: .trailing) {
                        if locationManager.isAuthorised() {
                            Button(action: setCoordinatesToCentre) {
                                Image(systemName: viewModel.positionReset ? "location.fill" : "location")
                            }
                            .background(content: {
                                RoundedRectangle(cornerRadius: 5)
                                    .foregroundStyle(scheme == .dark ? .black : .white)
                                    .frame(width: 40, height: 40)
                            })
                            .padding([.trailing], 30)
                        }
                    }
                    .onChange(of: coordinateRegion) { new in
                        if viewModel.positionReset { viewModel.positionReset = false }
                        if checkSpan(delta: 0.05) {
                            viewModel.startReloadTask()
                        }
                        viewModel.mirroredRegion = new
                    }
                    .task {
                        self.viewModel.markerPoints = stationData.mergedStations
                            .filter { stationData.lookupCoordinates(naptanId: $0.getNaptanString()) != nil }
                            .map { StationAnnotation(station: $0, title: $0.name, coordinate: stationData.lookupCoordinates(naptanId: $0.getNaptanString())!) }
                        locationManager.registerSuccessCallback {
                            self.setCoordinatesToCentre()
                        }
                        if !locationManager.isAuthorised() {
                            locationManager.requestLocationData()
                        }
                        if !hasLoadedPreviously {
                            setCoordinatesToCentre()
                            hasLoadedPreviously = true
                        }
                    }
                    MapCentreIndicator()
                }
            }
        }.environmentObject(stationData)
    }
    
    func setCoordinatesToCentre() {
        self.coordinateRegion = MKCoordinateRegion(
            center: locationManager.currentLocation ?? coordinateRegion.center,
            span: coordinateRegion.span)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.001) {
            self.viewModel.positionReset = true
        }
    }
    
    func checkSpan(delta: Double) -> Bool {
        let maxSpan = MKCoordinateSpan(
            latitudeDelta: CLLocationDegrees(floatLiteral: delta),
            longitudeDelta: CLLocationDegrees(floatLiteral: delta))
        return coordinateRegion.span.latitudeDelta < maxSpan.latitudeDelta
        && coordinateRegion.span.longitudeDelta < maxSpan.longitudeDelta
    }
    
}
//
//struct UIKitMapView: UIViewRepresentable {
//
//    @Binding private var selectedStation: (any Station)?
//    @Binding private var markers: [StationAnnotation]?
//    @Binding private var screen: String?
//
//    private let locationManager: LocationManager
//    private static let defaultLocation = MKCoordinateRegion(
//        center: CLLocationCoordinate2D(
//            latitude: CLLocationDegrees(floatLiteral: 51.501028),
//            longitude: CLLocationDegrees(floatLiteral: -0.125435)),
//        span: MKCoordinateSpan(
//            latitudeDelta: CLLocationDegrees(floatLiteral: 0.005),
//            longitudeDelta: CLLocationDegrees(floatLiteral: 0.005)))
//
//    init(markers: Binding<[StationAnnotation]?>, locationManager: LocationManager, selectedStation: Binding<(any Station)?>, screen: Binding<String?>) {
//        self._markers = markers
//        self.locationManager = locationManager
//        self._selectedStation = selectedStation
//        self._screen = screen
//    }
//
//    func makeCoordinator() -> Coordinator {
//        return Coordinator(onAnnotationTapGesture: { selectedStation = $0 })
//    }
//
//    func makeUIView(context: Context) -> MKMapView {
//        let mapView = MKMapView()
//        mapView.delegate = context.coordinator
//        mapView.showsUserLocation = true
//        mapView.region = getLocation()
//        mapView.pointOfInterestFilter = .init(excluding: [.publicTransport])
//        mapView.addAnnotations(markers ?? [])
//        return mapView
//    }
//
//    func getLocation() -> MKCoordinateRegion {
//        guard let location = locationManager.getLocation()
//        else { return UIKitMapView.defaultLocation }
//        return MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(
//            latitudeDelta: CLLocationDegrees(floatLiteral: 0.005),
//            longitudeDelta: CLLocationDegrees(floatLiteral: 0.005)))
//    }
//
//    func updateUIView(_ uiView: MKMapView, context: Context) {
//
//    }
//
//}



