//
//  Array+GroupBy.swift
//  Cataloger
//
//  Created by James Lawton on 3/15/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

extension Array {
    func groupBy<T: Hashable>(_ f: (Element) -> T) -> [T: [Element]] {
        var groups: [T: [Element]] = [:]

        for elem in self {
            let group = f(elem)
            var assetsInGroup = groups[group] ?? []
            assetsInGroup.append(elem)
            groups[group] = assetsInGroup
        }

        return groups
    }
}
