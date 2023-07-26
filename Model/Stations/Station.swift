//
//  Station.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 11/09/2022.
//

import Foundation

protocol Station {
    var name: String { get }
    var lines: Set<String> { get }
    func getReadableName() -> String
    func getMode() -> StopPointMetaData.modeName
    func pullArrivals() async -> [any PredictedArrival]
    func pullTimetabling(arrivals: [any PredictedArrival]) async -> [any TimetabledArrival]
    func needsTimetabling(arrivals: [any PredictedArrival]) -> Bool
    /**
     Check whether the station is favourited. If the implementation does not support favourites (i.e. combo stations),
     this method should return nil.
     */
    func isFavourite() -> Bool?
    func setFavourite(value: Bool)
}

struct CombinationNaptanStation: Station {
    
    let name: String
    let lines: Set<String>
    let naptanDictionary: [String: StopPointMetaData.modeName]
    
    init(name: String, lines: Set<String>, naptanDictionary: [String : StopPointMetaData.modeName]) {
        self.name = name
        self.lines = lines
        self.naptanDictionary = naptanDictionary
    }
    
    init(name: String, singleStations: [SingleStation]) {
        self.name = name
        self.lines = Set(singleStations.map { $0.lines }.joined())
        self.naptanDictionary = Dictionary(singleStations.map { ($0.name, $0.mode) }, uniquingKeysWith: { _, new in new })
    }
    
    func getReadableName() -> String {
        return BlacklistedStationTermStripper.removeBlacklistedTerms(input: name)
    }
    
    func getAllLineIds() -> Set<String> {
        return Set(naptanDictionary.keys)
    }
    
    func pullArrivals() async -> [any PredictedArrival] {
        var arrivals = [any PredictedArrival]()
        for (naptan, mode) in naptanDictionary {
            if [StopPointMetaData.modeName.tube, StopPointMetaData.modeName.dlr].contains(mode) {
                arrivals += await getTubeDLRArrivals(naptanID: naptan)
            } else {
                arrivals += await getOvergroundElizabethArrivals(naptanID: naptan, mode: mode)
            }
        }
        return arrivals
    }
    
    func pullTimetabling(arrivals: [any PredictedArrival]) async -> [any TimetabledArrival] {
        let linesToNaptans = lookupLinesForTimetabling(arrivals: arrivals)
        var timetableInfo = [TflTimetabledArrival]()
        for (line, naptans) in linesToNaptans {
            for naptan in naptans {
                guard let response: TwoWayTimetableResponse = await APIHandler.shared.tubeDlrTimetables(lineName: line, fromNaptan: naptan)
                else { continue }
                let timetabledArrivals = (response.inbound?.getTimetabledArrivals(originStation: name, lineName: line) ?? [])
                + (response.outbound?.getTimetabledArrivals(originStation: name, lineName: line) ?? [])
                timetableInfo.append(contentsOf: timetabledArrivals.filter { $0.isArrivalTimeValid() })
            }
        }
        return timetableInfo
    }
    
    func needsTimetabling(arrivals: [any PredictedArrival]) -> Bool {
        let lines = lookupLinesForTimetabling(arrivals: arrivals)
        return naptanDictionary.contains(where: { [StopPointMetaData.modeName.tube, StopPointMetaData.modeName.dlr].contains($0.value)} ) && !lines.isEmpty
    }
    
    func isFavourite() -> Bool? {
        return nil
    }
    
    func getMode() -> StopPointMetaData.modeName {
        return .allMetro
    }
    
    /**
     This implementation of station cannot support favourites, thus the method does nothing.
     */
    func setFavourite(value: Bool) {}
    
    private func lookupLinesForTimetabling(arrivals: [any PredictedArrival]) -> [String: Set<String>] {
        let stationLines = arrivals
            .filter { $0.getReadableStationName() == $0.getReadableDestinationName() && ![StopPointMetaData.modeNameAPIFormat(mode: .overground), StopPointMetaData.modeNameAPIFormat(mode: .elizabeth)].contains($0.lineId) }
            .map { ($0.lineId ?? "", $0.getNaptan() ?? "") }
            .filter { !($0.0.isEmpty || $0.1.isEmpty) }
        var lineToNaptans: [String: Set<String>] = Dictionary()
        for (line, naptan) in stationLines {
            if lineToNaptans[line] != nil {
                lineToNaptans[line]!.insert(naptan)
            } else {
                lineToNaptans[line] = [naptan]
            }
        }
        return lineToNaptans
    }
    
    private func getTubeDLRArrivals(naptanID: String) async -> [TubePrediction] {
        let predictionData = await APIHandler.shared.naptanTubeArrivals(naptanID: naptanID)
        return predictionData.filter {
            $0.timeToStation < 3600
        }
    }
    
    private func getOvergroundElizabethArrivals(naptanID: String, mode: StopPointMetaData.modeName) async -> [ArrivalDeparture] {
        let predictionData = await APIHandler.shared.naptanArrivalDepartures(naptanID: naptanID, mode: mode)
        return predictionData.filter {
            let arrivalTime = $0.getTimeToStationInSeconds()
            return arrivalTime != nil && arrivalTime! < 3600
        }
    }
    
}

struct SingleStation: Station, Hashable, Comparable {
    
    let name: String
    let lines: Set<String>
    let mode: StopPointMetaData.modeName
    let naptanID: String
    
    init(name: String, lines: Set<String>, mode: StopPointMetaData.modeName, naptanID: String) {
        self.name = name
        self.lines = lines
        self.mode = mode
        self.naptanID = naptanID
    }
    
    private var recentArrivals: ([any PredictedArrival], Date) = ([], Date.distantPast)
    
    static let `default` = SingleStation(name: "Paddington Underground Station", lines: ["bakerloo", "circle"], mode: StopPointMetaData.modeName.tube, naptanID: "")

    /**
     Strip blacklisted terms from the full station name and return the result.
     */
    func getReadableName() -> String {
        return BlacklistedStationTermStripper.removeBlacklistedTerms(input: name)
    }
    
    func pullArrivals() async -> [any PredictedArrival] {
        if !recentArrivals.0.isEmpty && recentArrivals.1.timetablingTime().secondsUntil(other: Date().timetablingTime())! < 30 {
            return recentArrivals.0
        }
        if [StopPointMetaData.modeName.tube, StopPointMetaData.modeName.dlr].contains(mode) {
            return await getTubeDLRArrivals()
        } else {
            return await getOvergroundElizabethArrivals()
        }
    }
    
    func pullTimetabling(arrivals: [any PredictedArrival]) async -> [any TimetabledArrival] {
        if needsTimetabling(arrivals: arrivals) {
            var timetableInfo = [TflTimetabledArrival]()
            let terminatingLines = getTimetablingLines(arrivals: arrivals)
            for line in terminatingLines {
                guard let response: TwoWayTimetableResponse = await APIHandler.shared.tubeDlrTimetables(lineName: line, fromNaptan: naptanID)
                else { continue }
                let timetabledArrivals = (response.inbound?.getTimetabledArrivals(originStation: name, lineName: line) ?? [])
                + (response.outbound?.getTimetabledArrivals(originStation: name, lineName: line) ?? [])
                timetableInfo.append(contentsOf: timetabledArrivals.filter { $0.isArrivalTimeValid() })
            }
            return timetableInfo
        } else {
            // Overground and DLR timetabling: not implemented server-side.
            return []
        }
    }
    
    func needsTimetabling(arrivals: [any PredictedArrival]) -> Bool {
        let linesForTimetabling = getTimetablingLines(arrivals: arrivals)
        return [StopPointMetaData.modeName.tube, StopPointMetaData.modeName.dlr].contains(mode) && !linesForTimetabling.isEmpty
    }
    
    func isFavourite() -> Bool? {
        return FavouritesInterface.stations.isFavourite(naptanID: naptanID, mode: mode)
    }
    
    func setFavourite(value: Bool) {
        FavouritesInterface.stations.setFavourite(name: name, naptanID: naptanID, mode: mode, lines: lines, value: value)
    }
    
    func getMode() -> StopPointMetaData.modeName {
        return mode
    }
    
    private func getTimetablingLines(arrivals: [any PredictedArrival]) -> Set<String> {
        let lineDestinationTuples = arrivals.filter { $0.lineId != nil }.map { ($0.lineId!, $0.getReadableDestinationName()) }
        let lines = Set(lineDestinationTuples.map { $0.0 })
        let linesForTimetabing = lines.filter { line in
            let filteredLineTuples = lineDestinationTuples.filter { $0.0 == line }
            let sampleName = lineDestinationTuples.first(where: { $0.0 == line})!.1
            return filteredLineTuples.allSatisfy { $0.1 == sampleName }
        }
        return Set(arrivals.filter { $0.getReadableStationName() == $0.getReadableDestinationName() }
            .compactMap { $0.lineId })
            .union(linesForTimetabing)
    }
    
    private func getTubeDLRArrivals() async -> [TubePrediction] {
        let predictionData = await APIHandler.shared.naptanTubeArrivals(naptanID: naptanID)
        let arrivals = predictionData.filter { $0.timeToStation < 3600 }
        return arrivals
    }
    
    private func getOvergroundElizabethArrivals() async -> [ArrivalDeparture] {
        let predictionData = await APIHandler.shared.naptanArrivalDepartures(naptanID: naptanID, mode: mode)
        let arrivals = predictionData.filter {
            let arrivalTime = $0.getTimeToStationInSeconds()
            return arrivalTime != nil && arrivalTime! < 3600
        }
        return arrivals
    }
    
    static func < (lhs: SingleStation, rhs: SingleStation) -> Bool {
        return lhs.name < rhs.name
    }
    
    static func ==(lhs: SingleStation, rhs: SingleStation) -> Bool {
        return lhs.getReadableName() == rhs.getReadableName()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(getReadableName())
    }
    
}
