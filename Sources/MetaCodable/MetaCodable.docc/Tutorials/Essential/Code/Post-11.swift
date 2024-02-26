import MetaCodable

@Codable
@CodingKeys(.snake_case)
@IgnoreCodingInitialized
struct Post {
    let id: String
    @CodedAt("header")
    let title: String
    @Default(0)
    let likes: Int
    let createdAt: String
    @CodedIn("created_by")
    let author: String
    var interacted: Bool = false
    @CodedIn
    var deliveredTime: Double = Date().timeIntervalSince1970
}
