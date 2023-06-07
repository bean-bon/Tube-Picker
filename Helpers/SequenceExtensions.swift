//
//  SequenceExtensions.swift
//  Tube Picker
//
//  Created by Benjamin Groom on 05/04/2023.
//

import Foundation

extension Sequence where Iterator.Element: Hashable {
    /**
     Filter the sequence to be unique.
     */
    func unique() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
    
}
