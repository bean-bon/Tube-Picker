//
//  Departure.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 15/09/2022.
//

import SwiftUI

struct Departure: View, Hashable, Comparable {
    
    static let `default` = Departure(predictedArrival: PredictedArrival.default)
    var predictedArrival: PredictedArrival
    
    var body: some View {
        
        var platformDisplay: String {
            if predictedArrival.platformName.contains(" - ") {
                return predictedArrival.platformName.components(separatedBy: " - ")[1]
            } else {
                return (predictedArrival.platformName.reduce(0) { $1 == " " ? $0 + 1 : $0 } == 0 ? "Platform " : "") + predictedArrival.platformName
            }
        }
        
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Rectangle()
                        .fill(Line.lookupColour(lineName: predictedArrival.lineName) ?? Color.white)
                        .frame(width: 25, height: 10)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.white, lineWidth: 1)
                        )
                    (Text(predictedArrival.lineName)
                        .font(.headline)
                     + Text(platformDisplay.contains("Unknown") ? "" : " - " + platformDisplay)
                        .font(.subheadline))
                    .fixedSize()
                }
                Text(predictedArrival.getReadableDestinationName() ?? "Check Station Board")
                    .fixedSize()
            }
                        
            let arrivalSeconds = predictedArrival.timeToStation
            let computedMinutes = arrivalSeconds / 60
            let minutesLabel = computedMinutes < 1 ? "Due" :
                (computedMinutes == 1 ? "1 min" : String(computedMinutes) + " mins")
            
            Text(minutesLabel)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
        }
        
    }
    
    static func < (lhs: Departure, rhs: Departure) -> Bool {
        return lhs.predictedArrival < rhs.predictedArrival
    }
    
}

struct Departure_Previews: PreviewProvider {
    static var previews: some View {
        Departure(predictedArrival: PredictedArrival.default)
    }
}
