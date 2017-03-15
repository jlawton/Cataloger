//
//  XCAssetReader.swift
//  Cataloger
//
//  Created by James Lawton on 3/14/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

enum XCAssetEnumerationError: Error {
    case expectedFileURL(URL)
    case expectedDirectory(URL)
    case directoryEnumerationError(Error)
}

enum AssetDataType: String {
    case appIconSet = ".appiconset"
    case cubeTextureSet = ".cubetextureset"
    case dataSet = ".dataset"
    case imageSet = ".imageset"
    case launchImage = ".launchimage"
    case mipmapSet = ".mipmapset"
    case spriteAtlas = ".spriteatlas"
    case sticker = ".sticker"
    case stickerPack = ".stickerpack"
    case stickerSequence = ".stickersequence"
    case textureSet = ".textureset"

    static let allTypes: [AssetDataType] = [
        appIconSet, cubeTextureSet, dataSet, imageSet,
        launchImage, mipmapSet, spriteAtlas, sticker,
        stickerPack, stickerSequence, textureSet]
}

func enumerateAssets(in catalog: URL) throws -> [String] {
    if (!catalog.isFileURL) {
        throw XCAssetEnumerationError.expectedFileURL(catalog)
    }

    let fs = FileManager.default
    var isDir: ObjCBool = false
    if (!fs.fileExists(atPath: catalog.path, isDirectory: &isDir) || !isDir.boolValue) {
        throw XCAssetEnumerationError.expectedDirectory(catalog)
    }

    let paths: [String]
    do {
        paths = try fs.subpathsOfDirectory(atPath: catalog.path)
    } catch {
        throw XCAssetEnumerationError.directoryEnumerationError(error)
    }

    // Strip paths short at the first qualifying name
    let assetPaths: [String] = paths.flatMap { (path: String) -> String? in
        var range: Range<String.Index>? = nil

        for t in AssetDataType.allTypes {
            if let r = path.range(of: "\(t.rawValue)/") {
                if (range == nil) || (r.upperBound < range!.upperBound) {
                    range = r
                }
            }
        }

        guard let foundRange = range else {
            return nil
        }

        var assetPath = path
        // Cut before the slash
        let cut = assetPath.index(before: foundRange.upperBound)
        assetPath.removeSubrange(cut..<assetPath.endIndex)
        return assetPath
    }

    // Strip duplicates
    let assetPathSet = Set(assetPaths)

    return assetPathSet.sorted()
}

func assetGroups(_ assetPaths: [String]) -> [String: [String]] {
    var groups: [String: [String]] = [:]

    for path in assetPaths {
        let group = (path as NSString).deletingLastPathComponent
        let name = (path as NSString).lastPathComponent
        var assetsInGroup = groups[group] ?? []
        assetsInGroup.append(name)
        groups[group] = assetsInGroup
    }

    return groups
}

func assetsOfType(_ type: AssetDataType, _ assetPaths: [String]) -> [String] {
    return assetPaths.flatMap { (path: String) -> String? in
        if let r = path.range(of: type.rawValue, options: [.backwards, .anchored], range: nil, locale: nil)   {
            return path.replacingCharacters(in: r, with: "")
        } else {
            return nil
        }
    }
}
