import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxMacros

/// Attribute type that checks for invalid macro-attribute
/// combinations.
///
/// This type doesn't represent a macro-attribute itself, rather compares
/// provided `Base` macro-attribute not intermixed with `Node` macro-attribute.
struct UnsupportedCombination<Base, Node>: Attribute
where Base: Attribute, Node: Attribute {
    /// The base attribute to compare against.
    ///
    /// The resulting diagnostics is generated
    /// based on this attribute.
    let base: Base
    /// The syntax for the base attribute provided during initialization.
    var node: AttributeSyntax { base.node }
    /// Creates a new instance with the provided node
    ///
    /// The initializer fails to create new instance if the name
    /// of the provided node is different than this attribute.
    ///
    /// - Parameter node: The attribute syntax to create with.
    /// - Returns: Newly created attribute instance.
    init?(from node: AttributeSyntax) {
        guard let base = Base(from: node) else { return nil }
        self.base = base
    }

    /// Validates the base attribute is used properly with the declaration provided.
    ///
    /// The `Base` attribute is checked to be not combined with provided `Node`
    /// attribute.
    ///
    /// - Parameters:
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The macro expansion context validation performed in.
    ///
    /// - Returns: True if attribute usage satisfies all conditions,
    ///            false otherwise.
    @discardableResult
    func validate(
        declaration: some SyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> Bool {
        var diagnostics: [(MetaCodableMessage, [FixIt])] = []

        guard
            case .choices(let choices) = DeclSyntax.structure
        else { return true }

        let declSyntaxChoice = choices.first { choice in
            if case .node(let type) = choice {
                return type is AttributableDeclSyntax.Type
                    && declaration.is(type)
            } else {
                return false
            }
        }

        guard
            let declSyntaxChoice,
            case .node(let declSyntaxType) = declSyntaxChoice,
            let declaration = declaration.as(declSyntaxType),
            let declaration = declaration as? AttributableDeclSyntax
        else { return true }

        let attribute = declaration.attributes?.first { attribute in
            guard
                case .attribute(let attribute) = attribute,
                Node(from: attribute) != nil
            else { return false }
            return true
        }

        guard
            case .attribute(let attribute) = attribute,
            let attribute = Node(from: attribute)
        else { return true }

        let message = node.diagnostic(
            message:
                "@\(base.name) can't be used in combination with @\(attribute.name)",
            id: base.misuseMessageID,
            severity: .error
        )

        diagnostics.append((message, [message.fixItByRemove]))
        for (message, fixes) in diagnostics {
            context.diagnose(
                .init(
                    node: Syntax(node),
                    message: message,
                    fixIts: fixes
                )
            )
        }
        return diagnostics.isEmpty
    }
}

/// A declaration syntax type that supports macro-attribute.
///
/// This type can check whether an `AttributeSyntax`
/// is for this attribute and perform validation of this attribute usage.
fileprivate protocol AttributableDeclSyntax: DeclSyntaxProtocol {
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
