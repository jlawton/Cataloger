//
//  CommandLineOptions.swift
//  Cataloger
//
//  Created by James Lawton on 3/19/17.
//  Copyright © 2017 James Lawton. All rights reserved.
//

import Foundation

struct CodeOutputOptions: OptionsProtocol {
    let language: Language
    let assetNamespace: AssetNamespace
    let imageBundle: BundleIdentification?
    let useQualifiedNames: Bool
    let isPublic: Bool

    static func evaluate(_ m: CommandMode) -> Result<CodeOutputOptions, CommandantError<CatalogerError>> {
        return create
            <*> m <| Option(key: "lang", defaultValue: Language.swift, usage: "The language to output. Can be \"swift\" or \"objc\". Default: swift")
            <*> AssetNamespace.evaluate(m)
            <*> BundleIdentification.evaluate(m)
    }

    private static func create(lang: Language) -> (AssetNamespace) -> (BundleIdentification?) -> CodeOutputOptions {
        return { ns in { bundle in
            return CodeOutputOptions(
                language: lang,
                assetNamespace: ns,
                imageBundle: bundle,
                useQualifiedNames: false,
                isPublic: false)
        } }
    }
}

enum Language: ArgumentProtocol {
    case swift
    case objC

    static let name: String = "language"

    /// Attempts to parse a value from the given command-line argument.
    static func from(string: String) -> Language? {
        switch string.lowercased() {
        case "swift": return .swift
        case "objc": fallthrough
        case "objectivec": fallthrough
        case "objective-c": return .objC
        default: return nil
        }
    }
}

enum BundleIdentification {
    case byClass(String, defineClassInOutput: Bool)
    case byPath(String)
    case byIdentifier(String)
}

enum AssetNamespace {
    case closedEnum(String)
    case extensibleEnum(String)
    case extensibleEnumExtension(String)

    var name: String {
        switch self {
        case .closedEnum(let name): return name
        case .extensibleEnum(let name): return name
        case .extensibleEnumExtension(let name): return name
        }
    }
}

private extension BundleIdentification {
    static func evaluate(_ m: CommandMode) -> Result<BundleIdentification?, CommandantError<CatalogerError>> {
        return create
            <*> m <| Option(key: "bundle-class", defaultValue: nil, usage: "The name of the class used to find the asset bundle. Default: none")
            <*> m <| Option(key: "bundle-path", defaultValue: nil, usage: "The path used to find the asset bundle in the output code. Default: none")
            <*> m <| Option(key: "bundle-id", defaultValue: nil, usage: "The identifier of the asset bundle. Default: none")
            <*> m <| Switch(flag: nil, key: "define-class", usage: "Define a class with the name given to --bundle-class")
    }

    static func create(_ className: String?) -> (String?) -> (String?) -> (Bool) -> BundleIdentification? {
        return { path in { identifier in { defineClass in
            if let className = className {
                return BundleIdentification.byClass(className, defineClassInOutput: defineClass)
            }
            if let path = path {
                return BundleIdentification.byPath(path)
            }
            if let identifier = identifier {
                return BundleIdentification.byIdentifier(identifier)
            }
            return nil
        } } }
    }
}

private extension AssetNamespace {
    static func evaluate(_ m: CommandMode) -> Result<AssetNamespace, CommandantError<CatalogerError>> {
        return { $0.withName }
            <*> m <| Option(key: "type", defaultValue: AssetNamespace.AwaitingName.from(string: "enum")!, usage: "The type of values to generate. Can be \"enum\", \"extensible\" or \"extension\". Default: enum")
            <*> m <| Option(key: "name", defaultValue: "Asset", usage: "The name of the type in code. Default: Asset")
    }

    struct AwaitingName: ArgumentProtocol {
        let withName: (String) -> AssetNamespace
        private init(_ withName: @escaping (String) -> AssetNamespace) {
            self.withName = withName
        }

        static let name: String = "asset value type"

        static func from(string: String) -> AwaitingName? {
            switch string.lowercased() {
            case "enum": return AwaitingName(AssetNamespace.closedEnum)
            case "extensible": return AwaitingName(AssetNamespace.extensibleEnum)
            case "extension": return AwaitingName(AssetNamespace.extensibleEnumExtension)
            default: return nil
            }
        }
    }
}
