//
//  TFLStationData.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 04/04/2023.
//

/**
 The IDs used for API calls related to specific underground lines.
 For all intents and purposes, every line is considered to be on the underground.
 */
let LineIDs: [String : Line] = [
    "bakerloo": Line(id: "bakerloo", name: "Bakerloo Line", mode: Line.Mode.tube),
    "central": Line(id: "central", name: "Central Line", mode: Line.Mode.tube),
    "circle": Line(id: "circle", name: "Circle Line", mode: Line.Mode.tube),
    "district": Line(id: "district", name: "District Line", mode: Line.Mode.tube),
    "dlr": Line(id: "dlr", name: "Docklands Light Railway", mode: Line.Mode.dlr),
    "elizabeth": Line(id: "elizabeth", name: "Elizabeth line", mode: Line.Mode.elizabeth),
    "hammersmith-city": Line(id: "hammersmith-city", name: "Hammersmith & City", mode: Line.Mode.tube),
    "jubilee": Line(id: "jubilee", name: "Jubilee Line", mode: Line.Mode.tube),
    "metropolitan": Line(id: "metropolitan", name: "Metropolitan Line", mode: Line.Mode.tube),
    "northern": Line(id: "northern", name: "Northern Line", mode: Line.Mode.tube),
    "london-overground": Line(id: "london-overground", name: "London Overground", mode: Line.Mode.overground),
    "piccadilly": Line(id: "piccadilly", name: "Piccadilly Line", mode: Line.Mode.tube),
    "victoria": Line(id: "victoria", name: "Victoria Line", mode: Line.Mode.tube),
    "waterloo-city": Line(id: "waterloo-city", name: "Waterloo & City Line", mode: Line.Mode.tube)
]

struct Line: Hashable, Comparable {
    
    static func < (lhs: Line, rhs: Line) -> Bool {
        return lhs.id < rhs.id
    }
    
    enum Mode: String {
        case tube = "tube"
        case elizabeth = "elizabeth"
        case dlr = "dlr"
        case overground = "overground"
    }
    
    let id: String
    let name: String
    let mode: Mode
    
}

//func lookupRedableName(id: UndergroundLineIDs?) -> String {
//    switch id {
//    case .bakerloo: return "Bakerloo Line"
//    case .central: return "Central Line"
//    case .circle: return "Circle Line"
//    case .district: return "District Line"
//    case .dlr: return "Docklands Light Railway"
//    case .elizabeth: return "Elizabeth line"
//    case .hammersmith_city: return "Hammersmith & City"
//    case .jubilee: return "Jubilee Line"
//    case .metropolitan: return "Metropolitan Line"
//    case .northern: return "Northern Line"
//    case .piccadilly: return "Piccadilly Line"
//    case .victoria: return "Victoria Line"
//    case .waterloo_city: return "Waterloo & City"
//    default: return ""
//    }
//}
