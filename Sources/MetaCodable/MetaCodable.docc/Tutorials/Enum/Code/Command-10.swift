import MetaCodable

@Codable
@CodedAt("type")
@CodedAs<Int>
enum Command {
    @CodedAs(0)
    case load(key: String)
    @CodedAs(1)
    case store(key: String, value: Int)
}
