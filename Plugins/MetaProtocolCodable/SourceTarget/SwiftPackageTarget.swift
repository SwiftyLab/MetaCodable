import Foundation
import PackagePlugin

/// Represents an SwiftPM target.
///
/// Uses `SourceModuleTarget` to provide conformances.
struct SwiftPackageTarget {
    /// The actual module for this target.
    ///
    /// The conformances provided uses this module.
    let module: any SourceModuleTarget
}

extension SwiftPackageTarget: MetaProtocolCodableSourceTarget {
    /// The name of the module produced
    /// by the target.
    ///
    /// This is derived from target name or SwiftPM customized name.
    var moduleName: String { module.moduleName }

    /// The targets on which the current target depends on.
    ///
    /// Represents direct dependencies of the target.
    var dependencyTargets: [Self] {
        module.dependencies.lazy.compactMap { dependency in
            return switch dependency {
            case .target(let target):
                target.sourceModule
            default:
                nil
            }
        }.map { Self.init(module: $0) }
    }

    /// All the targets on which current target depends on.
    ///
    /// Represents direct and transient dependencies of the target.
    var recursiveTargets: [Self] {
        module.recursiveTargetDependencies.lazy
            .compactMap { $0.sourceModule }
            .map { Self.init(module: $0) }
    }

    /// A list of source files in the target that have the given
    /// filename suffix.
    ///
    /// The list can possibly be empty if no file matched.
    ///
    /// - Parameter suffix: The name suffix.
    /// - Returns: The matching files.
    func sourceFiles(withSuffix suffix: String) -> FileList {
        module.sourceFiles(withSuffix: suffix)
    }

    /// The absolute path to config file if provided.
    ///
    /// The file name comparison is case-insensitive
    /// and if no match found `nil` is returned.
    ///
    /// The file is checked only in the module directory
    /// and not in any of its sub-directories.
    ///
    /// - Parameter name: The config file name.
    /// - Returns: The config file path.
    func configPath(named name: String) throws -> URL? {
        let fileManager = FileManager.default
        let directory = module.directoryURL
        let contents = try fileManager.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil
        )
        return contents.first { file in
            name.lowercased()
                == file.deletingPathExtension().lastPathComponent
                .components(separatedBy: .alphanumerics.inverted)
                .joined(separator: "")
                .lowercased()
        }
    }
}
