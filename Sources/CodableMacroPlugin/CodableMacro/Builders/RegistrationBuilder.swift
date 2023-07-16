import SwiftSyntax
import SwiftSyntaxMacros

/// A type representing builder that builds registrations
/// to partake in the code generation.
///
/// These builders update the input registration with data
/// from current syntax. Final built registration is passed to
/// `Registrar` to store and use in code generation.
protocol RegistrationBuilder<Input, Output> {
    /// The input registration variable type.
    associatedtype Input: Variable
    /// The output registration variable type.
    associatedtype Output: Variable
    /// Build new registration with provided input registration.
    ///
    /// New registration can have additional data based on
    /// the current syntax without the macro expansion.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with additional data.
    func build(with input: Registration<Input>) -> Registration<Output>
}

/// A result builder used to compose `RegistrationBuilder`s.
///
/// This [Result Builder](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/advancedoperators/#Result-Builders)
/// chains any number of `RegistrationBuilder`s that can produce
/// final registration to be passed to`Registrar`.
@resultBuilder
struct VariableRegistrationBuilder {

    /// Builds a partial registration builder action from a single, first component.
    ///
    /// - Parameter first: The first `RegistrationBuilder` to accumulate.
    /// - Returns: Building action of the passed builder.
    static func buildPartialBlock<Builder: RegistrationBuilder>(
        first: Builder
    ) -> ((Registration<Builder.Input>) -> Registration<Builder.Output>) {
        return first.build
    }

    /// Builds a partial registration builder action by combining an accumulated registration builder actions
    /// and a new `RegistrationBuilder`.
    ///
    /// - Parameters:
    ///   - accumulated: The accumulated registration builder actions.
    ///   - next: The next `RegistrationBuilder` to accumulate.
    ///
    /// - Returns: Building action of the passed builder chained after accumulated actions.
    static func buildPartialBlock<Input, Builder: RegistrationBuilder>(
        accumulated: @escaping
        (Registration<Input>) -> Registration<Builder.Input>,
        next: Builder
    ) -> ((Registration<Input>) -> Registration<Builder.Output>)
    where Input: Variable {
        return { next.build(with: accumulated($0)) }
    }
}

/// An extension that handles registration creation.
extension VariableDeclSyntax {
    /// Creates registrations for current variable declaration.
    ///
    /// Depending on whether variable declaration is single variable or grouped
    /// variable declaration, single or multiple registrations are produced respectively.
    ///
    /// In the builder action `RegistrationBuilder`s can be chained to produce
    /// final registrations.
    ///
    /// - Parameters:
    ///   - node: The `@Codable` macro-attribute syntax.
    ///   - context: The context in which to perform the macro expansion.
    ///   - builder: The registration building action.
    ///
    /// - Returns: The final registrations built by the action provided.
    ///
    /// - Important: For single variable declaration type needs to be provided explicitly.
    ///              For grouped variable declaration, if type for a variable is not the same
    ///              as the next explicit type declaration, then type needs to be specified explicitly.
    func registrations<Output: Variable>(
        node: AttributeSyntax,
        in context: some MacroExpansionContext,
        @VariableRegistrationBuilder
        builder: () -> ((Registration<BasicVariable>) -> Registration<Output>)
    ) -> [Registration<Output>] {
        var variablesData = [(PatternBindingSyntax, TokenSyntax, TypeSyntax?)]()
        for binding in bindings
        where binding.pattern.is(IdentifierPatternSyntax.self) {
            variablesData.append(
                (
                    binding,
                    binding.pattern.as(IdentifierPatternSyntax.self)!
                        .identifier.trimmed,
                    binding.typeAnnotation?.type.trimmed
                )
            )
        }

        var variables: [(PatternBindingSyntax, BasicVariable)] = []
        variables.reserveCapacity(variablesData.count)
        var latestType: TypeSyntax!
        for (binding, name, type) in variablesData.reversed() {
            if let type { latestType = type }
            variables.append((binding, .init(name: name, type: latestType)))
        }

        return variables.reversed().map { binding, variable in
            return builder()(
                Registration(
                    variable: variable,
                    expansion: context, node: node,
                    declaration: self, binding: binding
                )
            )
        }
    }
}
