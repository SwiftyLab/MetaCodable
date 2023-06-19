import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

extension CodableMacro.Registrar.Node {
    /// A type containing declared variable data necessary
    /// for generating variable decoding/encoding expression.
    ///
    /// This type contains field name and type syntax as required data,
    /// default value expression and helper decoder/encoder as optional data.
    ///
    /// This type can generate decoding/encoding expression
    /// for a single variable declaration.
    struct Data: Equatable, Hashable {
        /// The field name token of variable declaration.
        let field: TokenSyntax
        /// The field type token of variable declaration.
        private let type: TypeSyntax
        /// The optional default value expression provided
        /// using `CodableFieldMacro` macro.
        private let `default`: ExprSyntax?
        /// The optional helper decoder/encoder expression
        /// provided using `CodableFieldMacro` macro.
        private let helper: ExprSyntax?

        /// Indicates whether field type is an `Optional` type.
        private var isOptional: Bool {
            if self.type.is(OptionalTypeSyntax.self) {
                return true
            } else if let type = self.type.as(SimpleTypeIdentifierSyntax.self),
                      type.name.text == "Optional",
                      let gArgs = type.genericArgumentClause?.arguments,
                      gArgs.count == 1 {
                return true
            } else {
                return false
            }
        }

        /// Returns equivalent function parameter syntax for current data.
        ///
        /// This is used to generate member-wise initializer.
        ///
        /// If default expression is provided then it is used here,
        /// otherwise only optional fields have default value `nil`.
        var funcParam: FunctionParameterSyntax {
            if let `default` {
                return "\(field): \(type) = \(`default`)"
            } else if self.isOptional {
                return "\(field): \(type) = nil"
            } else {
                return "\(field): \(type)"
            }
        }

        /// Creates new metadata with provided inputs.
        ///
        /// - Parameters:
        ///   - field: The field name token.
        ///   - type: The field type token.
        ///   - default: The optional default value expression .
        ///   - helper: The optional helper decoder/encoder expression.
        ///
        /// - Returns: The newly created metadata instance.
        init(
            field: TokenSyntax,
            type: TypeSyntax,
            default: ExprSyntax? = nil,
            helper: ExprSyntax? = nil
        ) {
            self.field = field
            self.type = type
            self.default = `default`
            self.helper = helper
        }
    }
}

// MARK: Decoding
extension CodableMacro.Registrar.Node.Data {
    /// Provides type and method expression to use
    /// with container expression for decoding.
    ///
    /// For optional types `decodeIfPresent` method used for container,
    /// for other types `decode` method is used.
    ///
    /// - Returns: The type and method expression for decoding.
    func decodingTypeAndMethod() -> (TypeSyntax, ExprSyntax) {
        let (dType, dMethod): (TypeSyntax, ExprSyntax)
        if let type = self.type.as(OptionalTypeSyntax.self) {
            dType = type.wrappedType
            dMethod = "decodeIfPresent"
        } else if let type = self.type.as(SimpleTypeIdentifierSyntax.self),
                  type.name.text == "Optional",
                  let gArgs = type.genericArgumentClause?.arguments,
                  gArgs.count == 1,
                  let type = gArgs.first?.argumentType {
            dType = type
            dMethod = "decodeIfPresent"
        } else {
            dType = type
            dMethod = "decode"
        }
        return (dType, dMethod)
    }

    /// Provides the expression list syntax for decoding current
    /// field using current metadata.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - container: The decoding container variable for the current field.
    ///   - key: The `CodingKey` current field is associated with.
    ///
    /// - Returns: The generated expression list.
    func decoding(
        in context: some MacroExpansionContext,
        from container: TokenSyntax,
        key: ExprSyntax
    ) -> ExprListSyntax {
        let (type, method) = self.decodingTypeAndMethod()
        let prefExp: ExprSyntax?
        let dExpr: ExprSyntax
        if let helper {
            let decoder: TokenSyntax = "\(container)_\(field.raw)Decoder"
            prefExp = """
                let \(decoder) = try \(container).superDecoder(forKey: \(key))
                """
            dExpr = "\(helper).\(method)(from: \(decoder))"
        } else {
            prefExp = nil
            dExpr = "\(container).\(method)(\(type).self, forKey: \(key))"
        }

        let expr: ExprSyntax = if `default` != nil {
            "(try? \(dExpr)) ?? \(`default`!)"
        } else {
            "try \(dExpr)"
        }

        return ExprListSyntax {
            if let prefExp { prefExp }
            "self.\(field) = \(expr)" as ExprSyntax
        }
    }

    /// Provides the expression list syntax for decoding current
    /// field as a composition of parent type using current metadata.
    ///
    /// - Parameter context: The context in which to perform the macro expansion.
    /// - Returns: The generated expression list.
    func topDecoding(in context: some MacroExpansionContext) -> ExprListSyntax {
        let (_, method) = self.decodingTypeAndMethod()
        let dExpr: ExprSyntax
        if let helper {
            dExpr = "\(helper).\(method)(from: decoder)"
        } else {
            dExpr = "\(self.type)(from: decoder)"
        }

        let expr: ExprSyntax = if `default` != nil {
            "(try? \(dExpr)) ?? \(`default`!)"
        } else {
            "try \(dExpr)"
        }

        return ExprListSyntax { "self.\(field) = \(expr)" as ExprSyntax }
    }
}

// MARK: Encoding
extension CodableMacro.Registrar.Node.Data {
    /// Provides method expression to use with container expression for encoding.
    ///
    /// For optional types `encodeIfPresent` method used for container,
    /// for other types `encode` method is used.
    ///
    /// - Returns: The method expression for encoding.
    func encodingMethod() -> ExprSyntax {
        return self.isOptional ? "encodeIfPresent" : "encode"
    }

    /// Provides the expression list syntax for encoding current
    /// field using current metadata.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - container: The encoding container variable for the current field.
    ///   - key: The `CodingKey` current field is associated with.
    ///
    /// - Returns: The generated expression list.
    func encoding(
        in context: some MacroExpansionContext,
        to container: TokenSyntax,
        key: ExprSyntax
    ) -> ExprListSyntax {
        let method = self.encodingMethod()
        let prefExp: ExprSyntax?
        let expr: ExprSyntax
        if let helper {
            let encoder: TokenSyntax = "\(container)_\(field.raw)Encoder"
            prefExp = """
                let \(encoder) = \(container).superEncoder(forKey: \(key))
                """
            expr = "try \(helper).\(method)(self.\(field), to: \(encoder))"
        } else {
            prefExp = nil
            expr = """
                try \(container).\(method)(self.\(field), forKey: \(key))
                """
        }

        return ExprListSyntax {
            if let prefExp { prefExp }
            expr
        }
    }

    /// Provides the expression list syntax for encoding current
    /// field as a composition of parent type using current metadata.
    ///
    /// - Parameter context: The context in which to perform the macro expansion.
    /// - Returns: The generated expression list.
    func topEncoding(in context: some MacroExpansionContext) -> ExprListSyntax {
        let method = self.encodingMethod()
        let expr: ExprSyntax
        if let helper {
            expr = "try \(helper).\(method)(self.\(field), to: encoder)"
        } else {
            expr = """
                try self.\(field).encode(to: encoder)
                """
        }

        return ExprListSyntax { expr }
    }
}
