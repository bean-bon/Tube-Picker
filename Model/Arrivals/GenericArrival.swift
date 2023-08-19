//
//  GenericArrival.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 09/06/2023.
//

import Foundation
import SwiftUI

protocol GenericArrival: Equatable, Hashable {
    
    var stationName: String { get }
    var lineId: String? { get set }
    
    func getReadableStationName() -> String
    func getReadableDestinationName() -> String
    func getMode() -> StopPointMetaData.modeName
    func getPlatformDisplayName() -> String
    
    func getTimeToStationInSeconds() -> Int?
    func isArrivalTimeValid() -> Bool
    func isTimeUntilThisLessThan(seconds: UInt) -> Bool
    
    func getTimeDisplay() -> String
    
}
