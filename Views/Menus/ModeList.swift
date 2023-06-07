//
//  ModeList.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 28/05/2023.
//

import Foundation
import SwiftUI

struct ModeListView: View {
    
    @EnvironmentObject var stationData: StationData
    @State var isRefreshOccurring: Bool = false
    
    @ViewBuilder var body: some View {
        switch stationData.getLoadingState() {
        case .success:
            List(stationData.stationGroupKeys().sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { mode in
                NavigationLink(StopPointMetaData.modeNameDescription(mode: mode), destination:
                                StationList(stations: Set(stationData.groupedStations[mode]!.values), mode: mode)
                )
            }.navigationTitle("Transport Modes")
        case .downloading:
            ProgressView("Downloading station data")
                .progressViewStyle(CircularProgressViewStyle())
                .navigationTitle("")
        case .failure, .empty:
            VStack {
                Text("Unable to download required data.\n")
                    .bold() +
                Text("Please check your Wi-Fi or cellular connection then retry.")
                Button {
                    isRefreshOccurring = true
                    Task {
                        await stationData.loadData()
                        isRefreshOccurring = false
                    }
                } label: {
                    Text("Retry")
                }
                .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
                .foregroundColor(Color.white)
                .background(Color.blue)
                .cornerRadius(5)
                .disabled(isRefreshOccurring)
            }
        }
    }
    
}
