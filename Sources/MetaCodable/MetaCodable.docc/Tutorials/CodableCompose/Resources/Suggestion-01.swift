@Codable
struct Suggestion {
    enum `Type`: String, Codable {
        case widget = "WIDGET"
        case keyword = "KEYWORD"
    }

    let suggType: String
    let type: `Type`
    let value: String
    let refTag: String
    let strategyId: String
}
