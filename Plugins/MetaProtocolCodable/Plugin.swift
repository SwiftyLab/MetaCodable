@_implementationOnly import Foundation
@_implementationOnly import PackagePlugin

/// Provides `protocol` decoding/encoding syntax generation.
///
/// Creates build commands that produces syntax for `protocol`s
/// that indicate dynamic decoding/encoding with `Codable` macro.
@main
struct MetaProtocolCodable: BuildToolPlugin {
    /// Fetches config data from file.
    ///
    /// The alphanumeric characters of file name must case-insensitively
    /// match `"metacodableconfig"`, and the data contained must be
    /// either `plist` or `json` format, i.e. `metacodable-config.json`,
    /// `metacodable_config.json`,  `MetaCodableConfig.plist` are
    /// all valid names.
    ///
    /// - Parameter target: The target including plugin.
    /// - Returns: The config if provided, otherwise default config.
    func fetchConfig(for target: SourceModuleTarget) async throws -> Config {
        let fileManager = FileManager.default
        let directory = target.directory.string
        let contents = try fileManager.contentsOfDirectory(atPath: directory)
        let file = contents.first { file in
            let path = Path(file)
            let name = path.stem
                .components(separatedBy: .alphanumerics.inverted)
                .joined(separator: "")
                .lowercased()
            return name == "metacodableconfig"
        }
        guard let file else { return .init(scan: .target) }
        let pathStr = target.directory.appending([file]).string
        let path = Config.url(forFilePath: pathStr)
        let conf = try Data(contentsOf: path)
        let pConf = try? PropertyListDecoder().decode(Config.self, from: conf)
        let config = try pConf ?? JSONDecoder().decode(Config.self, from: conf)
        return config
    }

    /// Invoked by SwiftPM to create build commands for a particular target.
    ///
    /// Creates build commands that produces intermediate files scanning
    /// swift source files according to configuration. Final build command
    /// generates syntax aggregating all intermediate files.
    ///
    /// - Parameters:
    ///   - context: The package and environmental inputs context.
    ///   - target: The target including plugin.
    ///
    /// - Returns: The commands to be executed during build.
    func createBuildCommands(
        context: PluginContext, target: Target
    ) async throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }
        let tool = try context.tool(named: "ProtocolGen")
        // Get Config
        let config = try await fetchConfig(for: target)
        let (allTargets, imports) = config.scanInput(for: target)
        // Setup folder
        let genFolder = context.pluginWorkDirectory.appending(["ProtocolGen"])
        try FileManager.default.createDirectory(
            atPath: genFolder.string, withIntermediateDirectories: true
        )

        // Create source scan commands
        var intermFiles: [Path] = []
        var buildCommands = allTargets.flatMap { target in
            return target.sourceFiles(withSuffix: "swift").map { file in
                let moduleName = target.moduleName
                let fileName = file.path.stem
                let genFileName = "\(moduleName)-\(fileName)-gen.json"
                let genFile = genFolder.appending([genFileName])
                intermFiles.append(genFile)
                return Command.buildCommand(
                    displayName: """
                        Parse source file "\(fileName)" in module "\(moduleName)"
                        """,
                    executable: tool.path,
                    arguments: [
                        "parse",
                        file.path.string,
                        "--output",
                        genFile.string,
                    ],
                    inputFiles: [file.path],
                    outputFiles: [genFile]
                )
            }
        }

        // Create syntax generation command
        let moduleName = target.moduleName
        let genFileName = "\(moduleName)+ProtocolHelperCoders.swift"
        let genPath = genFolder.appending(genFileName)
        var genArgs = ["generate", "--output", genPath.string]
        for `import` in imports {
            genArgs.append(contentsOf: ["--module", `import`])
        }
        for file in intermFiles {
            genArgs.append(file.string)
        }
        buildCommands.append(
            .buildCommand(
                displayName: """
                    Generate protocol decoding/encoding syntax for "\(moduleName)"
                    """,
                executable: tool.path,
                arguments: genArgs,
                inputFiles: intermFiles,
                outputFiles: [genPath]
            )
        )
        return buildCommands
    }
}

extension Config {
    /// Returns targets to scan and import modules based on current
    /// configuration.
    ///
    /// Based on configuration, the targets for which source files need
    /// to be checked and the modules that will be imported in final syntax
    /// generated is returned.
    ///
    /// - Parameter target: The target including plugin.
    /// - Returns: The targets to scan and modules to import.
    func scanInput(
        for target: SourceModuleTarget
    ) -> (targets: [SourceModuleTarget], modules: [String]) {
        let allTargets: [SourceModuleTarget]
        let modules: [String]
        switch scan {
        case .target:
            allTargets = [target]
            modules = []
        case .local:
            var targets = target.dependencies.compactMap { dependency in
                return switch dependency {
                case .target(let target):
                    target.sourceModule
                default:
                    nil
                }
            }
            modules = targets.map(\.moduleName)
            targets.append(target)
            allTargets = targets
        case .recursive:
            var targets = target.recursiveTargetDependencies.compactMap {
                return $0 as? SourceModuleTarget
            }
            modules = targets.map(\.moduleName)
            targets.append(target)
            allTargets = targets
        }
        return (allTargets, modules)
    }
}
