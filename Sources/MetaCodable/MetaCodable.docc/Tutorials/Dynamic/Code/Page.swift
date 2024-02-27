import MetaCodable

@Codable
struct Page {
    @CodedBy(
        SequenceCoder(
            elementHelper: PostCoder()
        )
    )
    let content: [Post]
    let next: String
}
