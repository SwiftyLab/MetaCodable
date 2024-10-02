import SwiftSyntax

extension AttributeExpander {
    /// A type indicating various configurations available
    /// for `AttributeExpander`.
    ///
    /// These options are used as global level customization
    /// performed on the final generated implementation
    /// of `Codable` conformance.
    struct Options {
        /// The list of modifiers generator for
        /// conformance implementation declarations.
        let modifiersGenerator: DeclModifiersGenerator
        /// The list of `@available` attributes attached to
        /// original expanded declaration.
        let availableAttributes: [AttributeSyntax]

        /// Memberwise initialization generator with provided options.
        ///
        /// Creates memberwise initialization generator by passing
        /// the provided access modifiers.
        var initGenerator: MemberwiseInitGenerator {
            let modifiers = modifiersGenerator.generated
            return .init(options: .init(modifiers: modifiers))
        }

        /// Creates a new options instance with provided declaration group.
        ///
        /// - Parameters:
        ///   - decl: The declaration group options will be applied to.
        ///
        /// - Returns: The newly created options.
        init(for decl: some DeclGroupSyntax) {
            self.modifiersGenerator = .init(decl: decl)
            self.availableAttributes = decl.attributes.compactMap { attribute in
                switch attribute {
                case .attribute(let attr):
                    guard
                        attr.attributeName.trimmed.description == "available"
                    else { fallthrough }
                    return attr
                default:
                    return nil
                }
            }
        }
    }
}
