#if canImport(XcodeProjectPlugin)
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
        return dependencies.compactMap { dependency in
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
        return dependencies.flatMap { dependency in
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
        return self.inputFiles.filter {
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
    func configPath(named name: String) -> String? {
        let file = inputFiles.first { file in
            #if swift(>=6)
            let path = file.url.lastPathComponent
            #else
            let path = file.path.stem
            #endif
            let fileName = path.components(separatedBy: .alphanumerics.inverted)
                .joined(separator: "")
                .lowercased()
            return name.lowercased() == fileName
        }
        #if swift(>=6)
        return file?.url.lastPathComponent
        #else
        return file?.path.stem
        #endif
    }
}
#endif
