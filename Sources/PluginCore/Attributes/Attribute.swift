import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

/// A type indicating a macro-attribute.
///
/// This type can check whether an `AttributeSyntax`
/// is for this attribute and perform validation and code generation
/// for this attribute usage.
protocol Attribute: AttachedMacro {
    /// The name of this attribute.
    static var name: String { get }
    /// The syntax used for this attribute instance.
    var node: AttributeSyntax { get }
    /// Creates a new instance with the provided node
    ///
    /// The initializer fails to create new instance if the name
    /// of the provided node is different than this attribute.
    ///
    /// - Parameter node: The attribute syntax to create with.
    /// - Returns: Newly created attribute instance.
    init?(from node: AttributeSyntax)
    /// Builds diagnoser that can validate this macro
    /// attached declaration.
    ///
    /// All the usage conditions are provided to built
    /// diagnoser to check violations in attached
    /// declaration in the macro expansion context
    /// provided. Diagnostics are produced in case of
    /// any violation.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer
}

extension Attribute {
    /// The name of this attribute.
    ///
    /// Type name is used as attribute name.
    static var name: String { "\(Self.self)" }
    /// The name of this attribute.
    ///
    /// By default type name is used as attribute name.
    var name: String { Self.name }
    /// The lowercased-name of this attribute.
    ///
    /// This is used for attribute related diagnostics.
    var id: String { name.lowercased() }

    /// Message id for misuse of this attribute.
    ///
    /// This attribute can must be removed or its usage condition
    /// must be satisfied.
    var misuseMessageID: MessageID { messageID("\(id)-misuse") }

    /// Creates a new message id in current package domain.
    ///
    /// - Parameters id: The message id.
    /// - Returns: Created message id.
    func messageID(_ id: String) -> MessageID {
        return .init(
            domain: "com.SwiftyLab.MetaCodable",
            id: id
        )
    }

    /// Provides all the attributes of current type attached to
    /// the provided declaration.
    ///
    /// All the attribute syntaxes are checked and those matching
    /// the current type are returned.
    ///
    /// - Parameter syntax: The declaration to search in.
    /// - Returns: All the attributes of current type.
    static func attributes(attachedTo syntax: some SyntaxProtocol) -> [Self] {
        guard
            case .choices(let choices) = DeclSyntax.structure
        else { return [] }

        let declSyntaxChoice = choices.first { choice in
            if case .node(let type) = choice {
                return type is AttributableDeclSyntax.Type
                    && syntax.is(type)
            } else {
                return false
            }
        }

        guard
            let declSyntaxChoice,
            case .node(let declSyntaxType) = declSyntaxChoice,
            let declaration = syntax.as(declSyntaxType),
            let declaration = declaration as? AttributableDeclSyntax
        else { return [] }

        return declaration.attributes.compactMap { attribute in
            guard case let .attribute(attribute) = attribute else { return nil }
            return Self.init(from: attribute)
        }
    }

    /// Checks whether this attribute is applied more than once to
    /// provided declaration.
    ///
    /// - Parameter declaration: The declaration this macro attribute
    ///   is attached to.
    /// - Returns: Whether this attribute is applied more than once.
    func isDuplicated(in declaration: some SyntaxProtocol) -> Bool {
        return Self.attributes(attachedTo: declaration).count > 1
    }

    /// Creates a new diagnostic message instance at current attribute node
    /// with provided message, id and severity.
    ///
    /// - Parameters:
    ///   - message: The message to be shown.
    ///   - messageID: The id associated with diagnostic.
    ///   - severity: The severity of diagnostic.
    ///
    /// - Returns: The newly created diagnostic message instance.
    func diagnostic(
        message: String, id: MessageID,
        severity: DiagnosticSeverity
    ) -> MetaCodableMessage {
        return .init(
            macro: self.node,
            message: message,
            messageID: id,
            severity: severity
        )
    }
}
