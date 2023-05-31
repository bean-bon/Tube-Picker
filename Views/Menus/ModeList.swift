//
//  ModeList.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 28/05/2023.
//

import Foundation
import SwiftUI

struct ModeListView: View {
    
    @EnvironmentObject var stationData: StationData
    
    var body: some View {
        List(stationData.stationGroupKeys().sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { mode in
            NavigationLink(StopPointMetaData.modeNameDescription(mode: mode), destination:
                            StationList(stations: stationData.groupedStations[mode]!, mode: mode)
            )
        }.navigationTitle("Station Modes")
    }
    
}
