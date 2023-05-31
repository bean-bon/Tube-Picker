//
//  APIHandler.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 15/09/2022.
//

import Foundation

class APIHandler {
    
    func lineArrivals(line: String) async -> [LineArrival] {
        
        let url = "https://api.tfl.gov.uk/line/\(line)/arrivals"
        
        let lookup = await genericJsonLookup(url: url)
                
        do {
            let data = try lookup.get()
            return DataManager.decodeJson(data: data)
        }
        catch {
            print("Unexpected error retrieving line arrivals.")
        }
        
        return [LineArrival]()
        
    }
    
    func predictedArrivals(mode: StopPointMetaData.modeName, count: Int = 5) async -> [PredictedArrival] {
                
        var url = "https://api.tfl.gov.uk/Mode/\(mode)/Arrivals?count=\(count)"

        // Special case fr the elizabeth line since line arrivals uses "elizabeth", and this
        // uses "elizabeth-line".
        if mode == StopPointMetaData.modeName.elizabeth {
            url = "https://api.tfl.gov.uk/Mode/elizabeth-line/Arrivals?count=\(count)"
        }
        // Special case for the overground since line arrivals uses "london-overground", and predicted
        // uses "overground".
        if mode == StopPointMetaData.modeName.overground {
            url = "https://api.tfl.gov.uk/Mode/overground/Arrivals?count=\(count)"
        }
                
        let lookup = await genericJsonLookup(url: url)
        
        do {
            let data = try lookup.get()
            return DataManager.decodeJson(data: data)
        }
        catch {
            print("Unexpected error retrieving predicted arrivals.")
        }
        
        return []
        
    }
    
    /**
     Given a mode, return the corresponding StopPoints.
     */
    func stopPoints(mode: StopPointMetaData.modeName) async -> Array<StopPoint> {
        
        let modeDescription = StopPointMetaData.modeNameAPIFormat(mode: mode)
        
        let url = "https://api.tfl.gov.uk/StopPoint/Mode/\(modeDescription)"
        let lookup = await genericJsonLookup(url: url)
        
        do {
            let data = try lookup.get()
            let intermediateResponse: StopPointRawResponse = DataManager.decodeJson(data: data)
            return intermediateResponse.stopPoints
        } catch {
            print("Unexpected error thrown while retreiving StopPoints for mode: \(mode)")
        }
        
        return []
        
    }
    
    /**
     Given a StationNaptan, return the arrivals for the corresponding station.
     */
    func naptanStationArrivals(naptanID: String) async -> [PredictedArrival] {
        
        let url = "https://api.tfl.gov.uk/StopPoint/\(naptanID)/Arrivals"
        let lookup = await genericJsonLookup(url: url)
        
        do {
            let data = try lookup.get()
            return DataManager.decodeJson(data: data)
        } catch {
            print("Failed to parse arrivals from StopPoint lookup.")
            return []
        }
            
    }
    
    private func genericJsonLookup(url: String) async -> Result<Data, any Error> {
        
        let task = Task { () -> Data in
            let url = URL(string: url)!
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
        
        let value = await task.result
        return value
        
    }
    
}

