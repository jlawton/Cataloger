//
//  CommandLineOptions.swift
//  Cataloger
//
//  Created by James Lawton on 3/19/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

struct CodeOutputOptions {
    let assetNamespace: AssetNamespace
    let imageBundle: BundleIdentification?
    let useQualifiedNames: Bool
    let isPublic: Bool
}

enum BundleIdentification {
    case byClass(String, defineClassInOutput: Bool)
    case byPath(String)
    case byIdentifier(String)
}

enum AssetNamespace {
    case closedEnum(String)
    case extensibleEnum(String)
    case extensibleEnumExtension(String)

    var name: String {
        switch self {
        case .closedEnum(let name): return name
        case .extensibleEnum(let name): return name
        case .extensibleEnumExtension(let name): return name
        }
    }
}
