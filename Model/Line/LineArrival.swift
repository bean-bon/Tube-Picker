//
//  LineArrival.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 04/04/2023.
//

import Foundation

struct LineArrival: Hashable, Decodable, Identifiable {
    
    var id: String
    var stationName: String // Full station name.
    var lineId: String
    var lineName: String
    var platformName: String
    var destinationName: String?
    var timeToStation: Int32
    var towards: String // End of the line.
    
    static let `default` = LineArrival(id: "0", stationName: "Charing Cross Underground Station", lineId: "northern", lineName: "Northern", platformName: "4", destinationName: "High Barnet Underground Station", timeToStation: 35, towards: "High Barnet")
    
}
