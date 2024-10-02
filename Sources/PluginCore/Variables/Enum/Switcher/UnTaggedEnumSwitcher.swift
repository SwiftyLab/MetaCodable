import SwiftSyntax
import SwiftSyntaxMacros

/// An `EnumSwitcherVariable` generating switch expression for untagged enums.
///
/// Tries decoding associated variables for each case until success.
struct UnTaggedEnumSwitcher: EnumSwitcherVariable {
    /// The node at which variables are registered.
    ///
    /// Associated variables for all cases are registered with the path
    /// at this node. This node is used to generate associated variables
    /// and enum-cases decoding/encoding implementations.
    let node: PropertyVariableTreeNode
    /// The error variable for decoding failure.
    ///
    /// This error is thrown if no enum-case was decoded successfully.
    let error: TokenSyntax

    /// Provides node at which case associated variables are registered.
    ///
    /// The current `node` is provided to all the enum-cases.
    ///
    /// - Parameters:
    ///   - decl: The declaration for which to provide.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The registering node.
    func node(
        for decl: EnumCaseVariableDeclSyntax,
        in context: some MacroExpansionContext
    ) -> PropertyVariableTreeNode {
        return node
    }

    /// Creates value expressions for provided enum-case variable.
    ///
    /// If value expressions are explicitly provided then those are used,
    /// otherwise case name as `String` literal used as value.
    ///
    /// - Parameters:
    ///   - variable: The variable for which generated.
    ///   - values: The values present in syntax.
    ///   - codingKeys: The map where `CodingKeys` maintained.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The generated value.
    func keyExpression<Var: EnumCaseVariable>(
        for variable: Var, values: [ExprSyntax],
        codingKeys: CodingKeysMap, context: some MacroExpansionContext
    ) -> EnumVariable.CaseValue {
        let name = CodingKeysMap.Key.name(for: variable.name).text
        return .raw(!values.isEmpty ? values : ["\(literal: name)"])
    }

    /// Update provided variable data.
    ///
    /// Provided variable is updated with fallback data to throw current error,
    /// if decoding fails.
    ///
    /// - Parameter variable: The variable to transform.
    /// - Returns: Transformed variable.
    func transform(
        variable: BasicAssociatedVariable
    ) -> BasicAssociatedVariable {
        let `throw`: CodeBlockItemListSyntax = "throw \(error)"
        let fallback = DecodingFallback.ifMissing(`throw`, ifError: `throw`)
        return .init(
            base: variable.base, label: variable.label,
            fallback: fallback
        )
    }

    /// Provides the syntax for decoding at the provided location.
    ///
    /// The generated implementation tries decoding each case one by one
    /// stopping at the case for which decoding succeeds, returning that case.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location.
    ///
    /// - Returns: The generated decoding syntax.
    func decoding(
        in context: some MacroExpansionContext,
        from location: EnumSwitcherLocation
    ) -> CodeBlockItemListSyntax {
        var cases = location.cases
        let result = decodingSyntax(for: &cases, from: location, in: context)
        return CodeBlockItemListSyntax {
            if result.usesError {
                """
                let context = DecodingError.Context(
                    codingPath: \(location.coder).codingPath,
                    debugDescription: "Couldn't decode any case."
                )
                """
                "let \(error) =  DecodingError.typeMismatch(Self.self, context)"
            }
            result.syntax
        }
    }

    /// Provides the syntax for decoding the enum-cases at provided location.
    ///
    /// The generated implementation tries decoding each case one by one
    /// stopping at the case for which decoding succeeds, returning that case.
    ///
    /// - Parameters:
    ///   - cases: The enum-cases to be decoded.
    ///   - location: The decoding location.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: Whether `error` value is used and generated decoding syntax.
    private func decodingSyntax(
        for cases: inout [EnumVariable.Case],
        from location: EnumSwitcherLocation,
        in context: some MacroExpansionContext
    ) -> (usesError: Bool, syntax: CodeBlockItemListSyntax) {
        guard !cases.isEmpty else { return (true, "throw \(error)") }

        let `case` = cases.removeFirst()
        let coder = location.coder
        let cLocation = EnumCaseCodingLocation(coder: coder, values: [])
        let generated = `case`.variable.decoding(in: context, from: cLocation)
        let nResult = decodingSyntax(for: &cases, from: location, in: context)
        let catchClauses = CatchClauseListSyntax {
            CatchClauseSyntax {
                nResult.syntax
            }
        }

        let eCase = `case`.variable
        let tVisitor = ThrowingSyntaxVisitor(viewMode: .sourceAccurate)
        let doBlock = CodeBlockItemListSyntax {
            generated.code.codingSyntax
            generated.code.conditionalSyntax
            location.codeExpr(eCase.name, eCase.variables)
            "return"
        }

        tVisitor.walk(doBlock)
        let nUsesError = tVisitor.throws && nResult.usesError
        let eVisitor = ErrorUsageSyntaxVisitor(
            error: error, usesProvidedError: nUsesError,
            viewMode: .sourceAccurate
        )
        eVisitor.walk(doBlock)

        let syntax = CodeBlockItemListSyntax {
            generated.code.containerSyntax
            if tVisitor.throws {
                DoStmtSyntax(catchClauses: catchClauses) {
                    doBlock
                }
            } else {
                doBlock
            }
        }

        return (eVisitor.usesProvidedError || nUsesError, syntax)
    }

    /// Provides the syntax for encoding at the provided location.
    ///
    /// The generated implementation encodes all associated values for a case.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location.
    ///
    /// - Returns: The generated encoding syntax.
    func encoding(
        in context: some MacroExpansionContext,
        to location: EnumSwitcherLocation
    ) -> CodeBlockItemListSyntax {
        let coder = location.coder
        return CodeBlockItemListSyntax {
            self.encodeSwitchExpression(
                over: location.selfValue, at: location, from: coder,
                in: context, withDefaultCase: location.hasDefaultCase
            ) { _ in "" }
        }
    }

    /// Creates additional enum declarations for enum variable.
    ///
    /// No extra `CodingKeys` added by this variable.
    ///
    /// - Parameter context: The macro expansion context.
    /// - Returns: The generated enum declaration syntax.
    func codingKeys(
        in context: some MacroExpansionContext
    ) -> MemberBlockItemListSyntax {
        return []
    }
}

fileprivate extension UnTaggedEnumSwitcher {
    /// A `SyntaxVisitor` that checks provided syntax throwing behaviour.
    ///
    /// This `SyntaxVisitor` checks whether syntax has any un-caught error.
    final class ThrowingSyntaxVisitor: SyntaxVisitor {
        /// Whether the syntax has un-handled errors.
        private(set) var `throws` = false

        /// Decides whether to visit or skip children of provided node.
        ///
        /// If any unhandled error is already detected, visiting is skipped.
        /// Otherwise children are visited.
        ///
        /// - Parameter node: The node to visit.
        /// - Returns: Whether to visit or skip children of node.
        func visit<S: SyntaxProtocol>(node: S) -> SyntaxVisitorContinueKind {
            guard !`throws` else { return .skipChildren }
            return .visitChildren
        }

        /// Decides whether to visit or skip children of provided node.
        ///
        /// Sets un-handled error status to `true`.
        ///
        /// - Parameter n: The node to visit.
        /// - Returns: To skip visiting children of node.
        override func visit(_ n: TryExprSyntax) -> SyntaxVisitorContinueKind {
            `throws` = true
            return .skipChildren
        }

        /// Decides whether to visit or skip children of provided node.
        ///
        /// Sets un-handled error status to `true`.
        ///
        /// - Parameter n: The node to visit.
        /// - Returns: To skip visiting children of node.
        override func visit(_ n: ThrowStmtSyntax) -> SyntaxVisitorContinueKind {
            `throws` = true
            return .skipChildren
        }

        /// Decides whether to visit or skip children of provided node.
        ///
        /// Skips visiting children nodes:
        /// * If any unhandled error is already detected.
        /// * If node is inside a `do` statement.
        ///
        /// Otherwise children are visited.
        ///
        /// - Parameter node: The node to visit.
        /// - Returns: Whether to visit or skip children of node.
        override func visit(
            _ node: CodeBlockSyntax
        ) -> SyntaxVisitorContinueKind {
            guard !`throws` else { return .skipChildren }
            return node.parent?.kind == .doStmt ? .skipChildren : .visitChildren
        }

        /// Decides whether to visit or skip children of provided node.
        ///
        /// If any unhandled error is already detected, visiting is skipped.
        /// Otherwise children are visited.
        ///
        /// - Parameter node: The node to visit.
        /// - Returns: Whether to visit or skip children of node.
        override func visit(
            _ node: CodeBlockItemListSyntax
        ) -> SyntaxVisitorContinueKind {
            return self.visit(node: node)
        }

        /// Decides whether to visit or skip children of provided node.
        ///
        /// If any unhandled error is already detected, visiting is skipped.
        /// Otherwise children are visited.
        ///
        /// - Parameter node: The node to visit.
        /// - Returns: Whether to visit or skip children of node.
        override func visit(
            _ node: CodeBlockItemSyntax
        ) -> SyntaxVisitorContinueKind {
            return self.visit(node: node)
        }
    }

    /// A `SyntaxVisitor` that checks provided syntax error usage.
    ///
    /// This `SyntaxVisitor` checks whether syntax uses provided error value.
    final class ErrorUsageSyntaxVisitor: SyntaxVisitor {
        /// The error variable usage is checked of.
        let error: TokenSyntax
        /// Whether any usage is detected.
        private(set) var usesProvidedError = false

        /// Creates a new visitor with provided parameters.
        ///
        /// - Parameters:
        ///   - error: The error variable usage is checked of.
        ///   - usesProvidedError: Whether any usage is detected already.
        ///   - viewMode: The visit mode when traversing syntax tree.
        init(
            error: TokenSyntax, usesProvidedError: Bool,
            viewMode: SyntaxTreeViewMode = .sourceAccurate
        ) {
            self.error = error
            self.usesProvidedError = usesProvidedError
            super.init(viewMode: viewMode)
        }

        /// Decides whether to visit or skip children of provided node.
        ///
        /// If error usage is already detected, visiting is skipped.
        /// Otherwise children are visited.
        ///
        /// - Parameter node: The node to visit.
        /// - Returns: Whether to visit or skip children of node.
        func visit<S: SyntaxProtocol>(node: S) -> SyntaxVisitorContinueKind {
            guard !usesProvidedError else { return .skipChildren }
            return .visitChildren
        }

        /// Decides whether to visit or skip children of provided node.
        ///
        /// Updates error usage status if uses in the throwing statement.
        ///
        /// - Parameter node: The node to visit.
        /// - Returns: To skip visiting children of node.
        override func visit(
            _ node: ThrowStmtSyntax
        ) -> SyntaxVisitorContinueKind {
            usesProvidedError =
                usesProvidedError
                || node.expression.trimmed.description == error.trimmed.text
            return .skipChildren
        }

        /// Decides whether to visit or skip children of provided node.
        ///
        /// If error usage is already detected, visiting is skipped.
        /// Otherwise children are visited.
        ///
        /// - Parameter node: The node to visit.
        /// - Returns: Whether to visit or skip children of node.
        override func visit(
            _ node: CodeBlockSyntax
        ) -> SyntaxVisitorContinueKind {
            return self.visit(node: node)
        }

        /// Decides whether to visit or skip children of provided node.
        ///
        /// If error usage is already detected, visiting is skipped.
        /// Otherwise children are visited.
        ///
        /// - Parameter node: The node to visit.
        /// - Returns: Whether to visit or skip children of node.
        override func visit(
            _ node: CodeBlockItemListSyntax
        ) -> SyntaxVisitorContinueKind {
            return self.visit(node: node)
        }

        /// Decides whether to visit or skip children of provided node.
        ///
        /// If error usage is already detected, visiting is skipped.
        /// Otherwise children are visited.
        ///
        /// - Parameter node: The node to visit.
        /// - Returns: Whether to visit or skip children of node.
        override func visit(
            _ node: CodeBlockItemSyntax
        ) -> SyntaxVisitorContinueKind {
            return self.visit(node: node)
        }
    }
}
