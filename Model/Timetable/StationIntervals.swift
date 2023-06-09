//
//  StationIntervals.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 09/06/2023.
//

import Foundation

/**
 Represents a timetabled route, wherein a list of station intervals are stored
 along with an id, representing a route. Use the id here with intervalId in Schedule
 to lookup the route at a certain time.
 */
struct StationIntervals: Codable {
    
    let id: String
    let intervals: [Interval]
    
}

/**
 Represents a portion of a timetabled route where stopId is the NaptanID
 for a stop and timeToArrival is the estimated time to travel from the starting station to
 there.
 */
struct Interval: Codable {
    
    let stopId: String
    let timeToArrival: Int
    
}
