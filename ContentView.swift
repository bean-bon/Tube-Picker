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
    @State var showRoller: Bool = true
    
    var body: some View {
        
        let groups = stationData.stationGroups
        
        NavigationView {
            VStack {
                if stationData.stationGroups.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                if $searchString.wrappedValue.isEmpty {
                    List(groups.keys.sorted(), id: \.self) { line in
                        NavigationLink(line.name) {
                            List(groups[line]!.mappedUnique { $0.getReadableName() }.sorted(), id: \.self) { station in
                                NavigationLink(station.getReadableName(), destination: DepartureBoard(station: station))
                            }
                            .navigationTitle(line.name)
                        }
                        .onAppear {
                            updateRandomStation()
                        }
                    }
                }
                else {
                    List(searchResults.mappedUnique { $0.getReadableName() }.sorted(), id: \.self) { result in
                        NavigationLink(result.getReadableName(), destination: DepartureBoard(station: result))
                    }
                    .navigationTitle("Search Results")
                }
            }
            .navigationTitle("TfL Stations")
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
            if stationData.needsLoad() {
                await stationData.loadData()
            }
        }
        .searchable(text: $searchString)
                
    }
    
    var searchResults: [Station] {
        return stationData.allStations().filter { station in
            station.getReadableName().uppercased().contains($searchString.wrappedValue.uppercased())
        }.unique()
    }
    
    func updateRandomStation() -> Void {
        randomStation = stationData.allStations().randomElement()!
    }
    
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(StationData())
    }
}
