import PackageDescription

let appTarget = package.targets.first!
appTarget.plugins.append(
    .plugin(
        name: "MetaProtocolCodable",
        package: "MetaCodable"
    )
)
