//
//  Arrival.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 09/06/2023.
//

import SwiftUI

/**
 An arrival may be either timetabled or based on predictions
 from TfL.
 */
struct ArrivalView: View {
    
    let arrival: any GenericArrival
    
    var body: some View {
        
        HStack {
            VStack(alignment: .leading) {
                let tryTubeArrivalCast = arrival as? BusTubePrediction
                HStack {
                    LineArrivalRepresentativeMarker(lineId: arrival.lineId ?? "",
                                                    mode: tryTubeArrivalCast?.modeName ?? .unknown)
                    Text(arrival.getReadableDestinationName().capitalized)
                        .font(.headline)
                        .fixedSize()
                }
                HStack {
                    if tryTubeArrivalCast?.modeName != .bus {
                        let platformDisplay = arrival.getPlatformDisplayName()
                        let initialDisplay = platformDisplay.isEmpty ? "" : "\(platformDisplay): "
                        let fullLineName = Line.lookupName(lineID: arrival.lineId)
                        // 26 characters was found as a good length for using the compact name.
                        Text("\(initialDisplay)\(fullLineName)".count > 26 ? "\(initialDisplay)\(Line.lookupCompactName(lineID: arrival.lineId))" : "\(initialDisplay)\(fullLineName)")
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }

            Text("**\(arrival.getTimeDisplay())**")
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(arrival.getTimeDisplay().contains(":")
                                 ? Color.primary
                                 : Color.green)
            
        }
        
    }
    
}
