import Foundation

/// A decoder wrapper that carries inherited strict-decoding key metadata.
public struct MetaCodableStrictDecoder: Decoder {
    private let base: any Decoder
    fileprivate let state: State

    /// Creates a decoder wrapper with additional keys accepted at each path.
    ///
    /// - Parameters:
    ///   - decoder: The decoder to wrap.
    ///   - allowedKeysByPath: Additional accepted keys keyed by dot-separated
    ///     coding paths. The empty string represents the root container.
    public init(
        decoder: any Decoder,
        allowedKeysByPath: [String: [String]]
    ) {
        self.base = decoder
        self.state = .init(allowedKeysByPath: allowedKeysByPath)
    }

    fileprivate init(base: any Decoder, state: State) {
        self.base = base
        self.state = state
    }

    /// The coding path of the wrapped decoder.
    public var codingPath: [any CodingKey] { base.codingPath }
    /// The user information of the wrapped decoder.
    public var userInfo: [CodingUserInfoKey: Any] { base.userInfo }

    /// Creates a keyed container that preserves inherited key metadata.
    public func container<Key: CodingKey>(
        keyedBy type: Key.Type
    ) throws -> KeyedDecodingContainer<Key> {
        let container = try base.container(keyedBy: type)
        return KeyedDecodingContainer(
            StrictKeyedDecodingContainer(base: container, state: state)
        )
    }

    /// Creates an unkeyed container from the wrapped decoder.
    public func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        try base.unkeyedContainer()
    }

    /// Creates a single-value container from the wrapped decoder.
    public func singleValueContainer() throws
        -> any SingleValueDecodingContainer
    {
        try base.singleValueContainer()
    }

    fileprivate func additionalKeys(at path: [any CodingKey]) -> Set<String> {
        state.additionalKeys(at: path)
    }

    fileprivate final class State {
        let allowedKeysByPath: [String: Set<String>]
        var observedKeysByPath: [String: Set<String>] = [:]

        init(allowedKeysByPath: [String: [String]]) {
            self.allowedKeysByPath = allowedKeysByPath.mapValues(Set.init)
        }

        func record(key: any CodingKey, at path: [any CodingKey]) {
            let path = Self.path(for: path)
            observedKeysByPath[path, default: []].insert(key.stringValue)
        }

        func additionalKeys(at path: [any CodingKey]) -> Set<String> {
            let path = Self.path(for: path)
            return (allowedKeysByPath[path] ?? []).union(
                observedKeysByPath[path] ?? []
            )
        }

        static func path(for codingPath: [any CodingKey]) -> String {
            codingPath.map(\.stringValue).joined(separator: ".")
        }
    }
}

private struct StrictKeyedDecodingContainer<Key: CodingKey>:
    KeyedDecodingContainerProtocol
{
    let base: KeyedDecodingContainer<Key>
    let state: MetaCodableStrictDecoder.State

    var codingPath: [any CodingKey] { base.codingPath }
    var allKeys: [Key] { base.allKeys }

    func contains(_ key: Key) -> Bool {
        state.record(key: key, at: codingPath)
        return base.contains(key)
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        state.record(key: key, at: codingPath)
        return try base.decodeNil(forKey: key)
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }

    #if swift(>=6)
    @available(
        macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *
    )
    func decode(_ type: Int128.Type, forKey key: Key) throws -> Int128 {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }

    @available(
        macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0, *
    )
    func decode(_ type: UInt128.Type, forKey key: Key) throws -> UInt128 {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }
    #endif

    func decode<T: Decodable>(
        _ type: T.Type,
        forKey key: Key
    ) throws -> T {
        state.record(key: key, at: codingPath)
        return try base.decode(type, forKey: key)
    }

    func nestedContainer<NestedKey: CodingKey>(
        keyedBy type: NestedKey.Type,
        forKey key: Key
    ) throws -> KeyedDecodingContainer<NestedKey> {
        state.record(key: key, at: codingPath)
        let nested = try base.nestedContainer(keyedBy: type, forKey: key)
        return KeyedDecodingContainer(
            StrictKeyedDecodingContainer<NestedKey>(base: nested, state: state)
        )
    }

    func nestedUnkeyedContainer(
        forKey key: Key
    ) throws -> any UnkeyedDecodingContainer {
        state.record(key: key, at: codingPath)
        return try base.nestedUnkeyedContainer(forKey: key)
    }

    func superDecoder() throws -> any Decoder {
        MetaCodableStrictDecoder(
            base: try base.superDecoder(), state: state
        )
    }

    func superDecoder(forKey key: Key) throws -> any Decoder {
        state.record(key: key, at: codingPath)
        return MetaCodableStrictDecoder(
            base: try base.superDecoder(forKey: key), state: state
        )
    }
}

public extension Decoder {
    /// Throws when the keyed value contains keys outside the provided set.
    ///
    /// - Parameters:
    ///   - allowedKeys: The string values recognized by the generated decoder
    ///     at this container level.
    ///   - type: The type being decoded, used in the error context.
    /// - Throws: ``DecodingError/dataCorrupted(_:)`` when unsupported keys
    ///   are present or when the container cannot be inspected.
    func rejectUnknownKeys(
        allowedKeys: [String],
        type: Any.Type
    ) throws {
        let rawContainer = try container(
            keyedBy: DynamicCodableIdentifier<String>.self
        )
        let inheritedKeys =
            (self as? MetaCodableStrictDecoder)?.additionalKeys(
                at: codingPath
            ) ?? []
        let allowedKeys = Set(allowedKeys).union(inheritedKeys)
        let unknownKeys = rawContainer.allKeys
            .map(\.stringValue)
            .filter { !allowedKeys.contains($0) }
            .sorted()
        guard !unknownKeys.isEmpty else { return }

        let context = DecodingError.Context(
            codingPath: codingPath,
            debugDescription:
                "Unsupported keys found while decoding \(type): "
                + unknownKeys.joined(separator: ", ")
        )
        throw DecodingError.dataCorrupted(context)
    }

    /// Validates all keyed paths generated for a strict inherited class.
    func rejectUnknownKeys(
        allowedKeysByPath: [String: [String]],
        type: Any.Type
    ) throws {
        let rawContainer = try container(
            keyedBy: DynamicCodableIdentifier<String>.self
        )
        try rawContainer.rejectUnknownKeys(
            atPath: "",
            allowedKeysByPath: allowedKeysByPath,
            type: type,
            state: (self as? MetaCodableStrictDecoder)?.state
        )
    }
}

private extension KeyedDecodingContainer
where Key == DynamicCodableIdentifier<String> {
    func rejectUnknownKeys(
        atPath path: String,
        allowedKeysByPath: [String: [String]],
        type: Any.Type,
        state: MetaCodableStrictDecoder.State?
    ) throws {
        let inheritedKeys =
            state?.additionalKeys(at: codingPath) ?? []
        let allowedKeys = Set(allowedKeysByPath[path] ?? [])
            .union(inheritedKeys)
        let unknownKeys =
            allKeys
            .map(\.stringValue)
            .filter { !allowedKeys.contains($0) }
            .sorted()
        guard unknownKeys.isEmpty else {
            let context = DecodingError.Context(
                codingPath: codingPath,
                debugDescription:
                    "Unsupported keys found while decoding \(type): "
                    + unknownKeys.joined(separator: ", ")
            )
            throw DecodingError.dataCorrupted(context)
        }

        for key in allKeys {
            let childPath =
                path.isEmpty ? key.stringValue : "\(path).\(key.stringValue)"
            guard allowedKeysByPath[childPath] != nil,
                let nested = try? nestedContainer(
                    keyedBy: DynamicCodableIdentifier<String>.self,
                    forKey: key
                )
            else { continue }
            try nested.rejectUnknownKeys(
                atPath: childPath,
                allowedKeysByPath: allowedKeysByPath,
                type: type,
                state: state
            )
        }
    }
}
