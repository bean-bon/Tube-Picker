//
//  DepartureBoard.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 15/09/2022.
//

import SwiftUI

struct DepartureBoard: View {
    
    let api = APIHandler()
    
    var station: Station
    var overrideMode: Line.Mode?
    
    @State var departures: [Departure] = [Departure]()
    
    var body: some View {
        VStack {
            if departures.isEmpty {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                List(departures.sorted(), id: \.self) { departure in
                    departure
                        .padding(.top, 4)
                        .padding(.bottom, 4)
                }
            }
        }
        .navigationTitle(station.getReadableName())
        .refreshable {
            await reload()
        }
        .task {
            await reload()
        }
    }
    
    func reload() async {
        let data = await api.predictedArrivals(mode: overrideMode?.rawValue ?? station.mode.rawValue, count: 10)
        departures = data.filter {
            station.name == $0.stationName && $0.timeToStation < 3600
        }
        .map {
            Departure(predictedArrival: $0)
        }
    }
}

struct DepartureBoard_Previews: PreviewProvider {
    static var previews: some View {
        DepartureBoard(station: Station.default)
    }
}
