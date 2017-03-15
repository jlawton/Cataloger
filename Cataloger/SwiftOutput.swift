//
//  SwiftOutput.swift
//  Cataloger
//
//  Created by James Lawton on 3/14/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

func swiftCode(name: String, assets: [Asset]) -> String {
    var output = ""
    let className = "BundleClass_\(CodeGeneration.identifier(name, options: [.initialCap]))"

    output.append("// Generated automatically with the contents of the asset catalog\n")
    output.append("\n")
    output.append("import Foundation\n")
    output.append("\n")
    output.append("#if os(iOS)\n")
    output.append("    import UIKit\n")
    output.append("#endif\n")
    output.append("\n")


    let imageAssets = assets.filter { $0.type == .Image }
    output.append(swiftEnum(name: name, assets: imageAssets, options: [.includeUIImageAccessor], className: className))

    output.append("\n")
    output.append("// Class used to reference bundle for asset loading\n")
    output.append("private class \(className) {}\n")
    output.append("\n")

    return output
}

struct SwiftEumOptions: OptionSet {
    let rawValue: Int
    static let includeUIImageAccessor = SwiftEumOptions(rawValue: 1 << 0)
    static let `public` = SwiftEumOptions(rawValue: 1 << 1)
}

func swiftEnum(name: String, assets: [Asset], options: SwiftEumOptions = [], className: String) -> String {
    var output = ""

    output.append("enum \(CodeGeneration.identifier(name, options: [.initialCap])): String {\n")
    output.append("\n")

    let groups: [String: [Asset]] = assets.groupBy { $0.group }
    for group in groups.keys.sorted() {
        if !group.isEmpty {
            output.append("    // \(group)\n")
        }
        for asset in groups[group]! {
            output.append("    case \(CodeGeneration.identifier(asset.name, options: [.desnake])) = \(CodeGeneration.quoted(asset.name))\n")
        }
        output.append("\n")
    }

    if (options.contains(.includeUIImageAccessor)) {
        output.append("    #if os(iOS)\n")
        output.append("    var image: UIImage {\n")
        output.append("        let image = UIImage(named: self.rawValue, in: Bundle(for: \(className).self), compatibleWith: nil)\n")
        output.append("        assert(image != nil)\n")
        output.append("        return image!\n")
        output.append("    }\n")
        output.append("    #endif\n")
        output.append("\n")
    }

    output.append("}\n")

    return output
}
