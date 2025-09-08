/// Dynamic variation of CodedAs macro that accepts AnyCodableLiteral type variable arguments.
///
/// This macro provides a more flexible version of ``CodedAs(_:_:)-8wdaz`` that can
/// accept literal values of any type through the ``AnyCodableLiteral`` type. This
/// enables compile-time processing of mixed literal types while maintaining type safety.
///
/// ## Usage
///
/// This macro can be used in the same contexts as the regular ``CodedAs(_:_:)-8wdaz``
/// macro but with the added flexibility of accepting different literal types:
///
/// ```swift
/// @Codable
/// enum MixedCommand {
///     @CodedAs("load", 1, true)
///     case load(key: String)
///
///     @CodedAs("store", 2, false)
///     case store(key: String, value: Int)
/// }
/// ```
///
/// The macro processes the literal values at compile-time and generates appropriate
/// code for encoding and decoding operations.
///
/// ## Type Safety
///
/// While this macro accepts ``AnyCodableLiteral`` arguments, the actual type checking
/// and code generation happens at compile-time through macro expansion. The runtime
/// behavior is identical to the regular ``CodedAs(_:_:)-8wdaz`` macro.
///
/// ## Compile-Time Processing
///
/// The ``AnyCodableLiteral`` values are processed during macro expansion:
/// - Literal values are extracted and converted to appropriate types
/// - Type consistency is validated at compile-time
/// - Generated code uses concrete types, not ``AnyCodableLiteral``
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable(commonStrategies:)`` macro uses this macro
///   when generating final implementations for enum types.
///
/// - Important: The ``AnyCodableLiteral`` arguments are processed at compile-time
///   and never instantiated at runtime. All runtime safety is maintained through
///   the macro expansion process.
///
/// - Important: This attribute must be used combined with ``Codable(commonStrategies:)``
///   and ``CodedAt(_:)`` in the same way as the regular ``CodedAs(_:_:)-8wdaz`` macro
///   for enum types.
///
/// - Important: This attribute must not be combined with ``CodedAs()`` macro.
@attached(peer)
@available(swift 5.9)
public macro CodedAs(_ values: AnyCodableLiteral, _: AnyCodableLiteral...) =
    #externalMacro(module: "MacroPlugin", type: "CodedAs")
