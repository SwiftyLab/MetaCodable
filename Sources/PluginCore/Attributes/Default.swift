import SwiftSyntax

/// Attribute type for `Default` macro-attribute.
///
/// This type can validate`Default` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
package struct Default: PropertyAttribute {
    /// The node syntax provided
    /// during initialization.
    let node: AttributeSyntax

    /// The default value expression provided.
    var expr: ExprSyntax {
        exprs.first!
    }
    
    /// The default value expressions provided.
    var exprs: [ExprSyntax] {
        node.arguments!.as(LabeledExprListSyntax.self)!.map {
            $0.expression
        }
    }

    /// Creates a new instance with the provided node.
    ///
    /// The initializer fails to create new instance if the name
    /// of the provided node is different than this attribute.
    ///
    /// - Parameter node: The attribute syntax to create with.
    /// - Returns: Newly created attribute instance.
    init?(from node: AttributeSyntax) {
        guard
            node.attributeName.as(IdentifierTypeSyntax.self)!
                .name.text == Self.name
        else { return nil }
        self.node = node
    }

    /// Builds diagnoser that can validate this macro
    /// attached declaration.
    ///
    /// The following conditions are checked by the
    /// built diagnoser:
    /// * Attached declaration is a variable declaration.
    /// * Attached declaration is not a static variable
    ///   declaration
    /// * Macro usage is not duplicated for the same
    ///   declaration.
    /// * This attribute isn't used combined with
    ///   `IgnoreCoding` attribute.
    ///
    /// - Returns: The built diagnoser instance.
    func diagnoser() -> DiagnosticProducer {
        return AggregatedDiagnosticProducer {
            DefaultAttributeDeclaration<Self>(self)
            attachedToNonStaticVariable()
            cantDuplicate()
            cantBeCombined(with: IgnoreCoding.self)
        }
    }
}

extension Registration
where
    Decl: AttributableDeclSyntax, Var: PropertyVariable,
    Var.Initialization == RequiredInitialization
{
    /// The variable data with default expression
    /// that output registration will have.
    typealias DefOutput = AnyPropertyVariable<AnyRequiredVariableInitialization>
    /// Update registration with default value if exists.
    ///
    /// New registration is updated with default expression data that will be
    /// used for decoding failure and memberwise initializer(s), if provided.
    ///
    /// - Returns: Newly built registration with default expression data.
    func addDefaultValueIfExists() -> Registration<Decl, Key, DefOutput> {
        guard let attr = Default(from: self.decl)
        else { return self.updating(with: self.variable.any) }
        let newVar = self.variable.with(default: attr.expr)
        return self.updating(with: newVar.any)
    }
}

extension Registration
where
    Decl == PropertyDeclSyntax, Var: PropertyVariable,
    Var.Initialization == RequiredInitialization
{
    /// Update registration with default value if exists.
    ///
    /// New registration is updated with default expression data that will be
    /// used for decoding failure and memberwise initializer(s), if provided.
    ///
    /// - Returns: Newly built registration with default expression data.
    func addDefaultValueIfExists() -> Registration<Decl, Key, AnyPropertyVariable<AnyRequiredVariableInitialization>> {
        guard let attr = Default(from: self.decl)
        else { return self.updating(with: self.variable.any) }
        
        var i: Int = 0
        for (index, binding) in self.decl.decl.bindings.enumerated() {
            if binding.pattern == self.decl.binding.pattern {
                i = index
                break
            }
        }
        
        if i < attr.exprs.count {
            let newVar = self.variable.with(default: attr.exprs[i])
            return self.updating(with: newVar.any)
        }
        
        return self.updating(with: self.variable.any)
    }
}

fileprivate extension PropertyVariable
where Initialization == RequiredInitialization {
    /// Update variable data with the default value expression provided.
    ///
    /// `DefaultValueVariable` is created with this variable as base
    /// and default expression provided.
    ///
    /// - Parameter expr: The default expression to add.
    /// - Returns: Created variable data with default expression.
    func with(default expr: ExprSyntax) -> DefaultValueVariable<Self> {
        return .init(base: self, options: .init(expr: expr))
    }
}

@_implementationOnly import SwiftDiagnostics
@_implementationOnly import SwiftSyntaxMacros
/// A diagnostic producer type that can validate the ``Default`` attribut's number of parameters.
///
/// - Note: This producer also validates passed syntax is of variable
///   declaration type. No need to pass additional diagnostic producer
///   to validate this.
fileprivate struct DefaultAttributeDeclaration<Attr: PropertyAttribute>: DiagnosticProducer {
    /// The attribute for which
    /// validation performed.
    ///
    /// Uses this attribute name
    /// in generated diagnostic
    /// messages.
    let attr: Attr

    /// Underlying producer that validates passed syntax is variable
    /// declaration.
    ///
    /// This diagnostic producer is used first to check if passed declaration is
    /// variable declaration. If validation failed, then further validation by
    /// this type is terminated.
    let base: InvalidDeclaration<Attr>
    
    /// Creates a grouped variable declaration validation instance
    /// with provided attribute.
    ///
    /// Underlying variable declaration validation instance is created
    /// and used first. Post the success of base validation this type
    /// performs validation.
    ///
    /// - Parameter attr: The attribute for which
    ///   validation performed.
    /// - Returns: Newly created diagnostic producer.
    init(_ attr: Attr) {
        self.attr = attr
        self.base = .init(attr, expect: [VariableDeclSyntax.self])
    }

    /// Validates and produces diagnostics for the passed syntax
    /// in the macro expansion context provided.
    ///
    /// Check whether the number of parameters of the application's ``Default`` attribute corresponds to the number of declared variables.
    ///
    /// - Parameters:
    ///   - syntax: The syntax to validate and produce diagnostics for.
    ///   - context: The macro expansion context diagnostics produced in.
    ///
    /// - Returns: True if syntax fails validation, false otherwise.
    @discardableResult
    func produce(
        for syntax: some SyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> Bool {
        guard !base.produce(for: syntax, in: context) else { return true }
        let decl = syntax.as(VariableDeclSyntax.self)!
        let bindingsCount = decl.bindings.count
        
        let attributeArgumentsCount = self.attr.node.arguments?.as(LabeledExprListSyntax.self)?.count ?? 0
        
        guard bindingsCount != attributeArgumentsCount
        else { return false }
        
        var msg: String
        if bindingsCount - attributeArgumentsCount < 0 {
            msg = "@\(attr.name) expect \(bindingsCount) default \(bindingsCount > 1 ? "values" : "value") but found \(attributeArgumentsCount) !"
        } else if bindingsCount - attributeArgumentsCount == 1 {
            msg = "@\(attr.name) missing default value for variable "
        } else {
            msg = "@\(attr.name) missing default values for variables "
        }
        
        for (i, binding) in decl.bindings.enumerated() where binding.pattern.is(IdentifierPatternSyntax.self) {
            if i >= attributeArgumentsCount {
                msg += "'\(binding.pattern.trimmed.description)'"
                if i < decl.bindings.count - 1 {
                    msg += ", "
                }
            }
        }
        
        let message = attr.diagnostic(
            message:
                msg,
            id: attr.misuseMessageID,
            severity: .error
        )
        attr.diagnose(message: message, in: context)
        return true
    }
}
