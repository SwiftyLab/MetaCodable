import MetaCodable

@Codable
protocol Post {
    var id: UUID { get }
}
