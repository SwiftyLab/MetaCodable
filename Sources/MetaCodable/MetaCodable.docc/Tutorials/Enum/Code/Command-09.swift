import MetaCodable

@Codable
@CodedAt("type")
@CodedAs<Int>
enum Command {
    case load(key: String)
    case store(key: String, value: Int)
}
