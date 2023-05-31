//
//  BlacklistedTerms.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 24/05/2023.
//

import Foundation

class BlacklistedStationTermStripper {
    
    private static let blacklistedTerms: [String] = ["ELL", "(London)", "Crossrail", "Underground", "Rail", "DLR", "Station", "(H&C Line)-Underground"]

    static func removeBlacklistedTerms(input: String) -> String {
        var newStationName = input
        for item in blacklistedTerms {
            newStationName = newStationName.replacingOccurrences(of: item, with: "")
        }
        return newStationName
    }
    
    private init() {}
    
}
