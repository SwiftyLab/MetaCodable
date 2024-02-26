import MetaCodable

@Codable
enum Command {
    @CodedAs("load")
    case loads(_ key: String)
    case store(StoredData)
    @IgnoreCoding
    case dumpToDisk

    struct StoredData {
        let key: String
        let value: Int
    }
}
