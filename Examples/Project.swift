import ProjectDescription

let defaultSettings: SettingsDictionary = [:].codeSignIdentity("_")

let project = Project(
    name: "MetaCodable",
    packages: [
        .local(path: "../")
    ],
    targets: [
        .target(
            name: "MetaCodablemacOS",
            destinations: .macOS,
            product: .app,
            bundleId: "io.SwiftyLab.MetaCodable",
            deploymentTargets: .macOS("11.0"),
            sources: ["App/Sources/**"],
            resources: ["App/Resources/**"],
            dependencies: []
        ),
        .target(
            name: "MetaCodableiOS",
            destinations: .iOS,
            product: .app,
            bundleId: "io.SwiftyLab.MetaCodable",
            deploymentTargets: .iOS("14.0"),
            sources: ["App/Sources/**"],
            resources: ["App/Resources/**"],
            dependencies: [],
            settings: .settings(base: defaultSettings)
        ),
        .target(
            name: "MetaCodableMultiPlatform",
            destinations: [.mac, .iPhone],
            product: .app,
            bundleId: "io.SwiftyLab.MetaCodable",
            deploymentTargets: .multiplatform(iOS: "14.0", macOS: "11.0"),
            sources: ["App/Sources/**"],
            resources: ["App/Resources/**"],
            dependencies: [
                .package(product: "MetaCodable", type: .runtime),
                .package(product: "HelperCoders", type: .runtime),
                .package(product: "MetaProtocolCodable", type: .plugin),
            ],
            settings: .settings(base: defaultSettings)
        ),
    ]
)
