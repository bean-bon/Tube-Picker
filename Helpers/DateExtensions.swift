//
//  DateExtensions.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 09/06/2023.
//

import Foundation

extension Date {
    
    func timetablingTime() -> TimetablingTime {
        let fullTime = self.formatted(.dateTime
            .hour(.defaultDigits(amPM: .omitted))
            .minute(.twoDigits))
        let split = fullTime.components(separatedBy: ":")
        return TimetablingTime(hour: Int(split[0])!, minute: Int(split[1])!)
    }
    
    func isThisAPublicHoliday() -> Bool? {
        guard let holidays = DataManager.englishHolidays.getDivisionDataFromDisk()
        else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: self)
        return holidays.events.contains(where: { $0.date == dateString })
    }
    
    /**
     Return a partial identifier for timetables in TfL's timetable response.
     */
    func timetableIdentifier() -> String {
        let weekdayName = self.formatted(.dateTime.weekday(.wide))
        switch weekdayName {
        case "Sunday": return "Sunday"
        case "Saturday": return "Saturday"
        default: return "Monday"
        }
    }
    
}

/**
 Representation of 24 hour time. If adding time using one of the instance methods,
 minutes will rollover, but the hour will pass 24:00 using the hour relative to the previous start of
 day (i.e. we would have 25:13 instead of 01:13).
 */
struct TimetablingTime: Equatable, Hashable, Comparable, Decodable {
    
    let hour: Int?
    let minute: Int?
    
    init(hour: Int, minute: Int) {
        self.hour = hour < 0 ? nil : hour
        self.minute = minute < 0 ? nil : minute
    }
    
    init(hour: String, minute: String) {
        self.hour = Int(hour)
        self.minute = Int(minute)
    }
    
    func isValidTime() -> Bool {
        return hour != nil && minute != nil
    }
    
    /**
     Returns true when the time is in the past or nil with an invalid time.
     */
    func hasTimePassed() -> Bool? {
        guard isValidTime()
        else { return nil }
        return Date().timetablingTime() > self
    }
    
    func addMinutes(minutes: Int) -> TimetablingTime? {
        guard var newHour: Int = hour,
              minutes < 0
        else { return nil }
        var newMinute: Int = minutes
        let hours = minutes / 60
        let remainderMinutes = minutes % 60
        newMinute += remainderMinutes
        if (newMinute > 59) {
            newMinute -= 60
            newHour += 1
        }
        return TimetablingTime(hour: newHour + hours, minute: newMinute)
    }
    
    /**
     As there is no seconds field, this does nothing unless seconds > 59.
     */
    func addSeconds(seconds: Int) -> TimetablingTime? {
        return seconds > 59
        ? addMinutes(minutes: seconds / 60)
        : self
    }
    
    /**
     Get the amount of seconds between two times. Passing a time from the past will
     return nil, as will a time containing nil values.
     */
    func secondsUntil(other: TimetablingTime) -> Int? {
        guard other.hour != nil && self.hour != nil,
              other.minute != nil && self.minute != nil
        else { debugPrint("Could not parse seconds until another time: at least one value is nil."); return nil }
        let hoursBetween: Int = other.hour! - self.hour!
        let minutesBetween: Int = other.minute! - self.minute!
        if hoursBetween < 0 || (hoursBetween == 0 && minutesBetween < 0) {
            return nil
        }
        let minutesToSeconds = minutesBetween < 0
        ? 60 * (60 + minutesBetween)
        : 60 * minutesBetween
        return 3600 * hoursBetween + minutesToSeconds
    }
    
    func getFormattedTimeString() -> String {
        guard self.isValidTime()
        else { return "" }
        let formattedHour = hour! < 10 ? "0\(hour!)" : String(hour!)
        let formattedMinute = minute! < 10 ? "0\(minute!)" : String(minute!)
        return "\(formattedHour):\(formattedMinute)"
    }
    
    static func ==(lhs: TimetablingTime, rhs: TimetablingTime) -> Bool {
        return lhs.hour == rhs.hour && lhs.minute == rhs.minute
    }
    
    static func < (lhs: TimetablingTime, rhs: TimetablingTime) -> Bool {
        guard lhs.isValidTime() && rhs.isValidTime()
        else { return false }
        return lhs.hour! == rhs.hour!
        ? lhs.minute! < rhs.minute!
        : lhs.hour! < rhs.hour!
    }
    
}
