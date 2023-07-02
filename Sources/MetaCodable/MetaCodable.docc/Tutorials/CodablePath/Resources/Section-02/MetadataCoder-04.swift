struct MetadataCoder: ExternalHelperCoder {
    struct AnyCodingKey: CodingKey {
        let stringValue: String

        init(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int? { nil }
        init?(intValue: Int) { return nil }
    }

    func decode(from decoder: Decoder) throws -> [String: Any] {
        let codableTypes: [Codable.Type] = [
            Bool.self,
            Int.self, Double.self,
            String.self,
        ]

        let container = try decoder.container(keyedBy: AnyCodingKey.self)
        var result: [String: Any] = [:]
        result.reserveCapacity(container.allKeys.count)

        keyDecoding: for key in container.allKeys {
            let valueContainer = try container.superDecoder(forKey: key)
                .singleValueContainer()
            for type in codableTypes {
                guard let value = try? valueContainer.decode(type)
                else { continue }
                result[key.stringValue] = value
                continue keyDecoding
            }
        }
        return result
    }

    func encode(_ value: [String: Any], to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AnyCodingKey.self)
        for (key, value) in value where value is Encodable {
            let codingKey = AnyCodingKey(stringValue: key)
            let valueEncoder = container.superEncoder(forKey: codingKey)
            try (value as! Encodable).encode(to: valueEncoder)
        }
    }
}
