//
//  Tube_PickerApp.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 11/09/2022.
//

import SwiftUI

@main
struct Tube_PickerApp: App {
    
    @StateObject private var stationData = StationData()
    @StateObject private var lineData = LineStatusDataManager()
    @StateObject private var locationManager = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stationData)
                .environmentObject(locationManager)
                .environmentObject(lineData)
                .task {
                    NetworkMonitor.shared.registerConnectedCallback(callback: {
                        await lineData.updateStatusData()
                    })
                    await NetworkMonitor.shared.startMonitoring()
                }
        }
    }
}
