//
//  main.swift
//  Cataloger
//
//  Created by James Lawton on 3/14/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation


let registry = CommandRegistry<NoError>()
registry.register(GenerateCommand())
registry.register(ListCommand())

let helpCommand = HelpCommand(registry: registry)
registry.register(helpCommand)

registry.main(defaultVerb: helpCommand.verb) { _ in }
