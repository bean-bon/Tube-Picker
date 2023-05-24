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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(stationData)
        }
    }
}
