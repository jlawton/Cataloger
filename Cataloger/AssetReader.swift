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

enum ReaderError: Error {
    case expectedFileURL(URL)
    case expectedDirectory(URL)
    case enumerationError(Error)
}

func expectDirectory(url: URL) throws -> Void {
    if (!url.isFileURL) {
        throw ReaderError.expectedFileURL(url)
    }

    let fs = FileManager.default
    var isDir: ObjCBool = false
    if (!fs.fileExists(atPath: url.path, isDirectory: &isDir) || !isDir.boolValue) {
        throw ReaderError.expectedDirectory(url)
    }
}
