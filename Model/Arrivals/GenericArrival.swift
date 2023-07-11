//
//  GenericArrival.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 09/06/2023.
//

import Foundation
import SwiftUI

protocol GenericArrival {
    
    var lineName: String? { get set }
    
    func getReadableStationName() -> String
    func getReadableDestinationName() -> String
    func getPlatformDisplayName() -> String
    
    func getTimeToStationInSeconds() -> Int?
    func isArrivalTimeValid() -> Bool
    func isTimeUntilThisLessThan(seconds: UInt) -> Bool
    
    func getTimeDisplay() -> String
    
}
