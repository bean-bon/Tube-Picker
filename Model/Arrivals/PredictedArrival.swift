//
//  PredictedArrival.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 14/09/2022.
//

import Foundation
import SwiftUI

protocol PredictedArrival: GenericArrival {
    func getNaptan() -> String?
}

/**
 A representation of the data recieved when looking up arrivals/departures for
 the Elizabeth line or London Overground.
 URL: https://api.tfl.gov.uk/StopPoint/(naptanID)/ArrivalDepartures?lineIds=london-overground,elizabeth
 */
struct ArrivalDeparture: PredictedArrival, Decodable {
    
    let stationName: String
    var lineId: String?
    let naptanID: String?
    let platformName: String?
    let destinationName: String?
    let scheduledTimeOfDeparture: String?
    let minutesAndSecondsToDeparture: String?
    let departureStatus: String? // Usually "OnTime", may be different.
    
    func getNaptan() -> String? {
        return naptanID
    }
    
    func getReadableStationName() -> String {
        return BlacklistedStationTermStripper.removeBlacklistedTerms(input: stationName)
    }
    
    func getReadableDestinationName() -> String {
        return BlacklistedStationTermStripper.removeBlacklistedTerms(input: destinationName ?? "")
    }
    
    func getPlatformDisplayName() -> String {
        guard platformName != nil || platformName?.isEmpty == false,
              platformName?.contains("Unknown") == false
        else { return "" }
        return platformName!
    }
    
    /**
     This function is based on the format for time being mm:ss.
     */
    func getTimeToStationInSeconds() -> Int? {
        guard let minuteSecondSplit = minutesAndSecondsToDeparture?.components(separatedBy: ":"),
              minutesAndSecondsToDeparture?.isEmpty == false
        else { return nil }
        return Int(minuteSecondSplit[0])! * 60 + Int(minuteSecondSplit[1])!
    }
    
    func isArrivalTimeValid() -> Bool {
        return minutesAndSecondsToDeparture != nil
    }
    
    func isTimeUntilThisLessThan(seconds: UInt) -> Bool {
        guard let departureSeconds: Int = getTimeToStationInSeconds()
        else { return false }
        return departureSeconds < seconds
    }
    
    func getTimeDisplay() -> String {
        guard let timeSplit = minutesAndSecondsToDeparture?.components(separatedBy: ":")
        else {
            let time = getScheduledDepartureAsTimetablingTime()
            return time?.getFormattedTimeString() ?? ""
        }
        let mins = Int(timeSplit[0])!
        if mins == 0 {
            return "Due"
        } else if mins == 1 {
            return "1 min"
        } else {
            return "\(mins) mins"
        }
    }
    
    private func getScheduledDepartureAsTimetablingTime() -> TimetablingTime? {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: scheduledTimeOfDeparture ?? "")
        else { return nil }
        return date.timetablingTime()
    }
    
}

/**
 Prediction type which can be used for all TfL modes excluding busses, however, a more specialised
 version exists for the Elizabeth and Overground, so that should be favoured where applicable.
 */
struct TubePrediction: PredictedArrival, Decodable {
    
    static let `default` = TubePrediction(id: "0", naptanId: "940something", operationType: 0, stationName: "Charing Cross", lineId: "northern", platformName: "4", destinationName: "High Barnet", timeToStation: 35, modeName: "tube")
    
    let id: String
    let naptanId: String
    let operationType: Int
    let stationName: String
    var lineId: String?
    let platformName: String
    let destinationName: String?
    let timeToStation: Int
    let modeName: String
    
    func getNaptan() -> String? {
        return naptanId
    }
    
    func getReadableStationName() -> String {
        return BlacklistedStationTermStripper.removeBlacklistedTerms(input: stationName)
    }
    
    func getReadableDestinationName() -> String {
        return BlacklistedStationTermStripper.removeBlacklistedTerms(input: destinationName ?? "")
    }
    
    func getTimeToStationInSeconds() -> Int? {
        return timeToStation
    }
    
    func getPlatformDisplayName() -> String {
        return platformName.contains("-")
        ? "\(platformName.components(separatedBy: "-")[1].trimmingCharacters(in: .whitespaces))"
        : platformName.contains("Platform") ? "\(platformName)" : "Platform \(platformName)"
    }
    
    func isArrivalTimeValid() -> Bool {
        return timeToStation >= 0
    }
    
    func isTimeUntilThisLessThan(seconds: UInt) -> Bool {
        return timeToStation < seconds
    }
    
    func getTimeDisplay() -> String {
        let minutes = timeToStation / 60
        return minutes < 1
        ? "Due"
        : minutes == 1
            ? "1 min"
            : "\(minutes) mins"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(timeToStation)
        hasher.combine(destinationName)
        hasher.combine(lineId)
    }
    
    static func ==(lhs: TubePrediction, rhs: TubePrediction) -> Bool {
        return lhs.timeToStation == rhs.timeToStation
        && lhs.destinationName == rhs.destinationName
        && lhs.lineId == rhs.lineId
    }

}
