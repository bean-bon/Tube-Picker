//
//  ContentView.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 11/09/2022.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var stationData: StationData
    @EnvironmentObject var lineData: LineStatusDataManager
    @State var randomStation: Station = SingleStation.default
    
    var body: some View {
        TabView {
            FavouritesList()
                .environmentObject(stationData)
                .environmentObject(lineData)
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Favourites")
                }
            ModeListView()
                .environmentObject(stationData)
                .environmentObject(lineData)
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
            .tabItem {
                Image(systemName: "line.3.horizontal")
                Text("Index")
            }
        }
        .task(reloadData)
        .refreshable(action: reloadData)
                
    }
    
    @Sendable
    func reloadData() async {
        await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { await DataManager.englishHolidays.downloadAndSaveToDisk() }
            group.addTask {
                await stationData.loadData()
                await updateRandomStation()
            }
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
