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
    ///   - default: Whether default case is needed.
    ///   - preSyntax: The callback to generate case variation data.
    ///
    /// - Returns: The generated switch expression.
    func decodeSwitchExpression(
        over header: ExprSyntax,
        at location: EnumSwitcherLocation,
        from coder: TokenSyntax,
        in context: some MacroExpansionContext,
        withDefaultCase default: Bool,
        preSyntax: (TokenSyntax) -> CodeBlockItemListSyntax
    ) -> SwitchExprSyntax {
        return SwitchExprSyntax(subject: header) {
            for (`case`, value) in location.cases where `case`.decode ?? true {
                let cLocation = EnumCaseCodingLocation(
                    coder: coder, values: value.decodeExprs
                )
                let generated = `case`.decoding(in: context, from: cLocation)
                SwitchCaseSyntax(label: .case(generated.label)) {
                    preSyntax("\(value.decodeExprs.first!)")
                    generated.code.combined()
                    "\(location.codeExpr(`case`.name, `case`.variables))"
                }
            }
            if `default` {
                SwitchCaseSyntax(label: .default(.init())) {
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
    ) -> SwitchExprSyntax {
        let cases = location.cases
        let allEncodable = cases.allSatisfy { $0.variable.encode ?? true }
        var anyEncodeCondition = false
        return SwitchExprSyntax(subject: header) {
            for (`case`, value) in cases where `case`.encode ?? true {
                let cLocation = EnumCaseCodingLocation(
                    coder: coder, values: value.encodeExprs
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
                            preSyntax("\(value.encodeExprs.first!)")
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
    }
}
