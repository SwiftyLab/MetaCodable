/// Represents initialization must be ignored for the variable.
///
/// The variable needs to be already initialized and immutable
/// or a computed property.
struct IgnoredInitialization: VariableInitialization {
    /// Adds current initialization type to member-wise initialization
    /// generator.
    ///
    /// The passed generator is passed as-is since this type ignores
    /// any initialization.
    ///
    /// - Parameter generator: The init-generator to add in.
    /// - Returns: The provided member-wise initialization generator.
    func add(to generator: MemberwiseInitGenerator) -> MemberwiseInitGenerator {
        return generator
    }
}
