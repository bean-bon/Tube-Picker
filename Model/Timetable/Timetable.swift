//
//  Timetable.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 09/06/2023.
//

import Foundation

/**
 Represents the timetable for a station, identified by the departureStopId.
 */
struct Timetable: Codable {
    
    let departureStopId: String
    let routes: [Route]
    
}
