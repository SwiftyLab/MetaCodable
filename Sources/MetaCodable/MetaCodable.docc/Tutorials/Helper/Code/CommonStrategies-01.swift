import HelperCoders
import MetaCodable

@Codable(commonStrategies: [.codedBy(.valueCoder())])
struct User {
    let id: Int  // Will use ValueCoder
    let name: String  // Will use ValueCoder
    let active: Bool  // Will use ValueCoder
    let score: Double  // Will use ValueCoder
}
