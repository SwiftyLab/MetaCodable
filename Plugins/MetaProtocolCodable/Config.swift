@_implementationOnly import Foundation

/// The configuration data for plugin.
///
/// Depending on the configuration data, source file check and
/// syntax generation is performed.
struct Config {
    /// The source file scan mode.
    ///
    /// Specifies which source files need to be parsed for syntax generation.
    let scan: ScanMode

    /// The source file scan mode.
    ///
    /// Specifies which source files need to be parsed for syntax generation.
    enum ScanMode: String, Codable {
        /// Represents to check current target.
        ///
        /// Files only from the target which includes plugin are checked.
        case target
        /// Represents to check current target and target dependencies.
        ///
        /// Files from the target which includes plugin and target dependencies
        /// present in current package manifest are checked.
        case local
        /// Represents to check current target and all dependencies.
        ///
        /// Files from the target which includes plugin and all its
        /// dependencies are checked.
        case recursive
    }
}

extension Config: Codable {
    /// Creates a new instance by decoding from the given decoder.
    ///
    /// The scanning mode is set to only scan target unless specified
    /// explicitly.
    ///
    /// - Parameter decoder: The decoder to read data from.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.scan =
            try container.decodeIfPresent(
                ScanMode.self, forKey: .scan
            ) ?? .target
    }

    static func url(forFilePath filePath: String) -> URL {
        #if canImport(Darwin)
        if #available(macOS 13, iOS 16, macCatalyst 16, tvOS 16, watchOS 9, *) {
            return URL(filePath: filePath)
        } else {
            return URL(fileURLWithPath: filePath)
        }
        #else
        return URL(fileURLWithPath: filePath)
        #endif
    }
}
