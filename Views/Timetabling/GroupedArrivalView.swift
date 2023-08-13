//
//  GroupedArrivalView.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 12/08/2023.
//

import SwiftUI

struct GroupedArrivalView: View {
    
    let destination: String
    let lineId: String
    let mode: StopPointMetaData.modeName
    let times: [String]
    
    init(destination: String, lineId: String, mode: StopPointMetaData.modeName, times: [String]) {
        self.destination = destination
        self.lineId = lineId
        self.mode = mode
        self.times = times.count > 4 ? Array(times[..<5]) : times
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                LineArrivalRepresentativeMarker(lineId: lineId, mode: mode)
                Text(destination)
                    .font(.headline)
                    .lineLimit(2)
                if !times.isEmpty {
                    VStack(alignment: .trailing) {
                        Text(times.first!)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                            .lineLimit(1)
                        if times.count > 1 {
                            let timesString = String(times
                                .dropFirst()
                                .joined(separator: ", ")
                                .replacingOccurrences(of: " mins", with: "")
                                .replacingOccurrences(of: " min", with: ""))
                            let suffix: String = timesString.last != nil && String(timesString.last!) == "1"
                            ? "min"
                            : "mins"
                            Text("\(timesString) \(suffix)")
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }
}
