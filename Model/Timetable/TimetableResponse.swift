//
//  TimetableResponse.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 09/06/2023.
//

import Foundation

struct TimetableResponse: Codable {
    
    let stops: [TimetabledStop]
    let timetable: Timetable
    
    func getTimetabledArrivals(originStation: String, lineName: String) -> [TflTimetabledArrival] {
        let knownJourneyMapListObject = timetable.routes.compactMap { $0.getTodaysTimetabledArrivals(currentStationName: originStation, lineName: lineName) }
        let naptanToName: [String: String] = Dictionary(stops.map { ($0.id, $0.name) }, uniquingKeysWith: +)
        return knownJourneyMapListObject.map { mapObject in
            mapObject.knownJourneys.map { journey in
                let intervalIdToNaptanDestination = mapObject.intervalIdToNaptanDestination
                let arrival = TflTimetabledArrival(
                    stationName: originStation,
                    destinationName: naptanToName[intervalIdToNaptanDestination[String(journey.intervalId)]!],
                    lineId: lineName,
                    departureTime: TimetablingTime(hour: journey.hour, minute: journey.minute))
                return arrival
            }
        }.reduce([], +)
    }
    
}

struct TwoWayTimetableResponse {
    
    let inbound: TimetableResponse?
    let outbound: TimetableResponse?
    
}
