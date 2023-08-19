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
    
    let id: String
    let name: String
    let compactName: String
    let mode: StopPointMetaData.modeName
    let colour: Color
    
    /**
     The IDs used for API calls related to specific underground lines.
     */
    static let lineMap: [String: Line] = [
        "bakerloo": Line(id: "bakerloo", name: "Bakerloo Line", compactName: "Bakerloo", mode: .tube, colour: Color(red: 175/255, green: 92/255, blue: 14/255)),
        "central": Line(id: "central", name: "Central Line", compactName: "Central", mode: .tube, colour: Color(red: 227/255, green: 32/255, blue: 23/255)),
        "circle": Line(id: "circle", name: "Circle Line", compactName: "Circle", mode: .tube, colour: Color(red: 255/255, green: 211/255, blue: 0/255)),
        "district": Line(id: "district", name: "District Line", compactName: "District", mode: .tube, colour: Color(red: 0/255, green: 132/255, blue: 58/255)),
        "dlr": Line(id: "dlr", name: "Docklands Light Railway", compactName: "DLR", mode: .dlr, colour: Color(red: 126/255, green: 205/255, blue: 167/255)),
        "elizabeth": Line(id: "elizabeth", name: "Elizabeth line", compactName: "Elizabeth", mode: .elizabeth, colour: Color(red: 105/255, green: 80/255, blue: 161/255)),
        "hammersmith-city": Line(id: "hammersmith-city", name: "Hammersmith & City Line", compactName: "H&C Line", mode: .tube, colour: Color(red: 243/255, green: 169/255, blue: 187/255)),
        "jubilee": Line(id: "jubilee", name: "Jubilee Line", compactName: "Jubilee", mode: .tube, colour: Color(red: 160/255, green: 165/255, blue: 169/255)),
        "metropolitan": Line(id: "metropolitan", name: "Metropolitan Line", compactName: "Metropolitan", mode: .tube, colour: Color(red: 155/255, green: 0/255, blue: 86/255)),
        "northern": Line(id: "northern", name: "Northern Line", compactName: "Northern", mode: .tube, colour: Color(red: 0/255, green: 0/255, blue: 0/255)),
        "london-overground": Line(id: "london-overground", name: "London Overground", compactName: "Overground", mode: .overground, colour: Color(red: 238/255, green: 124/255, blue: 14/255)),
        "piccadilly": Line(id: "piccadilly", name: "Piccadilly Line", compactName: "Piccadilly", mode: .tube, colour: Color(red: 0/255, green: 54/255, blue: 136/255)),
        "victoria": Line(id: "victoria", name: "Victoria Line", compactName: "Victoria", mode: .tube, colour: Color(red: 0/255, green: 152/255, blue: 212/255)),
        "waterloo-city": Line(id: "waterloo-city", name: "Waterloo & City Line", compactName: "W&C Line", mode: .tube, colour: Color(red: 149/255, green: 205/255, blue: 186/255))
    ]
    
    static func lookupName(lineID: String?) -> String? {
        guard lineID != nil
        else { return nil }
        return lineMap[lineID!]?.name
    }
    
    static func lookupCompactName(lineID: String?) -> String {
        guard lineID != nil
        else { return "" }
        return lineMap[lineID!]?.compactName ?? ""
    }
    
    static func lookupColour(lineID: String?, darkMode: Bool = false) -> Color {
        guard lineID != nil
        else { return darkMode ? .white : .black }
        let colour = lineMap[lineID!]?.colour
        return colour == .black && darkMode ? .white : colour ?? .black
    }
    
    static func lookupLineID(searchString: String) -> String? {
        guard let candidate = searchString.components(separatedBy: " ").first?.lowercased()
        else { return nil }
        return lineMap.keys.first(where: { $0.contains(candidate) })
    }
    
}
