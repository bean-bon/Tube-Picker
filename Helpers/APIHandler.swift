//
//  APIHandler.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 15/09/2022.
//

import Foundation
import MapKit

enum AsyncLoadingState {
    case empty
    case success
    case downloading
    case failure
}

class APIHandler {
    
    static let shared = APIHandler()
    
    private init() {}
    
    private func tflRelayURL(_ uri: String) -> String {
        return "https://tubepicker.fly.dev/tfl?uri=\(uri)"
    }
    
    private func tflURL(_ uri: String) -> String {
        return "https://api.tfl.gov.uk/\(uri)"
    }
    
    private func timetableURL(stopName: String, mode: String) -> String {
        return "https://tubepicker.fly.dev/timetable?stopName=\(stopName)&mode=\(mode)"
    }
    
    func lineArrivals(line: String) async -> [LineArrival] {
        let url = tflRelayURL("line/\(line)/arrivals")
        return await lookupAndDecodeJson(url: url, decodeErrorMessage: "Unexpected error retrieving line arrivals.") ?? []
    }
    
    func allLineStatus() async -> [LineStatus] {
        let url = tflRelayURL("Line/Mode/\(StopPointMetaData.modeNameAPIFormat(mode: .allMetro))/Status")
        return await lookupAndDecodeJson(url: url, decodeErrorMessage: "Unexpected error decoding TfL Line statuses.") ?? []
    }
    
    func busStopsInRadius(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Int = 200) async -> [BusStop] {
        let url = tflURL("StopPoint?stopTypes=NaptanPublicBusCoachTram&lat=\(latitude)&lon=\(longitude)&radius=\(radius)")
        let stopPointsResponse: StopPointRawResponse? = await lookupAndDecodeJson(url: url, decodeErrorMessage: "Failed to decode bus SopPoints.")
        return stopPointsResponse?.stopPoints.map {
            return BusStop(
                name: $0.commonName,
                stopIndicator: $0.stopLetter ?? "",
                naptanId: $0.naptanId,
                lines: Set($0.lines.map { line in line.id }),
                bearing: $0.additionalProperties?.first(where: { p in p.key == .CompassPoint })?.value,
                lat: $0.lat,
                lon: $0.lon,
                towards: $0.additionalProperties?.first(where: { p in p.key == .Towards })?.value ?? ""
            )
        } ?? []
    }
        
    func predictedArrivals(mode: StopPointMetaData.modeName, count: Int = 5) async -> [BusTubePrediction] {
        
        let url = {
            switch mode {
            case StopPointMetaData.modeName.elizabeth:
                return tflRelayURL("Mode/elizabeth-line/Arrivals?count=\(count)")
            case StopPointMetaData.modeName.overground:
                return tflRelayURL("Mode/overground/Arrivals?count=\(count)")
            default:
                return tflRelayURL("Mode/\(mode)/Arrivals?count=\(count)")
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
        let url = tflRelayURL("StopPoint/Mode/\(modeDescription)")
        let stopPointResponse: StopPointRawResponse? = await lookupAndDecodeJson(url: url, decodeErrorMessage: "Failed to decode StopPoints for mode: \(mode)")
        return stopPointResponse?.stopPoints ?? []
        
    }
    
    /**
     Given a Line ID, return the corresponding StopPoints.
     */
    func stopPointsByLineID(line: Line) async -> Array<StopPoint> {
        let url = tflRelayURL("Line/\(line.id)/StopPoints")
        return await lookupAndDecodeJson(url: url, decodeErrorMessage: "Unexpected error thrown while retreiving StopPoints for line: \(line)") ?? Array()
    }
    
    /**
     Given a LineID, return the corresponding route/s.
     */
    func lineRoute(lineID: String) async -> RouteResponse? {
        let url = tflRelayURL("Line/\(lineID)/Route")
        return await lookupAndDecodeJson(url: url, decodeErrorMessage: "Could not parse line route for id: \(lineID)")
    }
    
    /**
     Given a StopPoint, return the routes served.
     */
    func busStopRoute(stopID: String) async -> [BusStopRoute] {
        let url = tflRelayURL("StopPoint/\(stopID)/Route")
        return await lookupAndDecodeJson(url: url, decodeErrorMessage: "Could not parse line route for id: \(stopID)") ?? []
    }
    
    /**
     Given a station NaptanID and its corresponding line, return the appropriate timetable.
     Note: this method will only work for DLR and the underground.
     */
    func tubeDlrTimetables(lineId: String, fromNaptan: String) async -> TwoWayTimetableResponse {
        let inboundUrl = tflRelayURL("Line/\(lineId)/Timetable/\(fromNaptan)?direction=inbound")
        let outboundUrl = tflRelayURL("Line/\(lineId)/Timetable/\(fromNaptan)?direction=outbound")
        return TwoWayTimetableResponse(inbound: await lookupAndDecodeJson(url: inboundUrl, decodeErrorMessage: "Could not lookup/decode inbound timetable data"),
                                       outbound: await lookupAndDecodeJson(url: outboundUrl, decodeErrorMessage: "Could not lookup/decode outbound timetable data"))
    }
    
    /**
     Given a station's NaptanID, return the Elizabeth line/Overground departures for
     the corresponding station.
     */
    func naptanArrivalDepartures(naptanID: String, mode: StopPointMetaData.modeName) async -> [ArrivalDeparture] {
        var modeString = ""
        switch mode {
        case .elizabeth: modeString = "elizabeth"
        case .overground: modeString = "london-overground"
        default: return []
        }
        let url = tflRelayURL("StopPoint/\(naptanID)/ArrivalDepartures?lineIds=\(modeString)")
        guard let data: [ArrivalDeparture]? = await lookupAndDecodeJson(url: url, decodeErrorMessage: "Failed to decode ArrivalDepartures from url: \(url)")
        else { return [] }
        return data!.map {
            var newArrivalDeparture = $0
            newArrivalDeparture.lineId = modeString
            return newArrivalDeparture
        }
    }
    
    /**
     Given a StationNaptan, return the tube/DLR arrivals for the corresponding station.
     */
    func naptanTubeArrivals(naptanID: String) async -> [BusTubePrediction] {
        let url = tflRelayURL("StopPoint/\(naptanID)/Arrivals")
        return await lookupAndDecodeJson(url: url, decodeErrorMessage: "Failed to parse arrivals from StopPoint lookup.") ?? []
    }
    
    func getEnglishHolidays() async -> HolidayDivision? {
        let url = "https://www.gov.uk/bank-holidays.json"
        let lookup = await genericDataLookup(url: url)
        let serverResponse: PublicHolidayServerResponse? = genericJsonDecode(lookup: lookup, errorMessage: "Could not decode public holidays.")
        return serverResponse?.englandAndWales
    }
    
    private func lookupAndDecodeJson<T: Decodable>(url: String, decodeErrorMessage: String?) async -> T? {
        let lookup = await genericDataLookup(url: url)
        return genericJsonDecode(lookup: lookup, errorMessage: decodeErrorMessage)
    }
    
    private func genericDataLookup(url: String) async -> Result<Data, any Error> {
        
        let task = Task { () -> Data in
            print(url)
            let url = URL(string: url)!
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        }
        
        let value = await task.result
        return value
        
    }
    
    private func genericJsonDecode<T: Decodable>(lookup: Result<Data, any Error>, errorMessage: String?) -> T? {
        do {
            let data = try lookup.get()
            return DataManager.decodeJson(data: data) ?? nil
        } catch {
            print(errorMessage ?? "Failed to decode data.")
            return nil
        }
    }
    
}

