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
    @State private var favouriteStations: [StationListItemWrapper] = []
    @State private var favouriteBusStops: [StationListItemWrapper] = []
    @State private var favouriteLines: Set<String> = .init()
    
    static let iconWidth = 30.0
    
    var body: some View {
        NavigationView {
            if favouriteStations.isEmpty && favouriteLines.isEmpty && favouriteBusStops.isEmpty {
                Text("No favourites yet!\nAdd some in Map or Index.")
            } else {
                let metroModeStations = favouriteStations.filter { StopPointMetaData.stationModesNames.contains($0.station.getMode()) }
                List {
                    if !lineStatusData.favourites.favouriteLines.isEmpty {
                        Section("Line Status") {
                            LineStatusList(linePredicate: { lineStatusData.favourites.isFavourite(lineId: $0.id) })
                                .environmentObject(lineStatusData)
                        }
                    }
                    if !favouriteBusStops.isEmpty {
                        Section("Bus Stops") {
                            ForEach(favouriteBusStops.sorted(by: { $0.station.name < $1.station.name }), id: \.self) { item in
                                let busStop = item.station as! BusStop
                                HStack {
                                    BusStopCircle(stopLetter: busStop.stopIndicator, rawBearing: nil, circleRadius: FavouritesList.iconWidth)
                                    NavigationLink(destination: JourneyBoard(station: item.station), label: {
                                        VStack(alignment: .leading) {
                                            Text(item.station.name)
                                                .lineLimit(1)
                                            if !busStop.towards.isEmpty {
                                                Text("towards \(busStop.towards)")
                                                    .font(.caption)
                                                    .lineLimit(1)
                                            }
                                        }
                                    })
                                }
                            }
                        }
                    }
                    if !metroModeStations.isEmpty {
                        Section("Stations") {
                            let roundelAspectRatio = 1.2307
                            ForEach(metroModeStations.sorted(by: { $0.station.name < $1.station.name }), id: \.self) { item in
                                HStack {
                                    ImageLoader.getRoundel(mode: item.station.getMode())
                                        .resizable()
                                        .frame(width: FavouritesList.iconWidth, height: FavouritesList.iconWidth / roundelAspectRatio)
                                    NavigationLink(item.station.name, destination: JourneyBoard(station: item.station))
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Favourites")
            }
        }
        .task {
            favouriteStations = makeStationsFromFavouriteData()
            favouriteLines = lineStatusData.favourites.favouriteLines
            favouriteBusStops = FavouritesInterface.buses.favouriteStops.compactMap(BusStop.init).map { StationListItemWrapper(station: $0) }
        }
        .refreshable {
            favouriteStations = makeStationsFromFavouriteData()
            favouriteLines = lineStatusData.favourites.favouriteLines
            favouriteBusStops = FavouritesInterface.buses.favouriteStops.compactMap(BusStop.init).map { StationListItemWrapper(station: $0) }
        }
    }
    
    private func makeStationsFromFavouriteData() -> [StationListItemWrapper] {
        let favourites = FavouritesInterface.stations.buildFavouritesList()
        let grouped: Dictionary<String, [FavouriteStation]> = Dictionary(grouping: favourites, by: { $0.name })
        return grouped.map {
            let mergedDictionary = $0.value.map { station in station.naptanDictionary }.reduce(Dictionary<String, StopPointMetaData.modeName>()) { fav, combined in
                fav.merging(combined, uniquingKeysWith: { _, new in new })
            }
            if $0.value.count == 1 && Set(mergedDictionary.keys).count == 1 {
                let station = $0.value.first
                return StationListItemWrapper(station: SingleStation(name: $0.key, lines: station!.lines, mode: station!.naptanDictionary.values.first!, naptanID: station!.naptanDictionary.keys.first!, lat: station!.lat, lon: station!.lon))
            } else {
                let mergedDictionary = $0.value.map { station in station.naptanDictionary }.reduce(Dictionary<String, StopPointMetaData.modeName>()) { fav, combined in
                    fav.merging(combined, uniquingKeysWith: { _, new in new })
                }
                return StationListItemWrapper(station: CombinationNaptanStation(name: $0.key, lines: Set($0.value.map { $0.lines }.joined()), naptanDictionary: mergedDictionary, lats: $0.value.map { $0.lat }, lons: $0.value.map { $0.lon }))
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
