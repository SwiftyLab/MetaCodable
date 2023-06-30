

@Codable
struct Coordinate {
    let latitude: Double
    let longitude: Double
}



@Codable
struct Landmark {
    let title: String
    let foundingDate: Int
    let location: Coordinate
    let metadata: [String: Any]
}
