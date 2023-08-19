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
    
    func getMode() -> StopPointMetaData.modeName {
        return .overgroundElizabeth
    }
    
    func getReadableStationName() -> String {
        return BlacklistedStationTermStripper.sanitiseStationName(input: stationName)
    }
    
    func getReadableDestinationName() -> String {
        return BlacklistedStationTermStripper.sanitiseStationName(input: destinationName ?? "")
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
 Prediction type which can be used for all TfL modes, however, a more specialised
 version exists for the Elizabeth and Overground, so that should be favoured where applicable.
 */
struct BusTubePrediction: PredictedArrival, Decodable {
    
    let id: String
    let naptanId: String
    let operationType: Int
    let stationName: String
    var lineId: String?
    let platformName: String
    let destinationName: String?
    let timeToStation: Int
    let modeName: StopPointMetaData.modeName
    
    enum CodingKeys: CodingKey {
        case id
        case naptanId
        case operationType
        case stationName
        case lineId
        case platformName
        case destinationName
        case timeToStation
        case modeName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.naptanId = try container.decode(String.self, forKey: .naptanId)
        self.operationType = try container.decode(Int.self, forKey: .operationType)
        self.stationName = try container.decode(String.self, forKey: .stationName)
        self.lineId = try container.decodeIfPresent(String.self, forKey: .lineId)
        self.platformName = try container.decode(String.self, forKey: .platformName)
        self.destinationName = try container.decodeIfPresent(String.self, forKey: .destinationName)
        self.timeToStation = try container.decode(Int.self, forKey: .timeToStation)
        self.modeName = StopPointMetaData.modeName.init(rawValue: try container.decode(String.self, forKey: .modeName)) ?? .unknown
    }
    
    func getNaptan() -> String? {
        return naptanId
    }
    
    func getMode() -> StopPointMetaData.modeName {
        return modeName
    }
    
    func getReadableStationName() -> String {
        return modeName == .bus
        ? BlacklistedStationTermStripper.sanitiseBusStopName(input: stationName)
        : BlacklistedStationTermStripper.sanitiseStationName(input: stationName)
    }
    
    func getReadableDestinationName() -> String {
        return modeName == .bus
        ? BlacklistedStationTermStripper.sanitiseBusStopName(input: destinationName ?? "")
        : BlacklistedStationTermStripper.sanitiseStationName(input: destinationName ?? "")
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
    
    static func ==(lhs: BusTubePrediction, rhs: BusTubePrediction) -> Bool {
        return lhs.timeToStation == rhs.timeToStation
        && lhs.destinationName == rhs.destinationName
        && lhs.lineId == rhs.lineId
    }

}
