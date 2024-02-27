import MetaCodable

@Codable
@CodingKeys(.snake_case)
struct Post {
    let id: String
    @CodedAt("header")
    let title: String
    @Default(0)
    let likes: Int
    let createdAt: String
    @CodedIn("created_by")
    let author: String
    @IgnoreCoding
    var interacted: Bool = false
}
