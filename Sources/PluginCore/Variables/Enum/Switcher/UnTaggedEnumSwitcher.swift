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
        let selfType = location.selfType
        return CodeBlockItemListSyntax {
            """
            let context = DecodingError.Context(
                codingPath: \(location.coder).codingPath,
                debugDescription: "Couldn't decode any case."
            )
            """
            "let \(error) =  DecodingError.typeMismatch(\(selfType), context)"
            decodingSyntax(for: &cases, from: location, in: context)
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
    /// - Returns: The generated decoding syntax.
    private func decodingSyntax(
        for cases: inout [EnumVariable.Case],
        from location: EnumSwitcherLocation,
        in context: some MacroExpansionContext
    ) -> CodeBlockItemListSyntax {
        guard !cases.isEmpty else { return "throw \(error)" }
        let `case` = cases.removeFirst()
        let coder = location.coder
        let cLocation = EnumCaseCodingLocation(coder: coder, values: [])
        let generated = `case`.variable.decoding(in: context, from: cLocation)
        let catchClauses = CatchClauseListSyntax {
            CatchClauseSyntax {
                decodingSyntax(for: &cases, from: location, in: context)
            }
        }
        return CodeBlockItemListSyntax {
            let `case` = `case`.variable
            generated.code.syntax
            DoStmtSyntax(catchClauses: catchClauses) {
                generated.code.conditionalSyntax
                location.codeExpr(`case`.name, `case`.variables)
                "return"
            }
        }
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
