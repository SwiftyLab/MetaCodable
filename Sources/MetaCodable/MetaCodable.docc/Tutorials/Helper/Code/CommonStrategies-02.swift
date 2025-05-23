import HelperCoders
import MetaCodable

@Codable(commonStrategies: [
    .codedBy(.valueCoder()),
    .codedBy(
        .sequenceCoder(elementHelper: .valueCoder(), configuration: .lossy
    ),
])
struct User {
    let id: Int  // Will use ValueCoder
    let tags: [String]  // Will use SequenceCoder with ValueCoder
    let scores: [Double]  // Will use SequenceCoder with ValueCoder
    @CodedBy(ISO8601DateCoder())  // Override with specific coder
    let createdAt: Date
}
