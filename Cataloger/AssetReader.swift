//
//  AssetReader.swift
//  Cataloger
//
//  Created by James Lawton on 3/15/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

protocol AssetReader {
    func enumerateAssets() throws -> [Asset]
}

struct Asset {
    enum AssetType {
        case Image
        case DataAsset
    }

    let group: String
    let name: String
    let path: String
    let type: AssetType
}

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

enum ReaderError: Error {
    case expectedFileURL(URL)
    case expectedDirectory(URL)
    case enumerationError(Error)
}
