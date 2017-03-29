//
//  SwiftOutput.swift
//  Cataloger
//
//  Created by James Lawton on 3/14/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

struct SwiftOutput: OutputGenerator {
    static func output(assets: Set<Asset>, options: CodeOutputOptions, invocation: CatalogerInvocation) -> [String: String] {
        let file = options.assetNamespace.name + ".swift"
        let contents = swiftCode(assets: assets.sorted(by: Asset.compareCatalogGroups), options: options, invocation: invocation)
        return [file: contents]
    }
}

private func swiftCode(assets: [Asset], options: CodeOutputOptions, invocation: CatalogerInvocation) -> String {
    var output = ""

    output.append(invocation.swiftHeader)
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
    case .classProperties: output.append(swiftClass(assets: assets, options: options))
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
        output.append(swiftAssetProperty(name: "image", path: "self.rawValue", type: .Image, bundle: bundle, isStatic: false, isPublic: options.isPublic))
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
        output.append(swiftAssetProperty(name: "image", path: "self.rawValue", type: .Image, bundle: bundle, isStatic: false, isPublic: options.isPublic))
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

private func swiftClass(assets: [Asset], options: CodeOutputOptions) -> String {
    var output = ""
    let className = CodeGeneration.identifier(options.assetNamespace.name, options: [.initialCap])
    let public_ = options.isPublic ? "public " : ""

    output.append("\(public_)final class \(className) {\n")

    let bundle = options.imageBundle ?? .byClass(className, defineClassInOutput: false)

    let groups: [String: [Asset]] = assets.groupBy { $0.group }
    for group in groups.keys.sorted() {
        output.append("\n")
        if !group.isEmpty {
            output.append("    // MARK: - \(group)\n")
            output.append("\n")
        }
        for asset in groups[group]! {
            let assetName = CodeGeneration.identifier(asset.name, options: [.desnake])
            let assetPath = CodeGeneration.quoted(asset.path)
            output.append(swiftAssetProperty(name: assetName, path: assetPath, type: asset.type, bundle: bundle, isStatic: true, isPublic: options.isPublic))
            output.append("\n")
        }
    }

    output.append("}\n")

    return output
}

private func swiftAssetProperty(name: String, path: String, type: Asset.AssetType, bundle: BundleIdentification, isStatic: Bool, isPublic: Bool, returnOptional: Bool = false) -> String {
    let (bundleCode, bundleOptional) = bundle.swiftOutput
    let public_ = isPublic ? "public " : ""
    let static_ = isStatic ? "static " : ""

    let returnType: String
    let varName: String
    switch type {
    case .Image:
        returnType = returnOptional ? "UIImage?" : "UIImage"
        varName = "img"
    case .DataAsset:
        returnType = returnOptional ? "NSDataAsset?" : "NSDataAsset"
        varName = "dataAsset"
    }

    let loadAsset = { (bundle: String) -> String in
        switch type {
        case .Image: return "UIImage(named: \(path), in: \(bundle), compatibleWith: nil)"
        case .DataAsset: return "NSDataAsset(name: \(path), bundle: \(bundle))"
        }
    }

    var output = ""
    output.append(    "    \(public_)\(static_)var \(name): \(returnType) {\n")
    if bundleOptional {
        output.append("        let bundle = \(bundleCode)\n")
        output.append("        let \(varName) = (bundle != nil)\n")
        output.append("            ? \(loadAsset("bundle!"))\n")
        output.append("            : nil\n")
    } else {
        output.append("        let \(varName) = \(loadAsset(bundleCode))\n")
    }
    if returnOptional {
        output.append("        return \(varName)\n")
    } else {
        output.append("        assert(\(varName) != nil)\n")
        output.append("        return \(varName)!\n")
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
