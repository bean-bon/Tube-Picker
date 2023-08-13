//
//  StationGroup.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 11/09/2022.
//

import Foundation
import SwiftUI
import MapKit

/**
 Initialise the station data based on which stations currently have departures.
 This seems flaky as it wouldn't show stations with no departures, but it's not a huge issue at
 the moment.
 */
@MainActor
final class StationData: ObservableObject {
        
    @Published var allStations: [SingleStation] = []
    @Published var mergedStations: [any Station] = []
    // Second dictionary groups by NaptanID.
    @Published var groupedStations: [StopPointMetaData.modeName: [String: SingleStation]] = Dictionary()
    @Published private var loadingState: AsyncLoadingState = .empty
    
    private var stopPointCache: Array<StopPoint> = Array()
    private var coordinateCache: [String: CLLocationCoordinate2D] = .init()
    
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
    
    func lookupCoordinates(naptanId: String) -> CLLocationCoordinate2D? {
        return coordinateCache[naptanId]
    }
    
    func stationGroupKeys() -> [StopPointMetaData.modeName] {
        return Array(groupedStations.keys)
    }

    private func updateStationVariables() {
        parseStationStopPoints()
        groupStationsFromAll()
    }
    
    private func parseStationStopPoints() {
        stopPointCache.forEach { stopPoint in
            stopPoint.modes.forEach { mode in
                let coordinates = CLLocationCoordinate2D(
                    latitude: CLLocationDegrees(floatLiteral: stopPoint.lat),
                    longitude: CLLocationDegrees(floatLiteral: stopPoint.lon)
                )
                if StopPointMetaData.stationModesNames.contains(mode) {
                    allStations.append(SingleStation(name: BlacklistedStationTermStripper.sanitiseStationName(input: stopPoint.commonName), lines: Set(stopPoint.lines.filter { Line.lineMap.keys.contains($0.id) }.map { $0.id }), mode: mode, naptanID: stopPoint.naptanId, lat: coordinates.latitude, lon: coordinates.longitude))
                }
                coordinateCache[stopPoint.naptanId] = coordinates
            }
        }
    }
    
    private func groupStationsFromAll() {
        groupedStations = Dictionary()
        allStations.forEach { station in
            let mode = station.mode
            if groupedStations[mode] == nil {
                groupedStations[mode] = Dictionary()
            }
            groupedStations[mode]![station.naptanID] = station
        }
        mergedStations = Dictionary(grouping: allStations, by: { $0.name.replacingOccurrences(of: "'", with: "") }).map {
            if $0.value.count != 1 {
                let comboStation = CombinationNaptanStation(name: $0.value.first!.name, singleStations: $0.value)
                coordinateCache[comboStation.getNaptanString()] = CLLocationCoordinate2D(latitude: comboStation.lat, longitude: comboStation.lon)
                return comboStation
            } else {
                return $0.value.first!
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
                while stopPointCache.isEmpty && attempts < 5 {
                    debugPrint("Attempt \(attempts + 1)/5 to redownload StopPoint data...")
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
            let stations = await APIHandler.shared.stopPointsByLineID(line: line.value)
            stopPointCache.append(contentsOf: stations)
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
    
}
