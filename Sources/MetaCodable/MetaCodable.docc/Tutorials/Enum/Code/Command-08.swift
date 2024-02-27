import MetaCodable

@Codable
@CodedAt("type")
enum Command {
    case load(key: String)
    case store(key: String, value: Int)
}
