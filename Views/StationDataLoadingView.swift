//
//  StationDataLoadingView.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 28/07/2023.
//

import Foundation
import SwiftUI

struct StationDataLoadingView<T: View>: View {
    
    @EnvironmentObject private var stationData: StationData
    @State var isRefreshOccurring: Bool = false
    private let successView: T
    
    init(@ViewBuilder successView: () -> T) {
        self.successView = successView()
    }
    
    var body: some View {
        switch stationData.getLoadingState() {
        case .success:
            successView
        case .downloading:
            ProgressView("Downloading station data")
                .progressViewStyle(CircularProgressViewStyle())
                .navigationTitle("")
        case .failure:
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
        default:
            EmptyView()
        }
    }
    
}
