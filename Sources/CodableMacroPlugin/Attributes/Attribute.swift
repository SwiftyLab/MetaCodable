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
    func diagnoser() -> any DiagnosticProducer
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
    var misuseMessageID: MessageID { .messageID("\(id)-misuse") }
    /// Message id for unnecessary usage of this attribute.
    ///
    /// This attribute can be omitted in such scenario and the
    /// final result will still be the same.
    var unusedMessageID: MessageID { .messageID("\(id)-unused") }

    /// Checks whether this attribute is applied more than once to
    /// provided declaration.
    ///
    /// - Parameter declaration: The declaration this macro attribute
    ///   is attached to.
    /// - Returns: Whether this attribute is applied more than once.
    func isDuplicated(in declaration: some SyntaxProtocol) -> Bool {
        return declaration.attributes(for: Self.self).count > 1
    }
}
