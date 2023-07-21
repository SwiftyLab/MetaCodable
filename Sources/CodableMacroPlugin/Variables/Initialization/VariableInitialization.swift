/// Represents the initialization type for `Variable`s inside type declarations.
///
/// Represents whether `Variable`s are required to be initialized
/// or initialization is optional. `Variable`s can also ignore initialization
/// if initialized already.
protocol VariableInitialization {
    /// Adds current initialization type to member-wise initialization generator.
    ///
    /// New member-wise initialization generator is created after adding this
    /// initialization type and returned.
    ///
    /// - Parameter generator: The init-generator to add in.
    /// - Returns: The modified generator containing this initialization.
    func add(to generator: MemberwiseInitGenerator) -> MemberwiseInitGenerator
}

extension VariableInitialization {
    /// Erases type for initialization type.
    ///
    /// Converts current initialization type to
    /// type-erased `AnyInitialization`.
    var any: AnyInitialization {
        return .init(base: self)
    }
}
