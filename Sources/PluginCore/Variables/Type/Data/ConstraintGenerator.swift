import SwiftSyntax

/// A where clause generator for `Codable` conformance.
///
/// This generator keeps track of generic type arguments,
/// and generates where clause based on whether these
/// types need to conform to `Decodable` or `Encodable`
/// for `Codable` conformance.
struct ConstraintGenerator {
    /// List of generic type arguments.
    ///
    /// Contains all the type requirement arguments
    /// of generic declaration.
    var typeArguments: [TokenSyntax] = []

    /// Creates a new generator with provided declaration group.
    ///
    /// - Parameters:
    ///   - decl: The declaration group generator picks
    ///     generic type arguments from.
    ///
    /// - Returns: The newly created generator.
    init(decl: GenericTypeDeclSyntax) {
        guard
            let paramClause = decl.genericParameterClause
        else { return }

        typeArguments.reserveCapacity(paramClause.parameters.count)
        for param in paramClause.parameters {
            typeArguments.append(param.name.trimmed)
        }
    }

    /// Provides where clause for the `Codable` extension declaration.
    ///
    /// The where clause contains conformance requirement for generic
    /// arguments necessary for `Codable` conformance.
    ///
    /// - Parameters:
    ///   - path: The requirement check path to be used for `Variable`.
    ///   - variables: List of all the variables registered in `AttributeExpander`.
    ///   - protocol: The`Codable` protocol type syntax.
    ///
    /// - Returns: The generated where clause.
    @inlinable
    func codingClause(
        forRequirementPath path: KeyPath<any PropertyVariable, Bool?>,
        withVariables variables: [any PropertyVariable],
        conformingTo protocol: TypeSyntax
    ) -> GenericWhereClauseSyntax? {
        let allTypes = variables.filter { $0[keyPath: path] ?? true }
            .map(\.type.trimmed.description)
        let typeArguments = self.typeArguments.filter { type in
            return allTypes.contains(type.description)
        }
        guard !typeArguments.isEmpty else { return nil }
        return GenericWhereClauseSyntax {
            for argument in typeArguments {
                GenericRequirementSyntax(
                    requirement: .conformanceRequirement(
                        .init(
                            leftType: IdentifierTypeSyntax(name: argument),
                            rightType: `protocol`
                        )
                    )
                )
            }
        }
    }

    /// Provides where clause for the `Decodable` extension declaration.
    ///
    /// The where clause contains conformance requirement for generic
    /// arguments necessary for `Decodable` conformance.
    ///
    /// - Parameters:
    ///   - variables: List of all the variables registered in `AttributeExpander`.
    ///   - protocol: The`Decodable` protocol type syntax.
    ///
    /// - Returns: The generated where clause.
    func decodingClause(
        withVariables variables: [any PropertyVariable],
        conformingTo protocol: TypeSyntax
    ) -> GenericWhereClauseSyntax? {
        return codingClause(
            forRequirementPath: \.requireDecodable,
            withVariables: variables, conformingTo: `protocol`
        )
    }

    /// Provides where clause for the `Encodable` extension declaration.
    ///
    /// The where clause contains conformance requirement for generic
    /// arguments necessary for `Encodable` conformance.
    ///
    /// - Parameters:
    ///   - variables: List of all the variables registered in `AttributeExpander`.
    ///   - protocol: The`Encodable` protocol type syntax.
    ///
    /// - Returns: The generated where clause.
    func encodingClause(
        withVariables variables: [any PropertyVariable],
        conformingTo protocol: TypeSyntax
    ) -> GenericWhereClauseSyntax? {
        return codingClause(
            forRequirementPath: \.requireEncodable,
            withVariables: variables, conformingTo: `protocol`
        )
    }
}

/// A declaration group syntax type that accepts generic parameter clause.
///
/// This type has optional `GenericParameterClauseSyntax` that
/// can be used for where clause generation for `Codable` conformance.
protocol GenericTypeDeclSyntax {
    /// A where clause that places additional constraints on generic parameters
    /// like `where Element: Hashable`.
    var genericParameterClause: GenericParameterClauseSyntax? { get }
}

extension StructDeclSyntax: GenericTypeDeclSyntax {}
extension ClassDeclSyntax: GenericTypeDeclSyntax {}
extension EnumDeclSyntax: GenericTypeDeclSyntax {}
extension ActorDeclSyntax: GenericTypeDeclSyntax {}
