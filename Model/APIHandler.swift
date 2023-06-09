//
//  APIHandler.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 15/09/2022.
//

import Foundation

enum AsyncLoadingState {
    case empty
    case success
    case downloading
    case failure
}

class APIHandler {
    
    func lineArrivals(line: String) async -> [LineArrival] {
        let url = "https://api.tfl.gov.uk/line/\(line)/arrivals"
        return await lookupAndDecodeJson(url: url, decodeErrorMessage: "Unexpected error retrieving line arrivals.") ?? []
    }
    
    func predictedArrivals(mode: StopPointMetaData.modeName, count: Int = 5) async -> [PredictedArrival] {
        
        let url = {
            switch mode {
            case StopPointMetaData.modeName.elizabeth:
                return "https://api.tfl.gov.uk/Mode/elizabeth-line/Arrivals?count=\(count)"
            case StopPointMetaData.modeName.overground:
                return "https://api.tfl.gov.uk/Mode/overground/Arrivals?count=\(count)"
            default:
                return "https://api.tfl.gov.uk/Mode/\(mode)/Arrivals?count=\(count)"
            }
        }()
                
        return await lookupAndDecodeJson(url: url, decodeErrorMessage: "Unexpected error retrieving predicted arrivals.") ?? []
        
    }
    
    /**
     Given a mode, return the corresponding StopPoints.
     This method seems to have a long response time so using stopPointsByLineID() is preferred.
     */
    func stopPoints(mode: StopPointMetaData.modeName) async -> Array<StopPoint> {
        
        let modeDescription = StopPointMetaData.modeNameAPIFormat(mode: mode)
        
        let url = "https://api.tfl.gov.uk/StopPoint/Mode/\(modeDescription)"
        let stopPointResponse: StopPointRawResponse? = await lookupAndDecodeJson(url: url, decodeErrorMessage: "Failed to decode StopPoints for mode: \(mode)")
        return stopPointResponse?.stopPoints ?? []
        
    }
    
    /**
     Given a Line ID, return the corresponding StopPoints.
     */
    func stopPointsByLineID(line: Line) async -> Array<StopPoint> {
        
        let url = "https://api.tfl.gov.uk/Line/\(line.id)/StopPoints"
        return await lookupAndDecodeJson(url: url, decodeErrorMessage: "Unexpected error thrown while retreiving StopPoints for line: \(line)") ?? Array()
        
    }
    
    /**
     Given a station NaptanID and its corresponding line, return the appropriate timetable.
     */
    func timetableGivenNaptanIDs(lineID: String, to: String, from: String) async -> TimetableResponse? {
        
        let url = "https://api.digital.tfl.gov.uk/Line/\(lineID)/Timetable/\(to)/to/\(from)"
        return await lookupAndDecodeJson(url: url, decodeErrorMessage: "Failed to parse a timetable response.")

    }
    
    /**
     Given a StationNaptan, return the arrivals for the corresponding station.
     */
    func naptanStationArrivals(naptanID: String) async -> [PredictedArrival] {
        
        let url = "https://api.tfl.gov.uk/StopPoint/\(naptanID)/Arrivals"
        return await lookupAndDecodeJson(url: url, decodeErrorMessage: "Failed to parse arrivals from StopPoint lookup.") ?? []

    }
    
    private func lookupAndDecodeJson<T: Decodable>(url: String, decodeErrorMessage: String?) async -> T? {
        let lookup = await genericJsonLookup(url: url)
        return await genericJsonDecode(lookup: lookup, errorMessage: decodeErrorMessage)
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
    
    private func genericJsonDecode<T: Decodable>(lookup: Result<Data, any Error>, errorMessage: String?) async -> T? {
        do {
            let data = try lookup.get()
            return DataManager.decodeJson(data: data) ?? nil
        } catch {
            debugPrint(errorMessage ?? "Failed to decode data.")
            return nil
        }
    }
    
}

