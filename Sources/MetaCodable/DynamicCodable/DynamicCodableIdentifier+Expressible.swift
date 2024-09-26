extension DynamicCodableIdentifier: ExpressibleByUnicodeScalarLiteral
where Value: ExpressibleByUnicodeScalarLiteral {
    /// Creates an instance initialized to the given value.
    ///
    /// Creates single identifier with the given value.
    ///
    /// - Parameter value: The value of the new instance.
    public init(unicodeScalarLiteral value: Value.UnicodeScalarLiteralType) {
        self = .one(.init(unicodeScalarLiteral: value))
    }
}

extension DynamicCodableIdentifier: ExpressibleByExtendedGraphemeClusterLiteral
where Value: ExpressibleByExtendedGraphemeClusterLiteral {
    /// Creates an instance initialized to the given value.
    ///
    /// Creates single identifier with the given value.
    ///
    /// - Parameter value: The value of the new instance.
    public init(
        extendedGraphemeClusterLiteral value: Value
            .ExtendedGraphemeClusterLiteralType
    ) {
        self = .one(.init(extendedGraphemeClusterLiteral: value))
    }
}

extension DynamicCodableIdentifier: ExpressibleByStringLiteral
where Value: ExpressibleByStringLiteral {
    /// Creates an instance initialized to the given string value.
    ///
    /// Creates single identifier with the given value.
    ///
    /// - Parameter value: The value of the new instance.
    public init(stringLiteral value: Value.StringLiteralType) {
        self = .one(.init(stringLiteral: value))
    }
}

extension DynamicCodableIdentifier: ExpressibleByIntegerLiteral
where Value: ExpressibleByIntegerLiteral {
    /// Creates an instance initialized to the specified integer value.
    ///
    /// Creates single identifier with the specified value.
    ///
    /// - Parameter value: The value to create.
    public init(integerLiteral value: Value.IntegerLiteralType) {
        self = .one(.init(integerLiteral: value))
    }
}

extension DynamicCodableIdentifier: ExpressibleByFloatLiteral
where Value: ExpressibleByFloatLiteral {
    /// Creates an instance initialized to the specified floating-point value.
    ///
    /// Creates single identifier with the specified value.
    ///
    /// - Parameter value: The value to create.
    public init(floatLiteral value: Value.FloatLiteralType) {
        self = .one(.init(floatLiteral: value))
    }
}

extension DynamicCodableIdentifier: ExpressibleByArrayLiteral {
    /// Creates an instance initialized with the given elements.
    ///
    /// Creates group identifiers containing the given elements.
    ///
    /// - Parameter elements: The elements to contain.
    public init(arrayLiteral elements: Value...) {
        self = .many(elements)
    }
}

extension DynamicCodableIdentifier: ExpressibleByNilLiteral
where Value: ExpressibleByNilLiteral {
    /// Creates an instance initialized with `nil`.
    ///
    /// Creates single identifier with the specified `nil` literal.
    ///
    /// - Parameter value: The `nil` value to assign.
    public init(nilLiteral value: ()) {
        self = .one(.init(nilLiteral: value))
    }
}
