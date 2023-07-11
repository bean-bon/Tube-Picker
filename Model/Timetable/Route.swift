//
//  Route.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 09/06/2023.
//

import Foundation

struct Route: Codable {
    
    let stationIntervals: [StationIntervals]
    let schedules: [Schedule]
    
    func getTodaysTimetabledArrivals(currentStationName: String, lineName: String) -> KnownJourneysWithIntervalIDNaptanMap? {
        guard stationIntervals.allSatisfy({ !$0.intervals.isEmpty })
        else { return nil }
        let naptanDestinationsByIntervalID: [String: String] = Dictionary(stationIntervals.map {
            ($0.id, $0.intervals.last!.stopId)
        }, uniquingKeysWith: { $0 + $1 })
        let knownJourneysByDay: [String: [KnownJourney]] = Dictionary(schedules.map {
            ($0.name, $0.knownJourneys)
        }, uniquingKeysWith: { $0 + $1 })
        let identifier = getTodaysTimetablePartialIdentifier()
        let journeys: [KnownJourney] = knownJourneysByDay.first(where: { $0.key.contains(identifier) })?.value ?? []
        return KnownJourneysWithIntervalIDNaptanMap(
            intervalIdToNaptanDestination: naptanDestinationsByIntervalID,
            knownJourneys: journeys)
    }

    func getTodaysTimetablePartialIdentifier() -> String {
        switch Date.now.isThisAPublicHoliday() {
        case nil: return "Monday"
        case true: return "Holiday"
        default: return Date.now.timetableIdentifier()
        }
    }
    
}

struct KnownJourneysWithIntervalIDNaptanMap {
    
    let intervalIdToNaptanDestination: [String: String]
    let knownJourneys: [KnownJourney]
    
}
