import SwiftSyntax
import SwiftSyntaxMacros

/// A type representing data associated with a tagged enum variable switch case.
///
/// This type informs how this variable needs to be initialized,
/// decoded/encoded in the macro expansion phase.
///
/// This type also provides default method for switch expression generation
/// based on tagging for both decoding and encoding.
protocol TaggedEnumSwitcherVariable: EnumSwitcherVariable {}

extension TaggedEnumSwitcherVariable {
    /// Provides the switch expression for decoding.
    ///
    /// Based on enum-cases the each case for switch expression is generated.
    /// Final expression generated combining all cases with provided parameters.
    ///
    /// - Parameters:
    ///   - header: The switch header cases are compared to.
    ///   - location: The decoding location.
    ///   - coder: The decoder for cases.
    ///   - context: The context in which to perform the macro expansion.
    ///   - default: Whether default case is needed. Note that for Bool type,
    ///     the default case is automatically skipped since both true and false
    ///     cases are explicitly handled, avoiding unreachable default warnings.
    ///   - forceDecodingReturn: Whether to force explicit `return` statements in each
    ///     switch case. When `true`, adds a `return` statement after the case assignment
    ///     for early exit. Defaults to `false` for backward compatibility.
    ///   - preSyntax: The callback to generate case variation data.
    ///
    /// - Returns: The generated switch expression.
    func decodeSwitchExpression(
        over header: EnumVariable.CaseValue.Expr,
        at location: EnumSwitcherLocation,
        from coder: TokenSyntax,
        in context: some MacroExpansionContext,
        withDefaultCase default: Bool,
        forceDecodingReturn: Bool = false,
        preSyntax: (TokenSyntax) -> CodeBlockItemListSyntax
    ) -> SwitchExprSyntax? {
        var switchable = false

        // For Bool type, check if both true and false values are present
        var hasBoolTrue = false
        var hasBoolFalse = false
        if header.type == .bool {
            for (_, value) in location.cases {
                let boolValues = value.decodeExprs.filter { $0.type == .bool }
                for boolValue in boolValues {
                    let valueStr = boolValue.syntax.trimmedDescription
                    if valueStr == "true" {
                        hasBoolTrue = true
                    } else if valueStr == "false" {
                        hasBoolFalse = true
                    }
                }
            }
        }
        let skipDefaultForBool = header.type == .bool && hasBoolTrue && hasBoolFalse

        let switchExpr = SwitchExprSyntax(subject: header.syntax) {
            for (`case`, value) in location.cases where `case`.decode ?? true {
                let values = value.decodeExprs
                    .filter { $0.type == header.type }
                    .map(\.syntax)
                let cLocation = EnumCaseCodingLocation(
                    coder: coder, values: values
                )
                let generated = `case`.decoding(in: context, from: cLocation)
                if !values.isEmpty {
                    let _ = { switchable = true }()
                    SwitchCaseSyntax(label: .case(generated.label)) {
                        preSyntax("\(values.first!)")
                        generated.code.combined()
                        "\(location.codeExpr(`case`.name, `case`.variables))"
                        if forceDecodingReturn {
                            "return"
                        }
                    }
                }
            }

            if `default` && !skipDefaultForBool {
                SwitchCaseSyntax(label: .default(.init())) {
                    "break"
                }
            }
        }
        return switchable ? switchExpr : nil
    }

    /// Generates error handling syntax for unmatched enum cases during decoding.
    ///
    /// Creates a `DecodingError.typeMismatch` with appropriate context information
    /// when no enum cases match the decoded value. This provides meaningful error
    /// messages that include the coding path and a descriptive message indicating
    /// that no cases could be matched.
    ///
    /// - Parameter coder: The decoder token used to access the coding path for
    ///   error context.
    ///
    /// - Returns: Code block syntax that throws a type mismatch decoding error
    ///   with contextual information.
    func unmatchedErrorSyntax(
        from coder: TokenSyntax
    ) -> CodeBlockItemListSyntax {
        CodeBlockItemListSyntax {
            """
            let context = DecodingError.Context(
                codingPath: \(coder).codingPath,
                debugDescription: "Couldn't match any cases."
            )
            """
            "throw DecodingError.typeMismatch(Self.self, context)"
        }
    }
}

extension EnumSwitcherVariable {
    /// Provides the switch expression for encoding.
    ///
    /// Based on enum-cases the each case for switch expression is generated.
    /// Final expression generated combining all cases with provided parameters.
    ///
    /// - Parameters:
    ///   - header: The switch header cases are compared to.
    ///   - location: The encoding location.
    ///   - coder: The encoder for cases.
    ///   - context: The context in which to perform the macro expansion.
    ///   - default: Whether default case is needed.
    ///   - preSyntax: The callback to generate case variation data.
    ///
    /// - Returns: The generated switch expression.
    func encodeSwitchExpression(
        over header: ExprSyntax,
        at location: EnumSwitcherLocation,
        from coder: TokenSyntax,
        in context: some MacroExpansionContext,
        withDefaultCase default: Bool,
        preSyntax: (TokenSyntax) -> CodeBlockItemListSyntax
    ) -> SwitchExprSyntax? {
        let cases = location.cases
        let allEncodable = cases.allSatisfy { $0.variable.encode ?? true }
        var anyEncodeCondition = false
        var switchable = false
        let switchExpr = SwitchExprSyntax(subject: header) {
            for (`case`, value) in cases where `case`.encode ?? true {
                let _ = { switchable = true }()
                let values = value.encodeExprs.map(\.syntax)
                let cLocation = EnumCaseCodingLocation(
                    coder: coder, values: values
                )

                let generated = `case`.encoding(in: context, to: cLocation)
                let expr = location.codeExpr(`case`.name, `case`.variables)
                let pattern = ExpressionPatternSyntax(expression: expr)
                let whereClause = generated.label.caseItems.first { item in
                    anyEncodeCondition = item.whereClause != nil
                    return anyEncodeCondition
                }?.whereClause
                let label = SwitchCaseLabelSyntax {
                    .init(pattern: pattern, whereClause: whereClause)
                }

                let generatedCode = generated.code.combined()
                SwitchCaseSyntax(label: .case(label)) {
                    if !generatedCode.isEmpty {
                        CodeBlockItemListSyntax {
                            preSyntax("\(values.first!)")
                            generatedCode
                        }
                    } else {
                        "break"
                    }
                }
            }

            if `default` || !allEncodable || anyEncodeCondition {
                SwitchCaseSyntax(label: .default(.init())) { "break" }
            }
        }
        return switchable ? switchExpr : nil
    }
}
