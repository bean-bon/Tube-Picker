//
//  JourneyBoard.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 15/09/2022.
//

import SwiftUI

struct JourneyBoard: View {
    
    let api = APIHandler()
    
    var station: Station
    
    static let defaultLineFilter: String = "All Lines"
    static let defaultDestinationFilter: String = "Any Destination"
    
    @State private var selectedLine: String = defaultLineFilter
    @State private var selectedDestination: String = defaultDestinationFilter
    
    @State private var lines: Set<String> = Set()
    @State private var destinations: [String] = []
    
    @State private var arrivals: [any PredictedArrival] = []
    @State private var filteredArrivals: [any PredictedArrival] = []
    
    @State private var timetabledArrivals: [any TimetabledArrival] = []
    @State private var filteredTimetabling: [any TimetabledArrival] = []
    
    @State private var loadingPredictions: Bool = false
    @State private var loadingTimetable: Bool = false
    
    var body: some View {
        VStack {
            let listArrivals = filteredArrivals.filter { $0.isArrivalTimeValid() && $0.getReadableDestinationName().contains(station.name) != true }
            VStack {
                List {
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
                    Section(header: Text("Timetable")) {
                        if !filteredTimetabling.isEmpty {
                            let sliceSize = filteredTimetabling.count > 10 ? 10 : filteredTimetabling.count
                            ForEach(filteredTimetabling.sorted(by: { $0.getTimeToStationInSeconds()! < $1.getTimeToStationInSeconds()! })[..<sliceSize], id: \.hashValue) { arrival in
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
        .navigationTitle(station.getReadableName())
        .refreshable {
            await loadJourneyBoardData()
        }
        .task {
            await loadJourneyBoardData()
        }
        .toolbar {
            let linePickerOptions: [String] = [JourneyBoard.defaultLineFilter] + lines.sorted()
            let destinationPickerOptions: [String] = [JourneyBoard.defaultDestinationFilter] + destinations.sorted()
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if linePickerOptions.count > 2 {
                    Picker ("Lines", selection: $selectedLine) {
                        ForEach(linePickerOptions.sorted(), id: \.self) { line in
                            Text(line)
                        }
                    }.onChange(of: selectedLine) { _ in
                        selectedDestination = JourneyBoard.defaultDestinationFilter
                        updateFilteredArrivals()
                        updateDestinations()
                    }
                }
                if destinationPickerOptions.count > 2 {
                    Picker("Destination", selection: $selectedDestination) {
                        ForEach(destinationPickerOptions, id: \.self) { destination in
                            Text(destination)
                        }
                    }.onChange(of: selectedDestination) { _ in updateFilteredArrivals() }
                }
            }
        }
    }
    
    private func loadJourneyBoardData() async {
        loadingPredictions = true
        await reloadPredicted()
        loadingPredictions = false
        loadingTimetable = true
        await updateUITimetableData()
        loadingTimetable = false
    }

    private func reloadPredicted() async {
        if station.naptanID == nil {
            await reloadWithGlobalDepartureLookup()
        } else {
            await reloadWithNaptanID()
        }
    }
    
    private func reloadWithGlobalDepartureLookup() async {
        let data = await api.predictedArrivals(mode: station.mode, count: 10)
        arrivals = data.filter {
            station.name == $0.stationName
        }
        lines = Set(arrivals.compactMap { $0.lineName })
        updateFilteredArrivals()
        updateDestinations()
    }
    
    private func reloadWithNaptanID() async {
        if [StopPointMetaData.modeName.tube, StopPointMetaData.modeName.dlr].contains(station.mode) {
            await reloadNaptanForTubeDLR()
        } else {
            await reloadNaptanForOvergroundElizabeth()
        }
        updateFilteredArrivals()
        updateDestinations()
    }
    
    private func reloadNaptanForTubeDLR() async {
        let predictionData = await api.naptanTubeArrivals(naptanID: station.naptanID ?? "")
        let arrivalPredictions = predictionData.filter {
            $0.timeToStation < 3600
        }
        lines = Set(arrivals.compactMap { $0.lineName })
        arrivals = Array(Set(arrivalPredictions))
    }
    
    private func reloadNaptanForOvergroundElizabeth() async {
        let predictionData = await api.naptanArrivalDepartures(naptanID: station.naptanID ?? "", mode: station.mode)
        let arrivalPredictions = predictionData.filter {
            let arrivalTime = $0.getTimeToStationInSeconds()
            return arrivalTime != nil && arrivalTime! < 3600
        }
        lines = Set(arrivals.compactMap { $0.lineName })
        arrivals = Array(Set(arrivalPredictions))
    }
    
    private func getTflTimetabling(lines: Set<String>) async -> [TflTimetabledArrival] {
        var timetableInfo = [TflTimetabledArrival]()
        for line in lines {
            guard let response: TwoWayTimetableResponse = await api.tubeDlrTimetables(lineName: line, fromNaptan: station.naptanID ?? "")
            else { continue }
            let timetabledArrivals = (response.inbound?.getTimetabledArrivals(originStation: station.name, lineName: line) ?? [])
            + (response.outbound?.getTimetabledArrivals(originStation: station.name, lineName: line) ?? [])
            timetableInfo.append(contentsOf: timetabledArrivals.filter { $0.isArrivalTimeValid() })
        }
        return timetableInfo
    }
        
    private func updateUITimetableData() async {
        if [StopPointMetaData.modeName.elizabeth, StopPointMetaData.modeName.overground].contains(station.mode) {
            let timetableData = Set(await api.overgroundElizabethTimetabling(lineName: station.mode.rawValue, searchTerm: station.name))
            timetabledArrivals = Array(timetableData.filter { $0.isTimeUntilThisLessThan(seconds: 3600) })
        } else {
            let linesWithTerminatingTrains: Set<String> = Set(arrivals.compactMap {
                $0.lineName
            })
            let timetableData = Set(await getTflTimetabling(lines: linesWithTerminatingTrains))
            timetabledArrivals = Array(timetableData.filter { $0.isTimeUntilThisLessThan(seconds: 3600) })
        }
        updateFilteredArrivals()
        updateDestinations()
    }
    
    private func updateFilteredArrivals() {
        let predicateObject = FilterPredicates(destinationSelection: selectedDestination, lineSelection: selectedLine)
        filteredArrivals = arrivals.filter(predicateObject.arrivalFilter)
        filteredTimetabling = timetabledArrivals.filter(predicateObject.arrivalFilter)
    }
    
    private func updateDestinations() {
        destinations = filteredArrivals.compactMap {
            BlacklistedStationTermStripper.removeBlacklistedTerms(input: $0.getReadableDestinationName())
        }.unique()
        destinations.removeAll(where: { station.name.contains($0) })
    }
    
}

struct DepartureBoard_Previews: PreviewProvider {
    static var previews: some View {
        JourneyBoard(station: Station.default)
    }
}

struct FilterPredicates {
    
    let destinationSelection: String
    let lineSelection: String
    
    func arrivalFilter(prediction: any GenericArrival) -> Bool {
        return lineCheck(lineName: prediction.lineName)
        && (defaultDestinationOrMatchesName(destinationName: prediction.getReadableDestinationName())
            || nilDestinationException(destinationName: prediction.getReadableDestinationName()))
    }
    
    private func nilDestinationException(destinationName: String) -> Bool {
        return destinationName == "" && destinationSelection == BlacklistedStationTermStripper.noStationFound
    }
    
    private func defaultDestinationOrMatchesName(destinationName: String?) -> Bool {
        return destinationSelection == JourneyBoard.defaultDestinationFilter ||
            destinationName?.contains(destinationSelection) == true
    }
    
    private func lineCheck(lineName: String?) -> Bool {
        return lineSelection == JourneyBoard.defaultLineFilter || lineName == lineSelection
    }
        
}
