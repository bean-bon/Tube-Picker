//
//  RouteResponse.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 10/06/2023.
//

import Foundation

struct RouteResponse: Codable {
    
    let id: String
    let routeSections: [RouteSummary]
    
    struct RouteSummary: Codable {
        
        let originationName: String
        let destinationName: String
        let originator: String // NaptanID.
        let destination: String // NaptanID.
        
    }
    
}
