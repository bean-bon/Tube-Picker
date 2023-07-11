//
//  BlacklistedTerms.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 24/05/2023.
//

import Foundation

class BlacklistedStationTermStripper {
    
    private static let blacklistedTerms: [String] = ["ELL", "(London)", "Crossrail", "Underground", "Rail", "DLR", "Station", "(H&C Line)-Underground", " El", "Nll", "(Berks)"]
    
    static let noStationFound: String = "Check Station Board"

    static func removeBlacklistedTerms(input: String) -> String {
        var newStationName = input
        let exceptions = ["Check Station Board", "Battersea Power Station"]
        guard let exemptName = exceptions.first(where: { newStationName.contains($0) })
        else {
            for item in blacklistedTerms {
                newStationName = newStationName.replacingOccurrences(of: item, with: "")
            }
            let ret = newStationName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !ret.isEmpty { return ret }
            else { return noStationFound }
        }
        return exemptName
    }
    
    private init() {}
    
}
