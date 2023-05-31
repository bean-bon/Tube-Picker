//
//  DepartureBoard.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 15/09/2022.
//

import SwiftUI

struct DepartureBoard: View {
    
    let api = APIHandler()
    
    var station: Station
    
    private static let defaultLineFilter: String = "All Lines"
    private static let defaultDestinationFilter: String = "Any Destination"
    private static let noStationFound: String = "Check Station Board"
    
    @State private var selectedLine: String = defaultLineFilter
    @State private var selectedDestination: String = defaultDestinationFilter
    
    @State private var lines: [String] = []
    @State private var destinations: [String] = []
    
    @State private var departures: [Departure] = []
    @State private var filteredDepartures: [Departure] = []
    
    var body: some View {
        VStack {
            if departures.isEmpty {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                if filteredDepartures.isEmpty {
                    Text("No Departures Found")
                } else {
                    List(filteredDepartures.sorted(), id: \.self) { departure in
                        departure
                            .padding(.top, 4)
                            .padding(.bottom, 4)
                    }
                }
            }
        }
        .navigationTitle(station.getReadableName())
        .refreshable {
            await reload()
        }
        .task {
            await reload()
        }
        .toolbar {
            let linePickerOptions: [String] = [DepartureBoard.defaultLineFilter] + lines.sorted()
            let destinationPickerOptions: [String] = [DepartureBoard.defaultDestinationFilter] + destinations.sorted()
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if linePickerOptions.count > 2 {
                    Picker ("Lines", selection: $selectedLine) {
                        ForEach(linePickerOptions.sorted(), id: \.self) { line in
                            Text(line)
                        }
                    }.onChange(of: selectedLine) { _ in
                        selectedDestination = DepartureBoard.defaultDestinationFilter
                        updateFilteredArrivals()
                        updateDestinations()
                    }
                }
                Picker("Destination", selection: $selectedDestination) {
                    ForEach(destinationPickerOptions, id: \.self) { destination in
                        Text(destination)
                    }
                }.onChange(of: selectedDestination) { _ in updateFilteredArrivals() }
            }
        }
    }
    
    func reload() async {
        if station.naptanID == nil {
            await reloadWithGlobalDepartureLookup()
        } else {
            await reloadWithNaptanID()
        }
    }
    
    private func reloadWithGlobalDepartureLookup() async {
        let data = await api.predictedArrivals(mode: station.mode, count: 10)
        departures = data.filter {
            station.name == $0.stationName && $0.timeToStation < 3600
        }
        .map {
            Departure(predictedArrival: $0)
        }
        lines = departures.map { $0.predictedArrival.lineName }.unique()
        updateFilteredArrivals()
        updateDestinations()
    }
    
    private func reloadWithNaptanID() async {
        let data = await api.naptanStationArrivals(naptanID: station.naptanID ?? "")
        let intermediateDepartures = data.filter {
            $0.timeToStation < 3600
        }.map {
            Departure(predictedArrival: $0)
        }
        let sliceSize = intermediateDepartures.count > 10 ? 10 : intermediateDepartures.count
        departures = Array(intermediateDepartures[..<sliceSize])
        updateFilteredArrivals()
        updateDestinations()
    }
    
    private func updateFilteredArrivals() {
        filteredDepartures = departures.filter {
            (selectedLine == DepartureBoard.defaultLineFilter || $0.predictedArrival.lineName == selectedLine)
            && (selectedDestination == DepartureBoard.defaultDestinationFilter ||
                $0.predictedArrival.destinationName?.contains(selectedDestination) == true ||
                ($0.predictedArrival.destinationName == nil && selectedDestination == DepartureBoard.noStationFound))
        }
    }
    
    private func updateDestinations() {
        destinations = filteredDepartures.compactMap {
            BlacklistedStationTermStripper.removeBlacklistedTerms(input: $0.predictedArrival.destinationName ?? DepartureBoard.noStationFound)
        }.unique()
    }
    
}

struct DepartureBoard_Previews: PreviewProvider {
    static var previews: some View {
        DepartureBoard(station: Station.default)
    }
}
