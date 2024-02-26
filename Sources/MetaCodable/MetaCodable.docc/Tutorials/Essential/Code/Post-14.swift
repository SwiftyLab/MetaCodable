import MetaCodable

@Codable
@CodingKeys(.snake_case)
struct Post {
    let id: String
    @CodedAt("header")
    let title: String
    let likes: Int
    let createdAt: String
}

@Codable
struct TextPost {
    let text: String
}

@Codable
struct PicturePost {
    let url: String
    let caption: String
}

@Codable
struct AudioPost {
    let url: String
    let duration: Float
}
