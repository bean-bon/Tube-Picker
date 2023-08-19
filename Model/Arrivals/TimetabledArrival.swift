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

    static let `default` = TflTimetabledArrival(stationName: "Charing Cross", destinationName: "Edgeware", lineId: "northern", departureTime: TimetablingTime(hour: "13", minute: "12"))
    
    let stationName: String
    var destinationName: String?
    var lineId: String?
    let departureTime: TimetablingTime
    
    func getReadableStationName() -> String {
        return BlacklistedStationTermStripper.sanitiseStationName(input: stationName)
    }
    
    func getReadableDestinationName() -> String {
        return BlacklistedStationTermStripper.sanitiseStationName(input: destinationName ?? "")
    }
    
    func getMode() -> StopPointMetaData.modeName {
        return lineId == nil
        ? .unknown
        : Line.lineMap[lineId ?? ""]?.mode ?? .bus
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
        hasher.combine(lineId)
    }
    
    static func ==(lhs: TflTimetabledArrival, rhs: TflTimetabledArrival) -> Bool {
        return lhs.isArrivalTimeValid() && rhs.isArrivalTimeValid()
        && lhs.departureTime == rhs.departureTime
        && lhs.destinationName == rhs.destinationName
        && lhs.lineId == rhs.lineId
    }
    
}
