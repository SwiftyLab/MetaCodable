import Foundation
import PackagePlugin

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
    func fetchConfig<Target: MetaProtocolCodableSourceTarget>(
        for target: Target
    ) throws -> Config {
        let pathStr = try target.configPath(named: "metacodableconfig")
        guard let pathStr else { return .init(scan: .target) }
        let path = Config.url(forFilePath: pathStr)
        let conf = try Data(contentsOf: path)
        let pConf = try? PropertyListDecoder().decode(Config.self, from: conf)
        let config = try pConf ?? JSONDecoder().decode(Config.self, from: conf)
        return config
    }

    /// Invoked by build systems to create build commands for a particular
    /// target.
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
    func createBuildCommands<Context>(
        in context: Context, for target: Context.Target
    ) throws -> [Command] where Context: MetaProtocolCodablePluginContext {
        // Get config
        let tool = try context.tool(named: "ProtocolGen")
        let config = try fetchConfig(for: target)
        let (allTargets, imports) = config.scanInput(for: target, in: context)

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

extension MetaProtocolCodable {
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
        return try self.createBuildCommands(
            in: context, for: SwiftPackageTarget(module: target)
        )
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension MetaProtocolCodable: XcodeBuildToolPlugin {
    /// Invoked by Xcode to create build commands for a particular target.
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
        context: XcodePluginContext, target: XcodeTarget
    ) throws -> [Command] {
        return try self.createBuildCommands(
            in: context, for: target
        )
    }
}
#endif
