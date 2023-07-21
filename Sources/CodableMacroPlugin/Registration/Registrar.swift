import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

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

    /// Add registration built in the provided macro-expansion context.
    ///
    /// This registrar asks `caseMap` to generate cases for
    /// `CodingKey`s and asks `root` node to register
    /// data at the level of key path provided in registration.
    ///
    /// - Parameters:
    ///   - registration: The variable metadata and `CodingKey`
    ///                   path to be added.
    ///   - context: The context in which to perform the macro expansion.
    mutating func add(
        registration: Registration<some Variable>,
        context: some MacroExpansionContext
    ) {
        let keyPath = registration.keyPath
        let variable = registration.variable
        caseMap.add(forKeys: keyPath, field: variable.name, context: context)
        root.register(
            variable: variable,
            keyPath: keyPath.map { Key(value: $0, map: caseMap) }
        )
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
        return InitializerDeclSyntax.decode(
            modifiers: options.modifiers
        ) { decoder in
            root.decoding(
                in: context,
                from: .coder(decoder, keyType: caseMap.type)
            )
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
        return FunctionDeclSyntax.encode(
            modifiers: options.modifiers
        ) { encoder in
            root.encoding(
                in: context,
                from: .coder(encoder, keyType: caseMap.type)
            )
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
        let allVariables = root.linkedVariables
        var params: [FunctionParameterSyntax] = []
        var exprs: [CodeBlockItemSyntax] = []
        params.reserveCapacity(allVariables.count)
        exprs.reserveCapacity(allVariables.count)

        allVariables.forEach { variable in
            switch variable.initializing(in: context) {
            case .ignored:
                break
            case .optional(let param, let expr),
                .required(let param, let expr):
                params.append(param)
                exprs.append(expr)
            }
        }
        return InitializerDeclSyntax(
            modifiers: options.modifiers,
            signature: .init(
                input: .init(
                    parameterList: .init {
                        for param in params { param }
                    }
                )
            )
        ) {
            for expr in exprs { expr }
        }
    }
}

/// An extension that handles `init(from:)`
/// implementation for `Decodable`.
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
        @CodeBlockItemListBuilder
        itemsBuilder: (TokenSyntax) throws -> CodeBlockItemListSyntax
    ) rethrows -> Self {
        let decoder: TokenSyntax = "decoder"
        let param = FunctionParameterSyntax(
            firstName: "from", secondName: decoder,
            type: SimpleTypeIdentifierSyntax(name: "Decoder")
        )

        let signature = FunctionSignatureSyntax(
            input: .init(parameterList: .init([param])),
            effectSpecifiers: .init(throwsSpecifier: .keyword(.throws))
        )

        return try InitializerDeclSyntax(
            modifiers: modifiers,
            signature: signature
        ) {
            for expr in try itemsBuilder(decoder) { expr }
        }
    }
}

/// An extension that handles `encode(to:)`
/// implementation for `Encodable`.
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
        @CodeBlockItemListBuilder
        itemsBuilder: (TokenSyntax) throws -> CodeBlockItemListSyntax
    ) rethrows -> Self {
        let encoder: TokenSyntax = "encoder"
        let param = FunctionParameterSyntax(
            firstName: "to", secondName: encoder,
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
            for expr in try itemsBuilder(encoder) { expr }
        }
    }
}
