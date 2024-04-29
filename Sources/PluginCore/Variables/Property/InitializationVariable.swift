import SwiftSyntax
import SwiftSyntaxMacros

/// A variable value containing initialization data.
///
/// The `InitializationVariable` type forwards `Variable`
/// encoding implementations, while customizing decoding and initialization
/// implementations.
struct InitializationVariable<Wrapped>: ComposedVariable, PropertyVariable
where
    Wrapped: PropertyVariable,
    Wrapped.Initialization: RequiredVariableInitialization
{
    /// The customization options for `InitializationVariable`.
    ///
    /// `InitializationVariable` uses the instance of this type,
    /// provided during initialization, for customizing code generation.
    struct Options {
        /// Whether variable can be initialized.
        ///
        /// True for non-initialized stored variables,
        /// initialized mutable variables. False for
        /// computed and initialized immutable variables.
        let `init`: Bool
        /// Whether variable has been initialized.
        ///
        /// True if variable has any initializing expression,
        /// false otherwise.
        let initialized: Bool
    }

    /// The value wrapped by this instance.
    ///
    /// The wrapped variable's type data is
    /// preserved and provided during initialization.
    let base: Wrapped
    /// The options for customizations.
    ///
    /// Options is provided during initialization.
    let options: Options

    /// Whether the variable is to be decoded.
    ///
    /// `false` if variable can't be initialized, otherwise depends on
    /// whether underlying variable is to be decoded.
    var decode: Bool? { options.`init` ? base.decode : false }
    /// Whether the variable is to be encoded.
    ///
    /// Depends on whether variable is initializable if underlying variable
    /// doesn't specify explicit encoding. Otherwise depends on whether
    /// underlying variable is to be decoded.
    var encode: Bool? {
        return base.encode ?? (options.initialized || options.`init`)
    }

    /// Whether the variable type requires `Decodable` conformance.
    ///
    /// Provides whether underlying variable type requires
    /// `Decodable` conformance, if variable can be
    /// initialized otherwise `false`.
    var requireDecodable: Bool? {
        return options.`init` ? base.requireDecodable : false
    }
    /// Whether the variable type requires `Encodable` conformance.
    ///
    /// Provides whether underlying variable type requires
    /// `Encodable` conformance, if underlying variable
    /// specifies explicit encoding. Otherwise depends on
    /// whether underlying variable is to be decoded.
    var requireEncodable: Bool? {
        return base.requireEncodable ?? (options.initialized || options.`init`)
    }

    /// Provides the code syntax for decoding this variable
    /// at the provided location.
    ///
    /// Provides code syntax for decoding of the underlying
    /// variable value if variable can be initialized
    /// (i.e. `options.init` is `true`). Otherwise variable
    /// ignored in decoding.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location for the variable.
    ///
    /// - Returns: The generated variable decoding code.
    func decoding(
        in context: some MacroExpansionContext,
        from location: PropertyCodingLocation
    ) -> CodeBlockItemListSyntax {
        guard options.`init` else { return .init([]) }
        return base.decoding(in: context, from: location)
    }

    /// Indicates the initialization type for this variable.
    ///
    /// Following checks are performed to determine initialization type:
    /// * Initialization is ignored if variable can't be initialized
    ///   (i.e. `options.init` is `false`).
    /// * Initialization is optional if variable is already initialized
    ///   and can be initialized again (i.e both `options.initialized`
    ///   and `options.init` is `true`)
    /// * Otherwise initialization type of the underlying variable value
    ///   is used.
    ///
    /// - Parameter context: The context in which to perform
    ///   the macro expansion.
    /// - Returns: The type of initialization for variable.
    func initializing(
        in context: some MacroExpansionContext
    ) -> AnyInitialization {
        return if options.`init` {
            if options.initialized {
                base.initializing(in: context).optionalize.any
            } else {
                base.initializing(in: context).any
            }
        } else {
            IgnoredInitialization().any
        }
    }
}

extension Registration
where
    Decl == PropertyDeclSyntax, Var: PropertyVariable & InitializableVariable,
    Var.Initialization: RequiredVariableInitialization
{
    /// The output registration variable type that handles initialization data.
    typealias InitOutput = InitializationVariable<Var>
    /// Update registration with initialization data.
    ///
    /// New registration is updated with new variable data indicating whether
    /// variable can be initialized and whether variable has been initialized
    /// before.
    ///
    /// - Returns: Newly built registration with initialization data.
    func checkCanBeInitialized() -> Registration<Decl, Key, InitOutput> {
        typealias Output = InitOutput
        let initialized = self.variable.value != nil
        let canInit =
            switch self.decl.accessorBlock?.accessors {
            case .getter:
                false
            case .accessors(let accessors):
                !accessors.contains { decl in
                    decl.accessorSpecifier.tokenKind == .keyword(.get)
                }
            // TODO: Re-evaluate when init accessor is introduced
            // https://github.com/apple/swift-evolution/blob/main/proposals/0400-init-accessors.md
            // || block.as(AccessorBlockSyntax.self)!.accessors.contains { decl in
            //     decl.accessorKind.tokenKind == .keyword(.`init`)
            // }
            default:
                self.decl.bindingSpecifier.tokenKind == .keyword(.var)
                    || !initialized
            }

        let options = Output.Options(init: canInit, initialized: initialized)
        let newVariable = Output(base: self.variable, options: options)
        return self.updating(with: newVariable)
    }
}
