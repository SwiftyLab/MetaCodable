import Foundation
import MetaCodable
import HelperCoders

@Codable
struct Model {
    @CodedBy(Since1970DateCoder())
    let timestamp: Date
    @CodedBy(ISO8601DateCoder())
    let date: Date
    let day: Date
}
