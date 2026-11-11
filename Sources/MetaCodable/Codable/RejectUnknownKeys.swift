import Foundation

private protocol MetaCodableDictionary {}

extension Dictionary: MetaCodableDictionary {}

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
        if let decoder = decoder as? MetaCodableStrictDecoder {
            self.base = decoder.base
            let codingPath = decoder.codingPath.map(\.stringValue)
            if codingPath == decoder.state.rootCodingPath {
                self.state = decoder.state
                self.state.merge(allowedKeysByPath: allowedKeysByPath)
            } else {
                self.state = .init(
                    allowedKeysByPath: allowedKeysByPath,
                    rootCodingPath: codingPath
                )
            }
        } else {
            self.base = decoder
            self.state = .init(
                allowedKeysByPath: allowedKeysByPath,
                rootCodingPath: decoder.codingPath.map(\.stringValue)
            )
        }
    }

    /// Decodes an optional value while preserving strict-decoding metadata.
    public static func decodeOptional<Value: Decodable>(
        _ type: Value.Type,
        from decoder: any Decoder
    ) throws -> Value? {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            return nil
        }
        let isStrictDecoder = decoder is MetaCodableStrictDecoder
        if !isStrictDecoder
            || Value.self == Date.self
            || Value.self == Data.self
            || Value.self == Decimal.self
            || Value.self is any MetaCodableDictionary.Type
        {
            return try container.decode(Value.self)
        }
        return try Value(from: decoder)
    }

    /// Begins an isolated decoding attempt for backtracking decoders.
    public static func beginAttempt(for decoder: any Decoder) -> Attempt {
        guard let strictDecoder = decoder as? MetaCodableStrictDecoder
        else {
            return Attempt(decoder: decoder)
        }

        let isolatedState = strictDecoder.state.copy()
        let isolatedDecoder = MetaCodableStrictDecoder(
            base: strictDecoder.base,
            state: isolatedState
        )
        return Attempt(
            decoder: isolatedDecoder,
            commit: {
                strictDecoder.state.replace(with: isolatedState)
            }
        )
    }

    /// An isolated decoding attempt whose state is committed only on success.
    public final class Attempt {
        /// The decoder used by this attempt.
        public let decoder: any Decoder
        private let commitAction: (() -> Void)?
        private var finished = false

        fileprivate init(decoder: any Decoder) {
            self.decoder = decoder
            self.commitAction = nil
        }

        fileprivate init(
            decoder: any Decoder,
            commit: @escaping () -> Void
        ) {
            self.decoder = decoder
            self.commitAction = commit
        }

        /// Commits observed metadata and consumed keys to the parent decoder.
        public func commit() {
            guard !finished else { return }
            finished = true
            commitAction?()
        }

        /// Discards all metadata and consumed keys observed by the attempt.
        public func rollback() {
            finished = true
        }
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
        state.recordContainer(at: container.codingPath)
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
        var allowedKeysByPath: [String: Set<String>]
        var observedKeysByPath: [String: Set<String>] = [:]
        var observedContainerPaths: Set<String> = []
        var terminalDecoderPaths: Set<String> = []
        let rootCodingPath: [String]

        init(
            allowedKeysByPath: [String: [String]],
            rootCodingPath: [String]
        ) {
            self.allowedKeysByPath = allowedKeysByPath.mapValues(Set.init)
            self.rootCodingPath = rootCodingPath
        }

        func record(key: any CodingKey, at path: [any CodingKey]) {
            let path = self.path(for: path)
            observedKeysByPath[path, default: []].insert(key.stringValue)
        }

        func recordContainer(at path: [any CodingKey]) {
            observedContainerPaths.insert(self.path(for: path))
        }

        func recordTerminalDecoder(at path: [any CodingKey]) {
            terminalDecoderPaths.insert(self.path(for: path))
        }

        func clearTerminalDecoder(at path: [any CodingKey]) {
            terminalDecoderPaths.remove(self.path(for: path))
        }

        func hasContainerPath(_ path: String) -> Bool {
            observedContainerPaths.contains(path)
        }

        func hasTerminalDecoder(at path: [any CodingKey]) -> Bool {
            terminalDecoderPaths.contains(self.path(for: path))
        }

        func additionalKeys(at path: [any CodingKey]) -> Set<String> {
            let path = self.path(for: path)
            return (allowedKeysByPath[path] ?? []).union(
                observedKeysByPath[path] ?? []
            )
        }

        func merge(allowedKeysByPath: [String: [String]]) {
            for (path, keys) in allowedKeysByPath {
                self.allowedKeysByPath[path, default: []].formUnion(keys)
            }
        }

        func copy() -> State {
            let copy = State(
                allowedKeysByPath: allowedKeysByPath.mapValues(Array.init),
                rootCodingPath: rootCodingPath
            )
            copy.observedKeysByPath = observedKeysByPath
            copy.observedContainerPaths = observedContainerPaths
            copy.terminalDecoderPaths = terminalDecoderPaths
            return copy
        }

        func replace(with other: State) {
            allowedKeysByPath = other.allowedKeysByPath
            observedKeysByPath = other.observedKeysByPath
            observedContainerPaths = other.observedContainerPaths
            terminalDecoderPaths = other.terminalDecoderPaths
        }

        fileprivate func path(for codingPath: [any CodingKey]) -> String {
            let components = codingPath.map(\.stringValue)
            let relative =
                components.starts(with: rootCodingPath)
                ? Array(components.dropFirst(rootCodingPath.count))
                : components
            return relative.map { component in
                "\(component.utf8.count):\(component)"
            }.joined(separator: "|")
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
        state.recordContainer(at: codingPath + [key])
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
        let decoder = try base.superDecoder()
        if decoder.codingPath.count > codingPath.count,
            let key = decoder.codingPath.last
        {
            state.record(key: key, at: codingPath)
        }
        return MetaCodableStrictDecoder(base: decoder, state: state)
    }

    func superDecoder(forKey key: Key) throws -> any Decoder {
        state.record(key: key, at: codingPath)
        let decoder = try base.superDecoder(forKey: key)
        state.recordTerminalDecoder(at: decoder.codingPath)
        return MetaCodableStrictDecoder(base: decoder, state: state)
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
        if let strictDecoder = self as? MetaCodableStrictDecoder {
            strictDecoder.state.clearTerminalDecoder(at: codingPath)
        }
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
        let rawContainer:
            KeyedDecodingContainer<
                DynamicCodableIdentifier<String>
            >
        do {
            rawContainer = try container(
                keyedBy: DynamicCodableIdentifier<String>.self
            )
        } catch let error as DecodingError {
            switch error {
            case .typeMismatch, .valueNotFound:
                return
            default:
                throw error
            }
        }
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
            if state?.hasTerminalDecoder(
                at: codingPath + [key]
            ) == true {
                continue
            }
            let childPath =
                state?.path(for: codingPath + [key]) ?? path
            guard
                allowedKeysByPath[childPath] != nil
                    || state?.hasContainerPath(childPath) == true,
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
