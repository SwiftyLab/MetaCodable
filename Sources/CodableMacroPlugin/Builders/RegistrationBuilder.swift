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

/// An extension that handles registration creation.
extension VariableDeclSyntax {
    /// Creates registrations for current variable declaration.
    ///
    /// Depending on whether variable declaration is single variable or grouped
    /// variable declaration, single or multiple registrations are produced
    /// respectively.
    ///
    /// In the builder action `RegistrationBuilder`s can be chained to produce
    /// final registrations.
    ///
    /// - Parameters:
    ///   - attr: The macro-attribute being expanded.
    ///   - context: The context in which to perform the macro expansion.
    ///   - builder: The registration building action.
    ///
    /// - Returns: The final registrations built by the action provided.
    ///
    /// - Important: For single variable declaration type needs to be
    ///   provided explicitly. For grouped variable declaration, if type for
    ///   a variable is not the same as the next explicit type declaration,
    ///   then type needs to be specified explicitly.
    func registrations<Output: Variable>(
        for attr: some RegistrationAttribute,
        in context: some MacroExpansionContext,
        with builder: (Registration<BasicVariable>) -> Registration<Output>
    ) -> [Registration<Output>] {
        var variablesData = [(PatternBindingSyntax, TokenSyntax, TypeSyntax?)]()
        for binding in bindings
            where binding.pattern.is(IdentifierPatternSyntax.self)
        {
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
            builder(
                Registration(
                    variable: variable,
                    expansion: context, attr: attr,
                    declaration: self, binding: binding
                )
            )
        }
    }
}

/// The chaining operator for `RegistrationBuilder`s.
///
/// Combines `RegistrationBuilder`s in the order
/// provided to create final builder action to process
/// and parse variable data.
infix operator |>: AdditionPrecedence

/// Builds a registration builder action by combining
/// two `RegistrationBuilder`s.
///
/// - Parameters:
///   - lhs: The first `RegistrationBuilder`.
///   - rhs: The second `RegistrationBuilder` to accumulate.
///
/// - Returns: Building action of the passed builders chained in order.
func |> <L: RegistrationBuilder, R: RegistrationBuilder>(
    lhs: L,
    rhs: R
) -> (Registration<L.Input>) -> Registration<R.Output>
    where L.Output == R.Input
{
    { rhs.build(with: lhs.build(with: $0)) }
}

/// Builds a registration builder action by combining
/// an accumulated registration builder action and
/// a new `RegistrationBuilder`.
///
/// - Parameters:
///   - accumulated: The accumulated registration builder action.
///   - next: The next `RegistrationBuilder` to accumulate.
///
/// - Returns: Building action of the passed builder chained after
///   accumulated actions.
func |> <I: Variable, R: RegistrationBuilder>(
    accumulated: @escaping (Registration<I>) -> Registration<R.Input>,
    next: R
) -> (Registration<I>) -> Registration<R.Output> {
    { next.build(with: accumulated($0)) }
}
