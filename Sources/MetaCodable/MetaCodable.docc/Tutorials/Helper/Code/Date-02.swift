import Foundation
import HelperCoders
import MetaCodable

@Codable
struct Model {
    @CodedBy(Since1970DateCoder())
    let timestamp: Date
    let date: Date
    let day: Date
}
