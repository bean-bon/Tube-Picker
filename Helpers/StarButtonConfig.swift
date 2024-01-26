//
//  StarButtonConfig.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 03/10/2023.
//

import SwiftUI

struct StarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.yellow)
    }
}
