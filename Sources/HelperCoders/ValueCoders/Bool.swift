import Foundation

extension Bool: ValueCodingStrategy {
    /// Decodes boolean data from the given `decoder`.
    ///
    /// Decodes basic data type `Bool`, `String`, `Int`, `Float`
    /// and converts to boolean representation with following rules.
    /// * For `Int` and `Float` types, `1` is mapped to `true`
    ///   and `0` to `false`, rest throw `DecodingError.typeMismatch` error.
    /// * For `String`` type, `1`, `y`, `t`, `yes`, `true` are mapped to
    ///   `true` and `0`, `n`, `f`, `no`, `false` to `false`,
    ///   rest throw `DecodingError.typeMismatch` error.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The decoded boolean.
    ///
    /// - Throws: If decoding fails due to corrupted or invalid basic data.
    public static func decode(from decoder: Decoder) throws -> Bool {
        do {
            return try Self(from: decoder)
        } catch {
            let fallbacks: [(Decoder) throws -> Bool?] = [
                String.boolValue,
                Int.boolValue,
                Float.boolValue,
            ]
            guard
                let value = try fallbacks.lazy.compactMap({
                    return try $0(decoder)
                }).first
            else { throw error }
            return value
        }
    }
}

private extension String {
    /// Decodes optional boolean data from the given `decoder`.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The decoded boolean matching representation,
    ///   `nil` otherwise.
    ///
    /// - Throws: If decoded data doesn't match boolean representation.
    static func boolValue(from decoder: Decoder) throws -> Bool? {
        guard let str = try? Self(from: decoder) else { return nil }
        let strValue = str.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        switch strValue {
        case "1", "y", "t", "yes", "true":
            return true
        case "0", "n", "f", "no", "false":
            return false
        default:
            switch Double(strValue) {
            case 1:
                return true
            case 0:
                return false
            case .some:
                throw DecodingError.typeMismatch(
                    Bool.self,
                    .init(
                        codingPath: decoder.codingPath,
                        debugDescription: """
                            "\(self)" can't be represented as Boolean
                            """
                    )
                )
            case .none:
                return nil
            }
        }
    }
}

private extension ExpressibleByIntegerLiteral
where Self: Decodable, Self: Equatable {
    /// Decodes optional boolean data from the given `decoder`.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: `true` if decoded `1`, `false` if decoded `0`,
    ///   `nil` if data of current type couldn't be decoded.
    ///
    /// - Throws: If decoded data doesn't match `0` or `1`.
    static func boolValue(from decoder: Decoder) throws -> Bool? {
        switch try? Self(from: decoder) {
        case 1:
            return true
        case 0:
            return false
        case .some:
            throw DecodingError.typeMismatch(
                Bool.self,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: """
                        "\(self)" can't be represented as Boolean
                        """
                )
            )
        case .none:
            return nil
        }
    }
}
