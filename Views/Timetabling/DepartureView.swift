//
//  DepartureView.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 09/06/2022.
//

import SwiftUI

struct DepartureView: View {
        
    var body: some View {
        arrivalView.getView()
    }
    
}

struct Departure_Previews: PreviewProvider {
    static var previews: some View {
        Departure(predictedArrival: PredictedArrival.default)
    }
}
