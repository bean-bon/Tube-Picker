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
    @State var isRefreshOccurring: Bool = false
    @State private var searchText: String = ""
    
    @ViewBuilder var body: some View {
        NavigationView {
            switch stationData.getLoadingState() {
            case .success:
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
                        let filteredStations = stationData.allStations.filter { $0.name.contains(searchText) }.sorted()
                        let nameGrouped = Dictionary(grouping: filteredStations, by: { $0.name })
                        let stations: [StationListItemWrapper] = nameGrouped.map {
                            if $0.value.count == 1 {
                                let station = $0.value.first
                                return StationListItemWrapper(station: SingleStation(name: $0.key, lines: station!.lines, mode: station!.mode, naptanID: station!.naptanID))
                            } else {
                                return StationListItemWrapper(station: CombinationNaptanStation(name: $0.key, lines: Set($0.value.map { $0.lines }.joined()), naptanDictionary: Dictionary($0.value.map { station in
                                    (station.naptanID, station.mode)
                                }, uniquingKeysWith: { old, _ in old })))
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
            case .downloading:
                ProgressView("Downloading station data")
                    .progressViewStyle(CircularProgressViewStyle())
                    .navigationTitle("")
            case .failure:
                VStack {
                    Text("Unable to download required data.\n")
                        .bold() +
                    Text("Please check your Wi-Fi or cellular connection then retry.")
                    Button {
                        isRefreshOccurring = true
                        Task {
                            await stationData.loadData()
                            isRefreshOccurring = false
                        }
                    } label: {
                        Text("Retry")
                    }
                    .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                    .foregroundColor(Color.white)
                    .background(Color.blue)
                    .cornerRadius(5)
                    .disabled(isRefreshOccurring)
                }
            default:
                VStack {
                    Text("Tube Picker")
                        .fontWeight(.bold)
                }
            }
        }
    }
}
