import MetaCodable

@Codable
struct Post {
    let id: String
    @CodedAt("header")
    let title: String
    let likes: Int
    @CodedAt("created_by", "author")
    let author: String
}
