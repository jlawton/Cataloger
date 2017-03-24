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
