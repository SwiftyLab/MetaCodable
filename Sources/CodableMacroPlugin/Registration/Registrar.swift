import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

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
        fileprivate let modifiers: DeclModifierListSyntax

        /// Memberwise initialization generator with provided options.
        ///
        /// Creates memberwise initialization generator by passing
        /// the provided access modifiers.
        var initGenerator: MemberwiseInitGenerator {
            return .init(options: .init(modifiers: modifiers))
        }

        /// Creates a new options instance with provided parameters.
        ///
        /// - Parameters:
        ///   - modifiers: List of modifiers need to be applied
        ///     to generated declarations.
        ///
        /// - Returns: The newly created options.
        init(modifiers: DeclModifierListSyntax = []) {
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
    ///     path to be added.
    ///   - context: The context in which to perform the macro expansion.
    mutating func add(
        registration: Registration<some Variable>,
        context: some MacroExpansionContext
    ) {
        let keyPath = registration.keyPath
        let variable = registration.variable
        if (variable.decode ?? true) || (variable.encode ?? true) {
            let name = variable.name
            caseMap.add(forKeys: keyPath, field: name, context: context)
        }
        root.register(
            variable: variable,
            keyPath: keyPath.map { Key(value: $0, map: caseMap) }
        )
    }

    /// Generates extension declarations for `Codable` macro.
    ///
    /// From the variables registered by `Codable` macro,
    /// `Codable` protocol conformance and `CodingKey` type
    /// declarations are generated in separate extensions.
    ///
    /// - Parameters:
    ///   - type: The type for which extensions provided.
    ///   - protocols: The list of `Codable` protocols to add
    ///     conformances to. These will always be either `Decodable`
    ///     or `Encodable`.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The generated extension declarations.
    func codableExpansion(
        for type: some TypeSyntaxProtocol,
        to protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) -> [ExtensionDeclSyntax] {
        var extensions: [ExtensionDeclSyntax] = []

        let decodable: TypeSyntax?
        let encodable: TypeSyntax?

        // check conformances to be generated
        if let conf = protocols.first(
            where: { $0.trimmed.description == "Decodable" }
        ) {
            decodable = conf
        } else if protocols.contains(
            where: { $0.description.contains("Decodable") }
        ) {
            decodable = "Decodable"
        } else {
            decodable = nil
        }

        if let conf = protocols.first(
            where: { $0.trimmed.description == "Encodable" }
        ) {
            encodable = conf
        } else if protocols.contains(
            where: { $0.description.contains("Encodable") }
        ) {
            encodable = "Encodable"
        } else {
            encodable = nil
        }

        // generate Decodable
        if let decodable {
            let ext = decoding(type: type, conformingTo: decodable, in: context)
            extensions.append(ext)
        }

        // generate Encodable
        if let encodable {
            let ext = encoding(type: type, conformingTo: encodable, in: context)
            extensions.append(ext)
        }

        // generate CodingKeys
        if decodable != nil || encodable != nil {
            extensions.append(codingKeys(for: type, in: context))
        }

        return extensions
    }

    /// Provides the `Decodable` extension declaration.
    ///
    /// The extension declaration contains conformance to `Decodable`
    /// with initialization declaration `init(from:)` for `Decodable`
    /// conformance implementation.
    ///
    /// - Parameters:
    ///   - type: The type for which extensions provided.
    ///   - protocol: The`Decodable` protocol type syntax.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The generated extension declaration.
    func decoding(
        type: some TypeSyntaxProtocol,
        conformingTo protocol: TypeSyntax = "Decodable",
        in context: some MacroExpansionContext
    ) -> ExtensionDeclSyntax {
        return .init(
            extendedType: type,
            inheritanceClause: .init { .init(type: `protocol`) }
        ) {
            InitializerDeclSyntax.decode(
                modifiers: options.modifiers
            ) { decoder in
                let type = caseMap.type
                root.decoding(in: context, from: .coder(decoder, keyType: type))
            }
        }
    }

    /// Provides the `Encodable` extension declaration.
    ///
    /// The extension declaration contains conformance to `Encodable`
    /// with method declaration `encode(to:)` for `Encodable`
    /// conformance implementation.
    ///
    /// - Parameters:
    ///   - type: The type for which extensions provided.
    ///   - protocol: The`Encodable` protocol type syntax.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The generated extension declaration.
    func encoding(
        type: some TypeSyntaxProtocol,
        conformingTo protocol: TypeSyntax = "Encodable",
        in context: some MacroExpansionContext
    ) -> ExtensionDeclSyntax {
        return .init(
            extendedType: type,
            inheritanceClause: .init { .init(type: `protocol`) }
        ) {
            FunctionDeclSyntax.encode(modifiers: options.modifiers) { encoder in
                let type = caseMap.type
                root.encoding(in: context, from: .coder(encoder, keyType: type))
            }
        }
    }

    /// Provides the declaration of `CodingKey` type that is used
    /// for `Codable` implementation generation.
    ///
    /// This registrar asks `caseMap` to generate `CodingKey`
    /// declaration based on current keys registrations.
    ///
    /// - Parameters:
    ///   - type: The type for which extensions provided.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The generated enum declaration.
    func codingKeys(
        for type: some TypeSyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> ExtensionDeclSyntax {
        return .init(extendedType: type) {
            caseMap.decl(in: context)
        }
    }

    /// Provides the memberwise initializer declaration(s).
    ///
    /// - Parameter context: The context in which to perform
    ///   the macro expansion.
    /// - Returns: The generated initializer declarations.
    func memberInit(
        in context: some MacroExpansionContext
    ) -> [InitializerDeclSyntax] {
        var generator = options.initGenerator
        for variable in root.linkedVariables {
            generator = variable.initializing(in: context).add(to: generator)
        }
        return generator.declarations(in: context)
    }
}

/// An extension that handles `init(from:)`
/// implementation for `Decodable`.
private extension InitializerDeclSyntax {
    /// Generates the initialization declaration `init(from:)`
    /// for `Decodable` conformance implementation.
    ///
    /// The declaration is generated applying provided modifiers
    /// and using given expressions.
    ///
    /// - Parameters:
    ///   - modifiers: The modifiers to apply to the declaration.
    ///   - itemsBuilder: The result builder that builds expressions
    ///     in the declaration.
    ///
    /// - Returns: The generated initializer declaration.
    static func decode(
        modifiers: DeclModifierListSyntax,
        @CodeBlockItemListBuilder itemsBuilder: (TokenSyntax) throws -> CodeBlockItemListSyntax
    ) rethrows -> Self {
        let decoder: TokenSyntax = "decoder"
        let param = FunctionParameterSyntax(
            firstName: "from", secondName: decoder,
            type: IdentifierTypeSyntax(name: "any Decoder")
        )

        let signature = FunctionSignatureSyntax(
            parameterClause: .init(parameters: .init([param])),
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
private extension FunctionDeclSyntax {
    /// Generates the method declaration `encode(to:)`
    /// for `Encodable` conformance implementation.
    ///
    /// The declaration is generated applying provided modifiers
    /// and using given expressions.
    ///
    /// - Parameters:
    ///   - modifiers: The modifiers to apply to the declaration.
    ///   - itemsBuilder: The result builder that builds expressions
    ///     in the declaration.
    ///
    /// - Returns: The generated method declaration.
    static func encode(
        modifiers: DeclModifierListSyntax,
        @CodeBlockItemListBuilder itemsBuilder: (TokenSyntax) throws -> CodeBlockItemListSyntax
    ) rethrows -> Self {
        let encoder: TokenSyntax = "encoder"
        let param = FunctionParameterSyntax(
            firstName: "to", secondName: encoder,
            type: IdentifierTypeSyntax(name: "any Encoder")
        )

        let signature = FunctionSignatureSyntax(
            parameterClause: .init(parameters: .init([param])),
            effectSpecifiers: .init(throwsSpecifier: .keyword(.throws))
        )

        return try FunctionDeclSyntax(
            modifiers: modifiers,
            name: "encode",
            signature: signature
        ) {
            for expr in try itemsBuilder(encoder) { expr }
        }
    }
}
