//
//  ModeList.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 28/05/2023.
//

import Foundation
import SwiftUI

struct ModeListView: View {
    
    @EnvironmentObject var stationData: StationData
    @EnvironmentObject var lineData: LineStatusDataManager
    
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationView {
            StationDataLoadingView {
                VStack {
                    if searchText.isEmpty {
                        List {
                            Section("Station Groups") {
                                ForEach(stationData.stationGroupKeys().sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { mode in
                                    NavigationLink(StopPointMetaData.modeNameDescription(mode: mode), destination:
                                                    SingleStationList(stations: Set(stationData.groupedStations[mode]!.values), mode: mode)
                                    )
                                }
                            }
                            Section("Line Status") {
                                LineStatusList(linePredicate: nil)
                                    .environmentObject(lineData)
                            }
                        }
                    } else {
                        let filteredStations = stationData.allStations.filter { $0.name.localizedCaseInsensitiveContains(searchText) }.sorted()
                        let nameGrouped = Dictionary(grouping: filteredStations, by: { $0.name })
                        let stations: [StationListItemWrapper] = nameGrouped.map {
                            if $0.value.count == 1 {
                                return StationListItemWrapper(station: $0.value.first!)
                            } else {
                                return StationListItemWrapper(station: CombinationNaptanStation(name: $0.key, singleStations: $0.value))
                            }
                        }
                        List(stations, id: \.self) { item in
                            NavigationLink(item.station.name, destination: JourneyBoard(station: item.station))
                        }
                    }
                }
                .navigationTitle("Transport Index")
                .searchable(text: $searchText, prompt: "Search Stations")
                .autocorrectionDisabled()
            }
            .environmentObject(stationData)
        }
    }
}
