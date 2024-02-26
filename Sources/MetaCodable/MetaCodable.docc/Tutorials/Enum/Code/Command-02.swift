import MetaCodable

@Codable
enum Command {
    case load(key: String)
    case store(key: String, value: Int)
}
