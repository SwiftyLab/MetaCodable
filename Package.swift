// swift-tools-version: 6.0
// swift-format-ignore-file

import CompilerPluginSupport
import Foundation
import PackageDescription

let package = Package(
    name: "MetaCodable",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13),
    ],
    products: [
        .library(name: "MetaCodable", targets: ["MetaCodable"]),
        .library(name: "HelperCoders", targets: ["HelperCoders"]),
        .plugin(name: "MetaProtocolCodable", targets: ["MetaProtocolCodable"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "509.1.0"..<"603.0.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.4"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        // MARK: Core
        .target(
            name: "PluginCore",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "OrderedCollections", package: "swift-collections"),
            ]
        ),

        // MARK: Macro
        .macro(
            name: "MacroPlugin",
            dependencies: [
                "PluginCore",
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(name: "MetaCodable", dependencies: ["MacroPlugin"]),
        .target(name: "HelperCoders", dependencies: ["MetaCodable"]),

        // MARK: Build Tool
        .executableTarget(
            name: "ProtocolGen",
            dependencies: [
                "PluginCore", "MetaCodable",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
            ]
        ),
        .plugin(
            name: "MetaProtocolCodable", capability: .buildTool(),
            dependencies: ["ProtocolGen"]
        ),

        // MARK: Test
        .testTarget(
            name: "MetaCodableTests",
            dependencies: [
                "PluginCore", "MacroPlugin", "MetaCodable", "HelperCoders",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ],
            plugins: ["MetaProtocolCodable"]
        ),
    ],
    swiftLanguageModes: [.v6, .v5]
)

extension Package.Dependency.Kind {
    var repoName: String? {
        guard
            case let .sourceControl(
                name: _, location: location, requirement: _
            ) = self,
            let location = URL(string: location),
            let name = location.lastPathComponent.split(separator: ".").first
        else { return nil }
        return String(name)
    }
}

var unusedDeps: Set<String> = []
var includeTargets: Set<String> = []
var includeProducts: Set<String> = []

if Context.environment["METACODABLE_BEING_USED_FROM_COCOAPODS"] != nil { // CocoaPods specific
    unusedDeps.formUnion(["swift-format", "swift-docc-plugin"])
    includeTargets.formUnion(["PluginCore", "MacroPlugin"])
    includeProducts.insert("MacroPlugin")
    package.products.append(.executable(name: "MacroPlugin", targets: ["MacroPlugin"]))
    package.targets = package.targets.compactMap { target in
        guard target.type == .macro else { return target }
        return .executableTarget(
            name: target.name,
            dependencies: target.dependencies,
            path: target.path,
            exclude: target.exclude,
            sources: target.sources,
            resources: target.resources,
            publicHeadersPath: target.publicHeadersPath,
            cSettings: target.cSettings,
            cxxSettings: target.cxxSettings,
            swiftSettings: target.swiftSettings,
            linkerSettings: target.linkerSettings,
            plugins: target.plugins
        )
    }

    if Context.environment["METACODABLE_COCOAPODS_PROTOCOL_PLUGIN"] != nil {
        includeTargets.insert("ProtocolGen")
        includeProducts.insert("ProtocolGen")
        package.products.append(
            .executable(name: "ProtocolGen", targets: ["ProtocolGen"])
        )
    } else {
        unusedDeps.insert("swift-argument-parser")
    }
} else if Context.environment["METACODABLE_CI"] == nil { // SPM specific
    unusedDeps.insert("swift-format")
    package.targets.removeAll { $0.name == "MetaCodableTests" }
    package.targets.append(
        .testTarget(
            name: "MetaCodableTests",
            dependencies: [
                "PluginCore", "MacroPlugin", "MetaCodable", "HelperCoders",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ],
            plugins: ["MetaProtocolCodable"]
        )
    )

    if Context.environment["SPI_GENERATE_DOCS"] == nil {
        unusedDeps.insert("swift-docc-plugin")
    }
}

package.dependencies.removeAll { unusedDeps.contains($0.kind.repoName ?? "") }

if !includeTargets.isEmpty {
    package.targets.removeAll { !includeTargets.contains($0.name) }
}

if !includeProducts.isEmpty {
    package.products.removeAll { !includeProducts.contains($0.name) }
}
