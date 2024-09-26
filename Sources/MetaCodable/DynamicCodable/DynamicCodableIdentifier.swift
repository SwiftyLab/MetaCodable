/// The identifier option for ``DynamicCodable`` types.
///
/// The identifier has option of one value or a group of values.
public enum DynamicCodableIdentifier<Value>: Equatable, Sendable
where Value: Equatable & Sendable {
    /// Represents identifier with a single value.
    ///
    /// The ``DynamicCodable`` type is decoded if this value is matched.
    /// When encoding the value is also encoded.
    ///
    /// - Parameter value: The single identifier value.
    case one(_ value: Value)
    /// Represents identifier with a group of value.
    ///
    /// The ``DynamicCodable`` type is decoded if any of the value is matched.
    /// When encoding, only the first value is encoded.
    ///
    /// - Parameter value: The single identifier value.
    case many(_ values: [Value])

    /// Returns a Boolean value indicating whether two values are equivalent.
    ///
    /// `True` if the identifier value is exactly equal when left value has only
    /// one identifier or left value contains the identifier value in case of
    /// multiple identifiers, `False` otherwise.
    ///
    /// - Parameters:
    ///   - left: The ``DynamicCodableIdentifier`` value.
    ///   - right: The identifier value compared.
    ///
    /// - Returns: Whether identifier value is equivalent.
    public static func ~= (left: Self, right: Value) -> Bool {
        return switch left {
        case .one(let value):
            value == right
        case .many(let values):
            values.contains(right)
        }
    }

    /// Returns a Boolean value indicating whether two values are equivalent.
    ///
    /// The result is `true`
    /// * If both have single exact identifier.
    /// * If one of the single identifier contained in another group.
    /// * Both group identifiers contain same elements, order may vary.
    /// otherwise result is `false`.
    ///
    /// - Parameters:
    ///   - left: The ``DynamicCodableIdentifier`` value.
    ///   - right: The identifier value compared.
    ///
    /// - Returns: Whether identifier value is equivalent.
    public static func ~= (
        left: Self, right: Self
    ) -> Bool where Value: Hashable {
        return switch (left, right) {
        case let (.one(left), .one(right)):
            left == right
        case let (.one(value), .many(values)):
            values.contains(value)
        case let (.many(values), .one(value)):
            values.contains(value)
        case let (.many(left), .many(right)):
            Set(left).subtracting(Set(right)).isEmpty
        }
    }
}

extension DynamicCodableIdentifier: Encodable where Value: Encodable {
    /// Encodes identifier value into the given encoder.
    ///
    /// Encodes first identifier value only, if multiple identifiers present.
    ///
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: If encoding identifier value throws.
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .one(let value):
            try value.encode(to: encoder)
        case .many(let values):
            guard let value = values.first else { return }
            try value.encode(to: encoder)
        }
    }
}
