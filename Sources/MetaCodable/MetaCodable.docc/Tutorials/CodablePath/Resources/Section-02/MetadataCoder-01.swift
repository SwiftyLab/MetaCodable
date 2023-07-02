struct MetadataCoder: ExternalHelperCoder {
    func decode(from decoder: Decoder) throws -> [String: Any] {
        let result: [String: Any] = [:]
        return result
    }

    func encode(_ value: [String: Any], to encoder: Encoder) throws {
        //
    }
}
