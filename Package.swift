// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let macroDeps: [Target.Dependency] = [
    .product(name: "SwiftSyntax", package: "swift-syntax"),
    .product(name: "SwiftDiagnostics", package: "swift-syntax"),
    .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
    .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
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
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13),
    ],
    products: [
        .library(name: "MetaCodable", targets: ["MetaCodable"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0-swift-DEVELOPMENT-SNAPSHOT-2023-07-09-a"),
        .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.4"),
    ],
    targets: [
        .macro(name: "CodableMacroPlugin", dependencies: macroDeps),
        .target(name: "MetaCodable", dependencies: ["CodableMacroPlugin"]),
        .testTarget(name: "MetaCodableTests", dependencies: testDeps),
    ]
)
