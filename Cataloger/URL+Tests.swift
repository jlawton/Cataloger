//
//  URL+Tests.swift
//  Cataloger
//
//  Created by James Lawton on 3/27/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

extension URL {
    var isRegularFile: Bool {
        let values = try? self.resourceValues(forKeys: [.isRegularFileKey])
        return values?.isRegularFile ?? false
    }
    var isDirectory: Bool {
        let values = try? self.resourceValues(forKeys: [.isDirectoryKey])
        return values?.isDirectory ?? false
    }
    var isSymlink: Bool {
        let values = try? self.resourceValues(forKeys: [.isSymbolicLinkKey])
        return values?.isSymbolicLink ?? false
    }
}
