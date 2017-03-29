//
//  ObcOutput.swift
//  Cataloger
//
//  Created by James Lawton on 3/22/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

struct ObjcOutput: OutputGenerator {
    static func output(assets: Set<Asset>, options: CodeOutputOptions, invocation: CatalogerInvocation) -> String {
        let (header, impl) = objcCode(assets: assets.sorted(by: Asset.compareCatalogGroups), options: options, invocation: invocation)
        return "//--- HEADER\n\(header)\n//--- IMPL\n\(impl)"
    }
}

private func objcCode(assets: [Asset], options: CodeOutputOptions, invocation: CatalogerInvocation) -> (String, String) {

    if case .classProperties = options.assetNamespace {
        return objcClass(assets: assets, options: options, invocation: invocation)
    }

    var header = ""
    var impl = ""

    header.append(invocation.objcHeader)
    header.append("\n")
    header.append("@import Foundation;\n")
    header.append("\n")

    if options.imageBundle != nil {
        header.append("#if TARGET_OS_IPHONE\n")
        header.append("@import UIKit;\n")
        header.append("#endif\n")
        header.append("\n")
    }

    let imageAssets = assets.filter { $0.type == .Image }
    let typeName = options.assetNamespace.name

    header.append(objcTypedef(assetNamespace: options.assetNamespace))

    impl.append(invocation.objcHeader)
    impl.append("\n")
    impl.append("#import \"\(typeName).h\"\n")
    impl.append("\n")

    let groups: [String: [Asset]] = imageAssets.groupBy { $0.group }
    for group in groups.keys.sorted() {
        if !group.isEmpty {
            header.append("// \(group)\n")
            impl.append("// \(group)\n")
        }
        for asset in groups[group]! {
            let assetName = typeName + CodeGeneration.identifier(asset.name, options: [.desnake, .initialCap])
            header.append("extern \(typeName) \(assetName);\n")
            impl.append("\(typeName) \(assetName) = \(CodeGeneration.quoted(asset.path));\n")
        }
    }

    if let bundle = options.imageBundle {
        header.append("\n")
        impl.append("\n")

        let bundleClass = objcBundleClass(bundle: bundle)
        if bundleClass != nil {
            impl.append(bundleClass!.0)
            impl.append("\n")
        }

        let accessor = objcUIImageAccessor(typeName: typeName, bundle: bundle)
        header.append("#if TARGET_OS_IPHONE\n")
        header.append(accessor.0)
        header.append("#endif\n")
        header.append("\n")
        impl.append("#if TARGET_OS_IPHONE\n")
        impl.append(accessor.1)
        impl.append("#endif\n")
        impl.append("\n")

        if bundleClass != nil {
            impl.append(bundleClass!.1)
            impl.append("\n")
        }
    }

    return (header, impl)
}

private func objcClass(assets: [Asset], options: CodeOutputOptions, invocation: CatalogerInvocation) -> (String, String) {
    var header = ""
    var impl = ""

    let typeName = options.assetNamespace.name

    header.append(invocation.objcHeader)
    header.append("\n")
    header.append("@import UIKit;\n")
    header.append("\n")
    header.append("NS_ASSUME_NONNULL_BEGIN\n")
    header.append("\n")
    header.append("@interface \(typeName): NSObject\n")
    header.append("\n")

    impl.append(invocation.objcHeader)
    impl.append("\n")
    impl.append("#import \"\(typeName).h\"\n")
    impl.append("\n")
    impl.append("NS_ASSUME_NONNULL_BEGIN\n")
    impl.append("\n")
    impl.append("@implementation \(typeName)\n")
    impl.append("\n")

    let bundle = options.imageBundle ?? .byClass(typeName, defineClassInOutput: false)

    let groups: [String: [Asset]] = assets.groupBy { $0.group }
    for group in groups.keys.sorted() {
        if !group.isEmpty {
            header.append("#pragma mark - \(group)\n\n")
            impl.append("#pragma mark - \(group)\n\n")
        }
        for asset in groups[group]! {
            let assetName = CodeGeneration.identifier(asset.name, options: [.desnake])
            let (h, i) = objcStaticProperty(name: assetName, path: asset.path, type: asset.type, bundle: bundle)
            header.append(h)
            impl.append(i)
            impl.append("\n")
        }
        header.append("\n")
        impl.append("\n")
    }

    header.append("@end\n")
    header.append("\n")
    header.append("NS_ASSUME_NONNULL_END\n")

    impl.append("@end\n")
    impl.append("\n")
    impl.append("NS_ASSUME_NONNULL_END\n")

    return (header, impl)
}

private func objcTypedef(assetNamespace: AssetNamespace) -> String {
    switch assetNamespace {
    case .closedEnum(let name): return "typedef NSString * \(name) NS_STRING_ENUM;\n"
    case .extensibleEnum(let name): return "typedef NSString * \(name) NS_EXTENSIBLE_STRING_ENUM;\n"
    case .extensibleEnumExtension: return "";
    case .classProperties: return "";
    }
}

private func objcStaticProperty(name: String, path: String, type: Asset.AssetType, bundle: BundleIdentification, returnOptional: Bool = false) -> (String, String) {
    let bundleCode = bundle.objcOutput
    let nullable = returnOptional ? "nullable " : ""
    let quotedPath = CodeGeneration.quoted(path)

    let returnType: String
    let loadAsset: String
    switch type {
    case .Image:
        returnType = "UIImage *"
        loadAsset = "[UIImage imageNamed:@\(quotedPath) inBundle:bundle compatibleWithTraitCollection:nil]"
    case .DataAsset:
        returnType = "NSDataAsset *"
        loadAsset = "[[NSDataAsset alloc] initWithName:@\(quotedPath) bundle:bundle]"
    }

    let header = "+ (\(nullable)\(returnType))\(name);\n"

    var impl = ""
    impl.append(    "+ (\(nullable)\(returnType))\(name)\n")
    impl.append(    "{\n")
    impl.append(    "    \(returnType)asset = nil;\n")
    impl.append(    "    NSBundle *bundle = \(bundleCode);\n")
    impl.append(    "    if (bundle) {\n")
    impl.append(    "        asset = \(loadAsset);\n")
    impl.append(    "    }\n")
    impl.append(    "\n")
    if !returnOptional {
        impl.append("    NSAssert(asset != nil, @\"Unable to find asset at path %@\", @\(quotedPath));\n")
    }
    impl.append(    "    return asset;\n")
    impl.append(    "}\n")

    return (header, impl)
}

private func objcUIImageAccessor(typeName: String, bundle: BundleIdentification, returnOptional: Bool = false) -> (String, String) {
    let returnType = returnOptional ? "nullable UIImage *" : "nonnull UIImage *"
    let bundleCode = bundle.objcOutput

    var header = ""
    header.append(    "@interface UIImage (\(typeName))\n")
    header.append(    "+ (\(returnType))imageWith\(typeName):(nonnull \(typeName))asset;\n")
    header.append(    "@end\n")

    var impl = ""
    impl.append(    "@implementation UIImage (\(typeName))\n")
    impl.append(    "\n")
    impl.append(    "+ (\(returnType))imageWith\(typeName):(nonnull \(typeName))asset\n")
    impl.append(    "{\n")
    impl.append(    "    UIImage *image = nil;\n")
    impl.append(    "    NSBundle *bundle = \(bundleCode);\n")
    impl.append(    "    if (bundle) {\n")
    impl.append(    "    }\n")
    impl.append(    "\n")
    if !returnOptional {
        impl.append("    NSAssert(image != nil, @\"Unable to find image for asset %@\", asset);\n")
    }
    impl.append(    "    return image;\n")
    impl.append(    "}\n")
    impl.append(    "\n")
    impl.append(    "@end\n")

    return (header, impl)
}

private func objcBundleClass(bundle: BundleIdentification) -> (String, String)? {
    if case let .byClass(className, defineClassInOutput: true) = bundle {
        var iface = ""
        iface.append("// Class used to reference bundle for image loading\n")
        iface.append("@interface \(className) : NSObject\n")
        iface.append("@end\n")

        var impl = ""
        impl.append("@implementation \(className)\n")
        impl.append("@end\n")

        return (iface, impl)
    }
    return nil
}

private extension BundleIdentification {
    var objcOutput: String {
        switch self {
        case .byClass(let className, defineClassInOutput: _): return "[NSBundle bundleForClass:\(className).class]"
        case .byIdentifier(let identifier): return "[NSBundle bundleWithIdentifier:@\(CodeGeneration.quoted(identifier))]"
        case .byPath(let path): return "[NSBundle bundleWithPath:@\(CodeGeneration.quoted(path))]"
        }
    }
}
