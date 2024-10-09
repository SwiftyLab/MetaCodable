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
/// - Important: When using with enums and protocols if ``HelperCoder/Coded``
///   is other than `String` type must be provided with ``CodedAs()`` macro.
///
/// - Important: This attribute must be used combined with ``Codable()``
///   and ``CodedAt(_:)`` when applying to enums/protocols.
@attached(peer)
@available(swift 5.9)
public macro CodedBy<T: HelperCoder>(_ helper: T) =
    #externalMacro(module: "MacroPlugin", type: "CodedBy")

/// Indicates the field needs to be decoded and encoded by the created `helper`
/// instance from provided arguments.
///
/// This can be used for decoding/encoding transformation based on properties
/// as an alternative to ``CodedBy(_:)`` macro. i.e. data transformations
/// based on specific version:
/// ```swift
/// @Codable
/// struct Dog {
///     let name: String
///     @Default(1)
///     let version: Int
///     @CodedBy(Info.VersionBasedTag.init, properties: \Dog.version)
///     let info: Info
///
///     @Codable
///     struct Info {
///         private(set) var tag: Int
///
///         struct VersionBasedTag: HelperCoder {
///             let version: Int
///
///             func decode(from decoder: any Decoder) throws -> Info {
///                 var info = try Info(from: decoder)
///                 info.tag += version >= 2 ? 1 : 0
///                 return info
///             }
///
///             func encode(_ value: Info, to encoder: any Encoder) throws {
///                 var info = value
///                 info.tag -= version >= 2 ? 1 : 0
///                 try info.encode(to: encoder)
///             }
///         }
///     }
/// }
/// ```
///
/// - Parameters:
///   - helperCreation: The function that will create the helper expression.
///   - properties: The key path to properties passed to the creation action.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: The `Parent` type must be the current `struct`/`class`/`actor`
///   type. The `Helper` type's ``HelperCoder/Coded`` associated type must be
///   the same as field type. Only stored `Property` types are supported.
@attached(peer)
@available(swift 5.9)
public macro CodedBy<Parent, Helper: HelperCoder, each Property>(
    _ helperCreation: (repeat each Property) -> Helper,
    properties: repeat KeyPath<Parent, each Property>
) = #externalMacro(module: "MacroPlugin", type: "CodedBy")

/// Indicates the field needs to be decoded and encoded by the created `helper`
/// instance from provided arguments.
///
/// This can be used for decoding/encoding transformation based on additional
/// arguments and properties as an alternative to ``CodedBy(_:)`` and
/// ``CodedBy(_:properties:)`` macros. i.e. passing data to a sequence
/// of child container items:
/// ```swift
/// @Codable
/// struct Item: Identifiable {
///     let title: String
///     @CodedBy(
///         SequenceCoder.init, arguments: Image.IdentifierCoder.init,
///         .lossy, properties: \Item.id
///     )
///     let images: [Image]
///     let id: String
///
///     @Codable
///     struct Image: Identifiable {
///         var id: String { identifier }
///
///         @IgnoreCoding
///         private(set) var identifier: String!
///         let width: Int
///         let height: Int
///
///         struct IdentifierCoder: HelperCoder {
///             let id: String
///
///             func decode(from decoder: any Decoder) throws -> Image {
///                 var image = try Image(from: decoder)
///                 image.identifier = id
///                 return image
///             }
///
///             func encode(_ value: Image, to encoder: any Encoder) throws
///             {
///                 var image = value
///                 image.identifier = nil
///                 try image.encode(to: encoder)
///             }
///         }
///     }
/// }
/// ```
///
/// - Parameters:
///   - helperCreation: The function that will create the helper expression.
///   - arguments: Additional arguments first passed to the creation action.
///   - properties: The key path to properties passed to the creation action.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: The `Parent` type must be the current `struct`/`class`/`actor`
///   type. The `Helper` type's ``HelperCoder/Coded`` associated type must be
///   the same as field type. Only stored `Property` types are supported.
@attached(peer)
@available(swift 5.9)
public macro CodedBy<Parent, Helper: HelperCoder, each Argument, each Property>(
    _ helperCreation: (repeat each Argument, repeat each Property) -> Helper,
    arguments: repeat each Argument,
    properties: repeat KeyPath<Parent, each Property>
) = #externalMacro(module: "MacroPlugin", type: "CodedBy")

/// Indicates the field needs to be decoded and encoded by the created `helper`
/// instance from provided arguments.
///
/// This can be used for decoding/encoding transformation based on additional
/// arguments and properties as an alternative to ``CodedBy(_:)`` and
/// ``CodedBy(_:properties:)`` macros.
///
/// - Parameters:
///   - helperCreation: The function that will create the helper expression.
///   - argument1: Additional argument first passed to the creation action.
///   - properties: The key path to properties passed to the creation action.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: The `Parent` type must be the current `struct`/`class`/`actor`
///   type. The `Helper` type's ``HelperCoder/Coded`` associated type must be
///   the same as field type. Only stored `Property` types are supported.
///
/// - SeeAlso: ``CodedBy(_:arguments:properties:)-7j53l``
@attached(peer)
@available(swift 5.9)
public macro CodedBy<Parent, Helper: HelperCoder, Argument1, each Property>(
    _ helperCreation: (Argument1, repeat each Property) -> Helper,
    arguments argument1: Argument1,
    properties: repeat KeyPath<Parent, each Property>
) = #externalMacro(module: "MacroPlugin", type: "CodedBy")

/// Indicates the field needs to be decoded and encoded by the created `helper`
/// instance from provided arguments.
///
/// This can be used for decoding/encoding transformation based on additional
/// arguments and properties as an alternative to ``CodedBy(_:)`` and
/// ``CodedBy(_:properties:)`` macros.
///
/// - Parameters:
///   - helperCreation: The function that will create the helper expression.
///   - argument1: Additional argument first passed to the creation action.
///   - argument2: Additional argument passed second to the creation action.
///   - properties: The key path to properties passed to the creation action.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: The `Parent` type must be the current `struct`/`class`/`actor`
///   type. The `Helper` type's ``HelperCoder/Coded`` associated type must be
///   the same as field type. Only stored `Property` types are supported.
///
/// - SeeAlso: ``CodedBy(_:arguments:properties:)-7j53l``
@attached(peer)
@available(swift 5.9)
public macro CodedBy<
    Parent, Helper: HelperCoder, Argument1, Argument2, each Property
>(
    _ helperCreation: (Argument1, Argument2, repeat each Property) -> Helper,
    arguments argument1: Argument1, _ argument2: Argument2,
    properties: repeat KeyPath<Parent, each Property>
) = #externalMacro(module: "MacroPlugin", type: "CodedBy")

/// Indicates the field needs to be decoded and encoded by the created `helper`
/// instance from provided arguments.
///
/// This can be used for decoding/encoding transformation based on additional
/// arguments and properties as an alternative to ``CodedBy(_:)`` and
/// ``CodedBy(_:properties:)`` macros.
///
/// - Parameters:
///   - helperCreation: The function that will create the helper expression.
///   - argument1: Additional argument first passed to the creation action.
///   - argument2: Additional argument passed second to the creation action.
///   - argument3: Additional argument passed third to the creation action.
///   - properties: The key path to properties passed to the creation action.
///
/// - Note: This macro on its own only validates if attached declaration
///   is a variable declaration. ``Codable()`` macro uses this macro
///   when generating final implementations.
///
/// - Important: The `Parent` type must be the current `struct`/`class`/`actor`
///   type. The `Helper` type's ``HelperCoder/Coded`` associated type must be
///   the same as field type. Only stored `Property` types are supported.
///
/// - SeeAlso: ``CodedBy(_:arguments:properties:)-7j53l``
@attached(peer)
@available(swift 5.9)
public macro CodedBy<
    Parent, Helper: HelperCoder, Argument1, Argument2, Argument3, each Property
>(
    _ helperCreation: (Argument1, Argument2, Argument3, repeat each Property) ->
        Helper,
    arguments argument1: Argument1, _ argument2: Argument2,
    _ argument3: Argument3, properties: repeat KeyPath<Parent, each Property>
) = #externalMacro(module: "MacroPlugin", type: "CodedBy")
