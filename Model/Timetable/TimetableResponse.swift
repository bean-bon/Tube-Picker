//
//  TimetableResponse.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 09/06/2023.
//

import Foundation

struct TimetableResponse: Codable {
    
    let stops: [TimetabledStop]
    let timetable: Timetable
    
}
