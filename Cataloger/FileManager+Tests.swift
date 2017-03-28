//
//  FileManager+Tests.swift
//  Cataloger
//
//  Created by James Lawton on 3/15/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

extension FileManager {
    func isRegularFile(url: URL) -> Bool {
        var isDir: ObjCBool = true
        return (url.isFileURL && fileExists(atPath: url.path, isDirectory: &isDir) && !isDir.boolValue)
    }
    func isDirectory(url: URL) -> Bool {
        var isDir: ObjCBool = false
        return (url.isFileURL && fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue)
    }
}

func expectDirectory(url: URL) throws -> Void {
    if (!url.isFileURL) {
        throw ReaderError.expectedFileURL(url)
    }
    if (!url.isDirectory) {
        throw ReaderError.expectedDirectory(url)
    }
}
