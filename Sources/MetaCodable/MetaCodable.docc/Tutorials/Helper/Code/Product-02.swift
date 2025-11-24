import MetaCodable

@Codable(commonStrategies: [.codedBy(.valueCoder())])
struct Product {
    let sku: Int
    let inStock: Bool
    let name: String
    let price: Double
}
