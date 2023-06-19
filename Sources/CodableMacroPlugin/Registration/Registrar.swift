import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

extension CodableMacro {
    /// A type managing registrations of variable and `CodingKey` data.
    ///
    /// Use `add` method to register new data and
    /// use `decoding`, `encoding` and `codingKeys` methods
    /// to get final generated implementation of `Codable` conformance.
    struct Registrar {
        /// A type indicating various configurations available
        /// for `Registrar`.
        ///
        /// These options are used as global level customization
        /// performed on the final generated implementation
        /// of `Codable` conformance.
        struct Options {
            /// The default list of modifiers to be applied to generated
            /// conformance implementation declarations.
            fileprivate let modifiers: ModifierListSyntax?

            /// Creates a new options instance with provided parameters.
            ///
            /// - Parameters:
            ///   - modifiers: List of modifiers need to be applied
            ///                to generated declarations.
            ///
            /// - Returns: The newly created options.
            init(modifiers: ModifierListSyntax? = nil) {
                self.modifiers = modifiers
            }
        }

        /// The root node containing all the keys
        /// and associated field metadata maps.
        private var root: Node
        /// The case map containing keys
        /// and generated case names.
        private let caseMap: CaseMap
        /// The options to use when generating declarations.
        private let options: Options

        /// Creates a new registrar with provided options, root node and case
        /// map.
        ///
        /// - Parameters:
        ///   - root: The root node that maintains key data levels.
        ///   - caseMap: The `CaseMap` that generates `CodingKey` maps.
        ///   - options: The options to use when generating declarations.
        ///
        /// - Returns: The newly created registrar instance.
        init(
            root: Node = .init(),
            caseMap: CaseMap = .init(),
            options: Options
        ) {
            self.root = root
            self.caseMap = caseMap
            self.options = options
        }

        /// Add metadata for the provided `CodingKey` path.
        ///
        /// This registrar asks `caseMap` to generate cases for
        /// `CodingKey`s and asks `root` node to register
        /// data at the level of key path provided.
        ///
        /// - Parameters:
        ///   - data: The metadata associated with field,
        ///           i.e. field name, type and additional macro metadata.
        ///   - keyPath: The `CodingKey` path where the value
        ///              will be decode/encoded.
        ///   - context: The context in which to perform the macro expansion.
        mutating func add(
            data: Node.Data,
            keyPath: [String] = [],
            context: some MacroExpansionContext
        ) {
            caseMap.add(forKeys: keyPath, field: data.field, context: context)
            let keyPath = keyPath.map { Key(value: $0, map: caseMap) }
            root.register(data: data, keyPath: keyPath)
        }

        /// Provides the declaration of `CodingKey` type that is used
        /// for `Codable` implementation generation.
        ///
        /// This registrar asks `caseMap` to generate `CodingKey`
        /// declaration based on current keys registrations.
        ///
        /// - Parameter context: The context in which to perform
        ///                      the macro expansion.
        ///
        /// - Returns: The generated enum declaration.
        func codingKeys(
            in context: some MacroExpansionContext
        ) -> EnumDeclSyntax {
            return caseMap.decl(in: context)
        }

        /// Provides the initialization declaration `init(from:)`
        /// for `Decodable` conformance implementation.
        ///
        /// - Parameter context: The context in which to perform
        ///                      the macro expansion.
        ///
        /// - Returns: The generated initializer declaration.
        func decoding(
            in context: some MacroExpansionContext
        ) -> InitializerDeclSyntax {
            return InitializerDeclSyntax.decode(modifiers: options.modifiers) {
                for data in root.datas {
                    data.topDecoding(in: context)
                }
                """
                let container = try decoder.container(keyedBy: \(caseMap.type))
                """ as ExprSyntax
                for (key, node) in root.children {
                    node.decoding(in: context, container: "container", key: key)
                }
            }
        }

        /// Provides the method declaration `encode(to:)`
        /// for `Encodable` conformance implementation.
        ///
        /// - Parameter context: The context in which to perform
        ///                      the macro expansion.
        ///
        /// - Returns: The generated function declaration.
        func encoding(
            in context: some MacroExpansionContext
        ) -> FunctionDeclSyntax {
            return FunctionDeclSyntax.encode(modifiers: options.modifiers) {
                for data in root.datas {
                    data.topEncoding(in: context)
                }
                """
                var container = encoder.container(keyedBy: \(caseMap.type))
                """ as ExprSyntax
                for (key, node) in root.children {
                    node.encoding(in: context, container: "container", key: key)
                }
            }
        }

        /// Provides the member-wise initializer declaration.
        ///
        /// - Parameter context: The context in which to perform
        ///                      the macro expansion.
        ///
        /// - Returns: The generated initializer declaration.
        func memberInit(
            in context: some MacroExpansionContext
        ) -> InitializerDeclSyntax {
            let signature = FunctionSignatureSyntax(
                input: .init {
                    for data in root.allDatas { data.funcParam }
                }
            )

            return InitializerDeclSyntax(
                modifiers: options.modifiers,
                signature: signature
            ) {
                for data in root.allDatas {
                    "self.\(data.field) = \(data.field)" as ExprSyntax
                }
            }
        }
    }
}

fileprivate extension InitializerDeclSyntax {
    /// Generates the initialization declaration `init(from:)`
    /// for `Decodable` conformance implementation.
    ///
    /// The declaration is generated applying provided modifiers
    /// and using given expressions.
    ///
    /// - Parameters:
    ///   - modifiers: The modifiers to apply to the declaration.
    ///   - itemsBuilder: The result builder that builds expressions
    ///                   in the declaration.
    ///
    /// - Returns: The generated initializer declaration.
    static func decode(
        modifiers: ModifierListSyntax?,
        @ExprListBuilder itemsBuilder: () throws -> ExprListSyntax
    ) rethrows -> Self {
        let param = FunctionParameterSyntax(
            firstName: .identifier("from"),
            secondName: .identifier("decoder"),
            type: SimpleTypeIdentifierSyntax(name: .identifier("Decoder"))
        )

        let signature = FunctionSignatureSyntax(
            input: .init(parameterList: .init([param])),
            effectSpecifiers: .init(throwsSpecifier: .keyword(.throws))
        )

        return try InitializerDeclSyntax(
            modifiers: modifiers,
            signature: signature
        ) {
            for expr in try itemsBuilder() { expr }
        }
    }
}

fileprivate extension FunctionDeclSyntax {
    /// Generates the method declaration `encode(to:)`
    /// for `Encodable` conformance implementation.
    ///
    /// The declaration is generated applying provided modifiers
    /// and using given expressions.
    ///
    /// - Parameters:
    ///   - modifiers: The modifiers to apply to the declaration.
    ///   - itemsBuilder: The result builder that builds expressions
    ///                   in the declaration.
    ///
    /// - Returns: The generated method declaration.
    static func encode(
        modifiers: ModifierListSyntax?,
        @ExprListBuilder itemsBuilder: () throws -> ExprListSyntax
    ) rethrows -> Self {
        let param = FunctionParameterSyntax(
            firstName: "to",
            secondName: "encoder",
            type: SimpleTypeIdentifierSyntax(name: "Encoder")
        )

        let signature = FunctionSignatureSyntax(
            input: .init(parameterList: .init([param])),
            effectSpecifiers: .init(throwsSpecifier: .keyword(.throws))
        )

        return try FunctionDeclSyntax(
            modifiers: modifiers,
            identifier: "encode",
            signature: signature
        ) {
            for expr in try itemsBuilder() { expr }
        }
    }
}
