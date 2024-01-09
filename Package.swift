// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

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
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.1.0"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.4"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
        .package(url: "https://github.com/apple/swift-format", from: "509.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        // MARK: Core
        .target(
            name: "PluginCore",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
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
    ]
)

if Context.environment["SWIFT_SYNTAX_EXTENSION_MACRO_FIXED"] != nil {
    package.dependencies.remove(at: 0)
    package.dependencies.append(
        .package(
            url: "https://github.com/soumyamahunt/swift-syntax.git",
            branch: "extension-macro-assert-fix"
        )
    )

    package.targets.forEach { target in
        guard target.isTest else { return }
        var settings = target.swiftSettings ?? []
        settings.append(.define("SWIFT_SYNTAX_EXTENSION_MACRO_FIXED"))
        target.swiftSettings = settings
    }
}
