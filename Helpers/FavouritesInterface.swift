//
//  FavouritesInterface.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 19/07/2023.
//

import Foundation
import MapKit

@MainActor
final class FavouritesInterface: ObservableObject {
        
    static let stations = Stations()
    static let buses = Buses()
    static let lines = Lines()
        
    private init() {}
    
    class Stations: ObservableObject {
        
        fileprivate init() {
            favourites = Set()
            favourites = readFavouritesFromDisk()
        }
        
        private let defaultsKey = "FavouriteStations"
        private var favourites: Set<String>
        
        private func readFavouritesFromDisk() -> Set<String> {
            return Set(UserDefaults.standard.array(forKey: defaultsKey) as? [String] ?? [])
        }
        
        private func updateCache() {
            UserDefaults.standard.setValue(Array(favourites), forKey: defaultsKey)
        }
        
        func isFavourite(naptanDictionary: [String: StopPointMetaData.modeName]) -> Bool {
            let naptanModeArray = naptanDictionary.sorted(by: { $0.key < $1.key }).map { "\($0.key),\($0.value)" }
            return favourites.contains(where: { entry in naptanModeArray.allSatisfy { tuple in
                entry.contains(tuple)
            } })
        }
        
        func setFavourite(name: String, naptanDictionary: [String: StopPointMetaData.modeName], lines: Set<String>, coordinates: CLLocationCoordinate2D, value: Bool) {
            let lookupString = makeRecordString(name: name, naptanDictionary: naptanDictionary, lines: lines, coordinates: coordinates)
            let partialLookup = favourites.first(where: { $0.contains(name) })
            if value {
                if partialLookup == nil {
                    favourites.insert(lookupString)
                } else {
                    let newFavouriteEntry = FavouriteStation(recordString: partialLookup!)! + FavouriteStation(name: name, lines: lines, naptanDictionary: naptanDictionary, lat: coordinates.latitude, lon: coordinates.longitude)
                    favourites.remove(partialLookup!)
                    favourites.insert(String(describing: newFavouriteEntry))
                }
            } else {
                if partialLookup == nil {
                    favourites.remove(lookupString)
                } else {
                    let newFavouriteEntry = FavouriteStation(recordString: partialLookup!)! - FavouriteStation(name: name, lines: lines, naptanDictionary: naptanDictionary, lat: coordinates.latitude, lon: coordinates.longitude)
                    favourites.remove(partialLookup!)
                    favourites.insert(String(describing: newFavouriteEntry))
                }
            }
            updateCache()
        }
                
        func buildFavouritesList() -> [FavouriteStation] {
            return favourites.compactMap {
                let result = FavouriteStation(recordString: $0)
                if result == nil {
                    UserDefaults.standard.setValue(favourites.remove($0), forKey: defaultsKey)
                }
                return result
            }
        }
        
        private func makeRecordString(name: String, naptanDictionary: [String: StopPointMetaData.modeName], lines: Set<String>, coordinates: CLLocationCoordinate2D) -> String {
            return "\(name):\(naptanDictionary.sorted(by: { $0.key < $1.key }).map { "\($0.key),\($0.value)" }.joined(separator: "-")):\(lines.joined(separator: ",")):\(coordinates.latitude):\(coordinates.longitude)"
        }
        
    }
    
    class Buses: ObservableObject {
        
        @Published var favouriteStops: Set<String> = .init()
        private let defaultsKey = "FavouriteBusStops"
        
        fileprivate init() {
            favouriteStops = readStopsFromDisk()
        }
        
        private func readStopsFromDisk() -> Set<String> {
            return Set(UserDefaults.standard.array(forKey: defaultsKey) as? [String] ?? [])
        }
        
        private func updateCache() {
            UserDefaults.standard.setValue(Array(favouriteStops), forKey: defaultsKey)
        }
        
        func isFavourite(stop: BusStop) -> Bool {
            return favouriteStops.contains(where: { $0.contains("\(stop.lat):\(stop.lon)") })
        }
        
        func setFavourite(stop: BusStop, value: Bool) {
            if value {
                favouriteStops.insert(String(describing: stop))
            } else {
                favouriteStops.remove(favouriteStops.first(where: { $0.contains("\(stop.lat):\(stop.lon)")}) ?? "")
            }
            updateCache()
        }
        
    }
    
    class Lines: ObservableObject {
        
        @Published var favouriteLines: Set<String> = .init()
        private let defaultsKey = "FavouriteLines"

        fileprivate init() {
            favouriteLines = readFavouritesFromDisk()
        }
        
        private func readFavouritesFromDisk() -> Set<String> {
            return Set(UserDefaults.standard.array(forKey: defaultsKey) as? [String] ?? [])
        }
        
        private func updateCache() {
            UserDefaults.standard.setValue(Array(favouriteLines), forKey: defaultsKey)
        }
        
        func isFavourite(lineId: String) -> Bool {
            return favouriteLines.contains(lineId)
        }
        
        func setFavourite(lineId: String, value: Bool) {
            if value {
                favouriteLines.insert(lineId)
            } else {
                favouriteLines.remove(lineId)
            }
            updateCache()
        }
        
    }
    
}

struct FavouriteStation: CustomStringConvertible {
    
    let name: String
    let lines: Set<String>
    let naptanDictionary: [String: StopPointMetaData.modeName]
    let lat: CLLocationDegrees
    let lon: CLLocationDegrees
    
    var description: String {
        return "\(name):\(naptanDictionary.sorted(by: { $0.key < $1.key }).map { "\($0.key),\($0.value)" }.joined(separator: "-")):\(lines.joined(separator: ",")):\(lat):\(lon)"
    }
        
    init(name: String, lines: Set<String>, naptanDictionary: [String: StopPointMetaData.modeName],
                 lat: CLLocationDegrees, lon: CLLocationDegrees) {
        self.name = name
        self.lines = lines
        self.naptanDictionary = naptanDictionary
        self.lat = lat
        self.lon = lon
    }
    
    fileprivate init?(recordString: String) {
        let split = recordString.split(separator: ":")
        guard split.count == 5 else { return nil }
        self.name = String(split[0])
        self.naptanDictionary = Dictionary(
            String(split[1]).split(separator: "-").compactMap { tuple in
                let naptan = tuple.split(separator: ",")[0]
                let mode = StopPointMetaData.modeName.init(rawValue: String(tuple.split(separator: ",")[1]))
                return (String(naptan), mode ?? .unknown)
            },
            uniquingKeysWith: { _, new in new })
        self.lines = Set(String(split[2]).split(separator: ",").map(String.init))
        guard let rawLat: Double = Double(String(split[3])),
              let rawLon: Double = Double(String(split[4]))
        else { return nil }
        self.lat = CLLocationDegrees(floatLiteral: rawLat)
        self.lon = CLLocationDegrees(floatLiteral: rawLon)
    }
    
    static func +(lhs: FavouriteStation, rhs: FavouriteStation) -> FavouriteStation {
        return FavouriteStation(
            name: lhs.name,
            lines: lhs.lines.union(rhs.lines),
            naptanDictionary: lhs.naptanDictionary.merging(rhs.naptanDictionary, uniquingKeysWith: { _, new in new }),
            lat: CLLocationDegrees(floatLiteral: (lhs.lat + rhs.lat) / 2.0),
            lon: CLLocationDegrees(floatLiteral: (lhs.lon + rhs.lon) / 2.0))
    }
    
    static func -(lhs: FavouriteStation, rhs: FavouriteStation) -> FavouriteStation {
        return FavouriteStation(
            name: lhs.name,
            lines: lhs.lines.subtracting(rhs.lines),
            naptanDictionary: lhs.naptanDictionary.filter { !rhs.naptanDictionary.keys.contains($0.key) },
            lat: CLLocationDegrees(floatLiteral: 2 * lhs.lat - rhs.lat),
            lon: CLLocationDegrees(floatLiteral: 2 * lhs.lon - rhs.lon))
    }
    
}
