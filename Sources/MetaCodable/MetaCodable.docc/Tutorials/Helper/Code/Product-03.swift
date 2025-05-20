import MetaCodable
import HelperCoders

@Codable(commonStrategies: [.codedBy(.valueCoder())])
struct Product {
    let sku: Int
    let inStock: Bool
    @CodedBy(ISO8601DateCoder())  // Override common strategy for this property
    let createdAt: Date
    let price: Double
}
