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
@MainActor
final class StationData: ObservableObject {
    
    @Published var allStations: [Station] = []
    // Second dictionary groups by NaptanID.
    @Published var groupedStations: [StopPointMetaData.modeName: [String: Station]] = Dictionary()
    @Published private var loadingState: AsyncLoadingState = .empty
    
    private let apiHandler = APIHandler()
    private var stopPointCache: Array<StopPoint> = Array()
    
    func loadData() async {
        if !needsLoad() {
            return
        }
        await loadStopPointData()
        updateStationVariables()
        loadingState = self.allStations.isEmpty ? .failure : .success
    }
    
    func getLoadingState() -> AsyncLoadingState {
        return loadingState
    }
    
    func stationGroupKeys() -> [StopPointMetaData.modeName] {
        return Array(groupedStations.keys)
    }

    private func updateStationVariables() {
        parseStationStopPoints()
        groupStationsFromAll()
    }
    
    private func parseStationStopPoints() {
        stopPointCache.filter {
            $0.commonName.contains("Station")
        }.forEach { stopPoint in
            stopPoint.modes.forEach { mode in
                var computedMode: StopPointMetaData.modeName? {
                    return mode == "elizabeth-line"
                    ? StopPointMetaData.modeName.elizabeth
                    : StopPointMetaData.modeName.init(rawValue: mode)
                }
                if computedMode != nil {
                    allStations += [Station(name: BlacklistedStationTermStripper.removeBlacklistedTerms(input: stopPoint.commonName), mode: computedMode!, naptanID: stopPoint.stationNaptan)]
                }
            }
        }
    }
    
    private func groupStationsFromAll() {
        StopPointMetaData.modeName.allCases.forEach { mode in
            allStations.filter {
                $0.mode == mode && $0.naptanID != nil
            }.forEach { station in
                if groupedStations[mode] == nil {
                    groupedStations[mode] = Dictionary()
                }
                if groupedStations[mode]![station.naptanID!] == nil {
                    groupedStations[mode]![station.naptanID!] = station
                }
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
            await downloadAndSaveStopPoints(filePath: stopPointFilePath)
        } else {
            do {
                let contents = try Data(contentsOf: stopPointFilePath)
                stopPointCache = DataManager.decodeJson(data: contents) ?? []
                var attempts = 0
                debugPrint("Parsing cache file returned an empty value, attempting to redownload data...")
                while stopPointCache.isEmpty && attempts < 5 {
                    debugPrint("Attempt \(attempts + 1)/5...")
                    await downloadAndSaveStopPoints(filePath: stopPointFilePath)
                    attempts += 1
                }
            } catch {
                debugPrint("Failed to parse StopPoint cache data, falling back on API download.")
                await downloadAndSaveStopPoints(filePath: stopPointFilePath)
            }
        }
        
    }
    
    private func downloadAndSaveStopPoints(filePath: URL) async {
        loadingState = .downloading
        for line in Line.lineMap {
            stopPointCache.append(contentsOf: await apiHandler.stopPointsByLineID(line: line.value))
        }
        loadingState = stopPointCache.isEmpty ? .failure : .success
        if loadingState == .success {
            DataManager.saveAsJsonRepresentation(path: filePath, data: stopPointCache)
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
