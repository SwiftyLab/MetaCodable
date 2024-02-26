import Foundation
import MetaCodable
import HelperCoders

@Codable
struct Model {
    @CodedBy(Since1970DateCoder())
    let timestamp: Date
    let date: Date
    let day: Date
}
