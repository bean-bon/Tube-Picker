//
//  SharedViews.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 12/08/2023.
//

import SwiftUI

struct LineArrivalRepresentativeMarker: View {
    
    private let colour: Color

    let lineId: String
    let mode: StopPointMetaData.modeName
    
    init(lineId: String, mode: StopPointMetaData.modeName) {
        self.colour = mode == .bus
        ? StopPointMetaData.lookupModeColour(.bus, night: lineId.capitalized.first == "N".first)
        : Line.lookupColour(lineID: lineId)
        self.lineId = lineId
        self.mode = mode
    }
    
    var body: some View {
        ZStack {
            let isBusArrival = mode == .bus
            Rectangle()
                .fill(colour)
                .frame(width: isBusArrival ? 60 : 25, height: isBusArrival ? 30 : 10)
                .cornerRadius(isBusArrival ? 5 : 10)
                .overlay(
                    RoundedRectangle(cornerRadius: isBusArrival ? 5 : 10)
                        .stroke(.white, lineWidth: 1)
                )
            if isBusArrival {
                Text(lineId.capitalized)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
        }
    }
}

struct RepresentativeMarker_Preview: PreviewProvider {
    static var previews: some View {
        VStack {
            LineArrivalRepresentativeMarker(lineId: "122", mode: .bus)
            LineArrivalRepresentativeMarker(lineId: "P1", mode: .bus)
            LineArrivalRepresentativeMarker(lineId: "N1", mode: .bus)
            LineArrivalRepresentativeMarker(lineId: "elizabeth", mode: .elizabeth)
        }
    }
}
