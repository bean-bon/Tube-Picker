//
//  BusStopRoute.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 19/08/2023.
//

import Foundation

struct BusStopRoute: Decodable {
    
    let lineId: String
    let routeSectionName: String
    let isActive: Bool
    let vehicleDestinationText: String
    let destinationName: String
    
    enum CodingKeys: CodingKey {
        case lineId
        case routeSectionName
        case isActive
        case vehicleDestinationText
        case destinationName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.lineId = try container.decode(String.self, forKey: .lineId)
        self.routeSectionName = try container.decode(String.self, forKey: .routeSectionName)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)
        self.vehicleDestinationText = try container.decode(String.self, forKey: .vehicleDestinationText)
        self.destinationName = try container.decode(String.self, forKey: .destinationName)
    }
    
}
