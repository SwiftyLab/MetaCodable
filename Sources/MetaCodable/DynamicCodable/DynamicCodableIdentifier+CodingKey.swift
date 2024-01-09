extension DynamicCodableIdentifier: CustomStringConvertible
where Value: CustomStringConvertible {
    /// A textual representation of this instance.
    ///
    /// Provides description of underlying value(s).
    public var description: String {
        switch self {
        case .one(let key):
            return key.description
        case .many(let keys):
            return keys.description
        }
    }
}

extension DynamicCodableIdentifier: CustomDebugStringConvertible
where Value: CustomDebugStringConvertible {
    /// A textual representation of this instance, suitable for debugging.
    ///
    /// Provides debugging description of underlying value(s).
    public var debugDescription: String {
        switch self {
        case .one(let key):
            return key.debugDescription
        case .many(let keys):
            return keys.debugDescription
        }
    }
}

extension DynamicCodableIdentifier<String>: CodingKey {
    /// The value to use in an integer-indexed collection
    /// (e.g. an int-keyed dictionary).
    ///
    /// Set as always `nil`.
    public var intValue: Int? { nil }
    /// The string to use in a named collection
    /// (e.g. a string-keyed dictionary).
    ///
    /// Only first value used in case of multiple identifiers,
    /// the identifier value itself is used in case of single
    /// identifier.
    public var stringValue: String {
        return switch self {
        case .one(let key):
            key
        case .many(let keys):
            keys.first ?? ""
        }
    }

    /// Creates a new instance from the specified integer.
    ///
    /// Initialization fails always, resulting in `nil`.
    ///
    /// - parameter intValue: The integer value of the desired key.
    public init?(intValue: Int) { return nil }
    /// Creates a new instance from the given string.
    ///
    /// Uses given string as single identifier value.
    ///
    /// - parameter stringValue: The string value of the desired key.
    public init?(stringValue: String) { self = .one(stringValue) }

    /// Returns a Boolean value indicating whether two values are equivalent.
    ///
    /// `True` if the `stringValue` is exactly equal when left value has only
    /// one identifier or left value contains the `stringValue` in case of
    /// multiple identifiers, `False` otherwise.
    ///
    /// - Parameters:
    ///   - left: The ``DynamicCodableIdentifier`` value.
    ///   - right: The `CodingKey` compared.
    ///
    /// - Returns: Whether `stringValue` is equivalent.
    public static func ~= <Key: CodingKey>(left: Self, right: Key) -> Bool {
        return switch left {
        case .one(let value):
            value == right.stringValue
        case .many(let values):
            values.contains(right.stringValue)
        }
    }
}
