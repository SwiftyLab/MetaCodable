import SwiftSyntax

/// A special `PropertyAttribute` that updates
/// `CodingKey` path data.
///
/// Attaching attribute of this type to variables indicates
/// explicit decoding/encoding of those variables.
protocol KeyPathProvider: PropertyAttribute {
    /// Indicates whether `CodingKey` path
    /// data is provided to this instance.
    ///
    /// If data is provided explicitly by attaching
    /// the macro then `true`, otherwise `false`
    /// This can be used to indicate variable is
    /// explicitly asked to decode/encode.
    var provided: Bool { get }

    /// Updates `CodingKey` path using the provided path.
    ///
    /// The `CodingKey` path may override current data
    /// or just update current `CodingKey` path.
    ///
    /// - Parameter path: Current `CodingKey` path.
    /// - Returns: Updated `CodingKey` path.
    func keyPath(withExisting path: [String]) -> [String]
}

extension KeyPathProvider {
    /// Returns `CodingKey` path
    /// provided in this attribute.
    ///
    /// The path components are provided
    /// as variadic arguments without any labels.
    ///
    /// - Important: The path components must be string literals
    ///   with single segment (i.e no interpolation, no string combinations).
    var providedPath: [String] {
        guard let exprs = node.arguments?.as(LabeledExprListSyntax.self)
        else { return [] }

        let path: [String] = exprs.compactMap { expr in
            guard expr.label == nil else { return nil }
            return expr.expression.as(StringLiteralExprSyntax.self)?
                .segments.first?.as(StringSegmentSyntax.self)?
                .content.text
        }
        return path
    }
}

extension CodedAt: KeyPathProvider {
    /// Indicates whether `CodingKey` path
    /// data is provided to this instance.
    ///
    /// Always `true` for this type.
    var provided: Bool { true }

    /// Updates `CodingKey` path using the provided path.
    ///
    /// The `CodingKey` path overrides current `CodingKey` path data.
    ///
    /// - Parameter path: Current `CodingKey` path.
    /// - Returns: Updated `CodingKey` path.
    func keyPath(withExisting path: [String]) -> [String] { providedPath }
}

extension CodedIn: KeyPathProvider {
    /// Indicates whether `CodingKey` path
    /// data is provided to this instance.
    ///
    /// If attribute is initialized with syntax node,
    /// then `true`, otherwise `false`.
    var provided: Bool { !inDefaultMode }

    /// Updates `CodingKey` path using the provided path.
    ///
    /// The `CodingKey` path is updated by prepending
    /// provided path to current `CodingKey` path.
    ///
    /// - Parameter path: Current `CodingKey` path.
    /// - Returns: Updated `CodingKey` path.
    func keyPath(withExisting path: [String]) -> [String] {
        var finalPath = providedPath
        finalPath.append(contentsOf: path)
        return finalPath
    }
}

extension Registration where Key == [String] {
    /// Update registration with `CodingKey` path data.
    ///
    /// New registration is updated with the provided `CodingKey` path from provider,
    /// updating current `CodingKey` path data.
    ///
    /// - Parameter provider: The `CodingKey` path data provider.
    /// - Returns: Newly built registration with additional `CodingKey` path data.
    func registerKeyPath(
        provider: KeyPathProvider
    ) -> Registration<Decl, Key, KeyedVariable<Var>> {
        typealias Output = KeyedVariable<Var>
        let options = Output.Options(code: provider.provided)
        let newVar = Output(base: self.variable, options: options)
        let output = self.updating(with: newVar)
        guard provider.provided else { return output }
        let updatedPath = provider.keyPath(withExisting: self.key)
        return output.updating(with: updatedPath)
    }
}
