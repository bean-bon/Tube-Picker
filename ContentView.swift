//
//  ContentView.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 11/09/2022.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var stationData: StationData
    @State var randomStation: Station = SingleStation.default
    
    var body: some View {
        TabView {
            FavouritesList()
                .environmentObject(stationData)
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Favourites")
                }
            VStack {
                Text("Map")
            }
            .tabItem {
                Image(systemName: "map")
                Text("Map")
            }
            NavigationView {
                ModeListView()
                    .environmentObject(stationData)
                    .onAppear {
                        updateRandomStation()
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            if stationData.getLoadingState() == .success {
                                NavigationLink(destination: JourneyBoard(station: randomStation)) {
                                    Image(systemName: "questionmark.app")
                                }
                                .navigationTitle(randomStation.getReadableName())
                            }
                        }
                    }
            }
            .tabItem {
                Image(systemName: "line.3.horizontal")
                Text("Index")
            }
        }
        .task {
            await stationData.loadData()
            updateRandomStation()
            await DataManager.englishHolidays.downloadAndSaveToDisk()
        }
        .refreshable {
            await stationData.loadData()
            updateRandomStation()
            await DataManager.englishHolidays.downloadAndSaveToDisk()
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
