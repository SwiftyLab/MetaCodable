@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// A `TypeVariable` that provides `Codable` conformance
/// for a `class` type.
///
/// This type can be used for `class`es either not conforming to `Codable`
/// entirely or confirming to `Codable` with super class conformance.
struct ClassVariable: TypeVariable, DeclaredVariable {
    /// The member group used to generate conformance implementations.
    let group: MemberGroup<ClassDeclSyntax>
    /// The declaration used to create this variable.
    let decl: ClassDeclSyntax

    /// Creates a new variable from declaration and expansion context.
    ///
    /// Uses the class declaration with member group to generate conformances.
    ///
    /// - Parameters:
    ///   - decl: The declaration to read from.
    ///   - context: The context in which the macro expansion performed.
    init(from decl: ClassDeclSyntax, in context: some MacroExpansionContext) {
        self.group = .init(from: decl, in: context)
        self.decl = decl
    }

    /// Checks whether two protocol are the same.
    ///
    /// Compares two protocols, whether both are equal.
    ///
    /// - Parameters:
    ///   - protocol1: The first protocol type.
    ///   - protocol2: The second protocol type.
    ///
    /// - Returns: Whether the protocols are the same.
    private func areSameProtocol(
        _ protocol1: TypeSyntax, _ protocol2: TypeSyntax
    ) -> Bool {
        func identifierType(protocol: TypeSyntax) -> IdentifierTypeSyntax? {
            if let type = `protocol`.as(IdentifierTypeSyntax.self) {
                return type
            } else if let anyType = `protocol`.as(SomeOrAnyTypeSyntax.self),
                anyType.someOrAnySpecifier.tokenKind == .keyword(.any),
                let type = anyType.constraint.as(IdentifierTypeSyntax.self)
            {
                return type
            } else {
                return nil
            }
        }

        guard
            let identifierType1 = identifierType(protocol: protocol1),
            let identifierType2 = identifierType(protocol: protocol2)
        else { return false }
        return identifierType1.name.text == identifierType2.name.text
    }

    /// Checks whether class already conforms to `Decodable`.
    ///
    /// - Parameter location: The decoding location.
    /// - Returns: Whether class implements `Decodable` conformance.
    private func implementDecodable(location: TypeCodingLocation) -> Bool {
        return !decl.memberBlock.members.contains { member in
            guard
                let decl = member.decl.as(InitializerDeclSyntax.self),
                decl.signature.parameterClause.parameters.count == 1,
                let parameter = decl.signature.parameterClause.parameters.first,
                case let label = parameter.firstName.tokenKind,
                label == .identifier(location.method.argLabel.text),
                self.areSameProtocol(parameter.type, location.method.argType)
            else { return false }
            return true
        }
    }

    /// Checks whether class already conforms to `Encodable`.
    ///
    /// - Parameter location: The decoding location.
    /// - Returns: Whether class implements `Encodable` conformance.
    private func implementEncodable(location: TypeCodingLocation) -> Bool {
        return !decl.memberBlock.members.contains { member in
            guard
                let decl = member.decl.as(FunctionDeclSyntax.self),
                decl.name.text == location.method.name.text,
                decl.signature.parameterClause.parameters.count == 1,
                let parameter = decl.signature.parameterClause.parameters.first,
                case let label = parameter.firstName.tokenKind,
                label == .identifier(location.method.argLabel.text),
                self.areSameProtocol(parameter.type, location.method.argType)
            else { return false }
            return true
        }
    }

    /// Provides the syntax for decoding at the provided location.
    ///
    /// Uses member group to generate syntax, based on whether
    /// class has super class conforming `Codable`.
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
        let newLocation: TypeCodingLocation
        let overridden: Bool
        var modifiers: DeclModifierListSyntax = [.init(name: "required")]
        var code: CodeBlockItemListSyntax
        #if swift(>=5.9.2)
        if location.conformance == nil, implementDecodable(location: location) {
            let method = location.method
            let conformance = TypeSyntax(stringLiteral: method.protocol)
            newLocation = .init(method: method, conformance: conformance)
            overridden = true
            code = "try super.\(method.name)(\(method.argLabel): \(method.arg))"
        } else {
            newLocation = location
            overridden = false
            code = ""
        }
        #else
        let conformance = TypeSyntax(stringLiteral: location.method.protocol)
        newLocation = .init(method: location.method, conformance: conformance)
        overridden = false
        code = ""
        #endif
        guard
            let generated = group.decoding(in: context, from: newLocation)
        else { return nil }
        code.insert(contentsOf: generated.code, at: code.startIndex)
        modifiers.append(contentsOf: generated.modifiers)
        return .init(
            code: code, modifiers: modifiers,
            whereClause: generated.whereClause,
            inheritanceClause: overridden ? nil : generated.inheritanceClause
        )
    }

    /// Provides the syntax for encoding at the provided location.
    ///
    /// Uses member group to generate syntax, based on whether
    /// class has super class conforming `Codable`.
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
        let newLocation: TypeCodingLocation
        let overridden: Bool
        var modifiers: DeclModifierListSyntax
        var code: CodeBlockItemListSyntax
        #if swift(>=5.9.2)
        if location.conformance == nil, implementEncodable(location: location) {
            let method = location.method
            let conformance = TypeSyntax(stringLiteral: method.protocol)
            newLocation = .init(method: method, conformance: conformance)
            overridden = true
            modifiers = [.init(name: "override")]
            code = "try super.\(method.name)(\(method.argLabel): \(method.arg))"
        } else {
            newLocation = location
            overridden = false
            modifiers = []
            code = ""
        }
        #else
        let conformance = TypeSyntax(stringLiteral: location.method.protocol)
        newLocation = .init(method: location.method, conformance: conformance)
        overridden = false
        modifiers = []
        code = ""
        #endif
        guard
            let generated = group.encoding(in: context, to: newLocation)
        else { return nil }
        code.insert(contentsOf: generated.code, at: code.startIndex)
        modifiers.append(contentsOf: generated.modifiers)
        return .init(
            code: code, modifiers: modifiers,
            whereClause: generated.whereClause,
            inheritanceClause: overridden ? nil : generated.inheritanceClause
        )
    }

    /// Provides the syntax for `CodingKeys` declarations.
    ///
    /// Uses member group to generate `CodingKeys` declarations,
    /// based on whether class has super class conforming `Codable`.
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
        var protocols = protocols
        let decodableProtocol = TypeCodingLocation.Method.decode.protocol
        let encodableProtocol = TypeCodingLocation.Method.encode.protocol
        let decodable = self.protocol(named: decodableProtocol, in: protocols)
        let encodable = self.protocol(named: encodableProtocol, in: protocols)
        let dLoc = TypeCodingLocation(method: .decode, conformance: decodable)
        let eLoc = TypeCodingLocation(method: .encode, conformance: encodable)
        if decodable == nil, implementDecodable(location: dLoc) {
            protocols.append(.init(stringLiteral: decodableProtocol))
        }
        if encodable == nil, implementEncodable(location: eLoc) {
            protocols.append(.init(stringLiteral: encodableProtocol))
        }
        return group.codingKeys(confirmingTo: protocols, in: context)
    }
}
