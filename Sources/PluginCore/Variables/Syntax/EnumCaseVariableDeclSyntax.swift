import SwiftSyntax

/// A `VariableSyntax` type representing enum-case variables.
///
/// Represents an individual enum-cases declaration .
struct EnumCaseVariableDeclSyntax: MemberGroupSyntax, AttributableDeclSyntax {
    /// The `Variable` type this syntax represents.
    ///
    /// Represents basic enum-case variable decoding/encoding data.
    typealias Variable = BasicEnumCaseVariable

    /// The actual variable syntax.
    ///
    /// Defines the actual enum-case values declaration.
    let element: EnumCaseElementSyntax
    /// The enum-case declaration source.
    ///
    /// Used for attributes source.
    let decl: EnumCaseDeclSyntax
    /// The parent declaration.
    ///
    /// Represents the enum type declaration.
    let parent: EnumDeclSyntax
    /// The `CodingKeys` map.
    ///
    /// The map containing all coding keys for enum.
    let codingKeys: CodingKeysMap

    /// The attributes attached to enum-case.
    ///
    /// The attributes attached to grouped or individual enum-case declaration
    /// and enum type declaration.
    var attributes: AttributeListSyntax {
        var attributes = decl.attributes
        attributes.append(contentsOf: parent.attributes)
        return attributes
    }

    /// The list of individual members syntax.
    ///
    /// Returns all the associated variables of this case.
    ///
    /// - Parameter input: The input to child syntax.
    /// - Returns: All the individual associated variables syntax.
    func codableMembers(input: Void) -> [AssociatedDeclSyntax] {
        guard let parameterClause = element.parameterClause else { return [] }
        return parameterClause.parameters.enumerated().map { index, param in
            let name: TokenSyntax
            let path: [String]
            switch param.firstName?.tokenKind {
            case .wildcard where param.secondName != nil:
                name = param.secondName.unsafelyUnwrapped.trimmed
                path = [CodingKeysMap.Key.name(for: name).text]
            case let .some(tokenKind) where tokenKind != .wildcard:
                name = param.firstName.unsafelyUnwrapped.trimmed
                path = [CodingKeysMap.Key.name(for: name).text]
            default:
                name = "_\(raw: index)"
                path = []
            }
            return .init(name: name, path: path, param: param, parent: self)
        }
    }
}
