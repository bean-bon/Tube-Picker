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

extension Sequence {
    
    /**
     Intended for objects with hashable elements, but cannot be hashable for whatever reason.
     */
    func uniquing<T: Hashable>(with mapFunction: (Element) -> T) -> [Iterator.Element] {
        var seenTuples: Set<T> = Set()
        var unique = [Iterator.Element]()
        for element in self {
            let hashableElements = mapFunction(element)
            if !seenTuples.contains(hashableElements) {
                unique.append(element)
                seenTuples.insert(hashableElements)
            }
        }
        return unique
    }
    
}
