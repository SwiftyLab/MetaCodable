import Foundation
import HelperCoders
import MetaCodable

@Codable
struct Model {
    @CodedBy(
        SequenceCoder(
            elementHelper: Base64Coder()
        )
    )
    let messages: [Data]
}
