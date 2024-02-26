import Foundation
import MetaCodable
import HelperCoders

let dayDateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter
        .setLocalizedDateFormatFromTemplate("MMMMd")
    return dateFormatter
}()

@Codable
struct Model {
    @CodedBy(Since1970DateCoder())
    let timestamp: Date
    @CodedBy(ISO8601DateCoder())
    let date: Date
    @CodedBy(dayDateFormatter)
    let day: Date
}
