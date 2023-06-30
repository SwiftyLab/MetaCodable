@Codable
struct Landmark {
    @CodablePath("title")
    let name: String
    @CodablePath("foundingDate")
    let foundingYear: Int
    let location: Coordinate
    let metadata: [String: String]
}

@Codable
struct Coordinate {
    let latitude: Double
    let longitude: Double
}
