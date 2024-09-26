/// A type that can be decoded/encoded dynamically based on unique identifier.
///
/// The type declared ``identifier`` is used to decode conformed type
/// if matches, and encode to represent data for the conformed type.
///
/// Conforming to this `protocol` allows type to be decoded/encoded dynamically
/// if it conforms to any additional `protocol`(s) that declare dynamic
/// decoding/encoding with attached ``Codable()`` macro, while the conformed
/// types can be declared in several different targets.
///
/// To use dynamic decoding, first declare a protocol with ``Codable()`` macro
/// attached that represents common data. i.e. for dynamic `Post` data:
///
/// ``` json
/// [
///   {
///     "id": "00005678-abcd-efab-0123-456789abcdef",
///     "type": "text",
///     "author": "12345678-abcd-efab-0123-456789abcdef",
///     "likes": 145,
///     "createdAt": "2021-07-23T07:36:43Z",
///     "text": "Lorem Ipsium"
///   },
///   {
///     "id": "43215678-abcd-efab-0123-456789abcdef",
///     "type": "picture",
///     "author": "abcd5678-abcd-efab-0123-456789abcdef",
///     "likes": 370,
///     "createdAt": "2021-07-23T09:32:13Z",
///     "url": "https://a.url.com/to/a/picture.png",
///     "caption": "Lorem Ipsium"
///   },
///   {
///     "id": "43215678-abcd-efab-0123-456789abcdef",
///     "type": "photo",
///     "author": "abcd5678-abcd-efab-0123-456789abcdef",
///     "likes": 370,
///     "createdAt": "2021-07-23T09:32:13Z",
///     "url": "https://a.url.com/to/a/picture.png",
///     "caption": "Lorem Ipsium"
///   },
///   {
///     "id": "64475bcb-caff-48c1-bb53-8376628b350b",
///     "type": "audio",
///     "author": "4c17c269-1c56-45ab-8863-d8924ece1d0b",
///     "likes": 25,
///     "createdAt": "2021-07-23T09:33:48Z",
///     "url": "https://a.url.com/to/a/audio.aac",
///     "duration": 60
///   },
///   {
///     "id": "98765432-abcd-efab-0123-456789abcdef",
///     "type": "video",
///     "author": "04355678-abcd-efab-0123-456789abcdef",
///     "likes": 2345,
///     "createdAt": "2021-07-23T09:36:38Z",
///     "url": "https://a.url.com/to/a/video.mp4",
///     "duration": 460,
///     "thumbnail": "https://a.url.com/to/a/thumbnail.png"
///   }
/// ]
/// ```
/// new protocol `Post` can be created, with the type of identifier tagging
/// (external, internal or adjacent) indicated, here tagging is `internal`.
/// Data type of identifier can also be specified with ``CodedAs()`` if
/// varies from `String`.
/// ```swift
/// @Codable
/// @CodedAt("type")
/// protocol Post {
///     var id: UUID { get }
///     var author: UUID { get }
///     var likes: Int { get }
///     var createdAt: String { get }
/// }
/// ```
/// Individual `Post` data type can be created conforming to `Post` and
/// `DynamicCodable`, specifying one or multiple identifier:
/// ```swift
/// @Codable
/// struct TextPost: Post, DynamicCodable {
///     static var identifier: DynamicCodableIdentifier<String> { "text" }
///
///     let id: UUID
///     let author: UUID
///     let likes: Int
///     let createdAt: String
///     let text: String
/// }
///
/// @Codable
/// struct PicturePost: Post, DynamicCodable {
///     static var identifier: DynamicCodableIdentifier<String> {
///         return ["picture", "photo"]
///     }
///
///     let id: UUID
///     let author: UUID
///     let likes: Int
///     let createdAt: String
///     let url: URL
///     let caption: String
/// }
///
/// @Codable
/// struct AudioPost: Post, DynamicCodable {
///     static var identifier: DynamicCodableIdentifier<String> { "audio" }
///
///     let id: UUID
///     let author: UUID
///     let likes: Int
///     let createdAt: String
///     let url: URL
///     let duration: Int
/// }
///
/// @Codable
/// struct VideoPost: Post, DynamicCodable {
///     static var identifier: DynamicCodableIdentifier<String> { "video" }
///
///     let id: UUID
///     let author: UUID
///     let likes: Int
///     let createdAt: String
///     let url: URL
///     let duration: Int
///     let thumbnail: URL
/// }
/// ```
/// Include `MetaProtocolCodable` build tool plugin to generate protocol
/// decoding/encoding ``HelperCoder`` named `\(protocolName)Coder`
/// where `\(protocolName)` is replaced with the protocol name.
public protocol DynamicCodable<IdentifierValue> {
    /// The type of identifier value.
    ///
    /// Represents the actual data type of the identifier.
    ///
    /// - Important: This type must match ``CodedAs()`` or ``CodedBy(_:)``
    ///   requirements if these macros are attached to the original dynamic
    ///   `protocol`, otherwise this type must be `String`.
    associatedtype IdentifierValue: Equatable & Sendable
    /// The identifier value(s) for this type.
    ///
    /// Type can declare one or many identifier values. In case of multiple
    /// identifiers, type is decoded if any of the identifier match, while only
    /// the first identifier is used when encoding.
    static var identifier: DynamicCodableIdentifier<IdentifierValue> { get }
}
