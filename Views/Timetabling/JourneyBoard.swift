//
//  JourneyBoard.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 15/09/2022.
//

import SwiftUI

struct JourneyBoard: View {
        
    let station: any Station
    
    @EnvironmentObject var lineData: LineStatusDataManager
    
    static let defaultLineFilter: String = "All Lines"
    static let defaultDestinationFilter: String = "Any Destination"
    
    @State private var stationIsFavourite: Bool? = nil
    @State private var showFilterSheet: Bool = false
    
    @State private var selectedLine: String = defaultLineFilter
    @State private var selectedDestination: String = defaultDestinationFilter
    
    @State private var destinations: [String] = []
    
    @State private var arrivals: [any PredictedArrival] = []
    @State private var filteredArrivals: [any PredictedArrival] = []
    
    @State private var timetabledArrivals: [any TimetabledArrival] = []
    @State private var filteredTimetabling: [any TimetabledArrival] = []
        
    @State private var loadingPredictions: Bool = false
    @State private var loadingTimetable: Bool = false
    
    var body: some View {
        VStack {
            VStack {
                let listArrivals = filteredArrivals.filter { $0.isArrivalTimeValid() && $0.getReadableDestinationName().contains(station.name) != true }
                let listTimetabling = filteredTimetabling.filter { $0.isArrivalTimeValid() && $0.getReadableDestinationName().contains(station.name) != true }
                VStack {
                    List {
                        if !station.lines.intersection(lineData.abnormalStatusLines()).isEmpty {
                            Section(header: Text("Line Status")) {
                                LineStatusList(linePredicate: { station.lines.contains($0.id) }, onlyShowAbnormalStatus: true, showFavouriteButtons: false)
                            }
                        }
                        Section(header: Text("Live Departures")) {
                            if !listArrivals.isEmpty {
                                let sliceSize = listArrivals.count > 10 ? 10 : listArrivals.count
                                ForEach(listArrivals.sorted(by: { $0.getTimeToStationInSeconds()! < $1.getTimeToStationInSeconds()! })[..<sliceSize], id: \.hashValue) { departure in
                                    ArrivalView(arrival: departure)
                                }
                            } else {
                                Text(loadingPredictions
                                     ? "Loading live departures..."
                                     : "No live departures found")
                                .font(.subheadline)
                            }
                        }
                        if station.needsTimetabling(arrivals: arrivals) {
                            Section(header: Text("Timetable")) {
                                if !listTimetabling.isEmpty {
                                    let sliceSize = listTimetabling.count > 10 ? 10 : listTimetabling.count
                                    ForEach(listTimetabling.sorted(by: { $0.getTimeToStationInSeconds()! < $1.getTimeToStationInSeconds()! })[..<sliceSize], id: \.hashValue) { arrival in
                                        ArrivalView(arrival: arrival)
                                    }
                                } else {
                                    Text(loadingTimetable || loadingPredictions // Timetable data loads after predictions.
                                         ? "Loading timetable..."
                                         : "No timetabling found")
                                    .font(.subheadline)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(station.getReadableName())
            .task {
                stationIsFavourite = station.isFavourite()
                await loadJourneyBoardData()
            }
            .refreshable {
                await loadJourneyBoardData()
            }
            .toolbar {
                ToolbarItemGroup {
                    if stationIsFavourite != nil {
                        Button(action: {
                            stationIsFavourite!.toggle()
                            station.setFavourite(value: stationIsFavourite!)
                        }) {
                            Image(systemName: stationIsFavourite! ? "star.fill" : "star")
                        }.accessibilityHint(stationIsFavourite! ? "Remove \(station.name) from favourites." : "Add \(station.name) to favourites.")
                    }
                    Button(action: { showFilterSheet = true }) {
                        Image(systemName: "ellipsis.circle")
                    }.accessibilityHint("Station Filters")
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                let linePickerOptions: [String] = [JourneyBoard.defaultLineFilter] + station.lines.sorted()
                let destinationPickerOptions: [String] = [JourneyBoard.defaultDestinationFilter] + destinations.sorted()
                VStack {
                    Text("Filters")
                        .font(.headline)
                        .padding(EdgeInsets(top: 20, leading: 0, bottom: 10, trailing: 0))
                        .frame(alignment: .center)
                    List {
                        Picker("Destination", selection: $selectedDestination) {
                            ForEach(destinationPickerOptions, id: \.self) { destination in
                                Text(destination)
                            }
                        }.onChange(of: selectedDestination) { _ in
                            updateFilteredArrivals()
                            updateFilteredTimetabling()
                        }
                        Picker ("Line", selection: $selectedLine) {
                            ForEach(linePickerOptions.sorted(), id: \.self) { line in
                                let lookup = Line.lookupName(lineID: line)
                                Text(lookup.isEmpty ? line : lookup)
                            }
                        }.onChange(of: selectedLine) { _ in
                            selectedDestination = JourneyBoard.defaultDestinationFilter
                            updateFilteredArrivals()
                            updateFilteredTimetabling()
                            updateDestinations()
                        }
                    }
                    Text("Naptan: \((station as? SingleStation)?.naptanID ?? "n/a")")
                    Button(action: { showFilterSheet = false }) {
                        Text("Apply Filters")
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(15)
                }
                // Black magic from https://stackoverflow.com/questions/72160368/how-to-disable-refreshable-in-nested-view-which-is-presented-as-sheet-fullscreen
                // to disable refreshable on the sheet.
                .environment(\EnvironmentValues.refresh as! WritableKeyPath<EnvironmentValues, RefreshAction?>, nil)
            }
        }
    }
    
    private func loadJourneyBoardData() async {
        loadingPredictions = true
        arrivals = await station.pullArrivals().uniquing(with: { [$0.lineId, $0.getReadableDestinationName(), $0.getTimeDisplay()] })
        updateFilteredArrivals()
        updateDestinations()
        loadingPredictions = false
        loadingTimetable = true
        timetabledArrivals = await station.pullTimetabling(arrivals: filteredArrivals)
        loadingTimetable = false
        updateFilteredTimetabling()
        updateDestinations()
    }
    
    private func updateFilteredArrivals() {
        let predicateObject = FilterPredicates(destinationSelection: selectedDestination, lineSelection: selectedLine)
        filteredArrivals = arrivals.filter(predicateObject.arrivalFilter)
    }
    
    private func updateFilteredTimetabling() {
        let predicateObject = FilterPredicates(destinationSelection: selectedDestination, lineSelection: selectedLine)
        filteredTimetabling = timetabledArrivals.filter(predicateObject.arrivalFilter)
    }
    
    private func updateDestinations() {
        destinations = (filteredArrivals + filteredTimetabling).compactMap {
            BlacklistedStationTermStripper.removeBlacklistedTerms(input: $0.getReadableDestinationName().capitalized)
        }.unique()
        destinations.removeAll(where: { station.name.contains($0.capitalized) })
    }
    
}

struct FilterPredicates {
    
    let destinationSelection: String
    let lineSelection: String
    
    func arrivalFilter(prediction: any GenericArrival) -> Bool {
        return lineCheck(lineName: prediction.lineId)
        && (defaultDestinationOrMatchesName(destinationName: prediction.getReadableDestinationName())
            || nilDestinationException(destinationName: prediction.getReadableDestinationName()))
    }
    
    private func nilDestinationException(destinationName: String) -> Bool {
        return destinationName == "" && destinationSelection == BlacklistedStationTermStripper.noStationFound
    }
    
    private func defaultDestinationOrMatchesName(destinationName: String?) -> Bool {
        return destinationSelection == JourneyBoard.defaultDestinationFilter ||
            destinationName?.localizedCaseInsensitiveContains(destinationSelection) == true
    }
    
    private func lineCheck(lineName: String?) -> Bool {
        return lineSelection == JourneyBoard.defaultLineFilter || lineName == lineSelection
    }
        
}
