@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// An `Attribute` type that generates declarations for the attached
/// declaration by performing registration of each member variables.
///
/// This macro verifies that macro usage condition is met by attached
/// declaration by using the `diagnoser().produce(syntax:in:)`
/// implementation. If verification succeeds only then registrar is created
/// with member variables registrations and declarations generated.
protocol RegistrationAttribute: Attribute {}

extension RegistrationAttribute {
    /// Creates and returns registrar with member variables registered.
    ///
    /// First verifies that macro usage condition is met by attached
    /// declaration by using the `diagnoser().produce(syntax:in:)`
    /// implementation. If verification succeeds only then registrar is created
    /// with member variables registrations.
    ///
    /// - Parameters:
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - node: The attribute describing this macro.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Created registrar if validation succeeds, otherwise `nil`.
    static func registrar(
        for declaration: some DeclGroupSyntax,
        node: AttributeSyntax,
        in context: some MacroExpansionContext
    ) -> Registrar? {
        guard
            let self = Self(from: node),
            !self.diagnoser().produce(for: declaration, in: context)
        else { return nil }

        let options = Registrar.Options(decl: declaration)
        var registrar = Registrar(options: options)

        declaration.memberBlock.members.forEach { member in
            // is a variable declaration
            guard let decl = member.decl.as(VariableDeclSyntax.self)
            else { return }

            // The Macro fails to compile if the decl.modifiers.contains
            // is directly used in the guard statement. Otherwise it should
            // be used as a second condition in guard block above.
            let isStatic = decl.modifiers.contains { $0.name.tokenKind == .keyword(.static) }
            guard !isStatic else { return }

            // builder
            let builder =
                CodingKeys(from: declaration)
                |> IgnoreCodingInitialized(from: declaration)
                |> KeyPathRegistrationBuilder(
                    provider: CodedAt(from: decl)
                        ?? CodedIn(from: decl)
                        ?? CodedIn()
                )
                |> HelperCodingRegistrationBuilder()
                |> DefaultCodingRegistrationBuilder()
                |> InitializationRegistrationBuilder()
                |> IgnoreCodingBuilder()

            // build
            let regs = decl.registrations(for: self, in: context, with: builder)

            // register
            for registration in regs {
                registrar.add(registration: registration, context: context)
            }
        }

        // send
        return registrar
    }
}
