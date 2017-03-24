//
//  OutputGenerator.swift
//  Cataloger
//
//  Created by James Lawton on 3/20/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

protocol OutputGenerator {
    static func output(assets: Set<Asset>, options: CodeOutputOptions, invocation: CatalogerInvocation) -> String
}


