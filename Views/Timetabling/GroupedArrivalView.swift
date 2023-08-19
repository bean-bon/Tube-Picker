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
    let platform: String?
    let mode: StopPointMetaData.modeName
    let times: [String]
    
    init(destination: String, lineId: String, mode: StopPointMetaData.modeName, platform: String? = nil, times: [String]) {
        self.destination = destination
        self.lineId = lineId
        self.platform = platform
        self.mode = mode
        self.times = times.count > 2 ? Array(times[..<3]) : times
    }
        
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        LineArrivalRepresentativeMarker(lineId: lineId, mode: mode)
                        Text(destination)
                            .font(.headline)
                            .lineLimit(2)
                    }
                    if mode != .bus {
                        let initialDisplay = platform == nil ? "" : "\(platform!): "
                        let fullLineName = Line.lookupName(lineID: lineId) ?? ""
                        // 26 characters was found as a good length for using the compact name.
                        Text("\(initialDisplay)\(fullLineName)".count > 26 ? "\(initialDisplay)\(Line.lookupCompactName(lineID: lineId))" : "\(initialDisplay)\(fullLineName)")
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .trailing) {
                    if !times.isEmpty {
                        Text(times.first!)
                            .fontWeight(.semibold)
                            .foregroundStyle(times.first!.contains(":") ? .white : .green)
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
                            Text("\(timesString)\(timesString.contains(":") ? "" : " \(suffix)")")
                                .lineLimit(1)
                        }
                    } else {
                        Text("Not due")
                    }
                }
            }
        }
    }
}

