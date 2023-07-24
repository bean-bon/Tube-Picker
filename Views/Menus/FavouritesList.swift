//
//  FavouritesList.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 24/07/2023.
//

import SwiftUI

struct FavouritesList: View {
    
    @EnvironmentObject private var stationData: StationData
    @State private var favourites: [FavouriteListItem] = []
    private let favouritesInterface = FavouriteStations.shared
    
    var body: some View {
        NavigationView {
            if favourites.isEmpty {
                Text("No favourites yet!\nAdd some in Map or Index.")
            } else {
                List(favourites.sorted(by: { $0.station.name < $1.station.name }), id: \.self) { item in
                    NavigationLink(item.station.name, destination: JourneyBoard(station: item.station))
                }
                .navigationTitle("Favourites")
            }
        }
        .task {
            favourites = makeStationsFromFavouriteData()
        }
    }
    
    private func makeStationsFromFavouriteData() -> [FavouriteListItem] {
        let favourites = favouritesInterface.buildFavouritesList()
        let grouped: Dictionary<String, [FavouriteStation]> = Dictionary(grouping: favourites, by: { $0.name })
        return grouped.map {
            if $0.value.count == 1 {
                let station = $0.value.first
                return FavouriteListItem(station: SingleStation(name: $0.key, mode: station!.mode, naptanID: station!.naptan))
            } else {
                return FavouriteListItem(station: CombinationNaptanStation(name: $0.key, naptanDictionary: Dictionary($0.value.map { favourite in
                    (favourite.naptan, favourite.mode)
                }, uniquingKeysWith: { old, _ in old })))
            }
        }
    }
    
}

private struct FavouriteListItem: Hashable, Equatable {
    
    let station: any Station
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(station.name)
    }
    
    static func == (lhs: FavouriteListItem, rhs: FavouriteListItem) -> Bool {
        if type(of: lhs.station) != type(of: rhs.station) {
            return false
        }
        return lhs.station.name == rhs.station.name
    }
    
}
