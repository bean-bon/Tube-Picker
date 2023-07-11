//
//  TFLStationData.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 04/04/2023.
//

import SwiftUI

struct Line: Hashable, Comparable {
    
    static func < (lhs: Line, rhs: Line) -> Bool {
        return lhs.id < rhs.id
    }
    
    enum Mode: String {
        case tube
        case elizabeth
        case dlr
        case overground
    }
    
    let id: String
    let name: String
    let mode: Mode
    let colour: Color
    
    /**
     The IDs used for API calls related to specific underground lines.
     */
    static let lineMap: [String: Line] = [
        "bakerloo": Line(id: "bakerloo", name: "Bakerloo Line", mode: Line.Mode.tube, colour: Color(red: 175/255, green: 92/255, blue: 14/255)),
        "central": Line(id: "central", name: "Central Line", mode: Line.Mode.tube, colour: Color(red: 227/255, green: 32/255, blue: 23/255)),
        "circle": Line(id: "circle", name: "Circle Line", mode: Line.Mode.tube, colour: Color(red: 255/255, green: 211/255, blue: 0/255)),
        "district": Line(id: "district", name: "District Line", mode: Line.Mode.tube, colour: Color(red: 0/255, green: 132/255, blue: 58/255)),
        "dlr": Line(id: "dlr", name: "Docklands Light Railway", mode: Line.Mode.dlr, colour: Color(red: 126/255, green: 205/255, blue: 167/255)),
        "elizabeth": Line(id: "elizabeth", name: "Elizabeth line", mode: Line.Mode.elizabeth, colour: Color(red: 105/255, green: 80/255, blue: 161/255)),
        "hammersmith-city": Line(id: "hammersmith-city", name: "Hammersmith & City", mode: Line.Mode.tube, colour: Color(red: 243/255, green: 169/255, blue: 187/255)),
        "jubilee": Line(id: "jubilee", name: "Jubilee Line", mode: Line.Mode.tube, colour: Color(red: 160/255, green: 165/255, blue: 169/255)),
        "metropolitan": Line(id: "metropolitan", name: "Metropolitan Line", mode: Line.Mode.tube, colour: Color(red: 155/255, green: 0/255, blue: 86/255)),
        "northern": Line(id: "northern", name: "Northern Line", mode: Line.Mode.tube, colour: Color(red: 0/255, green: 0/255, blue: 0/255)),
        "london-overground": Line(id: "london-overground", name: "London Overground", mode: Line.Mode.overground, colour: Color(red: 238/255, green: 124/255, blue: 14/255)),
        "piccadilly": Line(id: "piccadilly", name: "Piccadilly Line", mode: Line.Mode.tube, colour: Color(red: 0/255, green: 54/255, blue: 136/255)),
        "victoria": Line(id: "victoria", name: "Victoria Line", mode: Line.Mode.tube, colour: Color(red: 0/255, green: 152/255, blue: 212/255)),
        "waterloo-city": Line(id: "waterloo-city", name: "Waterloo & City Line", mode: Line.Mode.tube, colour: Color(red: 149/255, green: 205/255, blue: 186/255))
    ]
    
    static func lookupColour(lineName: String?) -> Color? {
        guard let lookupName = lineName?.uppercased().components(separatedBy: " ")[0]
        else { return nil }
        // Lookup exempt names.
        let exceptionLookup = colourLookupExceptions(name: lookupName)
        if exceptionLookup != nil {
            return exceptionLookup
        }
        for line in lineMap {
            let capitalisedComparator = line.value.name.uppercased().components(separatedBy: " ")[0]
            if capitalisedComparator.contains(lookupName) {
                return line.value.colour
            }
        }
        return nil
    }
    
    public static func lookupLineID(searchString: String) -> String? {
        guard let candidate = searchString.components(separatedBy: " ").first?.lowercased()
        else { return nil }
        return lineMap.keys.first(where: { $0.contains(candidate) })
    }
    
    private static func colourLookupExceptions(name: String) -> Color? {
        switch name {
        case "DLR":
            return Line.lineMap["dlr"]!.colour
        case "LONDON-OVERGROUND":
            return Line.lineMap["london-overground"]!.colour
        case "OVERGROUND":
            return Line.lineMap["london-overground"]!.colour
        default:
            return nil
        }
    }
    
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
