import MetaCodable

@Codable
protocol Post {
    var id: UUID { get }
}

typealias Identifier =
    DynamicCodableIdentifier<String>

@Codable
struct TextPost: Post, DynamicCodable {
    static var identifier: Identifier {
        return "text"
    }

    let id: UUID
    let text: String
}

@Codable
struct PicturePost: Post, DynamicCodable {
    static var identifier: Identifier {
        return "picture"
    }

    let id: UUID
    let url: URL
    let caption: String
}

@Codable
struct AudioPost: Post, DynamicCodable {
    static var identifier: Identifier {
        return "audio"
    }

    let id: UUID
    let url: URL
    let duration: Int
}

@Codable
struct VideoPost: Post, DynamicCodable {
    static var identifier: Identifier {
        return "video"
    }

    let id: UUID
    let url: URL
    let duration: Int
    let thumbnail: URL
}
