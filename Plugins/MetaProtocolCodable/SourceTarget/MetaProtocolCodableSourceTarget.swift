import PackagePlugin

/// Represents a target consisting of a source code module,
/// containing `Swift` source files.
///
/// Targets from multiple build system can support this plugin
/// by providing conformance.
protocol MetaProtocolCodableSourceTarget {
    /// Type representing sequence of files.
    associatedtype FileSequence: Sequence
    where FileSequence.Element == FileList.Element

    /// The name of the module produced
    /// by the target.
    ///
    /// This is used as additional imports in
    /// plugin generated code.
    var moduleName: String { get }
    /// The targets on which the current target depends on.
    ///
    /// These targets are scanned if `direct` scan mode
    /// provided in config.
    var dependencyTargets: [Self] { get }
    /// All the targets on which current target depends on.
    ///
    /// These targets are scanned if `recursive` scan mode
    /// provided in config.
    var recursiveTargets: [Self] { get }

    /// A list of source files in the target that have the given
    /// filename suffix.
    ///
    /// The list can possibly be empty if no file matched.
    ///
    /// - Parameter suffix: The name suffix.
    /// - Returns: The matching files.
    func sourceFiles(withSuffix suffix: String) -> FileSequence
    /// The absolute path to config file if provided.
    ///
    /// The file name comparison is case-insensitive
    /// and if no match found `nil` is returned.
    ///
    /// - Parameter name: The config file name.
    /// - Returns: The config file path.
    func configPath(named name: String) throws -> String?
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
    func scanInput<Context: MetaProtocolCodablePluginContext>(
        for target: Context.Target, in context: Context
    ) -> (targets: [Context.Target], modules: [String]) {
        let allTargets: [Context.Target]
        let modules: [String]
        switch scan {
        case .target:
            allTargets = [target]
            modules = []
        case .direct:
            var targets = target.dependencyTargets
            modules = targets.map(\.moduleName)
            targets.append(target)
            allTargets = targets
        case .local:
            allTargets = context.localTargets.filter { localTarget in
                return target.recursiveTargets.contains { target in
                    return target.moduleName == localTarget.moduleName
                }
            }
            modules = allTargets.lazy.map(\.moduleName).filter { module in
                return module != target.moduleName
            }
        case .recursive:
            var targets = target.recursiveTargets
            modules = targets.map(\.moduleName)
            targets.append(target)
            allTargets = targets
        }
        return (allTargets, modules)
    }
}
