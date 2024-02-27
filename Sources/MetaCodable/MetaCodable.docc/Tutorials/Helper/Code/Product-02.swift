import MetaCodable
import HelperCoders

@Codable
struct Product {
    @CodedBy(ValueCoder<Int>())
    let sku: Int
    @CodedBy(ValueCoder<Bool>())
    let inStock: Bool
}
