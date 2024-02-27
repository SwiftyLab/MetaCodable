import MetaCodable

@Codable
enum Command {
    @CodedAs("load")
    case loads(_ key: String)
    case store(StoredData)
    case execute(filePath: String)
    @CodingKeys(.snake_case)
    case send(localData: String)
    @IgnoreCoding
    case dumpToDisk

    struct StoredData {
        let key: String
        let value: Int
    }
}
