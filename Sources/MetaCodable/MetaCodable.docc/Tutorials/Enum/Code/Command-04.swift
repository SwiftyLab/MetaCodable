import MetaCodable

@Codable
enum Command {
    @CodedAs("load")
    case loads(_ key: String)
    case store(key: String, value: Int)
}
