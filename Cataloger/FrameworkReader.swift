//
//  FrameworkReader.swift
//  Cataloger
//
//  Created by James Lawton on 3/15/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

struct Framework: AssetReader {
    enum FileType: String {
        case PNG = ".png"
        case JPG = ".jpg"
        case JPEG = ".jpeg"

        static let allTypes: [FileType] = [.PNG, .JPG, .JPEG]

        var stripExtension: Bool {
            return (self == .PNG)
        }

        var assetType: Asset.AssetType {
            return .Image
        }
    }

    let catalogURL: URL
    init(catalogURL: URL) throws {
        try expectDirectory(url: catalogURL)
        self.catalogURL = catalogURL
    }

    func enumerateAssets() throws -> [Asset] {
        let fs = FileManager.default
        let paths: [String]
        do {
            paths = try fs.subpathsOfDirectory(atPath: catalogURL.path)
        } catch {
            throw ReaderError.enumerationError(error)
        }

        // Filter out nested bundles and other miscellany
        let assets: [Asset] = paths.flatMap { (path: String) -> Asset? in
            // Filter out nested bundles
            if path.range(of: ".bundle/") != nil || path.range(of: ".framework/") != nil {
                return nil
            }
            // Filter out folders
            guard fs.isRegularFile(url: catalogURL.appendingPathComponent(path)) else {
                return nil
            }
            // Filter out irrelavent file types
            return asset(path)
        }

        // Deduplicate
        return Set(assets).sorted { (a: Asset, b: Asset) -> Bool in
            return (a.group < b.group)
                || (a.group == b.group && a.name < b.name)
        }
    }

    private func asset(_ path: String) -> Asset? {
        let group = (path as NSString).deletingLastPathComponent
        if let (name, type) = assetType(filename: (path as NSString).lastPathComponent) {
            let fullname = (group as NSString).appendingPathComponent(name)
            return Asset(group: group, name: fullname, path: fullname, type: type)
        }
        return nil
    }

    private func assetType(filename: String) -> (name: String, type: Asset.AssetType)? {
        for type in FileType.allTypes {
            if let r = filename.range(of: type.rawValue, options: [.backwards, .anchored], range: nil, locale: nil)   {
                var name = filename.replacingCharacters(in: r, with: "")
                if (type.assetType == .Image) {
                    name = stripScale(name)
                }
                if !type.stripExtension {
                    name = name + filename.substring(with: r)
                }
                return (name: name, type: type.assetType)
            }
        }
        return nil
    }

    private func stripScale(_ name: String) -> String {
        for s in ["@2x", "@3x"] {
            if let r = name.range(of: s, options: [.backwards, .anchored], range: nil, locale: nil)   {
                return name.replacingCharacters(in: r, with: "")
            }
        }
        return name
    }
}
