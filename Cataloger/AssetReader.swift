//
//  AssetReader.swift
//  Cataloger
//
//  Created by James Lawton on 3/15/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

protocol AssetReader {
    func enumerateAssets() throws -> Set<Asset>
}

enum ReaderError: Error {
    case unknownCatalogType(URL)
    case expectedFileURL(URL)
    case expectedDirectory(URL)
    case enumerationError(URL, Error)

    var catalogURL: URL {
        switch self {
        case .unknownCatalogType(let url): return url
        case .expectedFileURL(let url): return url
        case .expectedDirectory(let url): return url
        case .enumerationError(let url, _): return url
        }
    }
}

func readAssets(catalogURL: URL) throws -> Set<Asset> {
    let reader: AssetReader = try assetReader(catalogURL: catalogURL)
    return try reader.enumerateAssets()
}

private func assetReader(catalogURL: URL) throws -> AssetReader {
    let name = catalogURL.lastPathComponent
    if name.hasSuffix(".xcassets") {
        return try XCAssetsReader(catalogURL: catalogURL)
    }
    if name.hasSuffix(".framework") {
        return try FrameworkReader(catalogURL: catalogURL)
    }
    if name.hasSuffix(".bundle") {
        return try FrameworkReader(catalogURL: catalogURL, includeCatalogNameInPath: true)
    }
    throw ReaderError.unknownCatalogType(catalogURL)
}
