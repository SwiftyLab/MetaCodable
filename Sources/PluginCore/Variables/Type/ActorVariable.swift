import SwiftSyntax
import SwiftSyntaxMacros

/// A `TypeVariable` that provides `Codable` conformance
/// for an `actor` type.
///
/// This type can be used for `actor`s for `Decodable` conformance and
/// `Encodable` implementation without conformance.
struct ActorVariable: TypeVariable, DeclaredVariable, ComposedVariable,
    InitializableVariable
{
    /// The initialization type of this variable.
    ///
    /// Initialization type is the same as underlying member group variable.
    typealias Initialization = MemberGroup<ActorDeclSyntax>.Initialization
    /// The member group used to generate conformance implementations.
    let base: MemberGroup<ActorDeclSyntax>

    /// Creates a new variable from declaration and expansion context.
    ///
    /// Uses the actor declaration with member group to generate conformances.
    ///
    /// - Parameters:
    ///   - decl: The declaration to read from.
    ///   - context: The context in which the macro expansion performed.
    init(from decl: ActorDeclSyntax, in context: some MacroExpansionContext) {
        self.base = .init(from: decl, in: context)
    }

    /// Provides the syntax for encoding at the provided location.
    ///
    /// Uses member group to generate syntax, the implementation is added
    /// while not conforming to `Encodable` protocol.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location.
    ///
    /// - Returns: The generated encoding syntax.
    func encoding(
        in context: some MacroExpansionContext,
        to location: TypeCodingLocation
    ) -> TypeGenerated? {
        guard
            let generated = base.encoding(in: context, to: location)
        else { return nil }
        return .init(
            code: generated.code, modifiers: generated.modifiers,
            whereClause: generated.whereClause,
            inheritanceClause: nil
        )
    }
}
