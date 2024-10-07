import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A variable value containing helper expression for decoding/encoding.
///
/// The `HelperCodedVariable` customizes decoding and encoding
/// by using the helper instance expression provided during initialization.
struct HelperCodedVariable<Wrapped>: ComposedVariable, PropertyVariable
where Wrapped: DefaultPropertyVariable {
    /// The customization options for `HelperCodedVariable`.
    ///
    /// `HelperCodedVariable` uses the instance of this type,
    /// provided during initialization, for customizing code generation.
    enum Options {
        /// Represents a single helper expression.
        ///
        /// This helper expression is passed to `CodedBy` macro.
        /// This expression is used for decode/encode syntax generation.
        ///
        /// - Parameter expr: The helper expression.
        case helper(_ expr: ExprSyntax)
        /// Represents an action that creates helper expression
        /// accepting arguments.
        ///
        /// This closure expression and arguments are passed to `CodedBy` macro.
        /// The expression created by passing arguments to the action is used
        /// for decode/encode syntax generation.
        ///
        /// - Parameters:
        ///   - action: The action that creates the helper expression.
        ///   - params: The arguments that action takes.
        case helperAction(_ action: ExprSyntax, _ params: [Parameter])

        /// Creates new instance based on the arguments expressions provided.
        ///
        /// - Parameter args: The `CodedBy` macro arguments.
        init(parsing args: LabeledExprListSyntax) {
            guard args.count > 1 else {
                self = .helper(args.first!.expression)
                return
            }

            var parameters: [Parameter] = []
            var parsingProperties = false
            for arg in args.dropFirst() {
                if arg.label?.trimmed.text == "properties" {
                    parsingProperties = true
                }

                if parsingProperties {
                    let kExpr = arg.expression.as(KeyPathExprSyntax.self)!
                    parameters.append(.property(kExpr.components))
                } else {
                    parameters.append(.argument(arg.expression))
                }
            }
            self = .helperAction(args.first!.expression, parameters)
        }

        /// The helper expression used for decoding/encoding.
        ///
        /// This expression is created from initialization arguments
        /// and used to generate assisted decoding/encoding syntax.
        var helperExpr: ExprSyntax {
            switch self {
            case let .helper(expr):
                return expr
            case let .helperAction(action, parameters):
                let args = LabeledExprListSyntax {
                    for param in parameters {
                        LabeledExprSyntax(expression: param.asArg)
                    }
                }
                let argsType = TupleTypeElementListSyntax {
                    for _ in parameters {
                        TupleTypeElementSyntax(type: "_" as TypeSyntax)
                    }
                }
                return "{ () -> (\(argsType)) -> _ in \(action) }()(\(args))"
            }
        }

        /// The argument type for helper expression action.
        ///
        /// The helper expression action only accepts arguments
        /// of the variation of this type.
        enum Parameter {
            /// Represents any kind of argument.
            ///
            /// The argument expressions are passed to `CodedBy` macro,
            /// before the properties key path expression.
            ///
            /// - Parameter expr: The argument expression.
            case argument(_ expr: ExprSyntax)
            /// Represents key path expression as argument.
            ///
            /// The argument expressions are passed to `CodedBy` macro
            /// and represents key path to instance properties of current type.
            ///
            /// - Parameter keyPath: The key path component expression.
            case property(_ keyPath: KeyPathComponentListSyntax)

            /// The argument expression passed to helper action.
            ///
            /// Returns the actual expression that should be passed to
            /// helper action to create the helper expression syntax.
            var asArg: ExprSyntax {
                switch self {
                case let .argument(expr):
                    expr
                case let .property(comps):
                    "self\(comps)"
                }
            }
        }
    }

    /// The value wrapped by this instance.
    ///
    /// Only default implementation provided with
    /// `BasicVariable` can be wrapped
    /// by this instance.
    let base: Wrapped
    /// The options for customizations.
    ///
    /// Options is provided during initialization.
    let options: Options

    /// Whether the variable is to
    /// be decoded.
    ///
    /// Always `true` for this type.
    var decode: Bool? { true }
    /// Whether the variable is to
    /// be encoded.
    ///
    /// Always `true` for this type.
    var encode: Bool? { true }

    /// Whether the variable type requires `Decodable` conformance.
    ///
    /// Always `false` for this type.
    var requireDecodable: Bool? { false }
    /// Whether the variable type requires `Encodable` conformance.
    ///
    /// Always `false` for this type.
    var requireEncodable: Bool? { false }

    /// Provides the code syntax for encoding this variable
    /// at the provided location.
    ///
    /// Uses helper expression provided, to generate implementation:
    /// * For directly decoding from decoder, passes decoder directly to
    ///   helper's `decode(from:)` (or `decodeIfPresent(from:)`
    ///   for optional types) method.
    /// * For decoding from container, passes super-decoder at container's
    ///   provided `CodingKey` to helper's `decode(from:)`
    ///   (or `decodeIfPresent(from:)` for optional types) methods.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location for the variable.
    ///
    /// - Returns: The generated variable encoding code.
    func decoding(
        in context: some MacroExpansionContext,
        from location: PropertyCodingLocation
    ) -> CodeBlockItemListSyntax {
        let (_, defMethod) = codingTypeMethod(forMethod: "decode")
        switch location {
        case .coder(let decoder, let passedMethod):
            let method = passedMethod ?? defMethod
            return CodeBlockItemListSyntax {
                """
                \(decodePrefix)\(name) = try \(options.helperExpr).\(method)(from: \(decoder))
                """
            }
        case .container(let container, let key, let passedMethod):
            let method = passedMethod ?? defMethod
            return CodeBlockItemListSyntax {
                """
                \(decodePrefix)\(name) = try \(options.helperExpr).\(method)(from: \(container), forKey: \(key))
                """
            }
        }
    }

    /// Provides the code syntax for encoding this variable
    /// at the provided location.
    ///
    /// Uses helper expression provided, to generate implementation:
    /// * For directly encoding to encoder, passes encoder directly to helper's
    ///   `encode(to:)` (or `encodeIfPresent(to:)`
    ///   for optional types) method.
    /// * For encoding to container, passes super-encoder at container's
    ///   provided `CodingKey` to helper's `encode(to:)`
    ///   (or `encodeIfPresent(to:)` for optional types) methods.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location for the variable.
    ///
    /// - Returns: The generated variable encoding code.
    func encoding(
        in context: some MacroExpansionContext,
        to location: PropertyCodingLocation
    ) -> CodeBlockItemListSyntax {
        let (_, defMethod) = codingTypeMethod(forMethod: "encode")
        switch location {
        case .coder(let encoder, let passedMethod):
            let method = passedMethod ?? defMethod
            return CodeBlockItemListSyntax {
                """
                try \(options.helperExpr).\(method)(\(encodePrefix)\(name), to: \(encoder))
                """
            }
        case .container(let container, let key, let passedMethod):
            let method = passedMethod ?? defMethod
            return CodeBlockItemListSyntax {
                """
                try \(options.helperExpr).\(method)(\(encodePrefix)\(name), to: &\(container), atKey: \(key))
                """
            }
        }
    }

    /// The number of variables this variable depends on.
    ///
    /// The number of instance property key path expression
    /// provided to `CodedBy` macro.
    var dependenciesCount: UInt {
        switch options {
        case .helper:
            return 0
        case .helperAction(_, let params):
            let count = params.count { param in
                switch param {
                case .property:
                    return true
                default:
                    return false
                }
            }
            return UInt(count)
        }
    }

    /// Checks whether this variable is dependent on the provided variable.
    ///
    /// Whether any of the instance property key path expression provided to
    /// `CodedBy` macro matches the provided variable name.
    ///
    /// - Parameter variable: The variable to check for.
    /// - Returns: Whether this variable is dependent on the provided variable.
    func depends<Variable: PropertyVariable>(on variable: Variable) -> Bool {
        switch options {
        case .helper:
            return base.depends(on: variable)
        case let .helperAction(_, parameters):
            return parameters.firstIndex { parameter in
                switch parameter {
                case .property(let components):
                    let component = components.first?.component
                    return component?.trimmedDescription.trimmingBackTicks
                        == variable.name.trimmed.text.trimmingBackTicks
                case .argument:
                    return false
                }
            } != nil
        }
    }
}

extension HelperCodedVariable: InitializableVariable
where Wrapped: InitializableVariable {
    /// The initialization type of this variable.
    ///
    /// Initialization type is the same as underlying wrapped variable.
    typealias Initialization = Wrapped.Initialization
}

extension HelperCodedVariable: AssociatedVariable
where Wrapped: AssociatedVariable {}

/// A `Variable` type representing that doesn't customize
/// decoding/encoding implementation.
///
/// `BasicPropertyVariable` confirms to this type since it doesn't
/// customize decoding/encoding implementation from Swift standard library.
///
/// `ComposedVariable`'s may confirm to this if no decoding/encoding
/// customization added on top of underlying variable and wrapped variable
/// also confirms to this type.
protocol DefaultPropertyVariable: PropertyVariable {}
