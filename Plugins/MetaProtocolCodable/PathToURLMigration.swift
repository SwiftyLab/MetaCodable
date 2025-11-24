import Foundation
import PackagePlugin

#if swift(<6)
extension PluginContext.Tool {
    /// Full path of the built or provided tool in the file system.
    var url: URL {
        Config.url(forFilePath: path.string)
    }
}

extension PackagePlugin.File {
    /// The path of the file.
    var url: URL {
        Config.url(forFilePath: path.string)
    }
}

extension PluginContext {
    /// The path of a writable directory into which the plugin or the build
    /// commands it constructs can write anything it wants. This could include
    /// any generated source files that should be processed further, and it
    /// could include any caches used by the build tool or the plugin itself.
    /// The plugin is in complete control of what is written under this di-
    /// rectory, and the contents are preserved between builds.
    ///
    /// A plugin would usually create a separate subdirectory of this directory
    /// for each command it creates, and the command would be configured to
    /// write its outputs to that directory. The plugin may also create other
    /// directories for cache files and other file system content that either
    /// it or the command will need.
    var pluginWorkDirectoryURL: URL {
        Config.url(forFilePath: pluginWorkDirectory.string)
    }
}

extension Command {
    /// Returns a command that runs when any of its output files are needed by
    /// the build, but out-of-date.
    ///
    /// An output file is out-of-date if it doesn't exist, or if any input files
    /// have changed since the command was last run.
    ///
    /// - Note: the paths in the list of output files may depend on the list of
    ///   input file paths, but **must not** depend on reading the contents of
    ///   any input files. Such cases must be handled using a `prebuildCommand`.
    ///
    /// - parameters:
    ///   - displayName: An optional string to show in build logs and other
    ///     status areas.
    ///   - executable: The absolute path to the executable to be invoked.
    ///   - arguments: Command-line arguments to be passed to the executable.
    ///   - environment: Environment variable assignments visible to the
    ///     executable.
    ///   - inputFiles: Files on which the contents of output files may depend.
    ///     Any paths passed as `arguments` should typically be passed here as
    ///     well.
    ///   - outputFiles: Files to be generated or updated by the executable.
    ///     Any files recognizable by their extension as source files
    ///     (e.g. `.swift`) are compiled into the target for which this command
    ///     was generated as if in its source directory; other files are treated
    ///     as resources as if explicitly listed in `Package.swift` using
    ///     `.process(...)`.
    static func buildCommand(
        displayName: String?, executable: URL, arguments: [String],
        environment: [String: String] = [:], inputFiles: [URL] = [],
        outputFiles: [URL] = []
    ) -> Self {
        .buildCommand(
            displayName: displayName,
            executable: .init(Config.filePath(forURL: executable)),
            arguments: arguments,
            environment: environment,
            inputFiles: inputFiles.map { .init(Config.filePath(forURL: $0)) },
            outputFiles: outputFiles.map { .init(Config.filePath(forURL: $0)) }
        )
    }
}

#if canImport(XcodeProjectPlugin)
extension XcodePluginContext {
    /// The path of a writable directory into which the plugin or the build
    /// commands it constructs can write anything it wants. This could include
    /// any generated source files that should be processed further, and it
    /// could include any caches used by the build tool or the plugin itself.
    /// The plugin is in complete control of what is written under this di-
    /// rectory, and the contents are preserved between builds.
    ///
    /// A plugin would usually create a separate subdirectory of this directory
    /// for each command it creates, and the command would be configured to
    /// write its outputs to that directory. The plugin may also create other
    /// directories for cache files and other file system content that either
    /// it or the command will need.
    var pluginWorkDirectoryURL: URL {
        Config.url(forFilePath: pluginWorkDirectory.string)
    }
}
#endif
#endif

extension SourceModuleTarget {
    /// The absolute path of the target directory in the local file system.
    var directoryURL: URL {
        #if swift(<6)
        return Config.url(forFilePath: directory.string)
        #else
        switch self {
        case let target as ClangSourceModuleTarget:
            return target.directoryURL
        case let target as SwiftSourceModuleTarget:
            return target.directoryURL
        default:
            fatalError("Unsupported target type")
        }
        #endif
    }
}
