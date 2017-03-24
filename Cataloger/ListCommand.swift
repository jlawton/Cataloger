//
//  ListCommand.swift
//  Cataloger
//
//  Created by James Lawton on 3/23/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

struct ListCommand: CommandProtocol {
    let verb: String = "list"
    let function: String = "Output a list of assets in an asset catalog"

    func run(_ options: ListOptions) -> Result<(), NoError> {
        var assets: Set<Asset>
        do {
            assets = try Asset.read(from: options.sources)
        } catch {
            fputs("\(error)\n", stderr)
            return .success(())
        }

        let imageAssets = assets.sorted().filter { $0.type == .Image }
        let separator = options.print0 ? "\0" : "\n"
        for asset in imageAssets {
            print(asset.path, terminator: separator)
        }

        return .success(())
    }
}

struct ListOptions: OptionsProtocol {
    let print0: Bool
    let sources: [String]

    static func evaluate(_ m: CommandMode) -> Result<ListOptions, CommandantError<NoError>> {
        return create
            <*> m <| Switch(flag: "0", key: "print0", usage: "Prints asset paths separated by NUL, rather than one per line")
            <*> m <| Argument<[String]>(defaultValue: nil, usage: "Asset catalogs")
    }

    static func create(_ print0: Bool) -> ([String]) -> ListOptions {
        return { sources in
            return ListOptions(print0: print0, sources: sources)
        }
    }
}
