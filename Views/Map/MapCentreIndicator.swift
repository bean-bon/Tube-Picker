//
//  MapCentreIndicator.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 02/08/2023.
//

import SwiftUI

struct MapCentreIndicator: View {
    var body: some View {
        ZStack(alignment: .top) {
            ForEach(0...4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 5)
                    .foregroundStyle(.orange)
                    .frame(width: 5, height: 40)
                    .rotationEffect(Angle(degrees: 360 / Double(i)))
            }
        }
    }
}
