/// Indicates the field or enum/protocol identifier needs to be decoded and
/// encoded by the provided `helper` instance.
///
/// An instance confirming to ``HelperCoder`` can be provided
/// to allow decoding/encoding customizations or to provide decoding/encoding
/// to non-`Codable` types. i.e ``LossySequenceCoder`` that decodes
/// sequence from JSON ignoring invalid data matches instead of throwing error
/// (failing decoding of entire sequence).
///
/// For enums and protocols, applying this attribute means ``HelperCoder``
/// will be used to decode and encode identifier value in internally/adjacently
/// tagged data.
///
/// - Parameter helper: The value that performs decoding and encoding.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: The `helper`'s ``HelperCoder/Coded``
///   associated type must be the same as field type.
///
/// - Important: This attribute must be used combined with ``Codable()``
///   and ``CodedAt(_:)`` when applying to enums/protocols.
@attached(peer)
@available(swift 5.9)
public macro CodedBy<T: HelperCoder>(_ helper: T) =
    #externalMacro(module: "MacroPlugin", type: "CodedBy")
