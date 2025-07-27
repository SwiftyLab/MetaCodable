import SwiftSyntax
import SwiftSyntaxMacros

/// Finds and stores common strategies from a type declaration's macro attributes.
///
/// This struct parses the macro attributes on a type declaration to extract any
/// common type conversion strategies (such as value coding strategies) that should
/// be applied to all properties. The extracted strategies can then be used to
/// automatically transform property registrations during macro expansion.
struct StrategyFinder {
    /// The list of value coding strategies (as type names) to apply to properties.
    let valueCodingStrategies: [TokenSyntax]
    // Extend with more strategies as needed

    /// Initializes a new `StrategyFinder` by parsing the macro attributes of the given declaration.
    ///
    /// - Parameter decl: The declaration to extract strategies from.
    init(decl: some AttributableDeclSyntax) {
        guard
            let attr: any PeerAttribute = Codable(from: decl)
                ?? ConformDecodable(from: decl) ?? ConformEncodable(from: decl),
            let arguments = attr.node.arguments?.as(LabeledExprListSyntax.self),
            let arg = arguments.first(where: {
                $0.label?.text == "commonStrategies"
            }),
            let expr = arg.expression.as(ArrayExprSyntax.self)
        else {
            self.valueCodingStrategies = []
            return
        }

        let codedBys = expr.elements.lazy
            .compactMap({ $0.expression.as(FunctionCallExprSyntax.self) })
            .filter({
                $0.calledExpression.as(MemberAccessExprSyntax.self)?.declName
                    .baseName.text == "codedBy"
            })
        let valueCoders = codedBys.flatMap({
            $0.arguments
                .compactMap({ $0.expression.as(FunctionCallExprSyntax.self) })
                .filter({
                    $0.calledExpression.as(MemberAccessExprSyntax.self)?
                        .declName.baseName.text == "valueCoder"
                })
        })

        var valueCodingStrategies: [TokenSyntax] = []
        if !valueCoders.isEmpty {
            // Default strategies for primitive types
            valueCodingStrategies = [
                "Bool", "Double", "Float", "String",
                "Int", "Int8", "Int16", "Int32", "Int64",
                "UInt", "UInt8", "UInt16", "UInt32", "UInt64",
            ]
            // Add any additional types specified in valueCoder(...)
            valueCodingStrategies.append(
                contentsOf: valueCoders.flatMap {
                    $0.arguments.first?.expression.as(ArrayExprSyntax.self)?
                        .elements.compactMap {
                            $0.expression.as(MemberAccessExprSyntax.self)?.base?
                                .as(DeclReferenceExprSyntax.self)?.baseName
                        } ?? []
                }
            )
        }
        self.valueCodingStrategies = valueCodingStrategies
    }
}

extension Registration where Var: DefaultPropertyVariable {
    /// Applies common strategies (such as value coding) to the property registration if the type declaration specifies them.
    ///
    /// This method uses `StrategyFinder` to extract any common strategies (e.g., value coding strategies)
    /// from the macro attributes of the provided type declaration. If the property's type matches one of the
    /// strategies, it wraps the property in a `HelperCodedVariable` using the appropriate helper (such as `ValueCoder`).
    ///
    /// - Parameter decl: The type declaration to extract strategies from.
    /// - Returns: A new registration, possibly wrapping the property variable with a strategy-based helper.
    func detectCommonStrategies(
        from decl: some AttributableDeclSyntax
    ) -> Registration<Decl, Key, StrategyVariable<Var.Initialization>> {
        let finder = StrategyFinder(decl: decl)
        let type = finder.valueCodingStrategies.first { strategy in
            return strategy.trimmedDescription
                == self.variable.type.trimmedDescription
                || strategy.trimmedDescription
                    == self.variable.type.wrappedType.trimmedDescription
        }

        let newVariable: AnyPropertyVariable<Var.Initialization>
        if let type = type {
            newVariable =
                HelperCodedVariable(
                    base: self.variable,
                    options: .helper("ValueCoder<\(type)>()")
                ).any
        } else {
            newVariable = self.variable.any
        }
        return self.updating(with: StrategyVariable(base: newVariable))
    }
}
