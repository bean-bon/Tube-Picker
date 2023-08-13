//
//  StopPoint.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 26/05/2023.
//

import Foundation
import SwiftUI
import UIKit.UIColor

/**
 Representation of a TfL StopPoint in the Unified API. This seems to refer
 to entrances for stations.
 */
struct StopPoint: Hashable, Comparable, Codable {
    
    let modes: [StopPointMetaData.modeName]
    let commonName: String
    let naptanId: String
    let lines: [ApiLine]
    let lat: Double
    let lon: Double
    
    let stopLetter: String?
    let additionalProperties: [AdditionalProperty]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.modes = try container.decode([String].self, forKey: .modes).map {
            $0 == "elizabeth-line"
            ? .elizabeth
            : (StopPointMetaData.modeName.init(rawValue: $0) ?? .unknown)
        }
        self.commonName = try container.decode(String.self, forKey: .commonName)
        self.naptanId = try container.decode(String.self, forKey: .naptanId)
        self.lines = try container.decode([ApiLine].self, forKey: .lines)
        self.lat = try container.decode(Double.self, forKey: .lat)
        self.lon = try container.decode(Double.self, forKey: .lon)
        self.stopLetter = try container.decodeIfPresent(String.self, forKey: .stopLetter)
        self.additionalProperties = try container.decodeIfPresent([AdditionalProperty].self, forKey: .additionalProperties)
    }
    
    static func < (lhs: StopPoint, rhs: StopPoint) -> Bool {
        return lhs.commonName < rhs.commonName
    }
    
    struct AdditionalProperty: Codable, Hashable, Equatable {
        
        let category: PropertyCategory
        let key: PropertyKey
        let value: String
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: AdditionalProperty.CodingKeys.self)
            let rawCategory = PropertyCategory.init(rawValue: try container.decode(String.self, forKey: .category))
            self.category = rawCategory ?? .Miscellaneous
            let rawKey = PropertyKey.init(rawValue: try container.decode(String.self, forKey: .key))
            self.key = rawKey ?? .Miscellaneous
            self.value = try container.decode(String.self, forKey: .value)
        }
        
        enum PropertyCategory: String, Encodable {
            case Direction
            case Miscellaneous
        }
        
        enum PropertyKey: String, Encodable {
            case CompassPoint
            case Towards
            case Miscellaneous
        }
        
    }
    
}

struct StopPointRawResponse: Codable {
    
    let stopPoints: [StopPoint]
    
}

struct ApiLine: Codable, Hashable, Equatable {
    let id: String
}

class StopPointMetaData {
    
    private init() {}
    
    static let stationModesNames = [modeName.allMetro, modeName.dlr, modeName.elizabeth, modeName.overground, modeName.tube]
    
    enum modeName: String, Codable, CaseIterable {
        case allMetro
        case tube
        case dlr
        case elizabeth
        case overground
        case bus
        case unknown
    }
    
    static func modeNameAPIFormat(mode: modeName) -> String {
        switch mode {
        case .allMetro: return "tube,dlr,elizabeth-line,overground"
        case .tube: return "tube"
        case .dlr: return "dlr"
        case .elizabeth: return "elizabeth-line"
        case .overground: return "overground"
        case .bus: return "bus"
        case .unknown: return "unknown"
        }
    }
    
    static func modeNameDescription(mode: modeName) -> String {
        switch mode {
        case .allMetro: return "All Modes"
        case .tube: return "London Underground"
        case .dlr: return "Docklands Light Railway"
        case .elizabeth: return "Elizabeth line"
        case .overground: return "London Overground"
        case .bus: return "Bus"
        case .unknown: return "unknown"
        }
    }
    
    static func lookupModeColour(_ mode: modeName) -> Color {
        switch mode {
        case .allMetro: return .white
        case .bus: return Color(red: 225/255, green: 37/255, blue: 27/255)
        case .tube: return Color(red: 0/256, green: 9/256, blue: 171/256)
        case .dlr: return Line.lookupColour(lineID: "dlr")
        case .elizabeth: return Line.lookupColour(lineID: "elizabeth")
        case .overground: return Line.lookupColour(lineID: "london-overground")
        default: return .white
        }
    }
    
    static let cachePath: URL = DataManager.getDocumentsDirectory().appendingPathComponent("StopPointCache.json")

}
