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
            <*> m <| Switch(key: "public", usage: "Generate code for public assets")
    }

    private static func create(lang: Language) -> (AssetNamespace) -> (BundleIdentification?) -> (Bool) -> CodeOutputOptions {
        return { ns in { bundle in { isPublic in
            return CodeOutputOptions(
                language: lang,
                assetNamespace: ns,
                imageBundle: bundle,
                useQualifiedNames: false,
                isPublic: isPublic)
        } } }
    }

    var effectiveCommandLineArguments: [String] {
        var args: [String] = []

        args.append("--lang")
        args.append(language.rawValue)

        switch assetNamespace {
        case .closedEnum(let name): args.append(contentsOf: ["--type", "enum", "--name", name])
        case .extensibleEnum(let name): args.append(contentsOf: ["--type", "extensible", "--name", name])
        case .extensibleEnumExtension(let name): args.append(contentsOf: ["--type", "extension", "--name", name])
        case .classProperties(let name): args.append(contentsOf: ["--type", "class", "--name", name])
        }

        if let bundle = imageBundle {
            switch bundle {
            case .byClass(let className, defineClassInOutput: let define):
                args.append(contentsOf: ["--bundle-class", className])
                if define {
                    args.append(contentsOf: ["--define-class"])
                }
            case .byIdentifier(let identifier):
                args.append(contentsOf: ["--bundle-id", identifier])
            case .byPath(let path):
                args.append(contentsOf: ["--bundle-path", path])
            }
        }

        return args
    }
}

enum Language: String, ArgumentProtocol {
    case swift = "swift"
    case objC = "objc"

    static let name: String = "language"

    /// Attempts to parse a value from the given command-line argument.
    static func from(string: String) -> Language? {
        return Language(rawValue: string.lowercased())
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
    case classProperties(String)

    var name: String {
        switch self {
        case .closedEnum(let name): return name
        case .extensibleEnum(let name): return name
        case .extensibleEnumExtension(let name): return name
        case .classProperties(let name): return name
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
            <*> m <| Option(key: "type", defaultValue: AssetNamespace.AwaitingName.from(string: "enum")!, usage: "The type of values to generate. Can be \"enum\", \"extensible\", \"extension\" or \"class\". Default: enum")
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
            case "class": return AwaitingName(AssetNamespace.classProperties)
            default: return nil
            }
        }
    }
}
