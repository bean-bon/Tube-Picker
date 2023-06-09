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

}
