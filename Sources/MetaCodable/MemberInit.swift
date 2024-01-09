/// Generate memberwise initializer(s) of `struct` and `actor` types
/// by leveraging custom attributes provided on variable declarations.
///
/// By default the memberwise initializer(s) generated are the same as generated
/// by Swift standard library. Following customization can be done on fields to
/// provide custom memberwise initializer(s):
///   * Use ``Default(_:)`` to provide default value in function parameters
///     of memberwise initializer(s).
///
/// - Important: The attached declaration must be of a struct type.
@attached(member, names: named(init))
@available(swift 5.9)
public macro MemberInit() =
    #externalMacro(module: "MacroPlugin", type: "MemberInit")
