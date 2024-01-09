import Foundation
import HelperCoders
import MetaCodable

@Codable
protocol ExtPost {
    var id: UUID { get }
    var author: UUID { get }
    var likes: Int { get }
    var createdAt: String { get }
}

@Codable
@CodedAs<String>
@CodedAt("type")
protocol IntPost {
    var id: UUID { get }
    var author: UUID { get }
    var likes: Int { get }
    var createdAt: String { get }
}

@Codable
@CodedAt("type")
@ContentAt("content")
protocol AdjPost {
    var id: UUID { get }
    var author: UUID { get }
    var likes: Int { get }
    var createdAt: String { get }
}

@Codable
struct TextPost: ExtPost, IntPost, AdjPost, DynamicCodable {
    static var identifier: DynamicCodableIdentifier<String> { "text" }

    let id: UUID
    let author: UUID
    let likes: Int
    let createdAt: String
    let text: String
}

@Codable
struct PicturePost: ExtPost, IntPost, AdjPost, DynamicCodable {
    static var identifier: DynamicCodableIdentifier<String> {
        return ["picture", "photo"]
    }

    let id: UUID
    let author: UUID
    let likes: Int
    let createdAt: String
    let url: URL
    let caption: String
}

@Codable
struct AudioPost: ExtPost, IntPost, AdjPost, DynamicCodable {
    static var identifier: DynamicCodableIdentifier<String> { "audio" }

    let id: UUID
    let author: UUID
    let likes: Int
    let createdAt: String
    let url: URL
    let duration: Int
}

@Codable
struct VideoPost: ExtPost, IntPost, AdjPost, DynamicCodable {
    static var identifier: DynamicCodableIdentifier<String> { "video" }

    let id: UUID
    let author: UUID
    let likes: Int
    let createdAt: String
    let url: URL
    let duration: Int
    let thumbnail: URL
}

@IgnoreCoding
struct InvalidPost: ExtPost, IntPost, AdjPost {
    let id: UUID
    let author: UUID
    let likes: Int
    let createdAt: String
    let invalid: Bool
}

struct Nested {
    @Codable
    struct ValidPost: ExtPost, IntPost, AdjPost, DynamicCodable {
        static var identifier: DynamicCodableIdentifier<String> { "nested" }

        let id: UUID
        let author: UUID
        let likes: Int
        let createdAt: String
    }
}

@Codable
struct PageWithIntPosts {
    @CodedAt("content")
    let items: [PostItem]

    @Codable
    struct PostItem {
        @CodedAt
        @CodedBy(IntPostCoder())
        let data: IntPost
    }
}

@Codable
struct PageWithExtPosts {
    @CodedAt("content")
    let items: [PostItem]

    @Codable
    struct PostItem {
        @CodedAt
        @CodedBy(ExtPostCoder())
        let data: ExtPost
    }
}

@Codable
struct PageWithAdjPosts {
    @CodedAt("content")
    let items: [PostItem]

    @Codable
    struct PostItem {
        @CodedAt
        @CodedBy(AdjPostCoder())
        let data: AdjPost
    }
}
