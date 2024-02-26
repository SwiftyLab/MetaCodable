import MetaCodable

@Codable
@CodingKeys(.snake_case)
struct Post {
    let id: String
    @CodedAt("header")
    @CodedAs("title_name")
    let title: String
    let likes: Int
    let createdAt: String
    @CodedIn("created_by")
    let author: String
}
