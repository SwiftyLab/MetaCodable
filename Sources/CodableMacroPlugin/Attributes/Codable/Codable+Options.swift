import Foundation
import SwiftSyntax

extension Codable {
    /// A type indicating various configuration options available
    /// for `Codable` macro-attribute.
    ///
    /// These options are used as global level customization
    /// performed on the final generated implementation
    /// by `Codable` macro-attribute.
    struct Options {
        /// The default options used.
        ///
        /// If no or invalid customization options are provided,
        /// this default options data is used instead.
        static let `default`: Self = .init(ignoreInitialized: false)
        /// Whether to ignore initialized variables
        /// in decoding and encoding by default.
        ///
        /// When set to `true`, initialized mutable variables
        /// are ignored from decoding and encoding unless
        /// explicitly asked with attached coding attributes,
        /// i.e. `CodedIn`, `CodedAt` etc.
        ///
        /// The default value for this option is `false`.
        let ignoreInitialized: Bool
    }
}

extension Codable.Options: Decodable {
    /// Creates a new instance by decoding from the given decoder.
    ///
    /// This initializer throws an error if reading from the decoder fails,
    /// or if the data read is corrupted or otherwise invalid.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: Decoded options.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.ignoreInitialized = try container.decodeIfPresent(
            Bool.self,
            forKey: .ignoreInitialized
        ) ?? false
    }

    /// Creates a new instance by reading provided
    /// options data from macro-attribute.
    ///
    /// Parses arguments passed to `@Codable`
    /// macro-attribute and creates the options instance.
    /// If no or invalid arguments provided, default options
    /// are used.
    ///
    /// - Parameter node: The attribute syntax
    ///                   to read options from.
    ///
    /// - Returns: Decoded options.
    init(from node: AttributeSyntax) {
        let body = node.argument?.as(TupleExprElementListSyntax.self)?
            .compactMap { element in
                guard
                    let key = element.label,
                    case let value = element.expression
                else { return nil }
                do {
                    let pair = #""\#(key)": \#(value)"#
                    let json = "{\(pair)}".data(using: .utf8)!
                    let _ = try JSONSerialization.jsonObject(with: json)
                    return pair
                } catch {
                    return #""\#(key)": "\#(value)""#
                }
            }.joined(separator: ",") ?? ""
        let json = "{\(body)}".data(using: .utf8)!
        self = (try? JSONDecoder().decode(Self.self, from: json)) ?? .default
    }

    /// The coding keys for `@Codable`
    /// macro-attribute options.
    ///
    /// The field of the options type is mapped to
    /// equivalent argument name in `@Codable`
    /// macro-attribute.
    enum CodingKeys: String, CodingKey {
        /// Label representing `ignoreInitialized`
        /// options property in `@Codable`
        /// macro-attribute.
        ///
        /// This argument is optional and
        /// default value is used in case
        /// not specified.
        case ignoreInitialized
    }
}
