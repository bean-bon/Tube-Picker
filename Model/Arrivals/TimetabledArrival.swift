//
//  TimetabledArrival.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 09/06/2023.
//

import Foundation
import SwiftUI

protocol TimetabledArrival: GenericArrival, Hashable {
    var departureTime: TimetablingTime { get }
}

/**
 Derived arrival type used to represent a timetabled arrival rather
 than one using predictions.
 */
struct TflTimetabledArrival: TimetabledArrival, Equatable {
    
    static let `default` = TflTimetabledArrival(stationName: "Charing Cross", destinationName: "Edgeware", lineName: "Northern", departureTime: TimetablingTime(hour: "13", minute: "12"))
    
    let stationName: String
    let destinationName: String?
    var lineName: String?
    let departureTime: TimetablingTime
    
    func getReadableStationName() -> String {
        return BlacklistedStationTermStripper.removeBlacklistedTerms(input: stationName)
    }
    
    func getReadableDestinationName() -> String {
        return BlacklistedStationTermStripper.removeBlacklistedTerms(input: destinationName ?? "")
    }
    
    func getTimeToStationInSeconds() -> Int? {
        let currentTime = Date().timetablingTime()
        return currentTime.secondsUntil(other: departureTime)
    }
    
    func getTime() -> TimetablingTime {
        return departureTime
    }
    
    func isTimeUntilThisLessThan(seconds: UInt) -> Bool {
        guard let timeToStation = getTimeToStationInSeconds()
        else { return false }
        return timeToStation < seconds
    }
    
    func getTimeDisplay() -> String {
        return departureTime.getFormattedTimeString()
    }
    
    func isArrivalTimeValid() -> Bool {
        return departureTime.hasTimePassed() == false
    }
    
    func getPlatformDisplayName() -> String {
        return ""
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(departureTime)
        hasher.combine(destinationName)
        hasher.combine(lineName)
    }
    
    static func ==(lhs: TflTimetabledArrival, rhs: TflTimetabledArrival) -> Bool {
        return lhs.isArrivalTimeValid() && rhs.isArrivalTimeValid()
        && lhs.departureTime == rhs.departureTime
        && lhs.destinationName == rhs.destinationName
        && lhs.lineName == rhs.lineName
    }
    
}

/**
 Timetable data derived from the Darwin Timetable API; the lines available from
 my API are: "elizabeth" and "overground". There is more work to be done on the server side,
 as associated trains are not currently supported: there may be seemingly conflicting services such as
 14:49 Stratford (Platform 1) and 14:50 Stratford (Platform 1); for now some are removed by placing a 2
 minute check when looking for equality.
 */
struct DarwinScheduleData: TimetabledArrival, Equatable, Decodable {

    let stationName: String
    let destinationName: String?
    var lineName: String?
    let platform: String
    let departureTime: TimetablingTime
    
    func getReadableStationName() -> String {
        return BlacklistedStationTermStripper.removeBlacklistedTerms(input: stationName)
    }
    
    func getReadableDestinationName() -> String {
        return BlacklistedStationTermStripper.removeBlacklistedTerms(input: destinationName ?? "")
    }
    
    func getPlatformDisplayName() -> String {
        if platform.isEmpty {
            return ""
        }
        return " - Platform \(platform)"
    }
    
    func getTimeToStationInSeconds() -> Int? {
        return Date().timetablingTime().secondsUntil(other: departureTime)
    }
    
    func isArrivalTimeValid() -> Bool {
        return departureTime.hasTimePassed() == false
    }
    
    func isTimeUntilThisLessThan(seconds: UInt) -> Bool {
        guard let timeToStation = getTimeToStationInSeconds()
        else { return false }
        return timeToStation < seconds
    }
    
    func getTimeDisplay() -> String {
        return departureTime.getFormattedTimeString()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(departureTime)
        hasher.combine(destinationName ?? String(Int.random(in: Int.min...Int.max)))
        hasher.combine(lineName ?? String(Int.random(in: Int.min...Int.max)))
    }
    
    static func ==(lhs: DarwinScheduleData, rhs: DarwinScheduleData) -> Bool {
        guard lhs.isArrivalTimeValid() && rhs.isArrivalTimeValid(),
              lhs.destinationName == rhs.destinationName,
              lhs.lineName == rhs.lineName
        else { return false }
        return abs(lhs.getTimeToStationInSeconds()! - rhs.getTimeToStationInSeconds()!) <= 120
    }
    
}
