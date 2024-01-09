@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

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

    /// The `CodingKeys` map that generates keys.
    ///
    /// It generates keys for associated variables decoding/encoding.
    let codingKeys: CodingKeysMap

    /// Creates a new enum-case variable from provided data.
    ///
    /// - Parameters:
    ///   - decl: The declaration to read data from.
    ///   - context: The context in which to perform the macro expansion.
    ///   - builder: The builder action to use to update associated variables
    ///     registration data.
    ///
    /// - Returns: Created enum-case variable.
    init<Output: AssociatedVariable>(
        from decl: EnumCaseVariableDeclSyntax,
        in context: some MacroExpansionContext,
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
        var node = PropertyVariableTreeNode()
        var variables: [any AssociatedVariable] = []
        for member in decl.codableMembers() {
            let reg = Registration(
                decl: member, key: member.path, context: context
            )
            let registration = builder(reg)
            let path = registration.key
            let variable = registration.variable
            variables.append(variable)
            guard
                (variable.decode ?? true) || (variable.encode ?? true)
            else { continue }
            let name = variable.name
            let keys = codingKeys.add(keys: path, field: name, context: context)
            node.register(variable: variable, keyPath: keys)
        }
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
    ) -> SwitchCaseSyntax {
        let firstKey = location.values.first!
        let label = SwitchCaseLabelSyntax(
            caseItems: .init {
                for value in location.values {
                    let pattern = ExpressionPatternSyntax(expression: value)
                    SwitchCaseItemSyntax.init(pattern: pattern)
                }
            }
        )
        return SwitchCaseSyntax(label: .case(label)) {
            location.action("\(firstKey)")
            node.decoding(
                in: context,
                from: .coder(location.coder, keyType: codingKeys.type)
            )
            "\(location.expr(name, variables))"
        }
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
    ) -> SwitchCaseSyntax {
        let expr: ExprSyntax = location.expr(name, variables)
        let pattern = ExpressionPatternSyntax(expression: expr)
        let label = SwitchCaseLabelSyntax { .init(pattern: pattern) }
        let value = location.values.first!
        let contentCoder = location.coder
        return SwitchCaseSyntax(label: .case(label)) {
            location.action("\(value)")
            node.encoding(
                in: context, to: .coder(contentCoder, keyType: codingKeys.type)
            )
        }
    }
}
