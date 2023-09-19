/// A type-erased initialization type.
///
/// The `AnyInitialization` type forwards `VariableInitialization`
/// implementations to an underlying variable value, hiding the type of
/// the wrapped value.
struct AnyInitialization: VariableInitialization {
    /// The value wrapped by this instance.
    ///
    /// The base property can be cast back
    /// to its original type using type casting
    /// operators (`as?`, `as!`, or `as`).
    let base: VariableInitialization

    /// Adds current initialization type to memberwise initialization
    /// generator.
    ///
    /// New memberwise initialization generator is created after adding
    /// underlying initialization type and returned.
    ///
    /// - Parameter generator: The init-generator to add in.
    /// - Returns: The modified generator containing this initialization.
    func add(to generator: MemberwiseInitGenerator) -> MemberwiseInitGenerator {
        base.add(to: generator)
    }
}
