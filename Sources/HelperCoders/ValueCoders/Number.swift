/// A ``ValueCodingStrategy`` type that specializes decoding/encoding
/// numeric data.
protocol NumberCodingStrategy: ValueCodingStrategy where Value == Self {}

public extension ValueCodingStrategy
where Value: Decodable & ExpressibleByIntegerLiteral & LosslessStringConvertible
{
    /// Decodes numeric data from the given `decoder`.
    ///
    /// Decodes basic data type `String,` `Bool`
    /// and converts to numeric representation.
    ///
    /// For decoded boolean type `true` is mapped to `1`
    /// and `false` to `0`.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The decoded number.
    ///
    /// - Throws: If decoding fails due to corrupted or invalid data
    ///   or decoded data can't be mapped to numeric type.
    static func decode(from decoder: Decoder) throws -> Value {
        do {
            return try Value(from: decoder)
        } catch {
            let fallbacks: [(Decoder) -> Value?] = [
                String.numberValue,
                Bool.numberValue,
                Double.numberValue,
            ]
            guard let value = fallbacks.lazy.compactMap({ $0(decoder) }).first
            else { throw error }
            return value
        }
    }
}

private extension Bool {
    /// Decodes optional numeric data from the given `decoder`.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The decoded number value, `nil` if boolean
    ///   data can't be decoded.
    static func numberValue<Number>(
        from decoder: Decoder
    ) -> Number? where Number: ExpressibleByIntegerLiteral {
        guard let boolValue = try? Self(from: decoder) else { return nil }
        return boolValue ? 1 : 0
    }
}

private extension String {
    /// Decodes optional numeric data from the given `decoder`.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The decoded number value, `nil` if text data
    ///   can't be decoded or converted to numeric representation.
    static func numberValue<Number>(
        from decoder: Decoder
    ) -> Number?
    where Number: LosslessStringConvertible & ExpressibleByIntegerLiteral {
        guard let strValue = try? Self(from: decoder) else { return nil }
        return Number(strValue) ?? Number(exact: Double(strValue))
    }
}

internal extension Double {
    /// Decodes optional numeric data from the given `decoder`.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The decoded number value, `nil` if float
    ///   data can't be converted to exact number value.
    @inlinable
    static func numberValue<Number>(
        from decoder: Decoder
    ) -> Number? where Number: ExpressibleByIntegerLiteral {
        return Number(exact: try? Self(from: decoder))
    }
}

internal extension ExpressibleByIntegerLiteral {
    /// Converts optional given float to integer.
    ///
    /// - Parameter float: The float value to convert.
    /// - Returns: The integer value, `nil` if float
    ///   data can't be converted to exact integer value.
    @usableFromInline
    init?(exact float: Double?) {
        guard
            let float = float,
            let type = Self.self as? any BinaryInteger.Type,
            let intVal = type.init(exactly: float) as (any BinaryInteger)?,
            let val = intVal as? Self
        else { return nil }
        self = val
    }
}

extension Double: NumberCodingStrategy {}
extension Float: NumberCodingStrategy {}
extension Int: NumberCodingStrategy {}
extension Int64: NumberCodingStrategy {}
extension Int32: NumberCodingStrategy {}
extension Int16: NumberCodingStrategy {}
extension Int8: NumberCodingStrategy {}
extension UInt: NumberCodingStrategy {}
extension UInt64: NumberCodingStrategy {}
extension UInt32: NumberCodingStrategy {}
extension UInt16: NumberCodingStrategy {}
extension UInt8: NumberCodingStrategy {}
