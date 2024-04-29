import Foundation
import HelperCoders
import MetaCodable

@Codable
struct Model {
    @CodedBy(
        SequenceCoder(
            elementHelper: Base64Coder(),
            configuration: [
                .lossy, .default([]),
            ]
        )
    )
    let messages: [Data]
}
