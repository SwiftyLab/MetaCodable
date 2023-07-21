import SwiftSyntax

/// A registration builder updating initialization data for variable.
///
/// Checks whether variable can be initialized and whether variable has been already initialized
/// from the current syntax and updates the registrations variable data accordingly.
struct InitializationRegistrationBuilder<Input: Variable>: RegistrationBuilder {
    /// The output registration variable type that handles initialization data.
    typealias Output = InitializationVariable<Input>

    /// Build new registration with provided input registration.
    ///
    /// New registration is updated with new variable data indicating whether variable can be initialized
    /// and whether variable has been initialized before.
    ///
    /// - Parameter input: The registration built so far.
    /// - Returns: Newly built registration with initialization data.
    func build(with input: Registration<Input>) -> Registration<Output> {
        let canInit = switch input.context.binding.accessor {
        case .some(let block) where block.is(CodeBlockSyntax.self):
            false
        case .some(let block) where block.is(AccessorBlockSyntax.self):
            !block.as(AccessorBlockSyntax.self)!.accessors.contains { decl in
                decl.accessorKind.tokenKind == .keyword(.get)
            }
            // TODO: Re-evaluate when init accessor is introduced
            // https://github.com/apple/swift-evolution/blob/main/proposals/0400-init-accessors.md
            // || block.as(AccessorBlockSyntax.self)!.accessors.contains { decl in
            //     decl.accessorKind.tokenKind == .keyword(.`init`)
            // }
        default:
            input.context.declaration.bindingKeyword.tokenKind == .keyword(.var)
            || input.context.binding.initializer == nil
        }

        let initialized = input.context.binding.initializer == nil
        let options = Output.Options(init: canInit, initialized: initialized)
        let newVariable = Output(base: input.variable, options: options)
        return input.updating(with: newVariable)
    }
}
