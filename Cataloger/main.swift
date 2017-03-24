//
//  main.swift
//  Cataloger
//
//  Created by James Lawton on 3/14/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

enum Cataloger {
    static let executableName: String = URL(fileURLWithPath: CommandLine.arguments[0]).lastPathComponent
    static let repository: String = "https://github.com/jlawton/Cataloger/"
}

let registry = CommandRegistry<CatalogerError>()
registry.register(GenerateCommand())
registry.register(ListCommand())

let helpCommand = HelpCommand(registry: registry)
registry.register(helpCommand)

registry.main(defaultVerb: helpCommand.verb) { (error: CatalogerError) in
    fputs("\(error)\n", stderr)
    exit(EXIT_FAILURE)
}
