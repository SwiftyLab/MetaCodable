import Foundation
import MetaCodable
import HelperCoders

@Codable
struct Model {
    @CodedBy(
        SequenceCoder(
            elementHelper: Base64Coder()
        )
    )
    let messages: [Data]
}
