extension SequenceCoder {
    /// The additional customization data for ``SequenceCoder``.
    ///
    /// Can be used to provide additional error handling etc. for
    /// sequence decoding and encoding.
    ///
    /// Exposed options, i.e. ``lossy-swift.type.property``, ``default(_:)``
    /// etc. can be combined to provide configurations from each option.
    public struct Configuration {
        /// Whether sequence decoded in a lossy manner.
        ///
        /// Invalid element data from sequence will be ignored
        /// instead of failing decoding.
        public let lossy: Bool
        /// The sequence to use in case of invalid data.
        ///
        /// If data type doesn't match a sequence when decoding,
        /// this value is returned instead of failing decoding.
        public let invalidDefault: Sequence?
        /// The sequence to use in case of empty data.
        ///
        /// If no valid data is found during decoding this
        /// sequence is returned.
        public let emptyDefault: Sequence?

        /// Create new configuration from provided data.
        ///
        /// By default, no fallback value used for invalid data type or
        /// empty data.
        ///
        /// - Parameters:
        ///   - lossy: Whether sequence decoded in a lossy manner.
        ///   - invalidDefault: The sequence to use in case of invalid data.
        ///   - emptyDefault: The sequence to use in case of empty data.
        public init(
            lossy: Bool = false,
            invalidDefault: Sequence? = nil, emptyDefault: Sequence? = nil
        ) {
            self.lossy = lossy
            self.invalidDefault = invalidDefault
            self.emptyDefault = emptyDefault
        }
    }
}

extension SequenceCoder.Configuration: OptionSet {
    /// Configuration with lossy decoding enabled.
    ///
    /// Only lossy decoding is enabled, no default values provided.
    public static var lossy: Self { .init(lossy: true) }

    /// Configuration with default value when empty data or invalid data type
    /// encountered.
    ///
    /// Only fallback data to be used in case of invalid type or empty data
    /// provided, lossy decoding isn't provided.
    ///
    /// - Parameter value: The sequence to use.
    /// - Returns: The created configuration.
    public static func `default`(_ value: Sequence) -> Self {
        return [.defaultWhenInvalid(value), .defaultWhenEmpty(value)]
    }
    /// Configuration with default value when invalid data type encountered.
    ///
    /// Only default data to be used when invalid type provided, lossy decoding
    /// and fallback data for empty data isn't provided.
    ///
    /// - Parameter value: The sequence to use.
    /// - Returns: The created configuration.
    public static func defaultWhenInvalid(_ value: Sequence) -> Self {
        return .init(lossy: false, invalidDefault: value, emptyDefault: nil)
    }
    /// Configuration with default value when empty data encountered.
    ///
    /// Only default data to be used when empty provided, lossy decoding
    /// and fallback data for invalid type isn't provided.
    ///
    /// - Parameter value: The sequence to use.
    /// - Returns: The created configuration.
    public static func defaultWhenEmpty(_ value: Sequence) -> Self {
        return .init(lossy: false, invalidDefault: nil, emptyDefault: value)
    }

    /// Creates a new configuration from provided configuration.
    ///
    /// Assigns the provided configuration to created configuration.
    ///
    /// - Parameter rawValue: The configuration to create from.
    public init(rawValue: Self) {
        self = rawValue
    }

    /// The corresponding config value.
    ///
    /// Represents current value.
    public var rawValue: Self { self }

    /// Create default configuration.
    ///
    /// Lossy decoding and default values aren't set.
    public init() {
        self.init(lossy: false, invalidDefault: nil, emptyDefault: nil)
    }

    /// Merges provided configuration with current.
    ///
    /// The merged configuration has:
    /// * lossy decoding if either had lossy decoding enabled.
    /// * default value from new configuration is used if provided,
    ///   otherwise old values are preserved.
    ///
    /// - Parameter other: The new configuration.
    public mutating func formUnion(_ other: __owned Self) {
        self = .init(
            lossy: lossy || other.lossy,
            invalidDefault: other.invalidDefault ?? invalidDefault,
            emptyDefault: other.emptyDefault ?? emptyDefault
        )
    }

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    ///
    /// - Returns: Whether two values are equal.
    private static func areEqual(_ lhs: Sequence?, _ rhs: Sequence?) -> Bool {
        func `is`<T: Equatable>(value lhs: T, equalTo rhs: Any?) -> Bool {
            return lhs == (rhs as? T)
        }

        guard
            let lhs = lhs as? any Equatable
        else { return false }
        return `is`(value: lhs, equalTo: rhs)
    }

    /// Updates current configuration in sync with provided configuration.
    ///
    /// The updated configuration has:
    /// * lossy decoding if both had lossy decoding enabled.
    /// * default value is used if both had same default values.
    ///
    /// - Parameter other: The new configuration.
    public mutating func formIntersection(_ other: Self) {
        let invalidDefault =
            if Self.areEqual(other.invalidDefault, self.invalidDefault) {
                self.invalidDefault
            } else {
                nil as Sequence?
            }
        let emptyDefault =
            if Self.areEqual(other.emptyDefault, self.emptyDefault) {
                self.emptyDefault
            } else {
                nil as Sequence?
            }
        self = .init(
            lossy: lossy && other.lossy,
            invalidDefault: invalidDefault,
            emptyDefault: emptyDefault
        )
    }

    /// Removes provided configuration data from current configuration.
    ///
    /// The updated configuration has:
    /// * lossy decoding if both had lossy decoding enabled.
    /// * default values are removed.
    ///
    /// - Parameter other: The new configuration.
    public mutating func formSymmetricDifference(_ other: __owned Self) {
        self = .init(
            lossy: lossy && other.lossy,
            invalidDefault: nil,
            emptyDefault: nil
        )
    }

    /// Returns a Boolean value indicating whether two configurations are equal.
    ///
    /// True only if all the configuration data match.
    ///
    /// - Parameters:
    ///   - lhs: A configuration to compare.
    ///   - rhs: Another configuration to compare.
    ///
    /// - Returns: True only if all the configuration data match.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.lossy == rhs.lossy
            && areEqual(lhs.invalidDefault, rhs.invalidDefault)
            && areEqual(lhs.emptyDefault, rhs.emptyDefault)
    }
}
