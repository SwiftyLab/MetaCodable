import Foundation

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
        case direct
        /// Represents to check all local target dependencies.
        ///
        /// Files from the target which includes plugin and all targets
        /// that are in the same project/package that are dependencies
        /// of this target.
        case local
        /// Represents to check current target and all dependencies.
        ///
        /// Files from the target which includes plugin and all its
        /// dependencies are checked.
        case recursive

        /// Creates a new instance by decoding from the given decoder.
        ///
        /// This initializer throws an error if reading from the decoder fails,
        /// or if the data read is corrupted or otherwise invalid.
        ///
        /// - Parameter decoder: The decoder to read data from.
        init(from decoder: Decoder) throws {
            let rawValue = try String(from: decoder).lowercased()
            guard let value = Self(rawValue: rawValue) else {
                throw DecodingError.typeMismatch(
                    Self.self,
                    .init(
                        codingPath: decoder.codingPath,
                        debugDescription: "Data doesn't match any case"
                    )
                )
            }
            self = value
        }
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
                ScanMode.self, forCaseInsensitiveKey: .scan
            ) ?? .target
    }

    /// Returns file path as URL converting provided string.
    ///
    /// Uses platform and version specific API to create URL file path.
    ///
    /// - Parameter filePath: The path to file as string.
    /// - Returns: The file path URL.
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

extension KeyedDecodingContainerProtocol {
    /// Decodes a value of the given type for the given key case-insensitively,
    /// if present.
    ///
    /// This method returns `nil` if the container does not have a value
    /// associated with key case-insensitively, or if the value is null.
    ///
    /// - Parameters:
    ///   - type: The type of value to decode.
    ///   - key: The key that the decoded value is associated with.
    ///
    /// - Returns: A decoded value of the requested type, or `nil`
    ///   if the `Decoder` does not have an entry associated with the given
    ///   key, or if the value is a null value.
    ///
    /// - Throws: `DecodingError.typeMismatch` if the encountered
    ///   encoded value is not convertible to the requested type or the key
    ///   value matches multiple value case-insensitively.
    func decodeIfPresent<T: Decodable>(
        _ type: T.Type,
        forCaseInsensitiveKey key: Key
    ) throws -> T? {
        let keys = self.allKeys.filter { eachKey in
            eachKey.stringValue.lowercased() == key.stringValue.lowercased()
        }

        guard keys.count <= 1 else {
            throw DecodingError.typeMismatch(
                type,
                .init(
                    codingPath: codingPath,
                    debugDescription: """
                    Duplicate keys found, keys are case-insensitive.
                    """
                )
            )
        }

        return try decodeIfPresent(type, forKey: keys.first ?? key)
    }
}
