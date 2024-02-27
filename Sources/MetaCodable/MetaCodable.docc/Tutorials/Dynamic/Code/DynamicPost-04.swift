import MetaCodable

@Codable
protocol Post {
    var id: UUID { get }
}

@Codable
struct TextPost: Post {
    let id: UUID
    let text: String
}

@Codable
struct PicturePost: Post {
    let id: UUID
    let url: URL
    let caption: String
}

@Codable
struct AudioPost: Post {
    let id: UUID
    let url: URL
    let duration: Int
}

@Codable
struct VideoPost: Post {
    let id: UUID
    let url: URL
    let duration: Int
    let thumbnail: URL
}
