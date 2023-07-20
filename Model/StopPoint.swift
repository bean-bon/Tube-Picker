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
    
    let modes: [String]
    let commonName: String
    let indicator: String?
    let stationNaptan: String
    let lat: Double
    let lon: Double
    
    static func < (lhs: StopPoint, rhs: StopPoint) -> Bool {
        return lhs.commonName < rhs.commonName
    }
    
}

struct StopPointRawResponse: Codable {
    
    let stopPoints: [StopPoint]
    
}

class StopPointMetaData {
    
    private init() {}
    
    enum modeName: String, CaseIterable {
        case all
        case tube
        case dlr
        case elizabeth
        case overground
    }
    
    static func modeNameAPIFormat(mode: modeName) -> String {
        switch mode {
        case .all: return "tube,dlr,elizabeth-line,overground"
        case .tube: return "tube"
        case .dlr: return "dlr"
        case .elizabeth: return "elizabeth-line"
        case .overground: return "overground"
        }
    }
    
    static func modeNameDescription(mode: modeName) -> String {
        switch mode {
        case .all: return "All Modes"
        case .tube: return "London Underground"
        case .dlr: return "Docklands Light Railway"
        case .elizabeth: return "Elizabeth line"
        case .overground: return "London Overground"
        }
    }
    
    static let cachePath: URL = DataManager.getDocumentsDirectory().appendingPathComponent("StopPointCache.json")

}
