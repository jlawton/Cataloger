//
//  GenerateCommand.swift
//  Cataloger
//
//  Created by James Lawton on 3/22/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

struct GenerateCommand: CommandProtocol {
    let verb: String = "generate"
    let function: String = "Output code constants for an asset catalog"

    func run(_ options: GenerateOptions) -> Result<(), NoError> {
        var assets: Set<Asset> = Set()
        for catalogPath in options.sources {
            do {
                let catalogURL: URL = URL(fileURLWithPath: catalogPath)
                let catalogAssets = try readAssets(catalogURL: catalogURL)
                assets = try Asset.merge(assets, catalogAssets)
            } catch {
                print("\(error)")
                return .success(())
            }
        }

        let code: String
        switch options.outputOptions.language {
        case .swift: code = SwiftOutput.output(assets: assets, options: options.outputOptions)
        case .objC: code = ObjcOutput.output(assets: assets, options: options.outputOptions)
        }

        print(code)

        return .success(())
    }
}

struct GenerateOptions: OptionsProtocol {
    let outputOptions: CodeOutputOptions
    let sources: [String]

    static func evaluate(_ m: CommandMode) -> Result<GenerateOptions, CommandantError<NoError>> {
        return create
            <*> CodeOutputOptions.evaluate(m)
            <*> m <| Argument<[String]>(defaultValue: nil, usage: "Asset catalogs")
    }

    private static func create(outputOptions: CodeOutputOptions) -> ([String]) -> GenerateOptions {
        return { sources in
            GenerateOptions(outputOptions: outputOptions, sources: sources)
        }
    }
}
