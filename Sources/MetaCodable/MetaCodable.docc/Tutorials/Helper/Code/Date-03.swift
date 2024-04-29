import Foundation
import HelperCoders
import MetaCodable

@Codable
struct Model {
    @CodedBy(Since1970DateCoder())
    let timestamp: Date
    @CodedBy(ISO8601DateCoder())
    let date: Date
    let day: Date
}
