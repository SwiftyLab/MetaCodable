// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let macroDeps: [Target.Dependency] = [
    .product(name: "SwiftSyntax", package: "swift-syntax"),
    .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
    .product(name: "SwiftOperators", package: "swift-syntax"),
    .product(name: "SwiftParser", package: "swift-syntax"),
    .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
    .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
    .product(name: "OrderedCollections", package: "swift-collections"),
]

let testDeps: [Target.Dependency] = [
    "CodableMacroPlugin", "MetaCodable",
    .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
]

let package = Package(
    name: "MetaCodable",
    platforms: [
        .iOS(.v8),
        .macOS(.v10_15),
        .tvOS(.v9),
        .watchOS(.v2),
        .macCatalyst(.v13),
    ],
    products: [
        .library(name: "MetaCodable", targets: ["MetaCodable"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0-swift-5.9-DEVELOPMENT-SNAPSHOT-2023-04-25-b"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.4"),
    ],
    targets: [
        .macro(name: "CodableMacroPlugin", dependencies: macroDeps),
        .target(name: "MetaCodable", dependencies: ["CodableMacroPlugin"]),
        .testTarget(name: "MetaCodableTests", dependencies: testDeps),
    ]
)
