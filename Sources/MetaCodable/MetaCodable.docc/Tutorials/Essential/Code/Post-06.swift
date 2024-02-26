import MetaCodable

@Codable
struct Post {
    let id: String
    @CodedAt("header")
    @CodedAs("title_name")
    let title: String
    let likes: Int
    @CodedIn("created_by")
    let author: String
}
