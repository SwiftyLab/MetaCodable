@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// A `TypeVariable` that provides `Codable` conformance for enum declarations.
///
/// This type can be used for `enum` types for `Codable` conformance
/// implementation.
struct EnumVariable: TypeVariable, DeclaredVariable {
    /// The type name of this variable.
    ///
    /// The name is read from provided declaration.
    let name: TokenSyntax
    /// The switch expression generator.
    ///
    /// This is used to generate switch expression for implementation
    /// along with generating case values.
    let switcher: any EnumSwitcherVariable
    /// All the cases for this type.
    ///
    /// All the case variables along with their value generated.
    let cases: [(variable: any EnumCaseVariable, value: CaseValue)]
    /// The `CodingKeys` map containing keys
    /// and generated case names.
    let codingKeys: CodingKeysMap
    /// The where clause generator for generic type arguments.
    let constraintGenerator: ConstraintGenerator

    /// Creates a new variable from declaration and expansion context.
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
        let codingKeys = CodingKeysMap(typeName: "CodingKeys")
        let decodingKeys = CodingKeysMap(typeName: "DecodingKeys")
        self.init(
            from: decl, in: context,
            switcher: ExternallyTaggedEnumSwitcher(decodingKeys: decodingKeys),
            codingKeys: codingKeys
        ) { input in
            return input.checkForInternalTagging(
                encodeContainer: "typeContainer", identifier: "type",
                fallbackType: "String", codingKeys: codingKeys, context: context
            ) { registration in
                return registration.useHelperCoderIfExists()
            } switcherBuilder: { registration in
                return registration.checkForAdjacentTagging(
                    contentDecoder: "contentDecoder",
                    contentEncoder: "contentEncoder",
                    codingKeys: codingKeys, context: context
                )
            }
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
        let reg = PathRegistration(decl: decl, key: [], variable: switcher)
        self.switcher = switcherBuilder(reg).variable
        self.codingKeys = codingKeys
        self.constraintGenerator = .init(decl: decl)
        var cases: [(variable: any EnumCaseVariable, value: CaseValue)] = []
        for member in decl.codableMembers(input: self.codingKeys) {
            let variable = BasicEnumCaseVariable(
                from: member, in: context, builder: propertyBuilder
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
    func decoding(
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
                keyType: codingKeys.type, selfType: selfType
            )
            let generated = switcher.decoding(in: context, from: switcherLoc)
            let codingPath: ExprSyntax =
                switch generated.data {
                case .container(let container):
                    "\(container).codingPath"
                case .coder(let coder, _):
                    "\(coder).codingPath"
                }
            code = CodeBlockItemListSyntax {
                generated.code
                SwitchExprSyntax(subject: generated.expr) {
                    for (`case`, value) in cases where `case`.decode ?? true {
                        let location = EnumCaseCodingLocation(
                            data: generated.data, values: value.decodeExprs
                        )
                        `case`.decoding(in: context, from: location)
                    }
                    if generated.defaultCase {
                        SwitchCaseSyntax(label: .default(.init())) {
                            """
                            let context = DecodingError.Context(
                                codingPath: \(codingPath),
                                debugDescription: "Couldn't match any cases."
                            )
                            """
                            "throw DecodingError.typeMismatch(\(selfType), context)"
                        }
                    }
                }
            }
        } else {
            code = CodeBlockItemListSyntax {
                """
                let context = DecodingError.Context(
                    codingPath: \(location.method.arg).codingPath,
                    debugDescription: "No decodable case present."
                )
                """
                "throw DecodingError.typeMismatch(\(selfType), context)"
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
    func encoding(
        in context: some MacroExpansionContext,
        to location: TypeCodingLocation
    ) -> TypeGenerated? {
        guard
            let conformance = location.conformance
        else { return nil }

        let selfType: ExprSyntax = "\(name).self"
        let code: CodeBlockItemListSyntax
        if cases.contains(where: { $0.variable.encode ?? true }) {
            let switcherLocation = EnumSwitcherLocation(
                coder: location.method.arg, container: "container",
                keyType: codingKeys.type, selfType: selfType
            )
            let generated = switcher.encoding(in: context, to: switcherLocation)
            let allEncodable = cases.allSatisfy { $0.variable.encode ?? true }
            code = CodeBlockItemListSyntax {
                generated.code
                SwitchExprSyntax(subject: generated.expr) {
                    for (`case`, value) in cases where `case`.encode ?? true {
                        let location = EnumCaseCodingLocation(
                            data: generated.data, values: value.encodeExprs
                        )
                        `case`.encoding(in: context, to: location)
                    }
                    if generated.defaultCase && !allEncodable {
                        SwitchCaseSyntax(label: .default(.init())) { "break" }
                    }
                }
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
    func codingKeys(
        confirmingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) -> MemberBlockItemListSyntax {
        guard
            !self.protocols(
                named: TypeCodingLocation.Method.decode.protocol,
                TypeCodingLocation.Method.encode.protocol,
                in: protocols
            ).isEmpty,
            let decl = codingKeys.decl(in: context)
        else { return [] }
        return MemberBlockItemListSyntax {
            decl
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
