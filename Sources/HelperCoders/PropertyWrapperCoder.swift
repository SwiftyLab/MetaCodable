import MetaCodable

/// An `HelperCoder` that helps decoding/encoding
/// using existing property wrappers.
///
/// This type can be used to reuse existing property
/// wrappers with custom decoding/encoding with
/// `MetaCodable` generated implementations.
public struct PropertyWrapperCoder<Wrapper: PropertyWrappable>: HelperCoder {
    /// Creates a new instance of `HelperCoder` that decodes/encodes
    /// using existing property wrappers.
    ///
    /// The property wrapper type `Wrapper` is used for decoding/encoding.
    public init() {}

    /// Decodes using `Wrapper` type from the given `decoder`.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Returns: The wrapped value decoded.
    /// - Throws: If the property wrapper throws error.
    @inlinable
    public func decode(from decoder: Decoder) throws -> Wrapper.Wrapped {
        return try Wrapper(from: decoder).wrappedValue
    }

    /// Encodes given value using `Wrapper` type to the provided `encoder`.
    ///
    /// - Parameters:
    ///   - value: The wrapped value to encode.
    ///   - encoder: The encoder to write data to.
    ///
    /// - Throws: If the property wrapper throws error.
    @inlinable
    public func encode(_ value: Wrapper.Wrapped, to encoder: Encoder) throws {
        try Wrapper(wrappedValue: value).encode(to: encoder)
    }
}

/// A type representing a [property wrapper].
///
/// A property wrapper adds a layer of separation
/// between code that manages how a property is stored
/// and the code that defines a property.
///
/// [property wrapper]: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/properties/#Property-Wrappers
public protocol PropertyWrappable: Codable {
    /// The type of the value wrapped.
    associatedtype Wrapped
    /// The value wrapped.
    var wrappedValue: Wrapped { get }
    /// Creates new instance wrapping provided value.
    ///
    /// - Parameters:
    ///   - wrappedValue: The value to be wrapped.
    init(wrappedValue: Wrapped)
}
