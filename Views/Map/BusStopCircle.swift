//
//  BusStopCircle.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 30/07/2023.
//

import SwiftUI

struct BusStopCircle: View {
    
    let stopLetter: String
    let rawBearing: String?
    let circleRadius: Double
    let colour: Color = StopPointMetaData.lookupModeColour(.bus)
    
    var body: some View {
        ZStack {
            let bearing: Double? = translateRawBearingToDouble()
            if bearing != nil {
                Triangle()
                    .foregroundStyle(colour)
                    .frame(width: circleRadius / 2, height: circleRadius / 2)
                    .padding(.bottom, circleRadius)
                    .rotationEffect(Angle(degrees: bearing!))
            }
            Circle()
                .foregroundStyle(colour)
                .frame(width: circleRadius, height: circleRadius)
            Text(stopLetter.replacingOccurrences(of: "->", with: ""))
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
    }
    
    func translateRawBearingToDouble() -> Double? {
        switch rawBearing {
        case "N": return 0
        case "NE": return 45
        case "E": return 90
        case "SE": return 135
        case "S": return 180
        case "SW": return 225
        case "W": return 270
        case "NW": return 315
        default: return nil
        }
    }
}
