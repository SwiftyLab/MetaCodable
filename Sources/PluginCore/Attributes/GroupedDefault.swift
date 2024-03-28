@_implementationOnly import SwiftSyntax
@_implementationOnly import SwiftSyntaxMacros

/// Attribute type for `GroupedDefault` macro-attribute.
///
/// This type can validate`GroupedDefault` macro-attribute
/// usage and extract data for `Codable` macro to
/// generate implementation.
package struct GroupedDefault: PropertyAttribute {
    /// The node syntax provided
    /// during initialization.
    let node: AttributeSyntax

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
            attachedToGroupedVariable()
            attachedToNonStaticVariable()
            cantDuplicate()
            cantBeCombined(with: IgnoreCoding.self)
        }
    }
}

extension Registration
where
Decl == PropertyDeclSyntax, Var: PropertyVariable & InitializableVariable, Var.Initialization == AnyRequiredVariableInitialization, Var == AnyPropertyVariable<AnyRequiredVariableInitialization>
{
    /// Update registration with binding initializer value.
    ///
    /// New registration is updated with default expression data that will be
    /// used for decoding failure and memberwise initializer(s), if provided.
    ///
    /// - Returns: Newly built registration with default expression data or self.
    func addDefaultValueIfInitializerExists() -> Self {
        guard Default(from: self.decl) == nil, GroupedDefault(from: self.decl) == nil, let value = decl.binding.initializer?.value, let variable = self.variable.base as? AnyPropertyVariable<RequiredInitialization> else {
            return self
        }
        
        let newVar = variable.with(default: value)
        return self.updating(with: newVar.any)
    }
    
    /// Update registration with pattern binding default values if exists.
    ///
    /// New registration is updated with default expression data that will be
    /// used for decoding failure and memberwise initializer(s), if provided.
    ///
    /// - Returns: Newly built registration with default expression data or self.
    func addGroupedDefaultIfExists() -> Self {
        guard let defaults = GroupedDefault(from: self.decl) else {
            return self
        }
        
        var i: Int = 0
        for (index, binding) in self.decl.decl.bindings.enumerated() {
            if binding.pattern.description == self.decl.binding.pattern.description {
                i = index
                break
            }
        }
        
        guard let variable = self.variable.base as? AnyPropertyVariable<RequiredInitialization>
        else { return self }

        let newVar = variable.with(default: defaults.exprs[i])
        return self.updating(with: newVar.any)
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
