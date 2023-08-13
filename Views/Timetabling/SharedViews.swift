//
//  SharedViews.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 12/08/2023.
//

import SwiftUI

struct LineArrivalRepresentativeMarker: View {
    
    let lineId: String
    let mode: StopPointMetaData.modeName
    
    var body: some View {
        ZStack {
            let isBusArrival = mode == .bus
            let colour = isBusArrival ? StopPointMetaData.lookupModeColour(.bus) : Line.lookupColour(lineID: lineId)
            Rectangle()
                .fill(colour)
                .frame(width: isBusArrival ? 60 : 25, height: isBusArrival ? 30 : 10)
                .cornerRadius(isBusArrival ? 5 : 10)
                .overlay(
                    RoundedRectangle(cornerRadius: isBusArrival ? 5 : 10)
                        .stroke(.white, lineWidth: 1)
                )
            if isBusArrival {
                Text(lineId)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
        }
    }
}
