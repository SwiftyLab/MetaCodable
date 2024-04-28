import SwiftSyntax

/// A declaration syntax type that supports macro-attribute.
///
/// This type can check whether an `AttributeSyntax`
/// is for this attribute and perform validation of this attribute usage.
protocol AttributableDeclSyntax {
    /// The list of attributes attached to this declaration.
    var attributes: AttributeListSyntax { get }
}

extension AccessorDeclSyntax: AttributableDeclSyntax {}
extension ActorDeclSyntax: AttributableDeclSyntax {}
extension AssociatedTypeDeclSyntax: AttributableDeclSyntax {}
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
extension PrecedenceGroupDeclSyntax: AttributableDeclSyntax {}
extension ProtocolDeclSyntax: AttributableDeclSyntax {}
extension StructDeclSyntax: AttributableDeclSyntax {}
extension SubscriptDeclSyntax: AttributableDeclSyntax {}
extension TypeAliasDeclSyntax: AttributableDeclSyntax {}
extension VariableDeclSyntax: AttributableDeclSyntax {}
