import SwiftOperators
import SwiftSyntax
import SwiftSyntaxMacros

/// A default enum-case variable value with basic functionalities.
///
/// The `BasicEnumCaseVariable` registers associated variables
/// on `PropertyVariableTreeNode` and generates implementations
/// based on registrations.
struct BasicEnumCaseVariable: EnumCaseVariable {
    /// The name of this variable.
    ///
    /// The name is provided during
    /// initialization of this variable.
    let name: TokenSyntax

    /// Whether the variable is to
    /// be decoded.
    ///
    /// By default set as `nil`,
    /// unless value passed explicitly
    /// during initialization.
    let decode: Bool?
    /// Whether the variable is to
    /// be encoded.
    ///
    /// By default set as `nil`,
    /// unless value passed explicitly
    /// during initialization.
    let encode: Bool?

    /// The node at which variables are registered.
    ///
    /// Associated variables are registered with the path at this node
    /// during initialization. This node is used to generate associated
    /// variables decoding/encoding implementations.
    let node: PropertyVariableTreeNode
    /// All the associated variables available for this case.
    ///
    /// While only decodable/encodable variables are registered on `node`,
    /// this list maintains all variables in the order of their appearance.
    let variables: [any AssociatedVariable]
    /// The associated attributes decoding and encoding data.
    ///
    /// Only variables registered with this data will be decoded/encoded
    /// from the `node`.
    let data: PropertyVariableTreeNode.CodingData

    /// The `CodingKeys` map that generates keys.
    ///
    /// It generates keys for associated variables decoding/encoding.
    let codingKeys: CodingKeysMap

    /// Creates a new enum-case variable from provided data.
    ///
    /// - Parameters:
    ///   - decl: The declaration to read data from.
    ///   - context: The context in which to perform the macro expansion.
    ///   - node: The node at which variables are registered.
    ///   - builder: The builder action to use to update associated variables
    ///     registration data.
    ///
    /// - Returns: Created enum-case variable.
    init<Switcher: EnumSwitcherVariable, Output: AssociatedVariable>(
        from decl: EnumCaseVariableDeclSyntax,
        in context: some MacroExpansionContext,
        switcher: Switcher,
        builder: (
            _ input: PathRegistration<
                AssociatedDeclSyntax, BasicAssociatedVariable
            >
        ) -> PathRegistration<AssociatedDeclSyntax, Output>
    ) {
        self.name = decl.element.name
        self.decode = nil
        self.encode = nil
        self.codingKeys = decl.codingKeys
        var node = switcher.node(for: decl, in: context)
        var data = PropertyVariableTreeNode.CodingData()
        var variables: [any AssociatedVariable] = []
        for member in decl.codableMembers() {
            let iReg = Registration(
                decl: member, key: member.path, context: context
            )
            let newVar = switcher.transform(variable: iReg.variable)
            let reg = iReg.updating(with: newVar)
            let registration = builder(reg)
            let path = registration.key
            let variable = registration.variable
            variables.append(variable)
            guard
                (variable.decode ?? true) || (variable.encode ?? true)
            else { continue }
            let name = variable.name
            let keys = codingKeys.add(keys: path, field: name, context: context)
            data.register(variable: variable, keyPath: keys)
            node.register(variable: variable, keyPath: keys)
        }
        self.data = data
        self.node = node
        self.variables = variables
    }

    /// Provides the syntax for decoding at the provided location.
    ///
    /// Depending on the tagging of enum and enum-case value data
    /// the decoding syntax is generated.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location.
    ///
    /// - Returns: The generated decoding syntax.
    func decoding(
        in context: some MacroExpansionContext,
        from location: EnumCaseCodingLocation
    ) -> EnumCaseGenerated {
        let label = SwitchCaseLabelSyntax(
            caseItems: .init {
                for value in location.values {
                    let expr =
                        OperatorTable.standardOperators
                        .foldAll(value) { _ in }.as(ExprSyntax.self) ?? value
                    let pattern =
                        if let asExpr = expr.as(AsExprSyntax.self) {
                            ExpressionPatternSyntax(
                                expression: asExpr.expression.trimmed
                            )
                        } else {
                            ExpressionPatternSyntax(expression: expr)
                        }
                    SwitchCaseItemSyntax(pattern: pattern)
                }
            }
        )
        let generated = node.decoding(
            with: data, in: context,
            from: .withCoder(location.coder, keyType: codingKeys.type)
        )
        let newSyntax = CodeBlockItemListSyntax {
            for variable in variables where variable.decode ?? true {
                "let \(variable.name): \(variable.type)"
            }
            generated.containerSyntax
        }
        let code = PropertyVariableTreeNode.Generated(
            containerSyntax: newSyntax, codingSyntax: generated.codingSyntax,
            conditionalSyntax: generated.conditionalSyntax
        )
        return .init(label: label, code: code)
    }

    /// Provides the syntax for encoding at the provided location.
    ///
    /// Depending on the tagging of enum and enum-case value data
    /// the encoding syntax is generated.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location.
    ///
    /// - Returns: The generated encoding syntax.
    func encoding(
        in context: some MacroExpansionContext,
        to location: EnumCaseCodingLocation
    ) -> EnumCaseGenerated {
        let generated = node.encoding(
            with: data, in: context,
            to: .withCoder(location.coder, keyType: codingKeys.type)
        )
        let pattern = IdentifierPatternSyntax(identifier: "_")
        let item = SwitchCaseItemSyntax(pattern: pattern)
        return .init(label: .init(caseItems: [item]), code: generated)
    }
}
