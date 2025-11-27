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
                    FunctionCallExprSyntax(calledExpression: callee) { args }
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
            codingKeys: codingKeys,
            forceInternalTaggingDecodingReturn: true
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
    ///   - caseDecodeExpr: The enum-case decoding expression generation callback.
    ///   - caseEncodeExpr: The enum-case encoding expression generation callback.
    ///   - encodeSwitchExpr: The expression used in switch header for encoding implementation.
    ///   - forceDefault: Whether to always add default case to decoding/encoding switch.
    ///   - switcher: The switch expression generator for externally tagged enums.
    ///   - codingKeys: The map where `CodingKeys` are maintained.
    ///   - forceInternalTaggingDecodingReturn: Whether to force explicit `return` statements
    ///     in generated decoding switch cases when internal tagging is detected. When `true`,
    ///     each internally tagged enum case includes a `return` after assignment for early exit.
    ///
    /// - Returns: Created enum variable.
    package init(
        from decl: EnumDeclSyntax, in context: some MacroExpansionContext,
        caseDecodeExpr: @escaping CaseCode, caseEncodeExpr: @escaping CaseCode,
        encodeSwitchExpr: ExprSyntax, forceDefault: Bool,
        switcher: ExternallyTaggedEnumSwitcher, codingKeys: CodingKeysMap,
        forceInternalTaggingDecodingReturn: Bool
    ) {
        self.init(
            from: decl, in: context,
            caseDecodeExpr: caseDecodeExpr, caseEncodeExpr: caseEncodeExpr,
            encodeSwitchExpr: encodeSwitchExpr, forceDefault: forceDefault,
            switcher: switcher, codingKeys: codingKeys
        ) { input in
            input.checkForInternalTagging(
                container: Self.typeContainer, identifier: Self.type,
                codingKeys: codingKeys,
                forceDecodingReturn: forceInternalTaggingDecodingReturn,
                context: context
            ) { registration in
                registration.useHelperCoderIfExists()
            } switcherBuilder: { registration in
                registration.checkForAdjacentTagging(
                    contentDecoder: Self.contentDecoder,
                    contentEncoder: Self.contentEncoder,
                    codingKeys: codingKeys, context: context
                )
            }.checkIfUnTagged(in: context)
        } caseBuilder: { input in
            input.checkForAlternateValue().checkCodingIgnored()
        } propertyBuilder: { input in
            let parent = input.decl.parent
            return input.transformKeysAccordingToStrategy(attachedTo: parent)
                .checkInitializedCodingIgnored(attachedAt: parent)
                .registerKeyPath(
                    provider: CodedAt(from: input.decl)
                        ?? CodedIn(from: input.decl) ?? CodedIn(),
                    forDecoding: DecodedAt(from: input.decl),
                    forEncoding: EncodedAt(from: input.decl)
                )
                .detectCommonStrategies(from: decl)
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
        let key = PathKey(decoding: [], encoding: [])
        let reg = PathRegistration(decl: decl, key: key, variable: switcher)
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
        guard let conformance = location.conformance else { return nil }
        let selfType: ExprSyntax = "\(name).self"
        let code: CodeBlockItemListSyntax
        if cases.contains(where: { $0.variable.decode ?? true }) {
            let switcherLoc = EnumSwitcherLocation(
                coder: location.method.arg, container: Self.container,
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
        guard let conformance = location.conformance else { return nil }
        let selfType: ExprSyntax = "\(name).self"
        let expr = encodeSwitchExpr
        let code: CodeBlockItemListSyntax
        if cases.contains(where: { $0.variable.encode ?? true }) {
            let switcherLocation = EnumSwitcherLocation(
                coder: location.method.arg, container: Self.container,
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
        case raw([Expr])
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
        var decodeExprs: [Expr] {
            switch self {
            case .raw(let exprs):
                return exprs
            case .key(let keys):
                return keys.map { Expr(syntax: $0.expr, type: .string) }
            case .keys(let decodeKeys, _):
                return decodeKeys.map { Expr(syntax: $0.expr, type: .string) }
            }
        }

        /// The expressions for encoding.
        ///
        /// Represents value expressions for case when encoding.
        var encodeExprs: [Expr] {
            switch self {
            case .raw(let exprs):
                return exprs
            case .key(let keys):
                return keys.map { Expr(syntax: $0.expr, type: .string) }
            case .keys(_, let encodeKeys):
                return encodeKeys.map { Expr(syntax: $0.expr, type: .string) }
            }
        }

        /// Represents the type of an enum case value expression.
        ///
        /// Used to categorize and handle different types of literal values that can be
        /// used as enum case identifiers. Supports built-in Swift types and custom types.
        enum TypeOf: Hashable {
            /// Boolean literal type.
            case bool
            /// Integer literal type.
            case int
            /// Double/floating-point literal type.
            case double
            /// String literal type.
            case string
            /// Custom or unrecognized type with explicit type syntax.
            case unknown(TypeSyntax)

            /// Returns all possible types for enum case values.
            ///
            /// If an inherited type is provided, returns only that type wrapped as `.unknown`.
            /// Otherwise, returns all built-in supported types for automatic type inference.
            ///
            /// - Parameter inheritedType: Optional explicit type to use instead of inference.
            /// - Returns: Array of type cases to consider for enum case values.
            static func all(inheritedType: TypeSyntax?) -> [Self] {
                if let inheritedType = inheritedType {
                    return [.unknown(inheritedType)]
                }
                return [.bool, .int, .double, .string]
            }

            /// Generates a name suffix for variable naming based on the type.
            ///
            /// Used to create unique variable names when multiple types are being processed.
            /// Returns the capitalized type name for built-in types, or empty string for
            /// custom types to avoid naming conflicts.
            ///
            /// - Returns: Token syntax for the type-based name suffix.
            func nameSuffix() -> TokenSyntax {
                switch self {
                case .bool:
                    "Bool"
                case .int:
                    "Int"
                case .double:
                    "Double"
                case .string:
                    "String"
                case .unknown:
                    ""
                }
            }

            /// Generates the type syntax for this type case.
            ///
            /// Creates the appropriate Swift type syntax for use in generated code.
            /// Can optionally wrap the type in an optional type syntax.
            ///
            /// - Parameter optional: Whether to wrap the type in optional syntax.
            /// - Returns: The generated type syntax, optionally wrapped.
            func syntax(optional: Bool) -> TypeSyntax {
                let type: TypeSyntax =
                    switch self {
                    case .bool:
                        "Bool"
                    case .int:
                        "Int"
                    case .double:
                        "Double"
                    case .string:
                        "String"
                    case .unknown(let type):
                        type
                    }
                return optional
                    ? TypeSyntax(OptionalTypeSyntax(wrappedType: type)) : type
            }

            /// Compares two TypeOf instances for equality.
            ///
            /// Built-in types are compared by case, while unknown types are compared
            /// by their trimmed type syntax description to handle formatting differences.
            ///
            /// - Parameters:
            ///   - lhs: The left-hand side TypeOf instance.
            ///   - rhs: The right-hand side TypeOf instance.
            /// - Returns: True if the types are equivalent, false otherwise.
            static func == (lhs: TypeOf, rhs: TypeOf) -> Bool {
                switch (lhs, rhs) {
                case (.bool, .bool), (.int, .int), (.double, .double),
                    (.string, .string):
                    return true
                case let (.unknown(lhsType), .unknown(rhsType)):
                    return lhsType.trimmedDescription
                        == rhsType.trimmedDescription
                default:
                    return false
                }
            }
        }

        /// Represents an expression with its associated type information.
        ///
        /// Combines a Swift expression syntax with type metadata to enable proper
        /// type handling and code generation for enum case values.
        struct Expr {
            /// The Swift expression syntax for the enum case value.
            let syntax: ExprSyntax
            /// The inferred or specified type of the expression.
            let type: TypeOf

            /// Creates an Expr instance by analyzing the provided expression syntax.
            ///
            /// Performs comprehensive type inference on the expression to determine its type category.
            /// The method follows a hierarchical approach to type determination:
            /// 1. If an inherited type is provided, uses that explicitly
            /// 2. Attempts to infer type from raw literal expressions (bool, int, double, string)
            /// 3. Attempts to infer type from operator expressions (ranges, prefix/postfix operators)
            /// 4. Falls back to string type if no other type can be determined
            ///
            /// Supports various expression types including:
            /// - Literal expressions (boolean, integer, float, string)
            /// - Range operators (`...`, `..<`)
            /// - Prefix operators (e.g., `-` for negative numbers)
            /// - Postfix operators (e.g., `...` for partial ranges)
            /// - Parenthesized expressions
            ///
            /// - Parameters:
            ///   - expression: The Swift expression syntax to analyze for type inference
            ///   - inheritedType: Optional explicit type to use instead of automatic inference
            ///   - context: The macro expansion context for diagnostics and error reporting
            /// - Returns: A new Expr instance with the expression and inferred/specified type
            static func from(
                expression: ExprSyntax, inheritedType: TypeSyntax?,
                context: some MacroExpansionContext
            ) -> Self {
                let type: TypeOf =
                    if let inheritedType = inheritedType {
                        .unknown(inheritedType)
                    } else if let type = typeOf(raw: expression) {
                        type
                    } else if let type = typeOf(
                        operator: expression, context: context)
                    {
                        type
                    } else {
                        .string
                    }
                return Expr(syntax: expression, type: type)
            }

            /// Infers the type of an expression containing operators.
            ///
            /// Analyzes expressions that contain range operators (`...`, `..<`) or other operators
            /// to determine the underlying type. This method handles various operator expression
            /// formats including:
            /// - Infix operators: `1...5`, `0..<10`
            /// - Prefix operators: `...5`, `..<10`
            /// - Postfix operators: `1...`, `5...`
            /// - Sequence expressions with multiple elements
            ///
            /// The method converts different operator expression types into a normalized
            /// `SequenceExprSyntax` format for consistent processing, then analyzes the
            /// operands to determine the overall expression type.
            ///
            /// - Parameters:
            ///   - expression: The operator expression to analyze
            ///   - context: The macro expansion context for diagnostics
            /// - Returns: The inferred type if successful, nil if type cannot be determined
            private static func typeOf(
                operator expression: ExprSyntax,
                context: some MacroExpansionContext
            ) -> TypeOf? {
                let operatorTexts = ["...", "..<"]
                let expr: SequenceExprSyntax
                if let expression = expression.as(SequenceExprSyntax.self) {
                    expr = expression
                } else if let expression = expression.as(
                    InfixOperatorExprSyntax.self
                ) {
                    expr = SequenceExprSyntax(
                        elements: [
                            expression.leftOperand,
                            expression.operator,
                            expression.rightOperand,
                        ]
                    )
                } else if let expression = expression.as(
                    PrefixOperatorExprSyntax.self
                ) {
                    expr = SequenceExprSyntax(
                        elements: [
                            ExprSyntax(
                                BinaryOperatorExprSyntax(
                                    operator: expression.operator
                                )
                            ),
                            expression.expression,
                        ]
                    )
                } else if let expression = expression.as(
                    PostfixOperatorExprSyntax.self
                ) {
                    expr = SequenceExprSyntax(
                        elements: [
                            expression.expression,
                            ExprSyntax(
                                BinaryOperatorExprSyntax(
                                    operator: expression.operator
                                )
                            ),
                        ]
                    )
                } else {
                    return nil
                }

                switch expr.elements.count {
                case 2:
                    if let opExpr = expr.elements.first!.as(
                        BinaryOperatorExprSyntax.self
                    ),
                        operatorTexts.contains(String(opExpr.operator.text)),
                        let type = typeOf(raw: expr.elements.last!)
                    {
                        return type
                    } else if let opExpr = expr.elements.last!.as(
                        BinaryOperatorExprSyntax.self),
                        operatorTexts.contains(String(opExpr.operator.text)),
                        let type = typeOf(raw: expr.elements.first!)
                    {
                        return type
                    }
                case 3:
                    let middleIndex = expr.elements.index(
                        expr.elements.startIndex, offsetBy: 1
                    )
                    guard
                        let opExpr = expr.elements[middleIndex].as(
                            BinaryOperatorExprSyntax.self
                        ),
                        operatorTexts.contains(String(opExpr.operator.text)),
                        let firstType = typeOf(raw: expr.elements.first!),
                        let lastType = typeOf(raw: expr.elements.last!)
                    else { break }
                    return maxOf(
                        leftType: firstType, rightType: lastType,
                        originExpression: expression, context: context
                    )
                default:
                    break
                }

                return nil
            }

            /// Infers the type of a raw literal expression.
            ///
            /// Analyzes literal expressions to determine their Swift type category.
            /// This method handles various literal expression formats and performs
            /// preprocessing to normalize the expression before type analysis:
            ///
            /// 1. Unwraps single-element tuple expressions: `(42)` → `42`
            /// 2. Handles negative number prefix operators: `-42` → `42` (int type)
            /// 3. Identifies literal types: boolean, integer, float, string
            ///
            /// Supported literal types:
            /// - `BooleanLiteralExprSyntax`: `true`, `false` → `.bool`
            /// - `IntegerLiteralExprSyntax`: `42`, `0`, `-5` → `.int`
            /// - `FloatLiteralExprSyntax`: `3.14`, `0.5` → `.double`
            /// - `StringLiteralExprSyntax`: `"hello"`, `"world"` → `.string`
            ///
            /// - Parameter expression: The raw expression to analyze for literal type
            /// - Returns: The inferred literal type if recognized, nil otherwise
            private static func typeOf(raw expression: ExprSyntax) -> TypeOf? {
                var expr: ExprSyntax
                if let tuple = expression.as(TupleExprSyntax.self),
                    tuple.elements.count == 1
                {
                    expr = tuple.elements.first!.expression
                } else {
                    expr = expression
                }

                if let prefixExpr = expr.as(PrefixOperatorExprSyntax.self),
                    prefixExpr.operator.text == "-"
                {
                    expr = prefixExpr.expression
                }

                if expr.is(BooleanLiteralExprSyntax.self) {
                    return .bool
                } else if expr.is(FloatLiteralExprSyntax.self) {
                    return .double
                } else if expr.is(IntegerLiteralExprSyntax.self) {
                    return .int
                } else if expr.is(StringLiteralExprSyntax.self) {
                    return .string
                } else {
                    return nil
                }
            }
        }

        /// Determines the maximum (most specific) type from two types in a range expression.
        ///
        /// When analyzing range expressions like `1...5.0`, this method determines the most
        /// appropriate type that can represent both operands. The type promotion follows
        /// Swift's type system rules:
        ///
        /// - Same types return the same type: `.int` + `.int` → `.int`
        /// - Integer and double promote to double: `.int` + `.double` → `.double`
        /// - Incompatible types generate a diagnostic error and fallback to `.string`
        ///
        /// This ensures that range expressions maintain type safety while allowing
        /// reasonable type promotions for numeric ranges.
        ///
        /// - Parameters:
        ///   - leftType: The type of the left operand in the range
        ///   - rightType: The type of the right operand in the range
        ///   - originExpression: The original expression for error reporting
        ///   - context: The macro expansion context for diagnostics
        /// - Returns: The promoted type that can represent both operands
        private static func maxOf(
            leftType: TypeOf, rightType: TypeOf, originExpression: ExprSyntax,
            context: some MacroExpansionContext
        ) -> TypeOf {
            switch (leftType, rightType) {
            case (.int, .int), (.double, .double), (.string, .string):
                return leftType
            case (.int, .double), (.double, .int):
                return .double
            default:
                context.diagnose(
                    .init(
                        node: originExpression,
                        message: MetaCodableMacroExpansionErrorMessage<CodedAs>(
                            "Invalid expression type for enum case value"
                        )
                    )
                )
                return .string
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
        LabeledExprListSyntax {
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
        LabeledExprListSyntax {
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
        .init(
            decodingKeys: decodingKeys,
            contentDecoder: contentDecoder, contentEncoder: contentEncoder
        )
    }
}

fileprivate extension EnumVariable {
    /// The default name for identifier type root container.
    ///
    /// This container is passed to each case for decoding.
    static var typeContainer: TokenSyntax { "typeContainer" }
    /// The default name for top-level root container.
    ///
    /// This container is passed to each case for decoding.
    static var container: TokenSyntax { "container" }

    /// The identifier type variable name.
    ///
    /// This name is passed for identifier variable declaration
    /// during decoding.
    static var type: TokenSyntax { "type" }

    /// The default name for content root decoder.
    ///
    /// This decoder is passed to each case for decoding.
    static var contentDecoder: TokenSyntax { "contentDecoder" }
    /// The default name for content root encoder.
    ///
    /// This encoder is passed to each case for encoding.
    static var contentEncoder: TokenSyntax { "contentEncoder" }
}
