//
//  StationGroup.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 11/09/2022.
//

import Foundation
import SwiftUI

/**
 Initialise the station data based on which stations currently have departures.
 This seems flaky as it wouldn't show stations with no departures, but it's not a huge issue at
 the moment.
 */
final class StationData: ObservableObject {
    
    private let apiHandler = APIHandler()
    private var allStationCache: Set<Station> = Set()
    private var stopPointCache: Array<StopPoint> = Array()
    @Published var stationGroups: [Line: Set<Station>] = Dictionary()
    
    func loadStationData() async {
        for line in LineIDs {
            let arrivals = await apiHandler.lineArrivals(line: line.key)
            DispatchQueue.main.async {
                self.parseLineArrivals(data: arrivals)
            }
        }
    }
    
    /**
     Load the StopPoint data either from the TfL API or the local cache (depending on if it exists or not and it's last update).
     The data will be redownloaded if the last cache update was more than 24 hours ago.
     */
    func loadStopPointData() async {
        
        let stopPointFilePath: URL = StopPointMetaData.cachePath
        var cacheFileModificationDate: Date? = getStopPointCacheModificationDate(filePath: stopPointFilePath)
                
        let daySeconds: Double = 60 * 60 * 24
        if  cacheFileModificationDate == nil || !cacheFileModificationDate!.timeIntervalSinceNow.isLess(than: daySeconds) {
            stopPointCache = await apiHandler.stopPoints(mode: StopPointMetaData.modeName.all)
            DataManager.saveAsJsonRepresentation(path: stopPointFilePath, data: stopPointCache)
        } else {
            do {
                let contents = try Data(contentsOf: stopPointFilePath)
                stopPointCache = DataManager.decodeJson(data: contents)
            } catch {
                debugPrint("Failed to parse StopPoint cache file, falling back on API download.")
                stopPointCache = await apiHandler.stopPoints(mode: StopPointMetaData.modeName.all)
            }
        }
        
    }
    
    /**
     To avoid downloading all StopPoints every time the app is accessed, only refresh the cache
     once per 24 hours. Return nil if the file was just created, otherwise the modification date.
     */
    private func getStopPointCacheModificationDate(filePath: URL) -> Date? {
        do {
            if !FileManager.default.fileExists(atPath: filePath.path) {
                FileManager.default.createFile(atPath: filePath.path, contents: nil)
                return nil
            }
            let cacheAttributes = try FileManager().attributesOfItem(atPath: filePath.path)
            return cacheAttributes[FileAttributeKey.modificationDate] as? Date
        } catch {
            fatalError("Could not parse StopPoint cache file: \(error).")
        }
    }
    
    func allStations() -> Set<Station> {
        if stationGroups.isEmpty && allStationCache.isEmpty {
            return Set()
        }
        if allStationCache.isEmpty {
            for group in stationGroups {
                allStationCache = allStationCache.union(group.value)
            }
        }
        return allStationCache
    }
    
    func needsLoad() -> Bool {
        return stationGroups.isEmpty
    }
    
    func lookupMode(stationName: String) -> Line.Mode {
        for stations in stationGroups.values {
            let searchResult = stations.first(where: { $0.name == stationName })
            if searchResult != nil { return searchResult!.mode }
        }
        return Line.Mode.tube
    }
    
    private func parseStopPoints(data: [StopPoint]) -> [StopPointMetaData.modeName: Set<StopPoint>] {
        var stopPointsByModeName: [StopPointMetaData.modeName: Set<StopPoint>] = Dictionary()
        for stopPoint in data {
            for mode in stopPoint.modes {
                let parsedMode: StopPointMetaData.modeName = StopPointMetaData.modeName.init(rawValue: mode) ?? StopPointMetaData.modeName.tube
                stopPointsByModeName[parsedMode]?.formUnion([stopPoint])
            }
        }
        return stopPointsByModeName
    }
    
    private func parseLineArrivals(data: [LineArrival]) {
        if data.isEmpty { return }
        var stations = Set<Station>()
        for arrival in data {
            // Exception for london-overground since this isn't a valid variable name.
            if arrival.lineId == "london-overground" {
                stations.insert(Station(name: arrival.stationName, mode: Line.Mode.overground))
            } else {
                stations.insert(Station(name: arrival.stationName, mode: Line.Mode.init(rawValue: arrival.lineId) ?? Line.Mode.tube))
            }
        }
        stationGroups.updateValue(stations, forKey: LineIDs[data[0].lineId] ?? LineIDs.first!.value)
    }
    
}
