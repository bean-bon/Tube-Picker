//
//  APIHandler.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 15/09/2022.
//

import Foundation

class APIHandler {
    
    /**
     Assuming the data has been retrieved, this function decodes recieved payloads.
     */
    private func decode<T: Decodable>(data: Data) -> T {
            
        do {
            let decoder = JSONDecoder()
            //debugPrint(String(decoding: data, as: UTF8.self))
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Couldn't parse \(T.self): \n\(error)")
        }
        
    }
    
    func lineArrivals(line: String) async -> [LineArrival] {
        
        let url = "https://api.tfl.gov.uk/line/\(line)/arrivals"
        
        let lookup = await genericJsonLookup(url: url)
                
        do {
            let data = try lookup.get()
            return decode(data: data)
        }
        catch {
            print("Unexpected error retrieving line arrivals.")
        }
        
        return [LineArrival]()
        
    }
    
    func predictedArrivals(mode: String, count: Int = 5) async -> [PredictedArrival] {
                
        var url = "https://api.tfl.gov.uk/Mode/\(mode)/Arrivals?count=\(count)"

        // Special case fr the elizabeth line since line arrivals uses "elizabeth", and this
        // uses "elizabeth-line".
        if mode == Line.Mode.elizabeth.rawValue {
            url = "https://api.tfl.gov.uk/Mode/elizabeth-line/Arrivals?count=\(count)"
        }
        // Special case for the overground since line arrivals uses "london-overground", and predicted
        // uses "overground".
        if mode == Line.Mode.overground.rawValue {
            url = "https://api.tfl.gov.uk/Mode/overground/Arrivals?count=10"
        }
        
        print("Using mode \(mode) with url: \(url)")
        
        let lookup = await genericJsonLookup(url: url)
        
        do {
            let data = try lookup.get()
            return decode(data: data)
        }
        catch {
            print("Unexpected error retrieving predicted arrivals.")
        }
        
        return [PredictedArrival]()
        
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

