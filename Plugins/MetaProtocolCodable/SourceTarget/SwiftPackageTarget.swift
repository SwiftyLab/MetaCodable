import Foundation
import PackagePlugin

/// This is a workaround because PackageDescription.Target.directoryURL will not be available until version 6.1
/// See:  https://github.com/swiftlang/swift-package-manager/blob/735ddd97fa651729921315c8e46bd790429362cb/Sources/PackagePlugin/PackageModel.swift#L184-L186///
/// The workaround defines a custom protocol that adds the missing property, and then introduces
/// a new initializer that accepts the actual target protocol and attempts to downcast.
protocol CompatSourceModuleTarget: SourceModuleTarget {
    var directoryURL: URL { get }
}

/// Represents an SwiftPM target.
///
/// Uses `SourceModuleTarget` to provide conformances.
struct SwiftPackageTarget {
    /// The actual module for this target.
    ///
    /// The conformances provided uses this module.
    let module: any CompatSourceModuleTarget
    
}

/// Workaround for 6.1 compatibility
extension ClangSourceModuleTarget: CompatSourceModuleTarget {}
extension SwiftSourceModuleTarget: CompatSourceModuleTarget {}

extension SwiftPackageTarget {
init<M>(module: M) where M: SourceModuleTarget {
    switch module {
    case let module as ClangSourceModuleTarget:
        self.module = module
        case let module as SwiftSourceModuleTarget:
        self.module = module
    default:
        fatalError("Unsupported module type")
    }
}
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
        return module.dependencies.lazy.compactMap { dependency in
            return switch dependency {
            case .target(let target):
                target.sourceModule
            default:
                nil
            }
        }.map { (target: any SourceModuleTarget) in  Self.init(module: target) }
    }

    /// All the targets on which current target depends on.
    ///
    /// Represents direct and transient dependencies of the target.
    var recursiveTargets: [Self] {
        return module.recursiveTargetDependencies.lazy
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
        return module.sourceFiles(withSuffix: suffix)
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
    func configPath(named name: String) throws -> String? {
        let fileManager = FileManager.default
        let directory = module.directoryURL
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let file = contents.first { file in
            return name.lowercased()
                == file.lastPathComponent
                .components(separatedBy: .alphanumerics.inverted)
                .joined(separator: "")
                .lowercased()
        }
        guard let file else { return nil }
        return directory.appending(path: file.absoluteString).absoluteString
    }
}
