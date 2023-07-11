//
//  PublicHolidayServerResponse.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 10/06/2023.
//

import Foundation

struct PublicHolidayServerResponse: Codable {
    
    let englandAndWales: HolidayDivision
    
    enum CodingKeys: String, CodingKey {
        case englandAndWales = "england-and-wales"
    }
    
}
