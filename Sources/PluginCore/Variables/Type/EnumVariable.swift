import SwiftSyntax
import SwiftSyntaxMacros

/// A `TypeVariable` that provides `Codable` conformance for enum declarations.
///
/// This type can be used for `enum` types for `Codable` conformance
/// implementation.
package struct EnumVariable: TypeVariable, DeclaredVariable {
    /// Represents enum-case decoding/encoding expression generation callback.
    package typealias CaseCode = (
        _ name: TokenSyntax, _ variables: [any AssociatedVariable]
    ) -> ExprSyntax
    /// Represents a enum-case and its associated decoding/encoding value.
    typealias Case = (variable: any EnumCaseVariable, value: CaseValue)
    /// The type name of this variable.
    ///
    /// The name is read from provided declaration.
    let name: TokenSyntax
    /// The expression used in switch header for encoding implementation.
    ///
    /// Represents the value expression compared with switch.
    let encodeSwitchExpr: ExprSyntax
    /// The enum-case decoding expression generation
    /// callback.
    ///
    /// The enum-case passes case name and associated variables
    /// to this callback to generate decoding expression.
    let caseDecodeExpr: CaseCode
    /// The enum-case encoding expression generation
    /// callback.
    ///
    /// The enum-case passes case name and associated variables
    /// to this callback to generate encoding expression.
    let caseEncodeExpr: CaseCode
    /// Whether to always add default case to decoding/encoding
    /// switch.
    ///
    /// Can be set to `true` if used in case of extensible cases,
    /// i.e. `protocol`s.
    let forceDefault: Bool
    /// The switch expression generator.
    ///
    /// This is used to generate switch expression for implementation
    /// along with generating case values.
    let switcher: any EnumSwitcherVariable
    /// All the cases for this type.
    ///
    /// All the case variables along with their value generated.
    let cases: [Case]
    /// The `CodingKeys` map containing keys
    /// and generated case names.
    let codingKeys: CodingKeysMap
    /// The where clause generator for generic type arguments.
    let constraintGenerator: ConstraintGenerator

    /// Creates a new variable from declaration and expansion context.
    ///
    /// Callback for enum-case decoding/encoding is used.
    ///
    /// Uses default builder actions that provides following features:
    /// * `CodingKeys` case style customization.
    /// * Initialized variables decoding/encoding ignore customization.
    /// * `CodingKeys` path customization for individual variables.
    /// * Multiple `CodingKeys` alias customization for individual variables.
    /// * Helper expression with custom decoding/encoding customization.
    /// * Individual cases and variables decoding/encoding ignore customization.
    ///
    /// - Parameters:
    ///   - decl: The declaration to read from.
    ///   - context: The context in which the macro expansion performed.
    ///
    /// - Returns: Created enum variable.
    init(from decl: EnumDeclSyntax, in context: some MacroExpansionContext) {
        let decodingKeys = CodingKeysMap(typeName: "DecodingKeys")
        let codingKeys = CodingKeysMap(typeName: "CodingKeys")
        let caseDecodeExpr: CaseCode = { name, variables in
            let args = Self.decodingArgs(representing: variables)
            return if !args.isEmpty {
                "self = .\(name)(\(args))"
            } else {
                "self = .\(name)"
            }
        }
        let caseEncodeExpr: CaseCode = { name, variables in
            let args = Self.encodingArgs(representing: variables)
            let callee: ExprSyntax = ".\(name)"
            let fExpr =
                if !args.isEmpty {
                    FunctionCallExprSyntax(callee: callee) { args }
                } else {
                    FunctionCallExprSyntax(calledExpression: callee) {}
                }
            return ExprSyntax(fExpr)
        }
        self.init(
            from: decl, in: context,
            caseDecodeExpr: caseDecodeExpr, caseEncodeExpr: caseEncodeExpr,
            encodeSwitchExpr: "self", forceDefault: false,
            switcher: Self.externallyTaggedSwitcher(decodingKeys: decodingKeys),
            codingKeys: codingKeys
        )
    }

    /// Creates a new enum variable from provided data.
    ///
    /// Uses default builder actions that provides following features:
    /// * `CodingKeys` case style customization.
    /// * Initialized variables decoding/encoding ignore customization.
    /// * `CodingKeys` path customization for individual variables.
    /// * Multiple `CodingKeys` alias customization for individual variables.
    /// * Helper expression with custom decoding/encoding customization.
    /// * Individual cases and variables decoding/encoding ignore customization.
    ///
    /// - Parameters:
    ///   - decl: The declaration to read data from.
    ///   - context: The context in which to perform the macro expansion.
    ///   - caseDecodeExpr: The enum-case decoding expression generation
    ///     callback.
    ///   - caseEncodeExpr: The enum-case encoding expression generation
    ///     callback.
    ///   - encodeSwitchExpr: The context in which to perform the macro expansion.
    ///   - forceDefault: The context in which to perform the macro expansion.
    ///   - switcher: The switch expression generator.
    ///   - codingKeys: The map where `CodingKeys` maintained.
    ///
    /// - Returns: Created enum variable.
    package init(
        from decl: EnumDeclSyntax, in context: some MacroExpansionContext,
        caseDecodeExpr: @escaping CaseCode, caseEncodeExpr: @escaping CaseCode,
        encodeSwitchExpr: ExprSyntax, forceDefault: Bool,
        switcher: ExternallyTaggedEnumSwitcher, codingKeys: CodingKeysMap
    ) {
        self.init(
            from: decl, in: context,
            caseDecodeExpr: caseDecodeExpr, caseEncodeExpr: caseEncodeExpr,
            encodeSwitchExpr: encodeSwitchExpr, forceDefault: forceDefault,
            switcher: switcher, codingKeys: codingKeys
        ) { input in
            return input.checkForInternalTagging(
                encodeContainer: "typeContainer", identifier: "type",
                fallbackType: "String", codingKeys: codingKeys, context: context
            ) { registration in
                return registration.useHelperCoderIfExists()
            } switcherBuilder: { registration in
                return registration.checkForAdjacentTagging(
                    contentDecoder: Self.contentDecoder,
                    contentEncoder: Self.contentEncoder,
                    codingKeys: codingKeys, context: context
                )
            }.checkIfUnTagged(in: context)
        } caseBuilder: { input in
            return input.checkForAlternateValue().checkCodingIgnored()
        } propertyBuilder: { input in
            let parent = input.decl.parent
            return input.transformKeysAccordingToStrategy(attachedTo: parent)
                .checkInitializedCodingIgnored(attachedAt: parent)
                .registerKeyPath(
                    provider: CodedAt(from: input.decl)
                        ?? CodedIn(from: input.decl) ?? CodedIn()
                )
                .useHelperCoderIfExists()
                .checkForAlternateKeyValues(addTo: codingKeys, context: context)
                .addDefaultValueIfExists()
                .checkCodingIgnored()
        }
    }

    /// Creates a new enum variable from provided data.
    ///
    /// - Parameters:
    ///   - decl: The declaration to read data from.
    ///   - context: The context in which to perform the macro expansion.
    ///   - caseDecodeExpr: The enum-case decoding expression generation
    ///     callback.
    ///   - caseEncodeExpr: The enum-case encoding expression generation
    ///     callback.
    ///   - encodeSwitchExpr: The context in which to perform the macro expansion.
    ///   - forceDefault: The context in which to perform the macro expansion.
    ///   - switcher: The switch expression generator.
    ///   - codingKeys: The map where `CodingKeys` maintained.
    ///   - switcherBuilder: The builder action to use to update switch case
    ///     variables registration data.
    ///   - caseBuilder: The builder action to use to update case variables
    ///     registration data.
    ///   - propertyBuilder: The builder action to use to update associated
    ///     variables registration data.
    ///
    /// - Returns: Created enum variable.
    init<
        Case: EnumCaseVariable, InSwitcher: EnumSwitcherVariable,
        OutSwitcher: EnumSwitcherVariable, Var: AssociatedVariable
    >(
        from decl: EnumDeclSyntax, in context: some MacroExpansionContext,
        caseDecodeExpr: @escaping CaseCode, caseEncodeExpr: @escaping CaseCode,
        encodeSwitchExpr: ExprSyntax, forceDefault: Bool,
        switcher: InSwitcher, codingKeys: CodingKeysMap,
        switcherBuilder: (
            _ input: PathRegistration<EnumDeclSyntax, InSwitcher>
        ) -> PathRegistration<EnumDeclSyntax, OutSwitcher>,
        caseBuilder: (
            _ input: ExprRegistration<
                EnumCaseVariableDeclSyntax, BasicEnumCaseVariable
            >
        ) -> ExprRegistration<EnumCaseVariableDeclSyntax, Case>,
        propertyBuilder: (
            _ input: PathRegistration<
                AssociatedDeclSyntax, BasicAssociatedVariable
            >
        ) -> PathRegistration<AssociatedDeclSyntax, Var>
    ) {
        self.name = decl.name.trimmed
        self.caseDecodeExpr = caseDecodeExpr
        self.caseEncodeExpr = caseEncodeExpr
        self.encodeSwitchExpr = encodeSwitchExpr
        self.forceDefault = forceDefault
        let reg = PathRegistration(decl: decl, key: [], variable: switcher)
        let switcher = switcherBuilder(reg).variable
        self.switcher = switcher
        self.codingKeys = codingKeys
        self.constraintGenerator = .init(decl: decl)
        var cases: [(variable: any EnumCaseVariable, value: CaseValue)] = []
        for member in decl.codableMembers(input: self.codingKeys) {
            let variable = BasicEnumCaseVariable(
                from: member, in: context, switcher: switcher,
                builder: propertyBuilder
            )
            let reg = ExprRegistration(
                decl: member, key: [], variable: variable
            )
            let registration = caseBuilder(reg)
            let `case` = registration.variable
            guard (`case`.decode ?? true) || (`case`.encode ?? true)
            else { continue }
            let value = self.switcher.keyExpression(
                for: `case`, values: registration.key,
                codingKeys: self.codingKeys, context: context
            )
            cases.append((variable: `case`, value: value))
        }
        self.cases = cases
    }

    /// Provides the syntax for decoding at the provided location.
    ///
    /// If conformance type provided is `nil` no expansion performed.
    /// Otherwise, cases registered are decoded based on registered data
    /// and switch expression data.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location.
    ///
    /// - Returns: The generated decoding syntax.
    package func decoding(
        in context: some MacroExpansionContext,
        from location: TypeCodingLocation
    ) -> TypeGenerated? {
        guard
            let conformance = location.conformance
        else { return nil }

        let selfType: ExprSyntax = "\(name).self"
        let code: CodeBlockItemListSyntax
        if cases.contains(where: { $0.variable.decode ?? true }) {
            let switcherLoc = EnumSwitcherLocation(
                coder: location.method.arg, container: "container",
                keyType: codingKeys.type, selfType: selfType, selfValue: "_",
                cases: cases, codeExpr: caseDecodeExpr,
                hasDefaultCase: forceDefault
            )
            code = CodeBlockItemListSyntax {
                switcher.decoding(in: context, from: switcherLoc)
            }
        } else {
            code = CodeBlockItemListSyntax {
                """
                let context = DecodingError.Context(
                    codingPath: \(location.method.arg).codingPath,
                    debugDescription: "No decodable case present."
                )
                """
                "throw DecodingError.typeMismatch(Self.self, context)"
            }
        }
        return .init(
            code: code, modifiers: [],
            whereClause: constraintGenerator.decodingClause(
                withVariables: cases.lazy
                    .filter { $0.variable.decode ?? true }
                    .flatMap(\.variable.variables)
                    .filter { $0.decode ?? true },
                conformingTo: conformance
            ),
            inheritanceClause: .init { .init(type: conformance) }
        )
    }

    /// Provides the syntax for encoding at the provided location.
    ///
    /// If conformance type provided is `nil` no expansion performed.
    /// Otherwise, cases registered are encoded based on registered data
    /// and switch expression data.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location.
    ///
    /// - Returns: The generated encoding syntax.
    package func encoding(
        in context: some MacroExpansionContext,
        to location: TypeCodingLocation
    ) -> TypeGenerated? {
        guard
            let conformance = location.conformance
        else { return nil }

        let selfType: ExprSyntax = "\(name).self"
        let expr = encodeSwitchExpr
        let code: CodeBlockItemListSyntax
        if cases.contains(where: { $0.variable.encode ?? true }) {
            let switcherLocation = EnumSwitcherLocation(
                coder: location.method.arg, container: "container",
                keyType: codingKeys.type, selfType: selfType, selfValue: expr,
                cases: cases, codeExpr: caseEncodeExpr,
                hasDefaultCase: forceDefault
            )
            code = CodeBlockItemListSyntax {
                switcher.encoding(in: context, to: switcherLocation)
            }
        } else {
            code = ""
        }
        return .init(
            code: code, modifiers: [],
            whereClause: constraintGenerator.encodingClause(
                withVariables: cases.lazy
                    .filter { $0.variable.encode ?? true }
                    .flatMap(\.variable.variables)
                    .filter { $0.encode ?? true },
                conformingTo: conformance
            ),
            inheritanceClause: .init { .init(type: conformance) }
        )
    }

    /// Provides the syntax for `CodingKeys` declarations.
    ///
    /// Single `CodingKeys` enum generated using the `codingKeys`
    /// provided during initialization along with optional `CodingKeys`
    /// enums generated based on switch expression syntax.
    ///
    /// - Parameters:
    ///   - protocols: The protocols for which conformance generated.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The `CodingKeys` declarations.
    package func codingKeys(
        confirmingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) -> MemberBlockItemListSyntax {
        guard
            !self.protocols(
                named: TypeCodingLocation.Method.decode().protocol,
                TypeCodingLocation.Method.encode.protocol,
                in: protocols
            ).isEmpty
        else { return [] }
        return MemberBlockItemListSyntax {
            if let decl = codingKeys.decl(in: context) { decl }
            switcher.codingKeys(in: context)
        }
    }
}

extension EnumVariable {
    /// A type representing enum-case value.
    ///
    /// The value can either be `CodingKey` based or raw value.
    enum CaseValue {
        /// Represents value is a set of raw values.
        ///
        /// The expression represents a set of raw value expressions.
        ///
        /// - Parameter exprs: The raw expressions.
        case raw(_ exprs: [ExprSyntax])
        /// Represents value is a set of `CodingKey`s.
        ///
        /// The expressions for the keys are used as value expressions.
        ///
        /// - Parameter keys: The `CodingKey` values.
        case key(_ keys: [CodingKeysMap.Key])
        /// Represents value is a set of `CodingKey`s.
        ///
        /// The expressions for the keys are used as value expressions.
        /// The value expressions are different for both decoding/encoding.
        ///
        /// - Parameters:
        ///   - dKeys: The decoding `CodingKey` values.
        ///   - eKeys: The encoding `CodingKey` values.
        case keys(_ dKeys: [CodingKeysMap.Key], _ eKeys: [CodingKeysMap.Key])

        /// The expressions for decoding.
        ///
        /// Represents value expressions for case when decoding.
        var decodeExprs: [ExprSyntax] {
            switch self {
            case .raw(let exprs):
                return exprs
            case .key(let keys):
                return keys.map(\.expr)
            case .keys(let decodeKeys, _):
                return decodeKeys.map(\.expr)
            }
        }

        /// The expressions for encoding.
        ///
        /// Represents value expressions for case when encoding.
        var encodeExprs: [ExprSyntax] {
            switch self {
            case .raw(let exprs):
                return exprs
            case .key(let keys):
                return keys.map(\.expr)
            case .keys(_, let encodeKeys):
                return encodeKeys.map(\.expr)
            }
        }
    }
}

package extension EnumVariable {
    /// Generates labeled expression for decoding representing provided
    /// variables.
    ///
    /// Uses variable name as expression if decodable, otherwise variable value
    /// is used as expression.
    ///
    /// - Parameter variables: The associated variables to generate for.
    /// - Returns: The labeled expressions.
    static func decodingArgs(
        representing variables: [any AssociatedVariable]
    ) -> LabeledExprListSyntax {
        return LabeledExprListSyntax {
            for variable in variables {
                let decode = (variable.decode ?? true)
                let name = variable.name
                let value = variable.value
                let expr: ExprSyntax = decode ? "\(name)" : value!
                let label = variable.label?.text
                LabeledExprSyntax(label: label, expression: expr)
            }
        }
    }

    /// Generates labeled expression for encoding representing provided
    /// variables.
    ///
    /// Uses variable name as variable declaration expression if encodable,
    /// otherwise `_` is used as expression.
    ///
    /// - Parameter variables: The associated variables to generate for.
    /// - Returns: The labeled expressions.
    static func encodingArgs(
        representing variables: [any AssociatedVariable]
    ) -> LabeledExprListSyntax {
        return LabeledExprListSyntax {
            for variable in variables {
                let encode = (variable.encode ?? true)
                let label = variable.label?.text
                let expr: ExprSyntaxProtocol =
                    if encode {
                        PatternExprSyntax(
                            pattern: ValueBindingPatternSyntax(
                                bindingSpecifier: .keyword(
                                    .let, trailingTrivia: .space),
                                pattern: IdentifierPatternSyntax(
                                    identifier: variable.name
                                )
                            )
                        )
                    } else {
                        "_" as ExprSyntax
                    }
                LabeledExprSyntax(label: label, expression: expr)
            }
        }
    }

    /// Create new enum switch variable with provided `CodingKey` map.
    ///
    /// Create new variable that generates switch expression for externally
    /// tagged enums.
    ///
    /// - Parameter decodingKeys: The map when decoding keys stored.
    /// - Returns: The created enum switch variable.
    static func externallyTaggedSwitcher(
        decodingKeys: CodingKeysMap
    ) -> ExternallyTaggedEnumSwitcher {
        return .init(
            decodingKeys: decodingKeys,
            contentDecoder: contentDecoder, contentEncoder: contentEncoder
        )
    }
}

fileprivate extension EnumVariable {
    /// The default name for content root decoder.
    ///
    /// This decoder is passed to each case for decoding.
    static var contentDecoder: TokenSyntax { "contentDecoder" }
    /// The default name for content root encoder.
    ///
    /// This encoder is passed to each case for encoding.
    static var contentEncoder: TokenSyntax { "contentEncoder" }
}
