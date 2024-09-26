import SwiftSyntax
import SwiftSyntaxMacros

/// Dummy implementation of swift-testing `require` macro.
struct RequireOptional: ExpressionMacro {
    /// Dummy implementation of swift-testing `require` macro.
    ///
    /// - Parameters:
    ///   - node: The expression describing this macro.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Equivalent `XCTUnwrap` expression.
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard !node.arguments.isEmpty else {
            let message = TestingMacroMessage(
                message: "Expecting atleast one argument",
                severity: .error
            )
            context.diagnose(.init(node: node, message: message))
            return ""
        }
        return ExprSyntax(
            FunctionCallExprSyntax(callee: "XCTUnwrap" as ExprSyntax) {
                LabeledExprSyntax(expression: node.arguments.first!.expression)
            }
        )
    }
}

/// Dummy implementation of swift-testing `expect` macro.
struct Expect: ExpressionMacro {
    /// Dummy implementation of swift-testing `expect` macro.
    ///
    /// This returns equivalent:
    /// * `XCTAssertEqual` expression if condition is an equality check.
    /// * `XCTAssertTrue` expression otherwise.
    ///
    /// - Parameters:
    ///   - node: The expression describing this macro.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Equivalent `XCTest` expression.
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        guard
            node.arguments.count == 1,
            let expr = node.arguments.first?.expression,
            let compExpr = expr.as(InfixOperatorExprSyntax.self),
            let oExpr = compExpr.operator.as(BinaryOperatorExprSyntax.self),
            oExpr.operator.tokenKind == .binaryOperator("==")
        else {
            guard !node.arguments.isEmpty else {
                let message = TestingMacroMessage(
                    message: "Expecting atleast one argument",
                    severity: .error
                )
                context.diagnose(.init(node: node, message: message))
                return ""
            }

            return ExprSyntax(
                FunctionCallExprSyntax(callee: "XCTAssertTrue" as ExprSyntax) {
                    LabeledExprSyntax(
                        expression: node.arguments.first!.expression
                    )
                }
            )
        }

        return ExprSyntax(
            FunctionCallExprSyntax(callee: "XCTAssertEqual" as ExprSyntax) {
                LabeledExprSyntax(expression: compExpr.leftOperand)
                LabeledExprSyntax(expression: compExpr.rightOperand)
            }
        )
    }
}

/// Dummy implementation of swift-testing `expect(throws:)` macro.
struct ExpectThrows: ExpressionMacro {
    /// Dummy implementation of swift-testing `expect(throws:)` macro.
    ///
    /// This returns to `XCTAssertThrowsError` expression that uses
    /// `XCTAssertTrue` for validating error type in `errorHandler`
    /// closure expression.
    ///
    /// - Parameters:
    ///   - node: The expression describing this macro.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Equivalent `XCTest` expression.
    static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        let trailingClosure: ClosureExprSyntax
        if let closure = node.trailingClosure {
            trailingClosure = closure
        } else if node.arguments.count > 1,
            case let args = node.arguments,
            case let index = args.index(args.startIndex, offsetBy: 1),
            let closure = args[index].expression.as(ClosureExprSyntax.self)
        {
            trailingClosure = closure
        } else {
            let message = TestingMacroMessage(
                message: "Expecting closure",
                severity: .error
            )
            context.diagnose(.init(node: node, message: message))
            return ""
        }

        let errorHandler = ClosureExprSyntax {
            "XCTAssertTrue(type(of: $0) == Decodable.self)"
        }
        return ExprSyntax(
            TryExprSyntax(
                expression: FunctionCallExprSyntax(
                    callee: "XCTAssertThrowsError" as ExprSyntax,
                    trailingClosure: errorHandler
                ) {
                    LabeledExprSyntax(
                        expression: FunctionCallExprSyntax(
                            callee: trailingClosure
                        )
                    )
                }
            )
        )
    }
}
