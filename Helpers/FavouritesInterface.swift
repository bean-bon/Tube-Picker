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
    
    func isFavourite(naptanID: String) -> Bool {
        return favourites.contains(naptanID)
    }
    
    func setFavourite(naptanID: String, value: Bool) {
        if value {
            favourites.insert(naptanID)
        } else {
            favourites.remove(naptanID)
        }
        updateCache()
    }
    
}
