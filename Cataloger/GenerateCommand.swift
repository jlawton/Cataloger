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

    func run(_ options: GenerateOptions) -> Result<(), CatalogerError> {
        return Result(())
            .tryMap { _ in
                return try Asset.read(from: options.sources)
            }
            .map { (assets: Set<Asset>) in
                let cmd = CatalogerInvocation(verb: verb, arguments: options.effectiveCommandLineArguments)
                let code: String
                switch options.outputOptions.language {
                case .swift: code = SwiftOutput.output(assets: assets, options: options.outputOptions, invocation: cmd)
                case .objC: code = ObjcOutput.output(assets: assets, options: options.outputOptions, invocation: cmd)
                }

                print(code)
            }
    }
}

struct GenerateOptions: OptionsProtocol {
    let outputOptions: CodeOutputOptions
    let sources: [String]

    static func evaluate(_ m: CommandMode) -> Result<GenerateOptions, CommandantError<CatalogerError>> {
        return create
            <*> CodeOutputOptions.evaluate(m)
            <*> m <| Argument<[String]>(defaultValue: nil, usage: "Asset catalogs")
    }

    private static func create(outputOptions: CodeOutputOptions) -> ([String]) -> GenerateOptions {
        return { sources in
            GenerateOptions(outputOptions: outputOptions, sources: sources)
        }
    }

    var effectiveCommandLineArguments: [String] {
        var args = outputOptions.effectiveCommandLineArguments
        args.append(contentsOf: sources.map { CodeGeneration.quoted(URL(fileURLWithPath: $0).lastPathComponent) })
        return args
    }
}
