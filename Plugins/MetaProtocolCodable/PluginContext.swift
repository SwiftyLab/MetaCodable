@_implementationOnly import PackagePlugin

/// Provides information about the package for which the plugin is invoked,
/// as well as contextual information based on the plugin's stated intent
/// and requirements.
///
/// Build systems can provide their own conformance implementations.
protocol MetaProtocolCodablePluginContext {
    /// The source code module type associated with this context.
    ///
    /// Build can customize target type based on build context.
    associatedtype Target: MetaProtocolCodableSourceTarget
    /// The path of a writable directory into which the plugin or the build
    /// commands it constructs can write anything it wants. This could include
    /// any generated source files that should be processed further, and it
    /// could include any caches used by the build tool or the plugin itself.
    ///
    /// The plugin is in complete control of what is written under this
    /// directory, and the contents are preserved between builds.
    ///
    /// A plugin would usually create a separate subdirectory of this directory
    /// for each command it creates, and the command would be configured to
    /// write its outputs to that directory. The plugin may also create other
    /// directories for cache files and other file system content that either
    /// it or the command will need.
    var pluginWorkDirectory: Path { get }
    /// The targets which are local to current context.
    ///
    /// These targets are included in the same package/project as this context.
    /// These targets are scanned if `local` scan mode provided in config.
    var localTargets: [Target] { get }
    /// Looks up and returns the path of a named command line executable tool.
    ///
    /// The executable must be provided by an executable target or a binary
    /// target on which the package plugin target depends. This function throws
    /// an error if the tool cannot be found. The lookup is case sensitive.
    ///
    /// - Parameter name: The executable tool name.
    /// - Returns: The executable tool.
    func tool(named name: String) throws -> PluginContext.Tool
}

extension PluginContext: MetaProtocolCodablePluginContext {
    /// The targets which are local to current context.
    ///
    /// Includes all the source code targets of the package.
    var localTargets: [SwiftPackageTarget] {
        return `package`.targets.compactMap { target in
            guard let sourceModule = target.sourceModule else { return nil }
            return SwiftPackageTarget(module: sourceModule)
        }
    }
}

#if canImport(XcodeProjectPlugin)
@_implementationOnly import XcodeProjectPlugin

extension XcodePluginContext: MetaProtocolCodablePluginContext {
    /// The targets which are local to current context.
    ///
    /// Includes all the targets of the Xcode project.
    var localTargets: [XcodeTarget] { xcodeProject.targets }
}
#endif
