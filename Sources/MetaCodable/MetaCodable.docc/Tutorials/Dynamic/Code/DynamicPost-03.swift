import MetaCodable

@Codable
protocol Post {
    var id: UUID { get }
}

@Codable
struct TextPost {
    let id: UUID
    let text: String
}

@Codable
struct PicturePost {
    let id: UUID
    let url: URL
    let caption: String
}

@Codable
struct AudioPost {
    let id: UUID
    let url: URL
    let duration: Int
}

@Codable
struct VideoPost {
    let id: UUID
    let url: URL
    let duration: Int
    let thumbnail: URL
}
