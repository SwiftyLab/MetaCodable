@_implementationOnly import SwiftSyntax

/// A `VariableSyntax` type that contains decodable/encodable members.
///
/// This type contains syntax for individual `Variable`s which can be used
/// to implement decode/encode logic for `Variable` of this syntax type.
protocol MemberGroupSyntax<Variable, MemberSyntax>: VariableSyntax {
    /// The syntax type of individual members.
    associatedtype MemberSyntax: VariableSyntax
    /// The list of individual members syntax.
    ///
    /// Returns all the individual members syntax of current syntax.
    func codableMembers() -> [MemberSyntax]
}

extension MemberGroupSyntax
where Self: DeclGroupSyntax, MemberSyntax == PropertyDeclSyntax {
    /// The list of individual members syntax.
    ///
    /// Returns all the member properties of this declaration group.
    /// Static properties and other members are ignored.
    ///
    /// - Returns: All the member properties.
    func codableMembers() -> [PropertyDeclSyntax] {
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

extension StructDeclSyntax: MemberGroupSyntax {
    /// The `Variable` type this syntax represents.
    ///
    /// The member group type used with current declaration.
    typealias Variable = MemberGroup<Self>
}

extension ClassDeclSyntax: MemberGroupSyntax {
    /// The `Variable` type this syntax represents.
    ///
    /// The class variable type used with current declaration.
    typealias Variable = ClassVariable
}
