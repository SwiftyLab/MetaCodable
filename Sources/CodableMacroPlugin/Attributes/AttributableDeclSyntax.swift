import SwiftSyntax

/// An extension that manages fetching attributes
/// attached to declarations.
extension SyntaxProtocol {
    /// Provides all the attributes attached to this declaration of
    /// the provided type.
    ///
    /// All the attribute syntaxes are checked and those matching
    /// the provided type are returned.
    ///
    /// - Parameter type: The macro-attribute type to search.
    /// - Returns: All the attributes of provided type.
    func attributes<A: Attribute>(for type: A.Type) -> [A] {
        guard
            case .choices(let choices) = DeclSyntax.structure
        else { return [] }

        let declSyntaxChoice = choices.first { choice in
            if case .node(let type) = choice {
                return type is AttributableDeclSyntax.Type
                    && self.is(type)
            } else {
                return false
            }
        }

        guard
            let declSyntaxChoice,
            case .node(let declSyntaxType) = declSyntaxChoice,
            let declaration = self.as(declSyntaxType),
            let declaration = declaration as? AttributableDeclSyntax
        else { return [] }

        return declaration.attributes?.compactMap { attribute in
            guard case .attribute(let attribute) = attribute else { return nil }
            return type.init(from: attribute)
        } ?? []
    }
}

/// A declaration syntax type that supports macro-attribute.
///
/// This type can check whether an `AttributeSyntax`
/// is for this attribute and perform validation of this attribute usage.
protocol AttributableDeclSyntax: DeclSyntaxProtocol {
    /// The list of attributes attached to this declaration.
    var attributes: AttributeListSyntax? { get }
}

extension AccessorDeclSyntax: AttributableDeclSyntax {}
extension ActorDeclSyntax: AttributableDeclSyntax {}
extension AssociatedtypeDeclSyntax: AttributableDeclSyntax {}
extension ClassDeclSyntax: AttributableDeclSyntax {}
extension DeinitializerDeclSyntax: AttributableDeclSyntax {}
extension EditorPlaceholderDeclSyntax: AttributableDeclSyntax {}
extension EnumCaseDeclSyntax: AttributableDeclSyntax {}
extension EnumDeclSyntax: AttributableDeclSyntax {}
extension ExtensionDeclSyntax: AttributableDeclSyntax {}
extension FunctionDeclSyntax: AttributableDeclSyntax {}
extension ImportDeclSyntax: AttributableDeclSyntax {}
extension InitializerDeclSyntax: AttributableDeclSyntax {}
extension MacroDeclSyntax: AttributableDeclSyntax {}
extension MacroExpansionDeclSyntax: AttributableDeclSyntax {}
extension MissingDeclSyntax: AttributableDeclSyntax {}
extension OperatorDeclSyntax: AttributableDeclSyntax {}
extension PrecedenceGroupDeclSyntax: AttributableDeclSyntax {}
extension ProtocolDeclSyntax: AttributableDeclSyntax {}
extension StructDeclSyntax: AttributableDeclSyntax {}
extension SubscriptDeclSyntax: AttributableDeclSyntax {}
extension TypealiasDeclSyntax: AttributableDeclSyntax {}
extension VariableDeclSyntax: AttributableDeclSyntax {}
