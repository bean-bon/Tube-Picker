//
//  TimetabledStop.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 09/06/2023.
//

import Foundation

/**
 Represents a stop in the list of those timetabled.
 */
struct TimetabledStop: Codable {
    
    let routeId: Int?
    let stationId: String // NaptanID.
    let direction: String?
    let towards: String?
    let name: String
    let lat: Double
    let lon: Double
    
}
