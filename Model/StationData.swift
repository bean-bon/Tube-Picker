//
//  StationGroup.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 11/09/2022.
//

import Foundation
import SwiftUI

/**
 Initialise the station data based on which stations currently have departures.
 This seems flaky as it wouldn't show stations with no departures, but it's not a huge issue at
 the moment.
 */
final class StationData: ObservableObject {
    
    private let apiHandler = APIHandler()
    private var allStationCache: Set<Station> = Set()
    @Published var stationGroups: [Line: Set<Station>] = Dictionary()
    
    func loadData() async {
        for line in LineIDs {
            let arrivals = await apiHandler.lineArrivals(line: line.key)
            DispatchQueue.main.async {
                self.parseLineArrivals(data: arrivals)
            }
        }
    }
    
    func allStations() -> Set<Station> {
        if stationGroups.isEmpty && allStationCache.isEmpty {
            return Set()
        }
        if allStationCache.isEmpty {
            for group in stationGroups {
                allStationCache = allStationCache.union(group.value)
            }
        }
        return allStationCache
    }
    
    func needsLoad() -> Bool {
        return stationGroups.isEmpty
    }
    
    func lookupMode(stationName: String) -> Line.Mode {
        for stations in stationGroups.values {
            let searchResult = stations.first(where: { $0.name == stationName })
            if searchResult != nil { return searchResult!.mode }
        }
        return Line.Mode.tube
    }
    
    private func parseLineArrivals(data: [LineArrival]) {
        if data.isEmpty { return }
        var stations = Set<Station>()
        for arrival in data {
            // Exception for london-overground since this isn't a valid variable name.
            if arrival.lineId == "london-overground" {
                stations.insert(Station(name: arrival.stationName, mode: Line.Mode.overground))
            } else {
                stations.insert(Station(name: arrival.stationName, mode: Line.Mode.init(rawValue: arrival.lineId) ?? Line.Mode.tube))
            }
        }
        stationGroups.updateValue(stations, forKey: LineIDs[data[0].lineId] ?? LineIDs.first!.value)
    }
    
}
