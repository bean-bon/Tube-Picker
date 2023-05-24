//
//  BlacklistedTerms.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 24/05/2023.
//

import Foundation

class BlacklistedStationTermStripper {
    
    private static let blacklistedTerms: [String] = ["ELL", "(London)", "Underground Station", "Rail Station", "DLR Station", "(H&C Line)-Underground"]
    
    // Exceptions for the readable name: if the full name contains one of these
    // items, that is returned instead of the standard processing.
    private static let readableExceptions = [
        "London City Airport",
        "London Bridge"
    ]

    static func removeBlacklistedTerms(input: String) -> String {
        let exemptName = BlacklistedStationTermStripper.readableExceptions.first { input.contains($0) }
        if exemptName != nil {
            return exemptName!
        }
        var newStationName = input
        for item in blacklistedTerms {
            newStationName = newStationName.replacingOccurrences(of: item, with: "")
        }
        return newStationName
    }
    
    private init() {}
    
}
