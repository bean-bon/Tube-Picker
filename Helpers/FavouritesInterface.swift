//
//  FavouritesInterface.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 19/07/2023.
//

import Foundation

class FavouriteStations {
    
    static let shared = FavouriteStations()
    
    private init() {
        favourites = Set()
        favourites = readFavouritesFromDisk()
    }
    
    private static let userDefaults = UserDefaults.standard

    private var favourites: Set<String>
    
    private func readFavouritesFromDisk() -> Set<String> {
        return Set(FavouriteStations.userDefaults.array(forKey: "Favourites") as? [String] ?? [])
    }
    
    private func updateCache() {
        FavouriteStations.userDefaults.setValue(Array(favourites), forKey: "Favourites")
    }
    
    func isFavourite(naptanID: String, mode: StopPointMetaData.modeName) -> Bool {
        return favourites.contains(where: { $0.contains("\(naptanID):\(mode)") })
    }
    
    func setFavourite(name: String, naptanID: String, mode: StopPointMetaData.modeName, value: Bool) {
        if value {
            favourites.insert("\(name):\(naptanID):\(mode)")
        } else {
            favourites.remove("\(name):\(naptanID):\(mode)")
        }
        updateCache()
    }
    
    func buildFavouritesList() -> [FavouriteStation] {
        return favourites.compactMap {
            let result = FavouriteStation(recordString: $0)
            if result == nil {
                FavouriteStations.userDefaults.setValue(favourites.remove($0), forKey: "Favourites")
            }
            return result
        }
    }
    
}

struct FavouriteStation {
    
    let name: String
    let naptan: String
    let mode: StopPointMetaData.modeName
        
    fileprivate init?(recordString: String) {
        let split = recordString.split(separator: ":")
        guard let mode = StopPointMetaData.modeName.init(rawValue: String(split[2])) else { return nil }
        self.name = String(split[0])
        self.naptan = String(split[1])
        self.mode = mode
    }
    
}
