//
//  PredictedArrival.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 14/09/2022.
//

import Foundation

struct PredictedArrival: Hashable, Decodable, Identifiable, Comparable {
    
    static let `default` = PredictedArrival(id: "0", operationType: 0, stationName: "Charing Cross", lineName: "Northern", platformName: "4", destinationName: "High Barnet", timeToStation: 35, modeName: "tube")
    
    var id: String
    var operationType: Int32
    var stationName: String
    var lineName: String
    var platformName: String
    var destinationName: String?
    var timeToStation: Int32
    var modeName: String
    
    func getReadableStationName() -> String {
        return BlacklistedStationTermStripper.removeBlacklistedTerms(input: stationName)
    }
    
    func getReadableDestinationName() -> String? {
        let result = BlacklistedStationTermStripper.removeBlacklistedTerms(input: destinationName ?? "")
        return result.count == 0 ? nil : result
    }
    
    static func < (lhs: PredictedArrival, rhs: PredictedArrival) -> Bool {
        return lhs.timeToStation < rhs.timeToStation
    }
    
}
