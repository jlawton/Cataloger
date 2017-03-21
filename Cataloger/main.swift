//
//  main.swift
//  Cataloger
//
//  Created by James Lawton on 3/14/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

let executableName: String = (CommandLine.arguments[0] as NSString).lastPathComponent

func main(_ arguments: [String]) {
    guard arguments.count == 1 else {
        usage()
    }

    var assets: Set<Asset> = Set()
    for catalogPath in arguments {
        do {
            let catalogURL: URL = URL(fileURLWithPath: catalogPath)
            let catalogAssets = try readAssets(catalogURL: catalogURL)
            assets = try Asset.merge(assets, catalogAssets)
        } catch {
            print("\(error)")
            return
        }
    }

    let codeOptions = CodeOutputOptions(
        assetNamespace: .closedEnum("Foo"),
        imageBundle: .byClass("BundleClass", defineClassInOutput: false),
        useQualifiedNames: true,
        isPublic: false)

    let swift = SwiftOutput.output(assets: assets, options: codeOptions)
    print(swift)
}

func usage() -> Never {
    print(
        "Usage: \(executableName) <catalog> [<catalog> …]\n" +
        "    where <catalog> is a .xcassets directory, .framework or .bundle"
    )
    exit(1)
}

main(Array(CommandLine.arguments.dropFirst(1)))
