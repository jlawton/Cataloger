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

    let assets: [Asset]
    do {
        let xcassets = try XCAssets(catalogURL: URL(fileURLWithPath: arguments[0]))
        assets = try xcassets.enumerateAssets()
    } catch {
        print("\(error)")
        return
    }

    let swift = swiftCode(name: "Media", assets: assets)
    print(swift)
}

func usage() -> Never {
    print("Usage: \(executableName) <xcassets>")
    exit(1)
}

main(Array(CommandLine.arguments.dropFirst(1)))
