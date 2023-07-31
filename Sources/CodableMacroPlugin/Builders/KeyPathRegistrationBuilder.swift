import SwiftSyntax

/// A specialized `RegistrationBuilder` that only updates `CodingKey`
/// path data keeping variable data as is.
///
/// This type can represent attributes attached to variable declarations and
/// hence has access to additional data to update registration with.
protocol KeyPathRegistrationBuilder: RegistrationBuilder, Attribute
where Output == Input {
    /// Create a new instance from provided attached
    /// variable declaration.
    ///
    /// This initialization can fail if this attribute not attached
    /// to provided variable declaration
    ///
    /// - Parameter declaration: The attached variable
    ///                          declaration.
    /// - Returns: Created registration builder attribute.
    init?(from declaration: VariableDeclSyntax)
}

extension KeyPathRegistrationBuilder {
    /// Returns `CodingKey` path
    /// provided in this attribute.
    ///
    /// The path components are provided
    /// as variadic arguments without any labels.
    ///
    /// - Important: The path components must be string literals
    ///              with single segment (i.e no interpolation,
    ///              no string combinations).
    var providedPath: [String] {
        guard let exprs = node.argument?.as(TupleExprElementListSyntax.self)
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

extension CodedAt: KeyPathRegistrationBuilder {
    /// The basic variable data that input registration can have.
    typealias Input = BasicVariable

    /// Build new registration with provided input registration.
    ///
    /// New registration is updated with the provided `CodingKey` path in
    /// attribute, overriding older `CodingKey` path data.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with additional `CodingKey`
    ///            path data.
    func build(with input: Registration<Input>) -> Registration<Input> {
        return input.adding(attribute: self).updating(with: providedPath)
    }
}

extension CodedIn: KeyPathRegistrationBuilder {
    /// The basic variable data that input registration can have.
    typealias Input = BasicVariable

    /// Build new registration with provided input registration.
    ///
    /// New registration is updated with the provided `CodingKey` path
    /// in attribute, prepending older `CodingKey` path data.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with additional `CodingKey`
    ///            path data.
    func build(with input: Registration<Input>) -> Registration<Input> {
        var finalPath = providedPath
        finalPath.append(contentsOf: input.keyPath)
        guard !self.inDefaultMode
        else { return input.updating(with: finalPath) }
        return input.adding(attribute: self).updating(with: finalPath)
    }
}
