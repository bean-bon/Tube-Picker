//
//  LineArrival.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 04/04/2023.
//

import Foundation

struct LineArrival: Hashable, Decodable, Identifiable {
    
    let id: String
    let stationName: String // Full station name.
    let lineId: String
    let mode: StopPointMetaData.modeName
    let lineName: String
    let platformName: String
    let destinationName: String?
    let timeToStation: Int32
    let towards: String // End of the line.
    
    enum CodingKeys: String, CodingKey {
        case id
        case stationName
        case lineId
        case mode = "modeName"
        case lineName
        case platformName
        case destinationName
        case timeToStation
        case towards
    }
    
    init(id: String, stationName: String, lineId: String, mode: StopPointMetaData.modeName, lineName: String, platformName: String, destinationName: String?, timeToStation: Int32, towards: String) {
        self.id = id
        self.stationName = stationName
        self.lineId = lineId
        self.mode = mode
        self.lineName = lineName
        self.platformName = platformName
        self.destinationName = destinationName
        self.timeToStation = timeToStation
        self.towards = towards
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.stationName = try container.decode(String.self, forKey: .stationName)
        self.lineId = try container.decode(String.self, forKey: .lineId)
        let rawMode = StopPointMetaData.modeName.init(rawValue: try container.decode(String.self, forKey: .mode))
        self.mode = rawMode ?? .unknown
        self.lineName = try container.decode(String.self, forKey: .lineName)
        self.platformName = try container.decode(String.self, forKey: .platformName)
        self.destinationName = try container.decodeIfPresent(String.self, forKey: .destinationName)
        self.timeToStation = try container.decode(Int32.self, forKey: .timeToStation)
        self.towards = try container.decode(String.self, forKey: .towards)
    }
    
    static let `default` = LineArrival(id: "0", stationName: "Charing Cross Underground Station", lineId: "northern", mode: .tube, lineName: "Northern", platformName: "4", destinationName: "High Barnet Underground Station", timeToStation: 35, towards: "High Barnet")
    
}
