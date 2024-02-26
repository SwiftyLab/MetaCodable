import MetaCodable

@Codable
enum Command {
    case load(_ key: String)
    case store(key: String, value: Int)
}
