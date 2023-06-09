//
//  KnownJourney.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 09/06/2023.
//

import Foundation

/**
 Represents a train arrival/departure. The intervalId can be used
 to lookup the route in StationIntervals.
 */
struct KnownJourney: Codable {
    
    let hour: String
    let minute: String
    let intervalId: Int
    
}
