import SwiftSyntax

/// A `VariableSyntax` type that contains decodable/encodable members.
///
/// This type contains syntax for individual `Variable`s which can be used
/// to implement decode/encode logic for `Variable` of this syntax type.
protocol MemberGroupSyntax<MemberSyntax> {
    /// The syntax type of individual members.
    associatedtype MemberSyntax
    /// The input type of member syntax.
    associatedtype ChildSyntaxInput = Void
    /// The list of individual members syntax.
    ///
    /// The individual members syntaxes that can be decoded/encoded
    /// are returned.
    ///
    /// - Parameter input: The input to child syntax.
    /// - Returns: All the individual members syntax of current syntax.
    func codableMembers(input: ChildSyntaxInput) -> [MemberSyntax]
}

extension MemberGroupSyntax where ChildSyntaxInput == Void {
    /// The list of individual members syntax.
    ///
    /// The individual members syntaxes that can be decoded/encoded
    /// are returned.
    ///
    /// - Returns: All the individual members syntax of current syntax.
    func codableMembers() -> [MemberSyntax] {
        return self.codableMembers(input: ())
    }
}

extension MemberGroupSyntax
where
    Self: MemberGroupSyntax, Self: DeclGroupSyntax,
    MemberSyntax == PropertyDeclSyntax, ChildSyntaxInput == Void
{
    /// The list of individual members syntax.
    ///
    /// Returns all the member properties of this declaration group.
    /// Static properties and other members are ignored.
    ///
    /// - Parameter input: The input to child syntax.
    /// - Returns: All the member properties.
    func codableMembers(input: Void) -> [PropertyDeclSyntax] {
        return self.memberBlock.members.flatMap { member in
            guard
                // is a variable declaration
                let decl = member.decl.as(VariableDeclSyntax.self),
                // is a member property.
                !decl.modifiers.contains(
                    where: { $0.name.tokenKind == .keyword(.static) }
                )
            else { return [] as [PropertyDeclSyntax] }

            var variablesData = [(PatternBindingSyntax, TypeSyntax?)]()
            for binding in decl.bindings
            where binding.pattern.is(IdentifierPatternSyntax.self) {
                let data = (binding, binding.typeAnnotation?.type.trimmed)
                variablesData.append(data)
            }

            var members: [PropertyDeclSyntax] = []
            members.reserveCapacity(variablesData.count)
            var latestType: TypeSyntax!
            for (binding, type) in variablesData.reversed() {
                if let type { latestType = type }
                members.append(
                    .init(
                        decl: decl, binding: binding, typeIfMissing: latestType
                    )
                )
            }

            return members.reversed()
        }
    }
}

extension StructDeclSyntax: MemberGroupSyntax, VariableSyntax {
    /// The `Variable` type this syntax represents.
    ///
    /// The member group type used with current declaration.
    typealias Variable = MemberGroup<Self>
}

extension ClassDeclSyntax: MemberGroupSyntax, VariableSyntax {
    /// The `Variable` type this syntax represents.
    ///
    /// The class variable type used with current declaration.
    typealias Variable = ClassVariable
}

extension ActorDeclSyntax: MemberGroupSyntax, VariableSyntax {
    /// The `Variable` type this syntax represents.
    ///
    /// The actor variable type used with current declaration.
    typealias Variable = ActorVariable
}

extension EnumDeclSyntax: MemberGroupSyntax, VariableSyntax {
    /// The `Variable` type this syntax represents.
    ///
    /// The enum variable type used with current declaration.
    typealias Variable = EnumVariable
    /// The input type of member syntax.
    ///
    /// The `CodingKeys` map for enum is provided.
    typealias ChildSyntaxInput = CodingKeysMap

    /// The list of individual members syntax.
    ///
    /// Returns all the cases of this declaration group.
    ///
    /// - Parameter input: The input to child syntax.
    /// - Returns: All the individual members syntax of current syntax.
    func codableMembers(input: CodingKeysMap) -> [EnumCaseVariableDeclSyntax] {
        return self.memberBlock.members.flatMap { member in
            guard
                // is a case declaration
                let decl = member.decl.as(EnumCaseDeclSyntax.self)
            else { return [] as [EnumCaseVariableDeclSyntax] }
            return decl.elements.map { element in
                return .init(
                    element: element, decl: decl,
                    parent: self, codingKeys: input
                )
            }
        }
    }
}
