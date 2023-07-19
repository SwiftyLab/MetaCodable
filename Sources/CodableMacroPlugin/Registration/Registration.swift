import SwiftSyntax
import SwiftSyntaxMacros

/// A type representing variable registration for code generation.
///
/// This type contains variable and `CodingKey` path data
/// that is necessary for syntax generation.
///
/// `RegistrationBuilder`s create registrations based on
/// current syntax.
struct Registration<Var: Variable> {
    /// The context associated with `Registration`.
    ///
    /// `Registration` uses this context to track additional attributes
    /// attached to variables and pass data to downstream.
    struct Context {
        /// The context in which to perform the macro expansion.
        let expansion: MacroExpansionContext
        /// The current `@Codable` macro-attribute syntax.
        let node: AttributeSyntax
        /// The variable declaration associated with this context.
        let declaration: VariableDeclSyntax
        /// The single variable pattern associated with this context.
        let binding: PatternBindingSyntax
        /// All the attributes associated with this context.
        ///
        /// Tracks all the attributes, that are attached
        /// to variable declaration of this context.
        let attributes: [Attribute]

        /// Creates a new context with provided parameters.
        ///
        /// - Parameters:
        ///   - expansion: The context in which to perform the macro expansion.
        ///   - node: The `@Codable` macro-attribute syntax.
        ///   - declaration: The variable declaration.
        ///   - binding: The variable pattern.
        ///   - attributes: The attributes to track.
        ///
        /// - Returns: Newly created context.
        fileprivate init(
            expansion: MacroExpansionContext,
            node: AttributeSyntax,
            declaration: VariableDeclSyntax,
            binding: PatternBindingSyntax,
            attributes: [Attribute] = []
        ) {
            self.expansion = expansion
            self.node = node
            self.declaration = declaration
            self.binding = binding
            self.attributes = attributes
        }

        /// Creates a new context from another context.
        ///
        /// The generic variable type information is overridden
        /// with the newly created context.
        ///
        /// - Parameter context: The context to create from.
        /// - Returns: Newly created context.
        fileprivate init<V: Variable>(from context: Registration<V>.Context) {
            self.init(
                expansion: context.expansion, node: context.node,
                declaration: context.declaration, binding: context.binding,
                attributes: context.attributes
            )
        }

        /// Add provided attribute to context.
        ///
        /// Track the new attribute provided in a newly created context.
        ///
        /// - Parameter attribute: The attribute to add.
        /// - Returns: Created context with the added attribute.
        fileprivate func adding(attribute: Attribute) -> Self {
            var attributes = attributes
            attributes.append(attribute)
            return .init(
                expansion: expansion, node: node,
                declaration: declaration, binding: binding,
                attributes: attributes
            )
        }
    }

    /// The `CodingKey` path for the variable.
    ///
    /// The `CodingKey` path where the variable
    /// value will be decode/encoded.
    let keyPath: [String]
    /// The variable data and additional metadata.
    ///
    /// The variable data is tracked for registrations,
    /// and code generation per variable.
    let variable: Var
    /// The context associated with current registration.
    ///
    /// The context is used to track additional
    /// attributes attached to variable declaration.
    let context: Context

    /// Creates a new registration with provided parameters.
    ///
    /// - Parameters:
    ///   - keyPath: The `CodingKey` path for the variable.
    ///   - variable: The variable data.
    ///   - context: The context associated.
    ///
    /// - Returns: Created registration.
    init(keyPath: [String], variable: Var, context: Context) {
        self.keyPath = keyPath
        self.variable = variable
        self.context = context
    }

    /// Creates a new registration with provided parameters.
    ///
    /// Creates context with provided parameters and uses
    /// variable name as `CodingKey` path in newly created
    /// registration.
    ///
    /// - Parameters:
    ///   - variable: The variable data.
    ///   - expansion: The context in which to perform the macro expansion.
    ///   - node: The `@Codable` macro-attribute syntax.
    ///   - declaration: The variable declaration.
    ///   - binding: The variable pattern.
    ///   - attributes: The attributes to track.
    ///
    /// - Returns: Created registration.
    init(
        variable: Var,
        expansion: MacroExpansionContext, node: AttributeSyntax,
        declaration: VariableDeclSyntax, binding: PatternBindingSyntax,
        attributes: [Attribute] = []
    ) {
        self.keyPath = [variable.name.asKey]
        self.variable = variable
        self.context = .init(
            expansion: expansion, node: node,
            declaration: declaration, binding: binding,
            attributes: attributes
        )
    }

    /// Add provided attribute to context.
    ///
    /// Track the new attribute provided in a newly created context
    /// associated with newly created registration.
    ///
    /// - Parameter attribute: The attribute to add.
    /// - Returns: Created registration with the added
    ///            attribute in the context.
    func adding(attribute: Attribute) -> Self {
        return .init(
            keyPath: keyPath, variable: variable,
            context: context.adding(attribute: attribute)
        )
    }

    /// Update the `CodingKey` path in this registration
    /// with provided `CodingKey` path.
    ///
    /// Creates a new registration with the provided `CodingKey`
    /// path, carrying forward previous context and variable data.
    ///
    /// - Parameter keyPath: The new `CodingKey` path.
    /// - Returns: Newly created registration with updated
    ///            `CodingKey` path.
    func updating(with keyPath: [String]) -> Self {
        return .init(keyPath: keyPath, variable: variable, context: context)
    }

    /// Update the variable data in this registration with provided data.
    ///
    /// Creates a new registration with the provided variable data,
    /// carrying forward previous context and `CodingKey` path.
    ///
    /// - Parameter variable: The new variable data.
    /// - Returns: Newly created registration with updated variable data.
    func updating<V: Variable>(with variable: V) -> Registration<V> {
        return .init(
            keyPath: keyPath, variable: variable,
            context: .init(from: context)
        )
    }
}
