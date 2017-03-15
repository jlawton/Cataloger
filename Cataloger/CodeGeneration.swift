//
//  CodeGeneration.swift
//  Cataloger
//
//  Created by James Lawton on 3/15/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

internal enum CodeGeneration {

    struct IdentifierOptions: OptionSet {
        let rawValue: Int
        static let initialCap = IdentifierOptions(rawValue: 1 << 0)
        static let desnake = IdentifierOptions(rawValue: 1 << 1)

        fileprivate var whitespaceSet: CharacterSet {
            var ws: CharacterSet = CharacterSet.whitespacesAndNewlines
            ws.update(with: "-")
            if self.contains(.desnake) {
                ws.update(with: "_")
            }
            return ws
        }
    }

    /// Turn a file name into a valid Swift identifier.
    /// Doing it very simplistically and slowly for now, making camel case.
    /// See https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/LexicalStructure.html
    static func identifier(_ input: String, options: IdentifierOptions = []) -> String {
        let legal = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        let legalHead = CharacterSet.letters.union(CharacterSet(charactersIn: "_"))
        let ws = options.whitespaceSet

        var output: String = ""
        let scalars: [UnicodeScalar] = Array(input.unicodeScalars)
        var capitalize: Bool = false
        for (i, c) in scalars.enumerated() {
            if i == 0 {
                if legalHead.contains(c) {
                    if scalars.count > 1 && String(scalars[1]) == String(scalars[1]).lowercased() {
                        if options.contains(.initialCap) {
                            output.append(String(c).uppercased())
                        } else {
                            output.append(String(c).lowercased())
                        }
                    } else {
                        output.append(Character(c))
                    }
                    continue
                } else {
                    output.append("_")
                }
            }

            if ws.contains(c) {
                capitalize = true
            } else if legal.contains(c) {
                if capitalize {
                    output.append(String(c).uppercased())
                    capitalize = false
                } else {
                    output.append(Character(c))
                }
            }
        }

        return output
    }

    /// Quote a string, escaping appropriately
    static func quoted(_ s: String) -> String {
        // Escape anything which might mess with the string
        let escaped = s
            // Escape '\' first, so we don't re-escape ones we add
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\"", with: "\\\"")

        return "\"" + escaped + "\""
    }
}
