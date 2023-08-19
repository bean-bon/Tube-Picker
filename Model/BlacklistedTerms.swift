//
//  BlacklistedTerms.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 24/05/2023.
//

import Foundation

class BlacklistedStationTermStripper {
    
    
    
    static let noStationFound: String = "Check Station Board"
    static let noBusDestinationFound: String = "Check front of Bus"

    static func sanitiseStationName(input: String) -> String {
        let exceptions = ["Check Station Board", "London Bridge", "London Fields", "London City Airport", "Battersea Power Station", "Nine Elms", "Bromley-by-Bow"]
        let blacklistedTerms: [String] = ["ELL", "(London)", "London", "Crossrail", "Underground", "Rail", "DLR", "Station", "(H&C Line)-Underground", " El", "Nll", "(Berks)", "(H&C Line)", "(for ExCel)", "-"]
        return sanitise(input: input, blacklisted: blacklistedTerms, exceptions: exceptions, noneFound: noStationFound)
    }
    
    static func sanitiseBusStopName(input: String) -> String {
        let blacklistedTerms = ["Woolwich Common "]
        return sanitise(input: input, blacklisted: blacklistedTerms, exceptions: [], noneFound: noBusDestinationFound)
    }
    
    private static func sanitise(input: String, blacklisted: [String], exceptions: [String], noneFound: String) -> String {
        var newStationName = input
        guard let exemptName = exceptions.first(where: { newStationName.contains($0) })
        else {
            for item in blacklisted {
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
