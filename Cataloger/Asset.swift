//
//  Asset.swift
//  Cataloger
//
//  Created by James Lawton on 3/17/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

struct Asset {
    enum AssetType {
        case Image
        case DataAsset
    }

    let catalog: URL
    let group: String
    let name: String
    let path: String
    let type: AssetType
}

// path is relative to the catalog, so assets will be "equal" if they're in
// different catalogs, with the same path. This is by design, as when we deal
// with assets from multiple catalogs, we're interested in path collisions.
extension Asset: Hashable, Comparable {
    var hashValue: Int {
        return path.hashValue
    }
}

func ==(_ a: Asset, _ b: Asset) -> Bool {
    return a.path == b.path
}
func <(_ a: Asset, _ b: Asset) -> Bool {
    return a.path < b.path
}

extension Asset {
    enum MergeError: Error {
        case duplicatePaths([String])
    }

    static func merge(_ a: Set<Asset>, _ b: Set<Asset>) throws -> Set<Asset> {
        let dupes = a.intersection(b)
        if !dupes.isEmpty {
            let paths = dupes.map({ $0.path }).sorted()
            throw MergeError.duplicatePaths(paths)
        }
        return a.union(b)
    }

    static func comparePaths(_ a: Asset, _ b: Asset) -> Bool {
        return a.path < b.path
    }
    static func compareCatalogGroups(_ a: Asset, _ b: Asset) -> Bool {
        return (a.catalog.path, a.group, a.name) < (b.catalog.path, b.group, b.name)
    }
}