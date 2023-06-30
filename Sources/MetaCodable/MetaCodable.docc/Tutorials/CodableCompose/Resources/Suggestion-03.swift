extension Suggestion {
    @Codable
    struct Widget {
        @Codable
        struct Item {
            let id: String
            let type: String
        }

        @CodableCompose
        let base: Suggestion
        let widgetId: String
        let template: String
        let metadata: [String: String]
        let widgetItems: [Item]
    }

    @Codable
    struct Keyword {
        @CodableCompose
        let base: Suggestion
        let candidateSources: String
        let strategyApiType: String
        let prior: Double
    }
}

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
