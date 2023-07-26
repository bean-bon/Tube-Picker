//
//  FavouritesInterface.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 19/07/2023.
//

import Foundation

@MainActor
final class FavouritesInterface: ObservableObject {
        
    static let stations = Stations()
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
        
        func isFavourite(naptanID: String, mode: StopPointMetaData.modeName) -> Bool {
            return favourites.contains(where: { $0.contains("\(naptanID):\(mode)") })
        }
        
        func setFavourite(name: String, naptanID: String, mode: StopPointMetaData.modeName, lines: Set<String>, value: Bool) {
            if value {
                favourites.insert("\(name):\(naptanID):\(mode):\(lines.joined(separator: ","))")
            } else {
                favourites.remove("\(name):\(naptanID):\(mode):\(lines.joined(separator: ","))")
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

struct FavouriteStation {
    
    let name: String
    let lines: Set<String>
    let naptan: String
    let mode: StopPointMetaData.modeName
        
    fileprivate init?(recordString: String) {
        let split = recordString.split(separator: ":")
        guard split.count == 4,
            let mode = StopPointMetaData.modeName.init(rawValue: String(split[2])) else { return nil }
        self.name = String(split[0])
        self.naptan = String(split[1])
        self.lines = Set(String(split[3]).split(separator: ",").map(String.init))
        self.mode = mode
    }
    
}
