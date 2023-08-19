//
//  StringExtensions.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 19/08/2023.
//

import Foundation

extension String? {
    
    func isNullOrEmpty() -> Bool {
        return self == nil || self!.isEmpty
    }
}
