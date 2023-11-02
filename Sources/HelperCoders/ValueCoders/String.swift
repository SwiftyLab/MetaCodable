extension String: ValueCodingStrategy {
    /// Decodes text data from the given `decoder`.
    ///
    /// Decodes basic data type `String,` `Bool`, `Int`, `UInt`,
    /// `Double` and converts to string representation.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The decoded text.
    ///
    /// - Throws: If decoding fails due to corrupted or invalid data
    ///   or couldn't decode basic data type.
    public static func decode(from decoder: Decoder) throws -> String {
        do {
            return try Self(from: decoder)
        } catch {
            let fallbackTypes: [(Decodable & CustomStringConvertible).Type] = [
                Bool.self,
                Int.self,
                UInt.self,
                Double.self,
            ]
            guard
                let value = fallbackTypes.lazy.compactMap({
                    return (try? $0.init(from: decoder))?.description
                }).first
            else { throw error }
            return value
        }
    }
}
