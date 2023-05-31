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
    @State var searchString: String = ""
    
    var body: some View {
                
        NavigationView {
            VStack {
                ModeListView()
                    .environmentObject(stationData)
            }
            .onAppear {
                updateRandomStation()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: DepartureBoard(station: randomStation)) {
                        Image(systemName: "questionmark.app")
                    }
                    .navigationTitle(randomStation.getReadableName())
                }
            }
        }
        .task {
            await stationData.loadData()
            updateRandomStation()
        }
                
    }
    
    var searchResults: [Station] {
        return stationData.allStations.mappedUnique {
            $0.getReadableName().uppercased()
        }.filter { station in
            station.getReadableName().uppercased().contains(searchString.uppercased())
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
