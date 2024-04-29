import Foundation
import HelperCoders
import MetaCodable

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
