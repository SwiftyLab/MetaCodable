import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A type managing registrations of variable and `CodingKey` data.
///
/// Use `add` method to register new data and
/// use `decoding`, `encoding` and `codingKeys` methods
/// to get final generated implementation of `Codable` conformance.
struct AttributeExpander {
    /// The variable that is expanded.
    ///
    /// Expands a specific type created from
    /// the declaration provided.
    let variable: any TypeVariable
    /// The options to use when generating declarations.
    private let options: Options

    /// Creates a new registrar with provided data.
    ///
    /// The variable to be expanded is read from the declaration provided.
    ///
    /// - Parameters:
    ///   - declaration: The declaration to read the variable data from.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The newly created registrar instance.
    init?(
        for declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) {
        guard
            let decl = declaration as? any VariableSyntax,
            case let variable = decl.codableVariable(
                in: context
            ) as any DeclaredVariable,
            let typeVar = variable as? any TypeVariable
        else { return nil }
        self.variable = typeVar
        self.options = .init(for: declaration)
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
        let dProtocol = TypeCodingLocation.Method.decode().protocol
        let eProtocol = TypeCodingLocation.Method.encode.protocol
        let decodable = variable.protocol(named: dProtocol, in: protocols)
        let encodable = variable.protocol(named: eProtocol, in: protocols)

        var extensions = [
            decoding(type: type, conformingTo: decodable, in: context),
            encoding(type: type, conformingTo: encodable, in: context),
            codingKeys(for: type, confirmingTo: protocols, in: context),
        ].compactMap { $0 }
        for index in extensions.indices {
            // attach available attributes from original declaration
            // to generated expanded declaration
            extensions[index].attributes = AttributeListSyntax {
                for attr in options.availableAttributes {
                    .attribute(attr)
                }
                extensions[index].attributes
            }
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
        conformingTo protocol: TypeSyntax?,
        in context: some MacroExpansionContext
    ) -> ExtensionDeclSyntax? {
        let method = TypeCodingLocation.Method.decode()
        let location = TypeCodingLocation(
            method: method, conformance: `protocol`
        )
        guard
            let generated = variable.decoding(in: context, from: location)
        else { return nil }

        let param = FunctionParameterSyntax(
            firstName: method.argLabel, secondName: method.arg,
            type: method.argType
        )

        #if canImport(SwiftSyntax600)
        let signature = FunctionSignatureSyntax(
            parameterClause: .init(parameters: .init([param])),
            effectSpecifiers: .init(
                throwsClause: .init(throwsSpecifier: .keyword(.throws))
            )
        )
        #else
        let signature = FunctionSignatureSyntax(
            parameterClause: .init(parameters: .init([param])),
            effectSpecifiers: .init(throwsSpecifier: .keyword(.throws))
        )
        #endif

        let modifiers = DeclModifierListSyntax {
            options.modifiersGenerator.generated
            generated.modifiers
        }
        return .init(
            extendedType: type,
            inheritanceClause: generated.inheritanceClause,
            genericWhereClause: generated.whereClause
        ) {
            InitializerDeclSyntax(
                modifiers: modifiers, signature: signature,
                genericWhereClause: generated.whereClause
            ) {
                generated.code
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
        conformingTo protocol: TypeSyntax?,
        in context: some MacroExpansionContext
    ) -> ExtensionDeclSyntax? {
        let method = TypeCodingLocation.Method.encode
        let location = TypeCodingLocation(
            method: method, conformance: `protocol`
        )
        guard
            let generated = variable.encoding(in: context, to: location)
        else { return nil }

        let param = FunctionParameterSyntax(
            firstName: method.argLabel, secondName: method.arg,
            type: method.argType
        )

        #if canImport(SwiftSyntax600)
        let signature = FunctionSignatureSyntax(
            parameterClause: .init(parameters: .init([param])),
            effectSpecifiers: .init(
                throwsClause: .init(throwsSpecifier: .keyword(.throws))
            )
        )
        #else
        let signature = FunctionSignatureSyntax(
            parameterClause: .init(parameters: .init([param])),
            effectSpecifiers: .init(throwsSpecifier: .keyword(.throws))
        )
        #endif

        let modifiers = DeclModifierListSyntax {
            options.modifiersGenerator.generated
            generated.modifiers
        }
        return .init(
            extendedType: type,
            inheritanceClause: generated.inheritanceClause,
            genericWhereClause: generated.whereClause
        ) {
            FunctionDeclSyntax(
                modifiers: modifiers, name: method.name, signature: signature,
                genericWhereClause: generated.whereClause
            ) {
                generated.code
            }
        }
    }

    /// Provides the declaration of `CodingKey` type that is used
    /// for `Codable` implementation generation.
    ///
    /// This registrar asks `variable` to generate `CodingKey`
    /// declaration based on current keys registrations.
    ///
    /// - Parameters:
    ///   - type: The type for which extensions provided.
    ///   - context: The context in which to perform the macro expansion.
    ///
    /// - Returns: The generated enum declaration.
    func codingKeys(
        for type: some TypeSyntaxProtocol,
        confirmingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) -> ExtensionDeclSyntax? {
        let members = variable.codingKeys(confirmingTo: protocols, in: context)
        guard !members.isEmpty else { return nil }
        return .init(extendedType: type) { members }
    }

    /// Provides the memberwise initializer declaration(s).
    ///
    /// - Parameter context: The context in which to perform
    ///   the macro expansion.
    /// - Returns: The generated initializer declarations.
    func memberInit(
        in context: some MacroExpansionContext
    ) -> [InitializerDeclSyntax] {
        guard
            let variable = variable as? any InitializableVariable,
            let initializations = variable.initializing(in: context)
                as? [AnyInitialization]
        else { return [] }

        var generator = options.initGenerator
        for initialization in initializations {
            generator = initialization.add(to: generator)
        }
        return generator.declarations(in: context)
    }
}
