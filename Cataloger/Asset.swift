//
//  Asset.swift
//  Cataloger
//
//  Created by James Lawton on 3/17/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

struct Asset {
    enum AssetType: Int, Comparable {
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
    func hash(into hasher: inout Hasher) {
        path.hash(into: &hasher)
    }
}

func ==(_ a: Asset, _ b: Asset) -> Bool {
    return a.path == b.path
}
func <(_ a: Asset, _ b: Asset) -> Bool {
    return a.path < b.path
}

func <(_ a: Asset.AssetType, _ b: Asset.AssetType) -> Bool {
    return a.rawValue < b.rawValue
}

extension Asset {
    enum MergeError: Error {
        case duplicatePaths([Asset])
    }

    static func merge(_ a: Set<Asset>, _ b: Set<Asset>) throws -> Set<Asset> {
        let dupes = a.intersection(b)
        if !dupes.isEmpty {
            throw MergeError.duplicatePaths(dupes.sorted())
        }
        return a.union(b)
    }

    static func comparePaths(_ a: Asset, _ b: Asset) -> Bool {
        return a.path < b.path
    }
    static func compareCatalogGroups(_ a: Asset, _ b: Asset) -> Bool {
        return (a.catalog.path, a.group, a.name) < (b.catalog.path, b.group, b.name)
    }

    static  func read(from sources: [String]) throws -> Set<Asset> {
        var assets: Set<Asset> = Set()
        for catalogPath in sources {
            let catalogURL: URL = URL(fileURLWithPath: catalogPath)
            let catalogAssets = try readAssets(catalogURL: catalogURL)
            assets = try Asset.merge(assets, catalogAssets)
        }
        return assets
    }
}
