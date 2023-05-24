//
//  Station.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 11/09/2022.
//

import Foundation

struct Station: Hashable, Comparable {
    
    let name: String
    let mode: Line.Mode
    
    static let `default` = Station(name: "Paddington Underground Station", mode: Line.Mode.tube)

    static func < (lhs: Station, rhs: Station) -> Bool {
        return lhs.name < rhs.name
    }

    func getReadableName() -> String {
        return BlacklistedStationTermStripper.removeBlacklistedTerms(input: name)
    }
        
    init(name: String, mode: Line.Mode) {
        self.name = name
        self.mode = mode
    }
    
}
