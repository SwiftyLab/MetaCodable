@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// An `EnumSwitcherVariable` generating switch expression for externally
/// tagged enums.
///
/// Maintains a specific `CodingKeys` map only for decoding. The generated
/// switch expression compares containers key against case values.
struct ExternallyTaggedEnumSwitcher: EnumSwitcherVariable {
    /// The decoding specific `CodingKeys` map.
    ///
    /// This map is used to only register decoding keys for enum-cases.
    let decodingKeys: CodingKeysMap

    /// Creates value expression for provided enum-case variable.
    ///
    /// If provided variable is decodable then decoding key expression
    /// with `decodingKeys` map is generated. The encoding key
    /// expression is generated from provided map.
    ///
    /// - Parameters:
    ///   - variable: The variable for which generated.
    ///   - value: The optional value present in syntax.
    ///   - codingKeys: The map where `CodingKeys` maintained.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The generated value.
    func keyExpression<Var: EnumCaseVariable>(
        for variable: Var, value: ExprSyntax?,
        codingKeys: CodingKeysMap, context: some MacroExpansionContext
    ) -> EnumVariable.CaseValue {
        let keyStr =
            value?.as(StringLiteralExprSyntax.self)?.segments.first?
            .as(StringSegmentSyntax.self)?.content.text
            ?? CodingKeysMap.Key.name(for: variable.name).text
        let keys = [keyStr]
        let name = variable.name
        let eKey = codingKeys.add(keys: keys, field: name, context: context)
            .first!
        guard variable.decode ?? true else { return .key(eKey) }
        let dKey = decodingKeys.add(keys: keys, field: name, context: context)
            .first!
        return .keys(dKey, eKey)
    }

    /// Provides the syntax for decoding at the provided location.
    ///
    /// The generated implementation checks:
    /// * Whether container of provided decoder has only one key from decoding
    ///   `CodingKeys` map, if failed `typeMismatch` error generated.
    /// * The switch expression compares the container key with all enum-case
    ///   values.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The decoding location.
    ///
    /// - Returns: The generated decoding syntax.
    func decoding(
        in context: some MacroExpansionContext,
        from location: EnumSwitcherLocation
    ) -> EnumSwitcherGenerated {
        let coder = location.coder
        let container = location.container
        let keyType = decodingKeys.type
        let selfType = location.selfType
        let expr: ExprSyntax = "\(container).allKeys.first.unsafelyUnwrapped"
        let code = CodeBlockItemListSyntax {
            "let \(container) = try \(coder).container(keyedBy: \(keyType))"
            """
            guard \(container).allKeys.count == 1 else {
                let context = DecodingError.Context(
                    codingPath: \(container).codingPath,
                    debugDescription: "Invalid number of keys found, expected one."
                )
                throw DecodingError.typeMismatch(\(selfType), context)
            }
            """
        }
        return .init(
            container: container, expr: expr, code: code,
            defaultCase: false
        )
    }

    /// Provides the syntax for encoding at the provided location.
    ///
    /// The generated implementation creates container from decoder
    /// keyed by passed `CodingKey` type.
    ///
    /// - Parameters:
    ///   - context: The context in which to perform the macro expansion.
    ///   - location: The encoding location.
    ///
    /// - Returns: The generated encoding syntax.
    func encoding(
        in context: some MacroExpansionContext,
        to location: EnumSwitcherLocation
    ) -> EnumSwitcherGenerated {
        let coder = location.coder
        let container = location.container
        let keyType = location.keyType
        let code = CodeBlockItemListSyntax {
            """
            var \(container) = \(coder).container(keyedBy: \(keyType))
            """
        }
        return .init(
            container: container, expr: "self", code: code,
            defaultCase: true
        )
    }

    /// Creates additional enum declarations for enum variable.
    ///
    /// Adds decoding specific `CodingKeys` map declaration.
    ///
    /// - Parameter context: The macro expansion context.
    /// - Returns: The generated enum declaration syntax.
    func codingKeys(
        in context: some MacroExpansionContext
    ) -> MemberBlockItemListSyntax {
        return MemberBlockItemListSyntax {
            decodingKeys.decl(in: context)
        }
    }
}
