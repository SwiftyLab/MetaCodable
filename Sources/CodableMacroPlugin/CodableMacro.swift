import Foundation
import SwiftSyntax
import SwiftDiagnostics
import SwiftSyntaxMacros

/// Describes a macro that generates `Codable` conformances and implementations.
///
/// This macro performs two different kinds of expansion:
///   * Conformance macro expansion, to confirm to `Decodable`
///     and `Encodable` protocols.
///   * Member macro expansion, to generate custom `CodingKey` type
///     for the attached struct declaration named `CodingKeys` and use
///     this type for `Codable` implementation of both `init(from:)`
///     and `encode(to:)` methods by using `CodableFieldMacro`
///     declarations. Additionally member-wise initializer is also generated.
struct CodableMacro: ConformanceMacro, MemberMacro {
    /// Expand to produce `Codable` conformance.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: `Codable` type to allow conformance to both
    ///            `Decodable` and `Encodable` protocols
    ///            without any where clause.
    static func expansion(
        of node: AttributeSyntax,
        providingConformancesOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [(TypeSyntax, GenericWhereClauseSyntax?)] {
        return [
            ("Codable", nil)
        ]
    }

    /// Expand to produce `Codable` implementation members for attached struct.
    ///
    /// For all the variable declarations in the attached type registration is
    /// done via `CodableMacro.Registrar` instance with optional
    /// `CodableFieldMacro` metadata. The `CodableMacro.Registrar`
    /// instance provides declarations based on all the registrations.
    ///
    /// - Parameters:
    ///   - node: The attribute describing this macro.
    ///   - declaration: The declaration this macro attribute is attached to.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: `CodingKeys` type and `init(from:)`, `encode(to:)`,
    ///             method declarations for `Codable` implementation along with
    ///             member-wise initializer declaration.
    static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        let name = node.attributeName
            .as(SimpleTypeIdentifierSyntax.self)!.description
        guard declaration.is(StructDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: MetaCodableMessage.diagnostic(
                        message: "@\(name) attribute only works for structs",
                        id: .codableMacroMisuse,
                        severity: .error
                    ),
                    fixIts: [
                        .init(
                            message: MetaCodableMessage.fixIt(
                                message: "Remove @\(name) attribute",
                                id: .codableMacroMisuse
                            ),
                            changes: [
                                .replace(
                                    oldNode: Syntax(node),
                                    newNode: Syntax("" as DeclSyntax)
                                )
                            ]
                        )
                    ]
                )
            )
            return []
        }

        var registrar = Registrar(
            options: .init(modifiers: declaration.modifiers)
        )

        declaration.memberBlock.members.forEach { member in
            // is a variable declaration
            guard let decl = member.decl.as(VariableDeclSyntax.self)
            else { return }

            // is a grouped property declaration
            if decl.initializableBindings.count > 1 {
                var variables: [(TokenSyntax, TypeSyntax?)] = []
                for binding in decl.initializableBindings
                where binding.pattern.is(IdentifierPatternSyntax.self) {
                    variables.append((
                        binding.pattern.as(IdentifierPatternSyntax.self)!
                            .identifier,
                        binding.typeAnnotation?.type
                    ))
                }

                var datas: [Registrar.Node.Data] = []
                datas.reserveCapacity(variables.count)

                var latestType: TypeSyntax!
                for (field, type) in variables.reversed() {
                    if let type { latestType = type }
                    datas.append(.init(field: field, type: latestType))
                }

                for data in datas.reversed() {
                    registrar.add(
                        data: data,
                        keyPath: [data.field.asKey],
                        context: context
                    )
                }
                return
            }

            // is a single property declaration
            guard
                let binding = decl.initializableBindings.first,
                let type = binding.typeAnnotation?.type,
                let field = binding.pattern
                    .as(IdentifierPatternSyntax.self)?.identifier
            else { return }

            // has CodableCompose macro
            if let mData = decl.attribute(withName: CodableFieldMacro.compose) {
                registrar.add(
                    data: .init(
                        field: field,
                        type: type,
                        default: mData.default,
                        helper: mData.helper
                    ),
                    context: context
                )
                return
            }

            // has CodablePath macro
            if let mData = decl.attribute(withName: CodableFieldMacro.path),
                let arg = mData.attr.argument,
                let exprs = arg.as(TupleExprElementListSyntax.self)
            {
                let path: [String] = exprs.compactMap { expr in
                    guard
                        !CodableFieldMacro.argLabels
                            .contains(expr.label?.text ?? "")
                    else { return nil }
                    return expr.expression.as(StringLiteralExprSyntax.self)?
                        .segments.first?.as(StringSegmentSyntax.self)?
                        .content.text
                }
                registrar.add(
                    data: .init(
                        field: field,
                        type: type,
                        default: mData.default,
                        helper: mData.helper
                    ),
                    keyPath: path.isEmpty ? [field.asKey] : path,
                    context: context
                )
                return
            }

            // default
            registrar.add(
                data: .init(field: field, type: type),
                keyPath: [field.asKey],
                context: context
            )
        }

        return [
            DeclSyntax(registrar.memberInit(in: context)),
            DeclSyntax(registrar.decoding(in: context)),
            DeclSyntax(registrar.encoding(in: context)),
            DeclSyntax(registrar.codingKeys(in: context)),
        ]
    }
}

/// An extension that manages `CodableMacro`
/// specific message ids.
fileprivate extension MessageID {
    /// Message id for misuse of `CodableMacro` application.
    static var codableMacroMisuse: Self { .messageID("codablemacro-misuse") }
}

/// An extension that manages retrieval of macro metadata
/// from a variable declaration.
fileprivate extension VariableDeclSyntax {
    /// Get attribute metadata for a given macro attribute name.
    ///
    /// - Parameter name: The name of macro attribute.
    /// - Returns: The macro attribute node, optional default
    ///            and helper expressions for variable decoding.
    func attribute(
        withName name: String
    ) -> (attr: AttributeSyntax, default: ExprSyntax?, helper: ExprSyntax?)? {
        guard
            let macro = attributes?.first(where: {
                $0.as(AttributeSyntax.self)?.attributeName
                    .as(SimpleTypeIdentifierSyntax.self)?.description == name
            })?.as(AttributeSyntax.self)
        else { return nil }

        // get default expression if provided
        let def = macro.argument?.as(TupleExprElementListSyntax.self)?.first {
            $0.label?.text == CodableFieldMacro.defaultArgLabel
        }?.expression

        // get helper expression if provided
        let hlpr = macro.argument?.as(TupleExprElementListSyntax.self)?.first {
            $0.label?.text == CodableFieldMacro.helperArgLabel
        }?.expression

        return (attr: macro, default: def, helper: hlpr)
    }

    /// Filters variables in variable declaration that can be initialized
    /// in parent type's Initializer.
    ///
    /// Filters variables that are not computed properties with getters,
    /// and if immutable not initialized already.
    var initializableBindings: [PatternBindingSyntax] {
        return self.bindings.filter { binding in
            switch binding.accessor {
            case .some(let block) where block.is(CodeBlockSyntax.self):
                false
            case .some(let block) where block.is(AccessorBlockSyntax.self):
                !block.as(AccessorBlockSyntax.self)!.accessors.contains { decl in
                    decl.accessorKind.tokenKind == .keyword(.get)
                }
                // TODO: Re-evaluate when init accessor is introduced
                // https://github.com/apple/swift-evolution/blob/main/proposals/0400-init-accessors.md
                // || block.as(AccessorBlockSyntax.self)!.accessors.contains { decl in
                //     decl.accessorKind.tokenKind == .keyword(.`init`)
                // }
            default:
                self.bindingKeyword.tokenKind == .keyword(.var)
                || binding.initializer == nil
            }
        }
    }
}

/// An extension that converts field token syntax
/// to equivalent key token.
extension TokenSyntax {
    /// Convert field token syntax
    /// to equivalent key token
    /// string by trimming \`s`.
    var asKey: String {
        self.text.trimmingCharacters(in: .swiftVariableExtra)
    }

    /// Convert field token syntax
    /// to equivalent key token
    /// by trimming \`s`.
    var raw: TokenSyntax { .identifier(self.asKey) }
}

/// An extension that manages
/// custom character sets
/// for macro expansion.
extension CharacterSet {
    /// Character set that contains extra characters in swift variable names
    /// not applicable for key construction.
    static let swiftVariableExtra: Self = .init(arrayLiteral: "`")
}
