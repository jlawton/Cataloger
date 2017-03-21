//
//  SwiftOutput.swift
//  Cataloger
//
//  Created by James Lawton on 3/14/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

struct SwiftOutput: OutputGenerator {
    static func output(assets: Set<Asset>, options: CodeOutputOptions) -> String {
        return swiftCode(assets: assets.sorted(by: Asset.compareCatalogGroups), options: options)
    }
}

private func swiftCode(assets: [Asset], options: CodeOutputOptions) -> String {
    var output = ""

    output.append("// Generated automatically with the contents of the asset catalog\n")
    output.append("\n")
    output.append("import Foundation\n")
    output.append("\n")

    if options.imageBundle != nil {
        output.append("#if os(iOS)\n")
        output.append("    import UIKit\n")
        output.append("#endif\n")
        output.append("\n")
    }

    let imageAssets = assets.filter { $0.type == .Image }
    switch options.assetNamespace {
    case .closedEnum: output.append(swiftEnum(assets: imageAssets, options: options))
    case .extensibleEnum: output.append(swiftExtensibleEnum(assets: imageAssets, options: options))
    case .extensibleEnumExtension: output.append(swiftExtensibleEnumExtension(assets: imageAssets, options: options))
    }
    output.append("\n")

    if case let .some(.byClass(className, defineClassInOutput: true)) = options.imageBundle {
        output.append("// Class used to reference bundle for image loading\n")
        output.append("private class \(className) {}\n")
        output.append("\n")
    }

    return output
}

private func swiftEnum(assets: [Asset], options: CodeOutputOptions) -> String {
    var output = ""
    let public_ = options.isPublic ? "public " : ""

    output.append("\(public_)enum \(CodeGeneration.identifier(options.assetNamespace.name, options: [.initialCap])): String {\n")
    output.append("\n")

    let groups: [String: [Asset]] = assets.groupBy { $0.group }
    for group in groups.keys.sorted() {
        if !group.isEmpty {
            output.append("    // \(group)\n")
        }
        for asset in groups[group]! {
            output.append("    case \(CodeGeneration.identifier(asset.name, options: [.desnake])) = \(CodeGeneration.quoted(asset.path))\n")
        }
        output.append("\n")
    }

    if let bundle = options.imageBundle {
        output.append("    #if os(iOS)\n")
        output.append(swiftUIImageAccessor(bundle: bundle, isPublic: options.isPublic))
        output.append("    #endif\n")
        output.append("\n")
    }

    output.append("}\n")

    return output
}

private func swiftExtensibleEnum(assets: [Asset], options: CodeOutputOptions) -> String {
    var output = ""
    let structName = CodeGeneration.identifier(options.assetNamespace.name, options: [.initialCap])
    let public_ = options.isPublic ? "public " : ""

    output.append("\(public_)struct \(structName): RawRepresentable {\n")
    output.append("    \(public_)typealias RawValue = String\n")
    output.append("    \(public_)let rawValue: RawValue\n")
    output.append("\n")

    if options.isPublic {
        output.append("    public init(rawValue: RawValue) {\n")
        output.append("        self.rawValue = rawValue\n")
        output.append("    }\n")
        output.append("\n")
    }

    let groups: [String: [Asset]] = assets.groupBy { $0.group }
    for group in groups.keys.sorted() {
        if !group.isEmpty {
            output.append("    // \(group)\n")
        }
        for asset in groups[group]! {
            let assetName = CodeGeneration.identifier(asset.name, options: [.desnake])
            output.append("    \(public_)static let \(assetName): \(structName) = \(structName)(rawValue: \(CodeGeneration.quoted(asset.path)))\n")
        }
        output.append("\n")
    }

    if let bundle = options.imageBundle {
        output.append("    #if os(iOS)\n")
        output.append(swiftUIImageAccessor(bundle: bundle, isPublic: options.isPublic))
        output.append("    #endif\n")
        output.append("\n")
    }

    output.append("}\n")

    return output
}

private func swiftExtensibleEnumExtension(assets: [Asset], options: CodeOutputOptions) -> String {
    var output = ""
    let structName = CodeGeneration.identifier(options.assetNamespace.name, options: [.initialCap])
    let public_ = options.isPublic ? "public " : ""

    output.append("\(public_)extension \(structName) {\n")
    output.append("\n")

    let groups: [String: [Asset]] = assets.groupBy { $0.group }
    for group in groups.keys.sorted() {
        if !group.isEmpty {
            output.append("    // \(group)\n")
        }
        for asset in groups[group]! {
            let assetName = CodeGeneration.identifier(asset.name, options: [.desnake])
            output.append("    \(public_)static let \(assetName): \(structName) = \(structName)(rawValue: \(CodeGeneration.quoted(asset.path)))\n")
        }
        output.append("\n")
    }

    output.append("}\n")

    return output
}

private func swiftUIImageAccessor(bundle: BundleIdentification, isPublic: Bool, returnOptional: Bool = false) -> String {
    let returnType = returnOptional ? "UIImage?" : "UIImage"
    let (bundleCode, bundleOptional) = bundle.swiftOutput
    let public_ = isPublic ? "public " : ""

    var output = ""
    output.append(    "    \(public_)var image: \(returnType) {\n")
    output.append(    "        let bundle = \(bundleCode)\n")
    if bundleOptional {
        output.append("        let img = (bundle != nil)\n")
        output.append("            ? UIImage(named: self.rawValue, in: bundle!, compatibleWith: nil)\n")
        output.append("            : nil\n")
    } else {
        output.append("        let img = UIImage(named: self.rawValue, in: bundle, compatibleWith: nil)\n")
    }
    if returnOptional {
        output.append("        return img\n")
    } else {
        output.append("        assert(img != nil)\n")
        output.append("        return img!\n")
    }
    output.append(    "    }\n")
    return output
}

private extension BundleIdentification {
    var swiftOutput: (String, isOptional: Bool) {
        switch self {
        case .byClass(let className, defineClassInOutput: _): return ("Bundle(for: \(className).self)", false)
        case .byIdentifier(let identifier): return ("Bundle(identifier: \(CodeGeneration.quoted(identifier)))", true)
        case .byPath(let path): return ("Bundle(path: \(CodeGeneration.quoted(path)))", true)
        }
    }
}
