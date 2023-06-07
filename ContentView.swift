//
//  ContentView.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 11/09/2022.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var stationData: StationData
    @State var randomStation: Station = Station.default
    
    var body: some View {
                
        NavigationView {
            ModeListView()
                .environmentObject(stationData)
                .onAppear {
                    updateRandomStation()
                }
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        if stationData.getLoadingState() == .success {
                            NavigationLink(destination: DepartureBoard(station: randomStation)) {
                                Image(systemName: "questionmark.app")
                            }
                            .navigationTitle(randomStation.getReadableName())
                        }
                    }
                }
        }
        .task {
            await stationData.loadData()
            updateRandomStation()
        }
        .refreshable {
            await stationData.loadData()
            updateRandomStation()
        }
                
    }
    
    func updateRandomStation() -> Void {
        if !stationData.allStations.isEmpty {
            randomStation = stationData.allStations.randomElement()!
        }
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(StationData())
    }
}
