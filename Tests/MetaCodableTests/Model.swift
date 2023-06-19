import Foundation
import MetaCodable

@Codable
public struct CodableData {
    let groupedOne, groupedTwo, groupedThree: String

    let optional: String?
    let genericOptional: Optional<String>

    // test back tick expression
    let `internal`: String

    @CodablePath(default: true)
    let defaultTrue: Bool
    @CodablePath(default: 5.678)
    let defaultDouble: Double
    @CodablePath(default: "default")
    let defaultString: String
    @CodablePath(default: Date(timeIntervalSince1970: 0))
    let defaultDate: Date
    @CodablePath(default: [])
    let defaultArray: [String]
    @CodablePath(default: [:])
    let defaultDictionary: [String: String]

    @CodablePath("customKey")
    let customKeyValue: String
    @CodablePath(default: "failed", "customFailableKey")
    let customKeyWithDefaultValue: String

    @CodablePath("deeply", "nested", "value")
    let deeplyNestedValue: String
    @CodablePath(default: "failed", "deeply", "nested", "value", "default")
    let deeplyNestedValueWithDefault: String

    @CodablePath(helper: PrimitiveCoder(), "dynamic")
    let dynamicValue: Codable
    @CodablePath(default: "failed", helper: PrimitiveCoder(), "dynamicFailable")
    let dynamicValueWithDefault: Codable
    @CodablePath(default: [1, 2], helper: LossySequenceCoder(default: [1, 2]))
    let lossyArray: [Int]

    @CodableCompose(default: "not present")
    let composed: String

    @CodablePath
    let simulateWithoutArgumentWarning1: String?
    @CodablePath()
    let simulateWithoutArgumentWarning2: String?
}

struct PrimitiveCoder: ExternalHelperCoder {
    func decode(from decoder: Decoder) throws -> Codable {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Bool.self) { return value }
        if let value = try? container.decode(Int.self) { return value }
        if let value = try? container.decode(Double.self) { return value }
        if let value = try? container.decode(String.self) { return value }
        if let value = try? container.decode([String].self) { return value }
        return try container.decode([String: String].self)
    }
}
