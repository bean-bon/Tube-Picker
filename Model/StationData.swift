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
    private var stopPointCache: Array<StopPoint> = Array()
    @Published var allStations: [Station] = []
    @Published var groupedStations: [StopPointMetaData.modeName: Set<Station>] = Dictionary()
    
    func loadData() async {
        if !needsLoad() {
            return
        }
        await loadStopPointData()
        DispatchQueue.main.async {
            self.updateStationVariables()
        }
    }
    
    func stationGroupKeys() -> [StopPointMetaData.modeName] {
        return Array(groupedStations.keys)
    }
    
    private func updateStationVariables() {
        stopPointCache.filter {
            $0.commonName.contains("Station")
        }.forEach { stopPoint in
            stopPoint.modes.forEach { mode in
                let computedMode: StopPointMetaData.modeName = {
                    return mode == "elizabeth-line"
                    ? StopPointMetaData.modeName.elizabeth
                    : StopPointMetaData.modeName.init(rawValue: mode) ?? StopPointMetaData.modeName.tube
                }()
                allStations.insert(Station(name: stopPoint.commonName, mode: computedMode, naptanID: stopPoint.stationNaptan), at: 0)
            }
        }
        allStations.forEach { station in
            let current = groupedStations[station.mode]
            if current == nil {
                groupedStations[station.mode] = [station]
            } else {
                groupedStations[station.mode]!.formUnion([station])
            }
        }
    }
    
    /**
     Load the StopPoint data either from the TfL API or the local cache (depending on if it exists or not and it's last update).
     The data will be redownloaded if the last cache update was more than 24 hours ago.
     */
    private func loadStopPointData() async {
        
        let stopPointFilePath: URL = StopPointMetaData.cachePath
        let cacheFileModificationDate: Date? = getStopPointCacheModificationDate(filePath: stopPointFilePath)
                
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
    
    private func needsLoad() -> Bool {
        return allStations.isEmpty
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
    
}
