//
//  StopPointList.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 28/05/2023.
//

import Foundation
import SwiftUI

struct StationList: View {
    
    let stations: Set<Station>
    let mode: StopPointMetaData.modeName
    
    var body: some View {
        List(stations.sorted(), id: \.self) { station in
            NavigationLink(station.getReadableName(), destination: DepartureBoard(station: station))
        }.navigationTitle(StopPointMetaData.modeNameDescription(mode: mode))
    }
    
}
