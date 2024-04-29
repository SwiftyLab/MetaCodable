import PluginCore
import SwiftSyntax
import SwiftSyntaxMacros

/// Attribute type for `Codable` macro-attribute.
///
/// Uses `PluginCore`'s `Codable` attribute implementation.
///
/// Describes a macro that validates `Codable` macro usage
/// and generates `Codable` conformances and implementations.
///
/// This macro performs extension macro expansion depending on `Codable`
/// conformance of type:
///   * Extension macro expansion, to confirm to `Decodable` or `Encodable`
///     protocols depending on whether type doesn't already conform to `Decodable`
///     or `Encodable` respectively.
///   * Extension macro expansion, to generate custom `CodingKey` type for
///     the attached declaration named `CodingKeys` and use this type for
///     `Codable` implementation of both `init(from:)` and `encode(to:)`
///     methods.
///   * If attached declaration already conforms to `Codable` this macro expansion
///     is skipped.
struct Codable: MemberMacro, ExtensionMacro {
    /// Expand to produce extensions with `Codable` implementation
    /// members for attached `class`.
    ///
    /// Conformance for both `Decodable` and `Encodable` is generated regardless
    /// of whether class already conforms to any. Class or its super class
    /// shouldn't conform to `Decodable` or `Encodable`
    ///
    /// The `AttributeExpander` instance provides declarations based on
    /// whether declaration is supported.
    ///
    /// - Parameters:
    ///   - node: The custom attribute describing this attached macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Declarations of `CodingKeys` type, `Decodable`
    ///   conformance with `init(from:)` implementation and `Encodable`
    ///   conformance with `encode(to:)` implementation depending on already
    ///   declared conformances of type.
    ///
    /// - Note: For types other than `class` types no declarations generated.
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try PluginCore.Codable.expansion(
            of: node, providingMembersOf: declaration, in: context
        )
    }

    /// Expand to produce extensions with `Codable` implementation
    /// members for attached `class`.
    ///
    /// Depending on whether attached type already conforms to `Decodable`
    /// or `Encodable`, `Decodable` or `Encodable` conformance
    /// implementation is skipped. Entire macro expansion is skipped if attached
    /// type already conforms to both `Decodable` and`Encodable`.
    ///
    /// The `AttributeExpander` instance provides declarations based on
    /// whether declaration is supported.
    ///
    /// - Parameters:
    ///   - node: The custom attribute describing this attached macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - protocols: The list of protocols to add conformances to. These will
    ///     always be protocols that `type` does not already state a conformance
    ///     to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Declarations of `CodingKeys` type, `Decodable`
    ///   conformance with `init(from:)` implementation and `Encodable`
    ///   conformance with `encode(to:)` implementation depending on already
    ///   declared conformances of type.
    ///
    /// - Note: For types other than `class` types no declarations generated.
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try PluginCore.Codable.expansion(
            of: node, providingMembersOf: declaration,
            conformingTo: protocols, in: context
        )
    }

    /// Expand to produce extensions with `Codable` implementation
    /// members for attached `struct` or `class`.
    ///
    /// Depending on whether attached type already conforms to `Decodable`
    /// or `Encodable` extension for `Decodable` or `Encodable` conformance
    /// implementation is skipped. Entire macro expansion is skipped if attached
    /// type already conforms to both `Decodable` and`Encodable`.
    ///
    /// The `AttributeExpander` instance provides declarations based on
    /// whether declaration is supported.
    ///
    /// - Parameters:
    ///   - node: The custom attribute describing this attached macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - type: The type to provide extensions of.
    ///   - protocols: The list of protocols to add conformances to. These will
    ///     always be protocols that `type` does not already state a conformance
    ///     to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Extensions with `CodingKeys` type, `Decodable`
    ///   conformance with `init(from:)` implementation and `Encodable`
    ///   conformance with `encode(to:)` implementation depending on already
    ///   declared conformances of type.
    ///
    /// - Note: For `class` types only conformance is generated,
    ///   member expansion generates the actual implementation.
    static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        return try PluginCore.Codable.expansion(
            of: node, attachedTo: declaration, providingExtensionsOf: type,
            conformingTo: protocols, in: context
        )
    }
}
/// Attribute type for `MemberInit` macro-attribute.
///
/// Uses `PluginCore`'s `MemberInit` attribute implementation.
///
/// Describes a macro that validates `MemberInit` macro usage
/// and generates memberwise initializer(s) declaration(s).
///
/// By default the memberwise initializer(s) generated are the same as
/// generated by Swift standard library. Additionally, `Default` attribute
/// can be added on fields to provide default value in function parameters
/// of memberwise initializer(s).
struct MemberInit: MemberMacro {
    /// Expand to produce memberwise initializer(s) for attached struct.
    ///
    /// The `AttributeExpander` instance provides declarations based on
    /// whether declaration is supported.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Memberwise initializer(s) declaration(s).
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try PluginCore.MemberInit.expansion(
            of: node, providingMembersOf: declaration, in: context
        )
    }
}

/// Attribute type for `CodedAt` macro-attribute.
///
/// Uses `PluginCore`'s `CodedAt` attribute implementation.
///
/// This type can validate`CodedAt` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct CodedAt: PeerMacro {
    /// Provide metadata to `Codable` macro for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `Codable` macro
    /// uses when performing expansion.
    ///
    /// This macro verifies that macro usage condition is met by attached
    /// declaration by using the `validate` implementation provided.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: No declaration is returned, only attached declaration is
    ///            analyzed.
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try PluginCore.CodedAt.expansion(
            of: node, providingPeersOf: declaration, in: context
        )
    }
}

/// Attribute type for `CodedIn` macro-attribute.
///
/// This type can validate`CodedIn` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct CodedIn: PeerMacro {
    /// Provide metadata to `Codable` macro for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `Codable` macro
    /// uses when performing expansion.
    ///
    /// This macro verifies that macro usage condition is met by attached
    /// declaration by using the `validate` implementation provided.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: No declaration is returned, only attached declaration is
    ///            analyzed.
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try PluginCore.CodedIn.expansion(
            of: node, providingPeersOf: declaration, in: context
        )
    }
}

/// Attribute type for `CodedBy` macro-attribute.
///
/// This type can validate`CodedBy` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct CodedBy: PeerMacro {
    /// Provide metadata to `Codable` macro for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `Codable` macro
    /// uses when performing expansion.
    ///
    /// This macro verifies that macro usage condition is met by attached
    /// declaration by using the `validate` implementation provided.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: No declaration is returned, only attached declaration is
    ///            analyzed.
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try PluginCore.CodedBy.expansion(
            of: node, providingPeersOf: declaration, in: context
        )
    }
}

/// Attribute type for `Default` macro-attribute.
///
/// This type can validate`Default` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct Default: PeerMacro {
    /// Provide metadata to `Codable` macro for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `Codable` macro
    /// uses when performing expansion.
    ///
    /// This macro verifies that macro usage condition is met by attached
    /// declaration by using the `validate` implementation provided.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: No declaration is returned, only attached declaration is
    ///            analyzed.
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try PluginCore.Default.expansion(
            of: node, providingPeersOf: declaration, in: context
        )
    }
}

/// Attribute type for `CodedAs` macro-attribute.
///
/// This type can validate`CodedAs` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct CodedAs: PeerMacro {
    /// Provide metadata to `Codable` macro for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `Codable` macro
    /// uses when performing expansion.
    ///
    /// This macro verifies that macro usage condition is met by attached
    /// declaration by using the `validate` implementation provided.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: No declaration is returned, only attached declaration is
    ///            analyzed.
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try PluginCore.CodedAs.expansion(
            of: node, providingPeersOf: declaration, in: context
        )
    }
}

/// Attribute type for `ContentAt` macro-attribute.
///
/// This type can validate`ContentAt` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct ContentAt: PeerMacro {
    /// Provide metadata to `Codable` macro for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `Codable` macro
    /// uses when performing expansion.
    ///
    /// This macro verifies that macro usage condition is met by attached
    /// declaration by using the `validate` implementation provided.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: No declaration is returned, only attached declaration is
    ///            analyzed.
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try PluginCore.ContentAt.expansion(
            of: node, providingPeersOf: declaration, in: context
        )
    }
}

/// Attribute type for `IgnoreCoding` macro-attribute.
///
/// This type can validate`IgnoreCoding` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct IgnoreCoding: PeerMacro {
    /// Provide metadata to `Codable` macro for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `Codable` macro
    /// uses when performing expansion.
    ///
    /// This macro verifies that macro usage condition is met by attached
    /// declaration by using the `validate` implementation provided.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: No declaration is returned, only attached declaration is
    ///            analyzed.
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try PluginCore.IgnoreCoding.expansion(
            of: node, providingPeersOf: declaration, in: context
        )
    }
}

/// Attribute type for `IgnoreDecoding` macro-attribute.
///
/// This type can validate`IgnoreDecoding` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct IgnoreDecoding: PeerMacro {
    /// Provide metadata to `Codable` macro for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `Codable` macro
    /// uses when performing expansion.
    ///
    /// This macro verifies that macro usage condition is met by attached
    /// declaration by using the `validate` implementation provided.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: No declaration is returned, only attached declaration is
    ///            analyzed.
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try PluginCore.IgnoreDecoding.expansion(
            of: node, providingPeersOf: declaration, in: context
        )
    }
}

/// Attribute type for `IgnoreEncoding` macro-attribute.
///
/// This type can validate`IgnoreEncoding` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
struct IgnoreEncoding: PeerMacro {
    /// Provide metadata to `Codable` macro for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `Codable` macro
    /// uses when performing expansion.
    ///
    /// This macro verifies that macro usage condition is met by attached
    /// declaration by using the `validate` implementation provided.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: No declaration is returned, only attached declaration is
    ///            analyzed.
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try PluginCore.IgnoreEncoding.expansion(
            of: node, providingPeersOf: declaration, in: context
        )
    }
}

/// Attribute type for `CodingKeys` macro-attribute.
///
/// This type can validate`CodingKeys` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
///
/// Attaching this macro to type declaration indicates all the
/// property names will be converted to `CodingKey` value
/// using the strategy provided.
struct CodingKeys: PeerMacro {
    /// Provide metadata to `Codable` macro for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `Codable` macro
    /// uses when performing expansion.
    ///
    /// This macro verifies that macro usage condition is met by attached
    /// declaration by using the `validate` implementation provided.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: No declaration is returned, only attached declaration is
    ///            analyzed.
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try PluginCore.CodingKeys.expansion(
            of: node, providingPeersOf: declaration, in: context
        )
    }
}

/// Attribute type for `IgnoreCodingInitialized` macro-attribute.
///
/// This type can validate`IgnoreCodingInitialized` macro-attribute
/// usage and extract data for `Codable` macro to generate implementation.
///
/// Attaching this macro to type declaration indicates all the initialized
/// properties for the said type will be ignored from decoding and
/// encoding unless explicitly asked with attached coding attributes,
/// i.e. `CodedIn`, `CodedAt` etc.
struct IgnoreCodingInitialized: PeerMacro {
    /// Provide metadata to `Codable` macro for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `Codable` macro
    /// uses when performing expansion.
    ///
    /// This macro verifies that macro usage condition is met by attached
    /// declaration by using the `validate` implementation provided.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: No declaration is returned, only attached declaration is
    ///            analyzed.
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try PluginCore.IgnoreCodingInitialized.expansion(
            of: node, providingPeersOf: declaration, in: context
        )
    }
}

/// Attribute type for `Inherits` macro-attribute.
///
/// This type can validate`Inherits` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
///
/// Attaching this macro to type allows indicating the generated
/// `Codable` conformance whether a class already inheriting
/// conformance from super class or not.
struct Inherits: PeerMacro {
    /// Provide metadata to `Codable` macro for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `Codable` macro
    /// uses when performing expansion.
    ///
    /// This macro verifies that macro usage condition is met by attached
    /// declaration by using the `validate` implementation provided.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: No declaration is returned, only attached declaration is
    ///            analyzed.
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try PluginCore.Inherits.expansion(
            of: node, providingPeersOf: declaration, in: context
        )
    }
}

/// Attribute type for `UnTagged` macro-attribute.
///
/// This type can validate`UnTagged` macro-attribute usage and
/// extract data for `Codable` macro to generate implementation.
///
/// Attaching this macro to enum declaration indicates the enum doesn't
/// have any identifier for its cases and each case should be tried for decoding
/// until decoding succeeds for a case.
struct UnTagged: PeerMacro {
    /// Provide metadata to `Codable` macro for final expansion
    /// and verify proper usage of this macro.
    ///
    /// This macro doesn't perform any expansion rather `Codable` macro
    /// uses when performing expansion.
    ///
    /// This macro verifies that macro usage condition is met by attached
    /// declaration by using the `validate` implementation provided.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: No declaration is returned, only attached declaration is
    ///            analyzed.
    static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return try PluginCore.UnTagged.expansion(
            of: node, providingPeersOf: declaration, in: context
        )
    }
}
