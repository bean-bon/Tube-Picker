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
                HStack {
                    let lineColour = Line.lookupColour(lineID: arrival.lineId)
                    Rectangle()
                        .fill(lineColour)
                        .frame(width: 25, height: 10)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.white, lineWidth: 1)
                        )
                    Text(arrival.getReadableDestinationName())
                        .font(.headline)
                        .fixedSize()
                }
                HStack {
                    let platformDisplay = arrival.getPlatformDisplayName()
                    let initialDisplay = platformDisplay.isEmpty ? "" : "\(platformDisplay): "
                    let fullLineName = Line.lookupName(lineID: arrival.lineId)
                    // 26 characters was found as a good length for using the compact name.
                    Text("\(initialDisplay)\(fullLineName)".count > 26 ? "\(initialDisplay)\(Line.lookupCompactName(lineID: arrival.lineId))" : "\(initialDisplay)\(fullLineName)")
                        .font(.caption)
                        .lineLimit(1)
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
