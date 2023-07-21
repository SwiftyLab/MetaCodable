/// Represents initialization is optional for the variable.
///
/// The variable must be mutable and initialized already.
struct OptionalInitialization: VariableInitialization {
    /// The value wrapped by this instance.
    ///
    /// Only function parameter and code block
    /// provided with`RequiredInitialization`
    /// can be wrapped by this instance.
    let base: RequiredInitialization

    /// Adds current initialization type to member-wise initialization generator.
    ///
    /// New member-wise initialization generator is created after adding this
    /// initialization as optional and returned.
    ///
    /// - Parameter generator: The init-generator to add in.
    /// - Returns: The modified generator containing this initialization.
    func add(to generator: MemberwiseInitGenerator) -> MemberwiseInitGenerator {
        generator.add(optional: .init(param: base.param, code: base.code))
    }
}
