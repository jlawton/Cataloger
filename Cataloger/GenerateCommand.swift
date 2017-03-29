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
            .map { (assets: Set<Asset>) -> [String: String] in
                let cmd = CatalogerInvocation(verb: verb, arguments: options.effectiveCommandLineArguments)
                let code: [String: String]
                switch options.outputOptions.language {
                case .swift: code = SwiftOutput.output(assets: assets, options: options.outputOptions, invocation: cmd)
                case .objC: code = ObjcOutput.output(assets: assets, options: options.outputOptions, invocation: cmd)
                }
                return code
            }
            .tryMap { (code: [String: String]) in
                if let outputDirectory = options.output {
                    let outputDir = URL(fileURLWithPath: outputDirectory)
                    try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true, attributes: nil)

                    for (file, contents) in code {
                        let outputURL = URL(fileURLWithPath: outputDirectory).appendingPathComponent(file)
                        try contents.write(to: outputURL, atomically: true, encoding: .utf8)
                    }
                } else {
                    for (file, contents) in code {
                        print("// ---------- " + file + " ----------")
                        print(contents)
                    }
                }
            }
    }
}

struct GenerateOptions: OptionsProtocol {
    let outputOptions: CodeOutputOptions
    let sources: [String]
    let output: String?

    static func evaluate(_ m: CommandMode) -> Result<GenerateOptions, CommandantError<CatalogerError>> {
        return create
            <*> CodeOutputOptions.evaluate(m)
            <*> m <| Option(key: "output", defaultValue: nil, usage: "Output directory. If not specified, prints to standard output. Default: none")
            <*> m <| Argument<[String]>(defaultValue: nil, usage: "Asset catalogs")
    }

    private static func create(outputOptions: CodeOutputOptions) -> (String?) -> ([String]) -> GenerateOptions {
        return { output in { sources in
            GenerateOptions(outputOptions: outputOptions, sources: sources, output: output)
        } }
    }

    var effectiveCommandLineArguments: [String] {
        var args = outputOptions.effectiveCommandLineArguments
        args.append(contentsOf: sources.map { CodeGeneration.quoted(URL(fileURLWithPath: $0).lastPathComponent) })
        return args
    }
}
