//
//  StopPoint.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 26/05/2023.
//

import Foundation

/**
 Representation of a TfL StopPoint in the Unified API. This seems to refer
 to entrances for stations.
 */
struct StopPoint: Hashable, Comparable, Codable {
    
    let modes: [StopPointMetaData.modeName]
    let commonName: String
    let stationNaptan: String
    let lat: Double
    let lon: Double
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.modes = try container.decode([String].self, forKey: .modes).map {
            $0 == "elizabeth-line"
            ? .elizabeth
            : (StopPointMetaData.modeName.init(rawValue: $0) ?? .unknown)
        }
        self.commonName = try container.decode(String.self, forKey: .commonName)
        self.stationNaptan = try container.decode(String.self, forKey: .stationNaptan)
        self.lat = try container.decode(Double.self, forKey: .lat)
        self.lon = try container.decode(Double.self, forKey: .lon)
    }
    
    static func < (lhs: StopPoint, rhs: StopPoint) -> Bool {
        return lhs.commonName < rhs.commonName
    }
    
}

struct StopPointRawResponse: Codable {
    
    let stopPoints: [StopPoint]
    
}

class StopPointMetaData {
    
    private init() {}
    
    static let stationModesNames = [modeName.dlr, modeName.elizabeth, modeName.overground, modeName.tube]
    
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
    
    static let cachePath: URL = DataManager.getDocumentsDirectory().appendingPathComponent("StopPointCache.json")

}
