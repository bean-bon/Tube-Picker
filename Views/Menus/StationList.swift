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
        
    @State var searchString: String = ""
    
    var body: some View {
        List(searchResults.sorted(), id: \.self) { station in
            NavigationLink(station.name, destination: JourneyBoard(station: station))
        }
        .navigationTitle(StopPointMetaData.modeNameDescription(mode: mode))
        .searchable(text: $searchString)
        .autocorrectionDisabled(true)
    }
    
    var searchResults: Set<Station> {
        if searchString.isEmpty {
            return stations
        } else {
            return stations.filter { station in
                station.name.uppercased().contains(searchString.uppercased())
            }
        }
    }
    
}
