//
//  Errors.swift
//  Cataloger
//
//  Created by James Lawton on 3/23/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

enum CatalogerError: Error {
    case readerError(error: ReaderError)
    case duplicateAssetPaths([Asset])
    case unknownError(error: Error)
}

extension CatalogerError: ErrorProtocolConvertible {
    static func error(from error: Error) -> CatalogerError {
        if let e = error as? CatalogerError {
            return e
        }
        if let e = error as? Asset.MergeError {
            if case let .duplicatePaths(assets) = e {
                return .duplicateAssetPaths(assets)
            }
        }
        if let e = error as? ReaderError {
            return .readerError(error: e)
        }
        return .unknownError(error: error)
    }
}

// It's a little ugly to do it here, but we prefix these with "error:" so that
// they show up in Xcode if we're in a Run Script build phase
extension CatalogerError: CustomStringConvertible {
    var description: String {
        switch self {
        case .readerError(let error):
            return "error: \(error)"

        case .unknownError(let error):
            return "error: \(error)"

        case .duplicateAssetPaths(let assets):
            let grouped = assets.groupBy { $0.path }
            return grouped.keys.sorted()
                .map { (path: String) -> String in
                    let catalogs = grouped[path]!.map { $0.catalog }
                    let catalogNames = catalogs.map { "\"" + $0.lastPathComponent + "\"" }.joined(separator: ", ")
                    return "error: Asset \"\(path)\" exists in multiple catalogs (\(catalogNames))\n"
                        + catalogs.map({ "    " + $0.path }).joined(separator: "\n")
                }
                .joined(separator: "\n")
        }
    }
}
