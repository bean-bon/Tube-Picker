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
    /**
     Filter the sequence to be unique based on a mapping of those elements.
     */
    func mappedUnique<T: Hashable>(mapFunction: (Self.Element) -> T) -> [Iterator.Element] {
        var seen: Set<T> = []
        return filter { seen.insert(mapFunction($0)).inserted }
    }
}
