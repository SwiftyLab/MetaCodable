import Foundation
import MetaCodable
import HelperCoders

@Codable
struct Model {
    @CodedBy(
        SequenceCoder(
            elementHelper: Base64Coder(),
            configuration: [
                .lossy, .default([])
            ]
        )
    )
    let messages: [Data]
}
