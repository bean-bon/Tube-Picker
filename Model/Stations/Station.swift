//
//  Station.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 11/09/2022.
//

import Foundation
import MapKit

protocol Station {
    var name: String { get }
    var lines: Set<String> { get }
    var lat: CLLocationDegrees { get }
    var lon: CLLocationDegrees { get }
    func getReadableName() -> String
    func getNaptanString() -> String
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
    let lat: CLLocationDegrees
    let lon: CLLocationDegrees
    
    init(name: String, lines: Set<String>, naptanDictionary: [String : StopPointMetaData.modeName], lat: CLLocationDegrees, lon: CLLocationDegrees) {
        self.name = name
        self.lines = lines
        self.naptanDictionary = naptanDictionary
        self.lat = lat
        self.lon = lon
    }
    
    init(name: String, lines: Set<String>, naptanDictionary: [String : StopPointMetaData.modeName], lats: [CLLocationDegrees], lons: [CLLocationDegrees]) {
        self.name = name
        self.lines = lines
        self.naptanDictionary = naptanDictionary
        self.lat = lats.reduce(0, +) / Double(lats.count)
        self.lon = lons.reduce(0, +) / Double(lons.count)
    }
    
    init(name: String, singleStations: [SingleStation]) {
        self.name = name
        self.lines = Set(singleStations.map { $0.lines }.joined())
        self.naptanDictionary = Dictionary(singleStations.map { ($0.naptanID, $0.mode) }, uniquingKeysWith: { _, new in new })
        self.lat = singleStations.map { $0.lat }.reduce(0, +) / Double(singleStations.count)
        self.lon = singleStations.map { $0.lon }.reduce(0, +) / Double(singleStations.count)
    }
    
    func getReadableName() -> String {
        return BlacklistedStationTermStripper.sanitiseStationName(input: name)
    }
    
    func getAllLineIds() -> Set<String> {
        return Set(naptanDictionary.keys)
    }
    
    func pullArrivals() async -> [any PredictedArrival] {
        let arrivalsActor = ArrivalsActor()
        await withThrowingTaskGroup(of: Void.self, returning: Void.self) { group in
            for (naptan, mode) in naptanDictionary {
                if [StopPointMetaData.modeName.tube, StopPointMetaData.modeName.dlr].contains(mode) {
                    group.addTask { await arrivalsActor.addArrivals(await getTubeDLRArrivals(naptanID: naptan)) }
                } else {
                    group.addTask{ await arrivalsActor.addArrivals(await getOvergroundElizabethArrivals(naptanID: naptan, mode: mode)) }
                }
            }
        }
        
        return await arrivalsActor.arrivals
        
        actor ArrivalsActor {
            var arrivals = [any PredictedArrival]()
            func addArrivals(_ new: [any PredictedArrival]) {
                arrivals += new
            }
        }
        
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
    
    func getNaptanString() -> String {
        return naptanDictionary.keys.joined(separator: ",")
    }
    
    func isFavourite() -> Bool? {
        return FavouritesInterface.stations.isFavourite(naptanDictionary: naptanDictionary)
    }
    
    func getMode() -> StopPointMetaData.modeName {
        let modeSet = Set(naptanDictionary.values)
        return modeSet.count == 1
        ? modeSet.first!
        : .allMetro
    }

    func setFavourite(value: Bool) {
        FavouritesInterface.stations.setFavourite(name: name, naptanDictionary: naptanDictionary, lines: lines, coordinates: CLLocationCoordinate2D(latitude: lat, longitude: lon), value: value)
    }
    
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
    
    private func getTubeDLRArrivals(naptanID: String) async -> [BusTubePrediction] {
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
    let lat: CLLocationDegrees
    let lon: CLLocationDegrees
    
    init(name: String, lines: Set<String>, mode: StopPointMetaData.modeName, naptanID: String, lat: CLLocationDegrees, lon: CLLocationDegrees) {
        self.name = name
        self.lines = lines
        self.mode = mode
        self.naptanID = naptanID
        self.lat = lat
        self.lon = lon
    }
    
    private var recentArrivals: ([any PredictedArrival], Date) = ([], Date.distantPast)
    
    static let `default` = SingleStation(name: "Paddington Underground Station", lines: ["bakerloo", "circle"], mode: StopPointMetaData.modeName.tube, naptanID: "", lat: 0, lon: 0)

    /**
     Strip blacklisted terms from the full station name and return the result.
     */
    func getReadableName() -> String {
        return BlacklistedStationTermStripper.sanitiseStationName(input: name)
    }
    
    func getNaptanString() -> String {
        return naptanID
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
        return FavouritesInterface.stations.isFavourite(naptanDictionary: [naptanID: mode])
    }
    
    func setFavourite(value: Bool) {
        FavouritesInterface.stations.setFavourite(name: name, naptanDictionary: [naptanID: mode], lines: lines, coordinates: CLLocationCoordinate2D(latitude: lat, longitude: lon), value: value)
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
    
    private func getTubeDLRArrivals() async -> [BusTubePrediction] {
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

struct BusStop: Station, Hashable, Comparable, CustomStringConvertible {
    
    let name: String
    let stopIndicator: String
    let naptanId: String
    let lines: Set<String>
    let bearing: String?
    let lat: CLLocationDegrees
    let lon: CLLocationDegrees
    let towards: String
    
    var description: String {
        return "\(name):\(stopIndicator):\(naptanId):\(lines.sorted().joined(separator: ",")):\(bearing ?? "nil"):\(lat):\(lon):\(towards)"
    }
    
    init(name: String, stopIndicator: String, naptanId: String, lines: Set<String>, bearing: String?, lat: CLLocationDegrees, lon: CLLocationDegrees, towards: String) {
        self.name = name
        self.stopIndicator = stopIndicator
        self.naptanId = naptanId
        self.lines = lines
        self.bearing = bearing
        self.lat = lat
        self.lon = lon
        self.towards = towards
    }
    
    /**
     This init is based on the format of the CustomStingConvertible description.
     */
    init?(recordString: String) {
        let splitString = recordString.split(separator: ":")
        guard splitString.count > 7 else { return nil }
        self.name = String(splitString[0])
        self.stopIndicator = String(splitString[1])
        self.naptanId = String(splitString[2])
        self.lines = Set(splitString[3].split(separator: ",").map(String.init))
        self.bearing = splitString[4] == "nil" ? nil : String(splitString[4])
        guard let doubleLat = Double(splitString[5]),
              let doubleLon = Double(splitString[6])
        else { return nil }
        self.lat = CLLocationDegrees(floatLiteral: doubleLat)
        self.lon = CLLocationDegrees(floatLiteral: doubleLon)
        self.towards = String(splitString[7])
    }
    
    func getReadableName() -> String {
        return name
    }
    
    func getNaptanString() -> String {
        return naptanId
    }
    
    func getMode() -> StopPointMetaData.modeName {
        return .bus
    }
    
    func pullArrivals() async -> [any PredictedArrival] {
        return await APIHandler.shared.naptanTubeArrivals(naptanID: naptanId)
    }
    
    func pullTimetabling(arrivals: [any PredictedArrival]) async -> [any TimetabledArrival] {
        return []
    }
    
    func needsTimetabling(arrivals: [any PredictedArrival]) -> Bool {
        return false
    }
    
    func isFavourite() -> Bool? {
        return FavouritesInterface.buses.isFavourite(stop: self)
    }
    
    func setFavourite(value: Bool) {
        FavouritesInterface.buses.setFavourite(stop: self, value: value)
    }
    
    static func < (lhs: BusStop, rhs: BusStop) -> Bool {
        return lhs.naptanId < rhs.naptanId
    }
    
    
}
