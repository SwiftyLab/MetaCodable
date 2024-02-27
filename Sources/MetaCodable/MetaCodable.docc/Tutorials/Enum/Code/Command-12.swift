import MetaCodable

@Codable
@CodedAt("type")
@ContentAt("content")
enum Command {
    case load(key: String)
    case store(key: String, value: Int)
    case ignore(count: Int = 1)
    @IgnoreCodingInitialized
    case dumpToDisk(info: Int = 0)
}
