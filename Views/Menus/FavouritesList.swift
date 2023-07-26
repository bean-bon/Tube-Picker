//
//  FavouritesList.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 24/07/2023.
//

import SwiftUI

struct FavouritesList: View {
    
    @EnvironmentObject private var stationData: StationData
    @EnvironmentObject private var lineStatusData: LineStatusDataManager
    @State private var favourites: [StationListItemWrapper] = []
    
    var body: some View {
        NavigationView {
            if favourites.isEmpty && lineStatusData.favourites.favouriteLines.isEmpty {
                Text("No favourites yet!\nAdd some in Map or Index.")
            } else {
                let metroModeStations = favourites.filter { StopPointMetaData.stationModesNames.contains($0.station.getMode()) }
                let busStops = favourites.filter { $0.station.getMode() == .bus }
                List {
                    if !lineStatusData.favourites.favouriteLines.isEmpty {
                        Section("Line Status") {
                            LineStatusList(linePredicate: { lineStatusData.favourites.isFavourite(lineId: $0.id) })
                                .environmentObject(lineStatusData)
                        }
                    }
                    if !busStops.isEmpty {
                        Section("Bus Stops") {
                            ForEach(busStops.sorted(by: { $0.station.name < $1.station.name }), id: \.self) { item in
                                NavigationLink(item.station.name, destination: JourneyBoard(station: item.station))
                            }
                        }
                    }
                    if !metroModeStations.isEmpty {
                        Section("Stations") {
                            ForEach(metroModeStations.sorted(by: { $0.station.name < $1.station.name }), id: \.self) { item in
                                NavigationLink(item.station.name, destination: JourneyBoard(station: item.station))
                            }
                        }
                    }
                }
                .navigationTitle("Favourites")
            }
        }
        .task {
            favourites = makeStationsFromFavouriteData()
        }
    }
    
    private func makeStationsFromFavouriteData() -> [StationListItemWrapper] {
        let favourites = FavouritesInterface.stations.buildFavouritesList()
        let grouped: Dictionary<String, [FavouriteStation]> = Dictionary(grouping: favourites, by: { $0.name })
        return grouped.map {
            if $0.value.count == 1 {
                let station = $0.value.first
                return StationListItemWrapper(station: SingleStation(name: $0.key, lines: station!.lines, mode: station!.mode, naptanID: station!.naptan))
            } else {
                return StationListItemWrapper(station: CombinationNaptanStation(name: $0.key, lines: Set($0.value.map { $0.lines }.joined()), naptanDictionary: Dictionary($0.value.map { favourite in
                    (favourite.naptan, favourite.mode)
                }, uniquingKeysWith: { old, _ in old })))
            }
        }
    }
    
}

struct StationListItemWrapper: Hashable, Equatable {
    
    let station: any Station
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(station.name)
    }
    
    static func == (lhs: StationListItemWrapper, rhs: StationListItemWrapper) -> Bool {
        if type(of: lhs.station) != type(of: rhs.station) {
            return false
        }
        return lhs.station.name == rhs.station.name
    }
    
}
