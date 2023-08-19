//
//  LineStatusList.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 24/07/2023.
//

import SwiftUI

struct LineStatusList: View {
    
    @EnvironmentObject private var lineInterface: LineStatusDataManager
    @Environment(\.colorScheme) private var scheme
    
    @State private var favouriteLines: Set<String> = .init()
        
    private static let normalStatus: Int = 10
    private let linePredicate: ((Line) -> Bool)?
    private let showFavouriteButtons: Bool
    private let onlyShowAbnormalStatus: Bool

    init(linePredicate: ((Line) -> Bool)?, onlyShowAbnormalStatus: Bool = false, showFavouriteButtons: Bool = true) {
        self.linePredicate = linePredicate
        self.showFavouriteButtons = showFavouriteButtons
        self.onlyShowAbnormalStatus = onlyShowAbnormalStatus
    }
    
    var body: some View {
        let filteredLines = linePredicate != nil ? Line.lineMap.values.filter(linePredicate!) : Array(Line.lineMap.values)
        let statusRows = filteredLines.map { line in
            LineStatusRow(
                id: line.id,
                name: Line.lookupName(lineID: line.id) ?? "",
                colour: Line.lookupColour(lineID: line.id, darkMode: scheme == .dark),
                showFavouriteButton: showFavouriteButtons
            )
        }
        let displayRows = onlyShowAbnormalStatus ? statusRows.filter { lineInterface.abnormalStatusLines().contains($0.id) } : statusRows
        ForEach(displayRows.sorted(by: { $0.name < $1.name })) { line in
            line.environmentObject(lineInterface)
                .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
}

struct LineStatusRow: View, Identifiable {
    
    @Environment(\.colorScheme) private var colourScheme
    @EnvironmentObject private var lineInterface: LineStatusDataManager

    @State private var isFavouriteLine: Bool = false
    @State var showDistruptionDetail: Bool = false
    
    private var statusDetails: StatusDetails? {
        return lineInterface.statusData.first(where: { $0.id == self.id })?.statusDetails.first
    }
    
    let id: String
    let name: String
    let descriptionColour: Color
    let showFavouriteButton: Bool
    
    fileprivate init(id: String, name: String, colour: Color, showFavouriteButton: Bool) {
        self.id = id
        self.name = name
        self.descriptionColour = colour
        self.showFavouriteButton = showFavouriteButton
    }

    var body: some View {
        
        let label = HStack(alignment: .center) {
            if showFavouriteButton {
                Button(action: {
                    isFavouriteLine.toggle()
                    lineInterface.favourites.setFavourite(lineId: id, value: isFavouriteLine)
                }) {
                    Image(systemName: isFavouriteLine ? "star.fill" : "star")
                        .frame(maxWidth: FavouritesList.iconWidth, maxHeight: FavouritesList.iconWidth)
                }
                .buttonStyle(PlainButtonStyle())
            }
            Text("**\(name)**").foregroundStyle(descriptionColour)
            Text(statusDetails?.statusSeverityDescription ?? (lineInterface.loadingData ? "Loading Status..." : "Unknown Status"))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(translateSeverityToColour(statusMessage: statusDetails?.statusSeverityDescription) ?? (colourScheme == .dark ? .white : .black))
        }
        
        VStack(alignment: .leading) {
            if statusDetails?.disruption != nil {
                DisclosureGroup(isExpanded: $showDistruptionDetail, content: {
                    if statusDetails!.disruption != nil {
                        Text(statusDetails!.disruption!.description ?? "")
                        if statusDetails!.disruption!.additionalInfo != nil {
                            Text("\n**Additional Information:** \(statusDetails!.disruption!.additionalInfo!)")
                        }
                    }
                }, label: { label })
                .animation(.none, value: showDistruptionDetail)
            } else {
                label
            }
        }
        .task {
            isFavouriteLine = lineInterface.favourites.isFavourite(lineId: id)
            await lineInterface.updateStatusData()
        }
    }
    
    private func translateSeverityToColour(statusMessage: String?) -> Color? {
        let colourTuples: [(String, Color)] = [("Good", .green), ("Delays", .orange), ("Reduced", .orange), ("Suspended", .red), ("Closure", .red)]
        return statusMessage != nil
        ? colourTuples.first(where: { statusMessage!.contains($0.0) })?.1
        : nil
    }
    
}
