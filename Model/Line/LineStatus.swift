//
//  LineStatus.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 24/07/2023.
//

import Foundation

@MainActor
class LineStatusDataManager: ObservableObject {
    
    @Published var favourites = FavouritesInterface.lines
    
    @Published var statusData: [LineStatus] = []
    @Published var loadingData: Bool = false
    private var lastUpdated: Date? = nil
    
    private var currentTask: Task<[LineStatus], any Error>?
        
    init() {}
    
    private func statusDataLoadTask() -> Task<[LineStatus], any Error> {
        return Task {
            self.loadingData = true
            let data = await APIHandler.shared.allLineStatus()
            self.lastUpdated = Date()
            self.loadingData = false
            self.currentTask = nil
            return data
        }
    }
    
    private func needsLoad() -> Bool {
        if statusData.isEmpty || currentTask != nil || lastUpdated == nil {
            return true
        }
        let dateComponents = Calendar.current.dateComponents([.minute], from: lastUpdated!, to: Date())
        return dateComponents.minute! > 5
    }
    
    func abnormalStatusLines() -> Set<String> {
        return Set(statusData.filter { $0.statusDetails.first?.statusSeverity != 10 }.map { $0.id })
    }
    
    func updateStatusData() async {
        if needsLoad() && NetworkMonitor.shared.connected {
            do {
                if currentTask == nil {
                    currentTask = statusDataLoadTask()
                }
                guard let taskValue = try await currentTask?.value else { return }
                statusData = taskValue
            } catch {
                print("Error thrown retrieving line status: \(error)")
            }
        }
    }
    
}

struct LineStatus: Decodable, Identifiable, Equatable {
    
    let id: String
    let mode: StopPointMetaData.modeName
    let statusDetails: [StatusDetails]
    
    enum CodingKeys: String, CodingKey {
        case id
        case mode = "modeName"
        case statusDetails = "lineStatuses"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        let rawMode = try container.decode(String.self, forKey: .mode)
        self.mode = StopPointMetaData.modeName.init(rawValue: rawMode) ?? .unknown
        self.statusDetails = try container.decode([StatusDetails].self, forKey: .statusDetails)
    }
    
}

struct StatusDetails: Decodable, Equatable {
    
    let lineId: String?
    let statusSeverity: Int
    let statusSeverityDescription: String
    let reason: String?
    let validityPeriods: [ValidityPeriod]
    let disruption: Disruption?
    
}

struct ValidityPeriod: Decodable, Equatable {
    
    let fromDate: Date
    let toDate: Date
    let isNow: Bool
    
    enum CodingKeys: CodingKey {
        case fromDate
        case toDate
        case isNow
    }
    
    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<ValidityPeriod.CodingKeys> = try decoder.container(keyedBy: ValidityPeriod.CodingKeys.self)
        let dateDecoder = ISO8601DateFormatter()
        self.fromDate = dateDecoder.date(from: try container.decode(String.self, forKey: ValidityPeriod.CodingKeys.fromDate)) ?? Date.distantPast
        self.toDate = dateDecoder.date(from: try container.decode(String.self, forKey: ValidityPeriod.CodingKeys.toDate)) ?? Date.distantFuture
        self.isNow = try container.decode(Bool.self, forKey: ValidityPeriod.CodingKeys.isNow)
    }
    
}

struct Disruption: Decodable, Equatable {
    
    let category: String?
    let description: String?
    let additionalInfo: String?
    let closureText: String?
    
}
