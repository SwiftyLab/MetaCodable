import SwiftSyntax

/// A `VariableSyntax` type representing properties.
///
/// Represents an individual property declaration.
struct PropertyDeclSyntax: VariableSyntax, AttributableDeclSyntax {
    /// The `Variable` type this syntax represents.
    ///
    /// Represents basic property decoding/encoding data.
    typealias Variable = BasicPropertyVariable

    /// The property declaration source.
    ///
    /// Used for attributes and specifier.
    let decl: VariableDeclSyntax
    /// The actual property binding.
    ///
    /// Defines the actual property in declaration.
    let binding: PatternBindingSyntax
    /// The type to use if missing.
    ///
    /// If property syntax is missing explicit type this type is used.
    let typeIfMissing: TypeSyntax!

    /// The type of the property.
    ///
    /// If type is not present in syntax, `typeIfMissing` is used.
    var type: TypeSyntax {
        return binding.typeAnnotation?.type.trimmed ?? typeIfMissing
    }

    /// The attributes attached to property.
    ///
    /// The attributes attached to grouped or individual property declaration.
    var attributes: AttributeListSyntax { decl.attributes }

    /// The accessors for the property.
    ///
    /// If property observer accessors are set or for computed property
    /// accessor block returned. Otherwise `nil` returned.
    var accessorBlock: AccessorBlockSyntax? { binding.accessorBlock }

    /// The declaration specifier for property.
    ///
    /// The specifier that defines the type of the property declared
    /// (`let` or `var`).
    var bindingSpecifier: TokenSyntax { decl.bindingSpecifier }
}
