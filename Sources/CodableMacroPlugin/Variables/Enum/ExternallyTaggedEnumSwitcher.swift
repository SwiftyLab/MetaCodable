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

    /// Creates value expressions for provided enum-case variable.
    ///
    /// If provided variable is decodable then decoding key expressions
    /// with `decodingKeys` map is generated. The encoding key
    /// expressions are generated from provided map.
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
        let setKeys = values.compactMap { expr in
            return expr.as(StringLiteralExprSyntax.self)?.segments.first?
                .as(StringSegmentSyntax.self)?.content.text
        }
        let keys =
            !setKeys.isEmpty
            ? setKeys : [CodingKeysMap.Key.name(for: variable.name).text]
        let name = variable.name

        let eKeys: [CodingKeysMap.Key] =
            if variable.encode ?? true {
                keys.map { key in
                    codingKeys.add(keys: [key], field: name, context: context)
                        .first!
                }
            } else {
                []
            }

        let dKeys: [CodingKeysMap.Key] =
            if variable.decode ?? true {
                keys.map { key in
                    decodingKeys.add(keys: [key], field: name, context: context)
                        .first!
                }
            } else {
                []
            }

        if !dKeys.isEmpty, !eKeys.isEmpty {
            return .keys(dKeys, eKeys)
        } else if !dKeys.isEmpty {
            return .key(dKeys)
        } else if !eKeys.isEmpty {
            return .key(eKeys)
        } else {
            return .raw(keys.map { "\(literal: $0)" })
        }
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
            data: .container(container), expr: expr, code: code,
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
            data: .container(container), expr: "self", code: code,
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
        guard let decl = decodingKeys.decl(in: context) else { return [] }
        return MemberBlockItemListSyntax { decl }
    }
}
