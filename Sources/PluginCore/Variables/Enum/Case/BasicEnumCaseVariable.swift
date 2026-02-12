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

    /// The node at which variables are registered for decoding.
    ///
    /// Associated variables are registered with the path at this node
    /// during initialization. This node is used to generate associated
    /// variables decoding implementations.
    let decodingNode: PropertyVariableTreeNode

    /// The node at which variables are registered for encoding.
    ///
    /// Associated variables are registered with the path at this node
    /// during initialization. This node is used to generate associated
    /// variables encoding implementations.
    let encodingNode: PropertyVariableTreeNode

    /// All the associated variables available for this case.
    ///
    /// While only decodable/encodable variables are registered on nodes,
    /// this list maintains all variables in the order of their appearance.
    let variables: [any AssociatedVariable]

    /// The associated attributes decoding data.
    ///
    /// Only variables registered with this data will be decoded
    /// from the decoding node.
    let decodingData: PropertyVariableTreeNode.CodingData

    /// The associated attributes encoding data.
    ///
    /// Only variables registered with this data will be encoded
    /// from the encoding node.
    let encodingData: PropertyVariableTreeNode.CodingData

    /// The `CodingKeys` map that generates keys.
    ///
    /// It generates keys for associated variables decoding/encoding.
    let codingKeys: CodingKeysMap

    /// Creates a new enum-case variable from provided data.
    ///
    /// - Parameters:
    ///   - decl: The declaration to read data from.
    ///   - context: The context in which to perform the macro expansion.
    ///   - switcher: The switcher variable for handling enum case variations.
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

        var decodingNode = switcher.node(for: decl, in: context)
        var encodingNode = switcher.node(for: decl, in: context)
        var decodingData = PropertyVariableTreeNode.CodingData()
        var encodingData = PropertyVariableTreeNode.CodingData()
        var variables: [any AssociatedVariable] = []

        for member in decl.codableMembers() {
            let key = PathKey(decoding: member.path, encoding: member.path)
            let iReg = Registration(
                decl: member, key: key, context: context
            )
            let newVar = switcher.transform(variable: iReg.variable)
            let reg = iReg.updating(with: newVar)
            let registration = builder(reg)
            let path = registration.key
            let variable = registration.variable
            variables.append(variable)

            let name = variable.name

            // Register in the appropriate node based on decode/encode flags
            if variable.decode ?? true {
                let decodingKeys = codingKeys.add(
                    keys: path.decoding, field: name, context: context
                )
                decodingData.register(variable: variable, keyPath: decodingKeys)
                decodingNode.register(variable: variable, keyPath: decodingKeys)
            }

            if variable.encode ?? true {
                let encodingKeys = codingKeys.add(
                    keys: path.encoding, field: name, context: context
                )
                encodingData.register(variable: variable, keyPath: encodingKeys)
                encodingNode.register(variable: variable, keyPath: encodingKeys)
            }
        }

        self.decodingData = decodingData
        self.encodingData = encodingData
        self.decodingNode = decodingNode
        self.encodingNode = encodingNode
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
        let generated = decodingNode.decoding(
            with: decodingData, in: context,
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
        let generated = encodingNode.encoding(
            with: encodingData, in: context,
            to: .withCoder(location.coder, keyType: codingKeys.type)
        )
        let pattern = IdentifierPatternSyntax(identifier: "_")
        let item = SwitchCaseItemSyntax(pattern: pattern)
        return .init(label: .init(caseItems: [item]), code: generated)
    }
}
