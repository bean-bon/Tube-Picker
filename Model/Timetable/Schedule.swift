//
//  Schedule.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 09/06/2023.
//

import Foundation

/**
 Part of the response model for the timetables recieved from the Unified API:
 contains the journeys made at which times, represented as KnownJourneys.
 */
struct Schedule: Codable {
    
    let name: String
    let knownJourneys: [KnownJourney]
    let firstJourney: KnownJourney
    let lastJourney: KnownJourney
    
}
