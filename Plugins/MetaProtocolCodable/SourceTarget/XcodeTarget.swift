#if canImport(XcodeProjectPlugin)
import Foundation
import PackagePlugin
import XcodeProjectPlugin

extension XcodeTarget: MetaProtocolCodableSourceTarget {
    /// The name of the module produced
    /// by the target.
    ///
    /// This is derived from target product name if present,
    /// falling back to target name.
    var moduleName: String { product?.name ?? displayName }

    /// The targets on which the current target depends on.
    ///
    /// Represents direct dependencies of the target.
    var dependencyTargets: [Self] {
        dependencies.compactMap { dependency in
            return switch dependency {
            case .target(let target):
                target
            default:
                nil
            }
        }
    }

    /// All the targets on which current target depends on.
    ///
    /// Represents direct and transient dependencies of the target.
    var recursiveTargets: [Self] {
        dependencies.flatMap { dependency in
            switch dependency {
            case .target(let target):
                var targets = [target]
                targets.append(contentsOf: target.recursiveTargets)
                return targets
            default:
                return []
            }
        }
    }

    /// A list of source files in the target that have the given
    /// filename suffix.
    ///
    /// The list can possibly be empty if no file matched.
    ///
    /// - Parameter suffix: The name suffix.
    /// - Returns: The matching files.
    func sourceFiles(withSuffix suffix: String) -> [FileList.Element] {
        self.inputFiles.filter {
            #if swift(>=6)
            $0.url.path.hasSuffix(suffix)
            #else
            $0.path.string.hasSuffix(suffix)
            #endif
        }
    }

    /// The absolute path to config file if provided.
    ///
    /// The file name comparison is case-insensitive
    /// and if no match found `nil` is returned.
    ///
    /// All the files in the target are checked.
    ///
    /// - Parameter name: The config file name.
    /// - Returns: The config file path.
    func configPath(named name: String) -> URL? {
        inputFiles.first { file in
            name.lowercased()
                == file.url.deletingPathExtension().lastPathComponent
                .components(separatedBy: .alphanumerics.inverted)
                .joined(separator: "")
                .lowercased()
        }?.url
    }
}
#endif
