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

    /// Provides the syntax for decoding at the provided location.
    ///
    /// Uses member group to generate syntax, adding `@preconcrrency`
    /// attribute for Swift 6 and above.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location.
    ///
    /// - Returns: The generated decoding syntax.
    func decoding(
        in context: some MacroExpansionContext,
        from location: TypeCodingLocation
    ) -> TypeGenerated? {
        guard
            let generated = base.decoding(in: context, from: location)
        else { return nil }

        #if swift(>=6)
        let preconcurrency: AttributeSyntax = "@preconcurrency"
        var inheritanceClause = generated.inheritanceClause
        let types = inheritanceClause?.inheritedTypes ?? []
        inheritedTypes: for (index, var inheritedType) in types.enumerated() {
            #if canImport(SwiftSyntax600)
            let fallbackType = AttributedTypeSyntax(
                specifiers: [], baseType: inheritedType.type
            )
            #else
            let fallbackType = AttributedTypeSyntax(
                baseType: inheritedType.type
            )
            #endif

            var type =
                inheritedType.type.as(AttributedTypeSyntax.self) ?? fallbackType
            let attribute = type.attributes.first { attribute in
                return switch attribute {
                case .attribute(let attr):
                    attr.attributeName.trimmedDescription
                        == preconcurrency.attributeName.trimmedDescription
                default:
                    false
                }
            }

            guard attribute == nil else { continue inheritedTypes }
            #if canImport(SwiftSyntax510)
            let index = inheritanceClause!.inheritedTypes.index(at: index)
            #else
            let inheritedTypes = inheritanceClause!.inheritedTypes
            let index = inheritedTypes.index(
                inheritedTypes.startIndex, offsetBy: index
            )
            #endif
            type.attributes.append(.attribute(preconcurrency))
            inheritedType.type = .init(type)
            inheritanceClause!.inheritedTypes[index] = inheritedType
        }
        #else
        let inheritanceClause = generated.inheritanceClause
        #endif

        return .init(
            code: generated.code, modifiers: generated.modifiers,
            whereClause: generated.whereClause,
            inheritanceClause: inheritanceClause
        )
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
