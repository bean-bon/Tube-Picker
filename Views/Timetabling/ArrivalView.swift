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
        
        var platformDisplay: String {
            let platformName = arrival.getPlatformDisplayName()
            if platformName.isEmpty {
                return ""
            } else if arrival.getPlatformDisplayName().contains(" - ") {
                return platformName.components(separatedBy: " - ")[1]
            } else {
                return (platformName.reduce(0) { $1 == " " ? $0 + 1 : $0 } == 0 ? "Platform " : "") + platformName
            }
        }
        
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Rectangle()
                        .fill(Line.lookupColour(lineName: arrival.lineName) ?? Color.white)
                        .frame(width: 25, height: 10)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.white, lineWidth: 1)
                        )
                    (Text(translateLineName())
                        .font(.headline)
                     + Text(arrival.getPlatformDisplayName())
                        .font(.subheadline))
                    .fixedSize()
                }
                Text(arrival.getReadableDestinationName())
                    .fixedSize()
            }

            Text("**\(arrival.getTimeDisplay())**")
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundColor(arrival.getTimeDisplay().contains(":")
                                 ? Color.primary
                                 : Color.green)
            
        }
        
    }
    
    /**
     Function specifically for Darwin timetable data: incomplete line names are filled in.
     */
    func translateLineName() -> String {
        switch arrival.lineName {
        case "london-overground": return Line.lineMap["london-overground"]!.name
        case "overground": return Line.lineMap["london-overground"]!.name
        case "elizabeth": return Line.lineMap["elizabeth"]!.name
        default: return arrival.lineName ?? ""
        }
    }
    
}
