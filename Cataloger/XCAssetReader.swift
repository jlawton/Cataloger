//
//  XCAssetReader.swift
//  Cataloger
//
//  Created by James Lawton on 3/14/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

struct XCAssets: AssetReader {
    private enum AssetDataType: String {
//        case appIconSet = ".appiconset"
//        case cubeTextureSet = ".cubetextureset"
        case dataSet = ".dataset"
        case imageSet = ".imageset"
//        case launchImage = ".launchimage"
//        case mipmapSet = ".mipmapset"
//        case spriteAtlas = ".spriteatlas"
//        case sticker = ".sticker"
//        case stickerPack = ".stickerpack"
//        case stickerSequence = ".stickersequence"
//        case textureSet = ".textureset"

        static let allTypes: [AssetDataType] = [.dataSet, .imageSet]

        var assetType: Asset.AssetType {
            switch self {
            case .dataSet:
                return .DataAsset
            case .imageSet:
                return .Image
            }
        }
    }

    let catalogURL: URL
    init(catalogURL: URL) throws {
        try expectDirectory(url: catalogURL)
        self.catalogURL = catalogURL
    }

    func enumerateAssets() throws -> [Asset] {
        let paths: [String]
        do {
            paths = try FileManager.default.subpathsOfDirectory(atPath: catalogURL.path)
        } catch {
            throw ReaderError.enumerationError(error)
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

        // Convert to assets
        return assetPathSet.sorted().flatMap { (path: String) -> Asset? in
            return asset(path)
        }
    }

    private func asset(_ path: String) -> Asset? {
        let group = (path as NSString).deletingLastPathComponent
        if let (name, type) = assetType(filename: (path as NSString).lastPathComponent) {
            return Asset(group: group, name: name, path: name, type: type)
        }
        return nil
    }

    private func assetType(filename: String) -> (name: String, type: Asset.AssetType)? {
        for type in AssetDataType.allTypes {
            if let r = filename.range(of: type.rawValue, options: [.backwards, .anchored], range: nil, locale: nil)   {
                let name = filename.replacingCharacters(in: r, with: "")
                return (name: name, type: type.assetType)
            }
        }
        return nil
    }
}
