import Foundation
import HelperCoders
import MetaCodable
import Testing

@testable import PluginCore

@Suite("Coded By Action Tests")
struct CodedByActionTests {
    // https://forums.swift.org/t/codable-passing-data-to-child-decoder/12757
    @Suite("Coded By Action - Dependency Before")
    struct DependencyBefore {
        @Codable
        struct Dog {
            let name: String
            @Default(1)
            let version: Int
            @CodedBy(Info.VersionBasedTag.init, properties: \Dog.version)
            let info: Info

            @Codable
            struct Info {
                private(set) var tag: Int

                struct VersionBasedTag: HelperCoder {
                    let version: Int

                    func decode(from decoder: any Decoder) throws -> Info {
                        var info = try Info(from: decoder)
                        if version >= 2 {
                            info.tag += 1
                        }
                        return info
                    }

                    func encode(_ value: Info, to encoder: any Encoder) throws {
                        var info = value
                        if version >= 2 {
                            info.tag -= 1
                        }
                        try info.encode(to: encoder)
                    }
                }
            }
        }

        @Test("Generates macro expansion with @Codable for struct (CodedByActionTests #52)")
        func expansion() {
            assertMacroExpansion(
                """
                @Codable
                struct Dog {
                    let name: String
                    @Default(1)
                    let version: Int
                    @CodedBy(Info.VersionBasedTag.init, properties: \\Dog.version)
                    let info: Info

                    @Codable
                    struct Info {
                        private(set) var tag: Int

                        struct VersionBasedTag: HelperCoder {
                            let version: Int

                            func decode(from decoder: any Decoder) throws -> Info {
                                var info = try Info(from: decoder)
                                if version >= 2 {
                                    info.tag += 1
                                }
                                return info
                            }

                            func encode(_ value: Info, to encoder: any Encoder) throws {
                                var info = value
                                if version >= 2 {
                                    info.tag -= 1
                                }
                                try info.encode(to: encoder)
                            }
                        }
                    }
                }
                """,
                expandedSource:
                    """
                    struct Dog {
                        let name: String
                        let version: Int
                        let info: Info
                        struct Info {
                            private(set) var tag: Int

                            struct VersionBasedTag: HelperCoder {
                                let version: Int

                                func decode(from decoder: any Decoder) throws -> Info {
                                    var info = try Info(from: decoder)
                                    if version >= 2 {
                                        info.tag += 1
                                    }
                                    return info
                                }

                                func encode(_ value: Info, to encoder: any Encoder) throws {
                                    var info = value
                                    if version >= 2 {
                                        info.tag -= 1
                                    }
                                    try info.encode(to: encoder)
                                }
                            }
                        }
                    }

                    extension Dog.Info: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.tag = try container.decode(Int.self, forKey: CodingKeys.tag)
                        }
                    }

                    extension Dog.Info: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.tag, forKey: CodingKeys.tag)
                        }
                    }

                    extension Dog.Info {
                        enum CodingKeys: String, CodingKey {
                            case tag = "tag"
                        }
                    }

                    extension Dog: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.name = try container.decode(String.self, forKey: CodingKeys.name)
                            do {
                                self.version = try container.decodeIfPresent(Int.self, forKey: CodingKeys.version) ?? 1
                            } catch {
                                self.version = 1
                            }
                            self.info = try { () -> (_) -> _ in
                                Info.VersionBasedTag.init
                            }()(self.version).decode(from: container, forKey: CodingKeys.info)
                        }
                    }

                    extension Dog: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.name, forKey: CodingKeys.name)
                            try container.encode(self.version, forKey: CodingKeys.version)
                            try { () -> (_) -> _ in
                                Info.VersionBasedTag.init
                            }()(self.version).encode(self.info, to: &container, atKey: CodingKeys.info)
                        }
                    }

                    extension Dog {
                        enum CodingKeys: String, CodingKey {
                            case name = "name"
                            case version = "version"
                            case info = "info"
                        }
                    }
                    """
            )
        }

        @Test("Encodes and decodes successfully (CodedByActionTests #12)")
        func customCoderVersionBehavior() throws {
            // Test version 1 behavior
            let dog1 = Dog(name: "Buddy", version: 1, info: Dog.Info(tag: 5))
            let encoded1 = try JSONEncoder().encode(dog1)
            let decoded1 = try JSONDecoder().decode(Dog.self, from: encoded1)
            #expect(decoded1.name == "Buddy")
            #expect(decoded1.version == 1)
            #expect(decoded1.info.tag == 5)  // No modification for version < 2

            // Test version 2 behavior
            let dog2 = Dog(name: "Max", version: 2, info: Dog.Info(tag: 5))
            let encoded2 = try JSONEncoder().encode(dog2)
            let decoded2 = try JSONDecoder().decode(Dog.self, from: encoded2)
            #expect(decoded2.name == "Max")
            #expect(decoded2.version == 2)
            #expect(decoded2.info.tag == 5)  // Should be 5 after encode(-1) then decode(+1)
        }

        @Test("Decodes from JSON successfully (CodedByActionTests #30)")
        func customCoderFromJSON() throws {
            let jsonStr = """
                {
                    "name": "Rex",
                    "version": 3,
                    "info": {
                        "tag": 10
                    }
                }
                """
            let jsonData = try #require(jsonStr.data(using: .utf8))
            let decoded = try JSONDecoder().decode(Dog.self, from: jsonData)
            #expect(decoded.name == "Rex")
            #expect(decoded.version == 3)
            #expect(decoded.info.tag == 11)  // 10 + 1 for version >= 2
        }
    }

    // https://forums.swift.org/t/codable-passing-data-to-child-decoder/12757
    @Suite("Coded By Action - Dependency After")
    struct DependencyAfter {
        @Codable
        struct Dog {
            let name: String
            @CodedBy(Info.VersionBasedTag.init, properties: \Dog.version)
            let info: Info
            @Default(1)
            let version: Int

            @Codable
            struct Info {
                private(set) var tag: Int

                struct VersionBasedTag: HelperCoder {
                    let version: Int

                    func decode(from decoder: any Decoder) throws -> Info {
                        var info = try Info(from: decoder)
                        if version >= 2 {
                            info.tag += 1
                        }
                        return info
                    }

                    func encode(_ value: Info, to encoder: any Encoder) throws {
                        var info = value
                        if version >= 2 {
                            info.tag -= 1
                        }
                        try info.encode(to: encoder)
                    }
                }
            }
        }

        @Test("Generates macro expansion with @Codable for struct (CodedByActionTests #53)")
        func expansion() {
            assertMacroExpansion(
                """
                @Codable
                struct Dog {
                    let name: String
                    @CodedBy(Info.VersionBasedTag.init, properties: \\Dog.version)
                    let info: Info
                    @Default(1)
                    let version: Int

                    @Codable
                    struct Info {
                        private(set) var tag: Int

                        struct VersionBasedTag: HelperCoder {
                            let version: Int

                            func decode(from decoder: any Decoder) throws -> Info {
                                var info = try Info(from: decoder)
                                if version >= 2 {
                                    info.tag += 1
                                }
                                return info
                            }

                            func encode(_ value: Info, to encoder: any Encoder) throws {
                                var info = value
                                if version >= 2 {
                                    info.tag -= 1
                                }
                                try info.encode(to: encoder)
                            }
                        }
                    }
                }
                """,
                expandedSource:
                    """
                    struct Dog {
                        let name: String
                        let info: Info
                        let version: Int
                        struct Info {
                            private(set) var tag: Int

                            struct VersionBasedTag: HelperCoder {
                                let version: Int

                                func decode(from decoder: any Decoder) throws -> Info {
                                    var info = try Info(from: decoder)
                                    if version >= 2 {
                                        info.tag += 1
                                    }
                                    return info
                                }

                                func encode(_ value: Info, to encoder: any Encoder) throws {
                                    var info = value
                                    if version >= 2 {
                                        info.tag -= 1
                                    }
                                    try info.encode(to: encoder)
                                }
                            }
                        }
                    }

                    extension Dog.Info: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.tag = try container.decode(Int.self, forKey: CodingKeys.tag)
                        }
                    }

                    extension Dog.Info: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.tag, forKey: CodingKeys.tag)
                        }
                    }

                    extension Dog.Info {
                        enum CodingKeys: String, CodingKey {
                            case tag = "tag"
                        }
                    }

                    extension Dog: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.name = try container.decode(String.self, forKey: CodingKeys.name)
                            do {
                                self.version = try container.decodeIfPresent(Int.self, forKey: CodingKeys.version) ?? 1
                            } catch {
                                self.version = 1
                            }
                            self.info = try { () -> (_) -> _ in
                                Info.VersionBasedTag.init
                            }()(self.version).decode(from: container, forKey: CodingKeys.info)
                        }
                    }

                    extension Dog: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.name, forKey: CodingKeys.name)
                            try { () -> (_) -> _ in
                                Info.VersionBasedTag.init
                            }()(self.version).encode(self.info, to: &container, atKey: CodingKeys.info)
                            try container.encode(self.version, forKey: CodingKeys.version)
                        }
                    }

                    extension Dog {
                        enum CodingKeys: String, CodingKey {
                            case name = "name"
                            case info = "info"
                            case version = "version"
                        }
                    }
                    """
            )
        }

        @Test(arguments: [nil, 1, 2, 5])
        func decoding(version: Int?) throws {
            let data = try #require(dogJSON(version: version))
            let dog = try JSONDecoder().decode(Dog.self, from: data)
            #expect(dog.name == "Dog")
            #expect(dog.version == version ?? 1)
            if dog.version >= 2 {
                #expect(dog.info.tag == 13)
            } else {
                #expect(dog.info.tag == 12)
            }
        }
    }

    // https://stackoverflow.com/questions/62242365/access-property-of-parent-struct-in-a-nested-codable-struct-when-decoding-the-ch
    @Suite("Coded By Action - Nested Property Dependency Before")
    struct NestedPropertyDependencyBefore {
        @Codable
        struct Item: Identifiable {
            let id: String
            let title: String
            @CodedAt("images", "original")
            @CodedBy(Image.IdentifierCoder.init, properties: \Item.id)
            let originalImage: Image
            @CodedAt("images", "small")
            @CodedBy(Image.IdentifierCoder.init, properties: \Item.id)
            let smallImage: Image

            @Codable
            struct Image: Identifiable {
                var id: String { identifier }

                @IgnoreCoding
                private(set) var identifier: String!
                let width: Int
                let height: Int

                struct IdentifierCoder: HelperCoder {
                    let id: String

                    func decode(from decoder: any Decoder) throws -> Image {
                        var image = try Image(from: decoder)
                        image.identifier = id
                        return image
                    }

                    func encode(_ value: Image, to encoder: any Encoder) throws
                    {
                        var image = value
                        image.identifier = nil
                        try image.encode(to: encoder)
                    }
                }
            }
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (CodedByActionTests #37)")
        func expansion() {
            assertMacroExpansion(
                """
                @Codable
                struct Item: Identifiable {
                    let id: String
                    let title: String
                    @CodedAt("images", "original")
                    @CodedBy(Image.IdentifierCoder.init, properties: \\Item.id)
                    let originalImage: Image
                    @CodedAt("images", "small")
                    @CodedBy(Image.IdentifierCoder.init, properties: \\Item.id)
                    let smallImage: Image

                    @Codable
                    struct Image: Identifiable {
                        var id: String { identifier }

                        @IgnoreCoding
                        private(set) var identifier: String!
                        let width: Int
                        let height: Int

                        struct IdentifierCoder: HelperCoder {
                            let id: String

                            func decode(from decoder: any Decoder) throws -> Image {
                                var image = try Image(from: decoder)
                                image.identifier = id
                                return image
                            }

                            func encode(_ value: Image, to encoder: any Encoder) throws {
                                var image = value
                                image.identifier = nil
                                try image.encode(to: encoder)
                            }
                        }
                    }
                }
                """,
                expandedSource:
                    """
                    struct Item: Identifiable {
                        let id: String
                        let title: String
                        let originalImage: Image
                        let smallImage: Image
                        struct Image: Identifiable {
                            var id: String { identifier }
                            private(set) var identifier: String!
                            let width: Int
                            let height: Int

                            struct IdentifierCoder: HelperCoder {
                                let id: String

                                func decode(from decoder: any Decoder) throws -> Image {
                                    var image = try Image(from: decoder)
                                    image.identifier = id
                                    return image
                                }

                                func encode(_ value: Image, to encoder: any Encoder) throws {
                                    var image = value
                                    image.identifier = nil
                                    try image.encode(to: encoder)
                                }
                            }
                        }
                    }

                    extension Item.Image: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.width = try container.decode(Int.self, forKey: CodingKeys.width)
                            self.height = try container.decode(Int.self, forKey: CodingKeys.height)
                        }
                    }

                    extension Item.Image: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.width, forKey: CodingKeys.width)
                            try container.encode(self.height, forKey: CodingKeys.height)
                        }
                    }

                    extension Item.Image {
                        enum CodingKeys: String, CodingKey {
                            case width = "width"
                            case height = "height"
                        }
                    }

                    extension Item: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let images_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.images)
                            self.id = try container.decode(String.self, forKey: CodingKeys.id)
                            self.title = try container.decode(String.self, forKey: CodingKeys.title)
                            self.originalImage = try { () -> (_) -> _ in
                                Image.IdentifierCoder.init
                            }()(self.id).decode(from: images_container, forKey: CodingKeys.originalImage)
                            self.smallImage = try { () -> (_) -> _ in
                                Image.IdentifierCoder.init
                            }()(self.id).decode(from: images_container, forKey: CodingKeys.smallImage)
                        }
                    }

                    extension Item: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.id, forKey: CodingKeys.id)
                            try container.encode(self.title, forKey: CodingKeys.title)
                            var images_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.images)
                            try { () -> (_) -> _ in
                                Image.IdentifierCoder.init
                            }()(self.id).encode(self.originalImage, to: &images_container, atKey: CodingKeys.originalImage)
                            try { () -> (_) -> _ in
                                Image.IdentifierCoder.init
                            }()(self.id).encode(self.smallImage, to: &images_container, atKey: CodingKeys.smallImage)
                        }
                    }

                    extension Item {
                        enum CodingKeys: String, CodingKey {
                            case id = "id"
                            case title = "title"
                            case originalImage = "original"
                            case images = "images"
                            case smallImage = "small"
                        }
                    }
                    """
            )
        }
    }

    // https://stackoverflow.com/questions/62242365/access-property-of-parent-struct-in-a-nested-codable-struct-when-decoding-the-ch
    @Suite("Coded By Action - Nested Property Dependency After")
    struct NestedPropertyDependencyAfter {
        @Codable
        struct Item: Identifiable {
            let title: String
            @CodedAt("images", "original")
            @CodedBy(Image.IdentifierCoder.init, properties: \Item.id)
            let originalImage: Image
            @CodedAt("images", "small")
            @CodedBy(Image.IdentifierCoder.init, properties: \Item.id)
            let smallImage: Image
            let id: String

            @Codable
            struct Image: Identifiable {
                var id: String { identifier }

                @IgnoreCoding
                private(set) var identifier: String!
                let width: Int
                let height: Int

                struct IdentifierCoder: HelperCoder {
                    let id: String

                    func decode(from decoder: any Decoder) throws -> Image {
                        var image = try Image(from: decoder)
                        image.identifier = id
                        return image
                    }

                    func encode(_ value: Image, to encoder: any Encoder) throws
                    {
                        var image = value
                        image.identifier = nil
                        try image.encode(to: encoder)
                    }
                }
            }
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (CodedByActionTests #38)")
        func expansion() {
            assertMacroExpansion(
                """
                @Codable
                struct Item: Identifiable {
                    let title: String
                    @CodedAt("images", "original")
                    @CodedBy(Image.IdentifierCoder.init, properties: \\Item.id)
                    let originalImage: Image
                    @CodedAt("images", "small")
                    @CodedBy(Image.IdentifierCoder.init, properties: \\Item.id)
                    let smallImage: Image
                    let id: String

                    @Codable
                    struct Image: Identifiable {
                        var id: String { identifier }

                        @IgnoreCoding
                        private(set) var identifier: String!
                        let width: Int
                        let height: Int

                        struct IdentifierCoder: HelperCoder {
                            let id: String

                            func decode(from decoder: any Decoder) throws -> Image {
                                var image = try Image(from: decoder)
                                image.identifier = id
                                return image
                            }

                            func encode(_ value: Image, to encoder: any Encoder) throws {
                                var image = value
                                image.identifier = nil
                                try image.encode(to: encoder)
                            }
                        }
                    }
                }
                """,
                expandedSource:
                    """
                    struct Item: Identifiable {
                        let title: String
                        let originalImage: Image
                        let smallImage: Image
                        let id: String
                        struct Image: Identifiable {
                            var id: String { identifier }
                            private(set) var identifier: String!
                            let width: Int
                            let height: Int

                            struct IdentifierCoder: HelperCoder {
                                let id: String

                                func decode(from decoder: any Decoder) throws -> Image {
                                    var image = try Image(from: decoder)
                                    image.identifier = id
                                    return image
                                }

                                func encode(_ value: Image, to encoder: any Encoder) throws {
                                    var image = value
                                    image.identifier = nil
                                    try image.encode(to: encoder)
                                }
                            }
                        }
                    }

                    extension Item.Image: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.width = try container.decode(Int.self, forKey: CodingKeys.width)
                            self.height = try container.decode(Int.self, forKey: CodingKeys.height)
                        }
                    }

                    extension Item.Image: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.width, forKey: CodingKeys.width)
                            try container.encode(self.height, forKey: CodingKeys.height)
                        }
                    }

                    extension Item.Image {
                        enum CodingKeys: String, CodingKey {
                            case width = "width"
                            case height = "height"
                        }
                    }

                    extension Item: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let images_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.images)
                            self.title = try container.decode(String.self, forKey: CodingKeys.title)
                            self.id = try container.decode(String.self, forKey: CodingKeys.id)
                            self.originalImage = try { () -> (_) -> _ in
                                Image.IdentifierCoder.init
                            }()(self.id).decode(from: images_container, forKey: CodingKeys.originalImage)
                            self.smallImage = try { () -> (_) -> _ in
                                Image.IdentifierCoder.init
                            }()(self.id).decode(from: images_container, forKey: CodingKeys.smallImage)
                        }
                    }

                    extension Item: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.title, forKey: CodingKeys.title)
                            var images_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.images)
                            try { () -> (_) -> _ in
                                Image.IdentifierCoder.init
                            }()(self.id).encode(self.originalImage, to: &images_container, atKey: CodingKeys.originalImage)
                            try { () -> (_) -> _ in
                                Image.IdentifierCoder.init
                            }()(self.id).encode(self.smallImage, to: &images_container, atKey: CodingKeys.smallImage)
                            try container.encode(self.id, forKey: CodingKeys.id)
                        }
                    }

                    extension Item {
                        enum CodingKeys: String, CodingKey {
                            case title = "title"
                            case originalImage = "original"
                            case images = "images"
                            case smallImage = "small"
                            case id = "id"
                        }
                    }
                    """
            )
        }

        @Test(arguments: ["unique", "some_id"])
        func decoding(id: String) throws {
            let data = try #require(itemJSON(id: id))
            let item = try JSONDecoder().decode(Item.self, from: data)
            #expect(item.id == id)
            #expect(item.title == "Great")
            #expect(item.originalImage.id == id)
            #expect(item.originalImage.height == 1080)
            #expect(item.originalImage.width == 1920)
            #expect(item.smallImage.id == id)
            #expect(item.smallImage.height == 108)
            #expect(item.smallImage.width == 192)
        }
    }

    @Suite("Coded By Action - Multi Chained Dependency")
    struct MultiChainedDependency {
        @Codable
        struct SomeCodable {
            @CodedBy(Multiplier.init, properties: \SomeCodable.three)
            let one: Int
            @CodedIn("deeply", "nested", "value")
            @CodedBy(
                Multiplier.init, properties: \SomeCodable.one, \SomeCodable.four
            )
            @Default(ifMissing: 2, forErrors: 4)
            let two: Int
            @CodedIn("deeply", "nested")
            let three: Int
            let four: Int
            @CodedAt("deeply", "value", "six")
            @CodedBy(Multiplier.init, properties: \SomeCodable.six)
            @Default(ifMissing: 5)
            let five: Int
            @CodedAt("deeply", "value", "six")
            @CodedBy(ValueCoder<Int>())
            @Default(ifMissing: 6)
            let six: Int

            struct Multiplier: HelperCoder {
                let multipliers: [Int]

                init(multiplier: Int) {
                    self.multipliers = [multiplier]
                }

                init(multiplier1: Int, multiplier2: Int) {
                    self.multipliers = [multiplier1, multiplier2]
                }

                func decode(from decoder: any Decoder) throws -> Int {
                    try multipliers.reduce(Int(from: decoder), *)
                }

                func encode(_ value: Int, to encoder: any Encoder) throws {
                    try multipliers.reduce(value, /).encode(to: encoder)
                }
            }
        }

        @Test("Generates macro expansion with @Codable for struct with nested paths (CodedByActionTests #39)")
        func expansion() {
            assertMacroExpansion(
                """
                @Codable
                struct SomeCodable {
                    @CodedBy(Multiplier.init, properties: \\SomeCodable.three)
                    let one: Int
                    @CodedIn("deeply", "nested", "value")
                    @CodedBy(
                        Multiplier.init, properties: \\SomeCodable.one, \\SomeCodable.four
                    )
                    @Default(ifMissing: 2, forErrors: 4)
                    let two: Int
                    @CodedIn("deeply", "nested")
                    let three: Int
                    let four: Int
                    @CodedAt("deeply", "value", "six")
                    @CodedBy(Multiplier.init, properties: \\SomeCodable.six)
                    @Default(ifMissing: 5)
                    let five: Int
                    @CodedAt("deeply", "value", "six")
                    @CodedBy(ValueCoder<Int>())
                    @Default(ifMissing: 6)
                    let six: Int

                    struct Multiplier: HelperCoder {
                        let multipliers: [Int]

                        init(multiplier: Int) {
                            self.multipliers = [multiplier]
                        }

                        init(multiplier1: Int, multiplier2: Int) {
                            self.multipliers = [multiplier1, multiplier2]
                        }

                        func decode(from decoder: any Decoder) throws -> Int {
                            return try multipliers.reduce(Int(from: decoder), *)
                        }

                        func encode(_ value: Int, to encoder: any Encoder) throws {
                            return try multipliers.reduce(value, /).encode(to: encoder)
                        }
                    }
                }
                """,
                expandedSource:
                    """
                    struct SomeCodable {
                        let one: Int
                        let two: Int
                        let three: Int
                        let four: Int
                        let five: Int
                        let six: Int

                        struct Multiplier: HelperCoder {
                            let multipliers: [Int]

                            init(multiplier: Int) {
                                self.multipliers = [multiplier]
                            }

                            init(multiplier1: Int, multiplier2: Int) {
                                self.multipliers = [multiplier1, multiplier2]
                            }

                            func decode(from decoder: any Decoder) throws -> Int {
                                return try multipliers.reduce(Int(from: decoder), *)
                            }

                            func encode(_ value: Int, to encoder: any Encoder) throws {
                                return try multipliers.reduce(value, /).encode(to: encoder)
                            }
                        }
                    }

                    extension SomeCodable: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            let deeply_container = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            let nested_deeply_container = try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            let value_nested_deeply_container: KeyedDecodingContainer<CodingKeys>?
                            let value_nested_deeply_containerMissing: Bool
                            if (try? nested_deeply_container.decodeNil(forKey: CodingKeys.value)) == false {
                                value_nested_deeply_container = try? nested_deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.value)
                                value_nested_deeply_containerMissing = false
                            } else {
                                value_nested_deeply_container = nil
                                value_nested_deeply_containerMissing = true
                            }
                            let value_deeply_container = ((try? deeply_container.decodeNil(forKey: CodingKeys.value)) == false) ? try deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.value) : nil
                            self.four = try container.decode(Int.self, forKey: CodingKeys.four)
                            self.three = try nested_deeply_container.decode(Int.self, forKey: CodingKeys.three)
                            if let _ = value_nested_deeply_container {
                            } else if value_nested_deeply_containerMissing {
                            } else {
                            }
                            if let value_deeply_container = value_deeply_container {
                                self.six = try ValueCoder<Int>().decodeIfPresent(from: value_deeply_container, forKey: CodingKeys.five) ?? 6
                            } else {
                                self.six = 6
                            }
                            self.one = try { () -> (_) -> _ in
                                Multiplier.init
                            }()(self.three).decode(from: container, forKey: CodingKeys.one)
                            if let value_nested_deeply_container = value_nested_deeply_container {
                                do {
                                    self.two = try { () -> (_, _) -> _ in
                                            Multiplier.init
                                    }()(self.one, self.four).decodeIfPresent(from: value_nested_deeply_container, forKey: CodingKeys.two) ?? 2
                                } catch {
                                    self.two = 4
                                }
                            } else if value_nested_deeply_containerMissing {
                                self.two = 2
                            } else {
                                self.two = 4
                            }
                            if let value_deeply_container = value_deeply_container {
                                self.five = try { () -> (_) -> _ in
                                    Multiplier.init
                                }()(self.six).decodeIfPresent(from: value_deeply_container, forKey: CodingKeys.five) ?? 5
                            } else {
                                self.five = 5
                            }
                        }
                    }

                    extension SomeCodable: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try { () -> (_) -> _ in
                                Multiplier.init
                            }()(self.three).encode(self.one, to: &container, atKey: CodingKeys.one)
                            var deeply_container = container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.deeply)
                            var nested_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.nested)
                            var value_nested_deeply_container = nested_deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.value)
                            try { () -> (_, _) -> _ in
                                    Multiplier.init
                            }()(self.one, self.four).encode(self.two, to: &value_nested_deeply_container, atKey: CodingKeys.two)
                            try nested_deeply_container.encode(self.three, forKey: CodingKeys.three)
                            var value_deeply_container = deeply_container.nestedContainer(keyedBy: CodingKeys.self, forKey: CodingKeys.value)
                            try ValueCoder<Int>().encode(self.six, to: &value_deeply_container, atKey: CodingKeys.five)
                            try { () -> (_) -> _ in
                                Multiplier.init
                            }()(self.six).encode(self.five, to: &value_deeply_container, atKey: CodingKeys.five)
                            try container.encode(self.four, forKey: CodingKeys.four)
                        }
                    }

                    extension SomeCodable {
                        enum CodingKeys: String, CodingKey {
                            case one = "one"
                            case two = "two"
                            case deeply = "deeply"
                            case nested = "nested"
                            case value = "value"
                            case three = "three"
                            case four = "four"
                            case five = "six"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Coded By Action - Array Dependency")
    struct ArrayDependency {
        #if swift(>=6)
        @Codable
        struct Item: Identifiable {
            let title: String
            @CodedBy(
                SequenceCoder.init, arguments: Image.IdentifierCoder.init,
                properties: \Item.id
            )
            let images: [Image]
            let id: String

            @Codable
            struct Image: Identifiable {
                var id: String { identifier }

                @IgnoreCoding
                private(set) var identifier: String!
                let width: Int
                let height: Int

                struct IdentifierCoder: HelperCoder {
                    let id: String

                    func decode(from decoder: any Decoder) throws -> Image {
                        var image = try Image(from: decoder)
                        image.identifier = id
                        return image
                    }

                    func encode(_ value: Image, to encoder: any Encoder) throws
                    {
                        var image = value
                        image.identifier = nil
                        try image.encode(to: encoder)
                    }
                }
            }
        }

        @Test(arguments: ["unique", "some_id"])
        func decoding(id: String) throws {
            let data = try #require(itemImagesJSON(id: id, count: 5))
            let item = try JSONDecoder().decode(Item.self, from: data)
            #expect(item.id == id)
            #expect(item.title == "Great")
            #expect(item.images.map(\.id) == .init(repeating: id, count: 5))
            #expect(
                item.images.map(\.height) == .init(repeating: 1080, count: 5))
            #expect(
                item.images.map(\.width) == .init(repeating: 1920, count: 5))
        }
        #endif

        @Test("Generates macro expansion with @Codable for struct (CodedByActionTests #54)")
        func expansion() {
            assertMacroExpansion(
                """
                @Codable
                struct Item: Identifiable {
                    let title: String
                    @CodedBy(
                        SequenceCoder.init, arguments: Image.IdentifierCoder.init,
                        properties: \\Item.id
                    )
                    let images: [Image]
                    let id: String

                    @Codable
                    struct Image: Identifiable {
                        var id: String { identifier }

                        @IgnoreCoding
                        private(set) var identifier: String!
                        let width: Int
                        let height: Int

                        struct IdentifierCoder: HelperCoder {
                            let id: String

                            func decode(from decoder: any Decoder) throws -> Image {
                                var image = try Image(from: decoder)
                                image.identifier = id
                                return image
                            }

                            func encode(_ value: Image, to encoder: any Encoder) throws
                            {
                                var image = value
                                image.identifier = nil
                                try image.encode(to: encoder)
                            }
                        }
                    }
                }
                """,
                expandedSource:
                    """
                    struct Item: Identifiable {
                        let title: String
                        let images: [Image]
                        let id: String
                        struct Image: Identifiable {
                            var id: String { identifier }
                            private(set) var identifier: String!
                            let width: Int
                            let height: Int

                            struct IdentifierCoder: HelperCoder {
                                let id: String

                                func decode(from decoder: any Decoder) throws -> Image {
                                    var image = try Image(from: decoder)
                                    image.identifier = id
                                    return image
                                }

                                func encode(_ value: Image, to encoder: any Encoder) throws
                                {
                                    var image = value
                                    image.identifier = nil
                                    try image.encode(to: encoder)
                                }
                            }
                        }
                    }

                    extension Item.Image: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.width = try container.decode(Int.self, forKey: CodingKeys.width)
                            self.height = try container.decode(Int.self, forKey: CodingKeys.height)
                        }
                    }

                    extension Item.Image: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.width, forKey: CodingKeys.width)
                            try container.encode(self.height, forKey: CodingKeys.height)
                        }
                    }

                    extension Item.Image {
                        enum CodingKeys: String, CodingKey {
                            case width = "width"
                            case height = "height"
                        }
                    }

                    extension Item: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.title = try container.decode(String.self, forKey: CodingKeys.title)
                            self.id = try container.decode(String.self, forKey: CodingKeys.id)
                            self.images = try { () -> (_, _) -> _ in
                                    SequenceCoder.init
                            }()(Image.IdentifierCoder.init, self.id).decode(from: container, forKey: CodingKeys.images)
                        }
                    }

                    extension Item: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.title, forKey: CodingKeys.title)
                            try { () -> (_, _) -> _ in
                                    SequenceCoder.init
                            }()(Image.IdentifierCoder.init, self.id).encode(self.images, to: &container, atKey: CodingKeys.images)
                            try container.encode(self.id, forKey: CodingKeys.id)
                        }
                    }

                    extension Item {
                        enum CodingKeys: String, CodingKey {
                            case title = "title"
                            case images = "images"
                            case id = "id"
                        }
                    }
                    """
            )
        }
    }

    @Suite("Coded By Action - Lossy Set Dependency")
    struct LossySetDependency {
        #if swift(>=6)
        @Codable
        struct Item: Identifiable {
            let title: String
            @CodedBy(
                SequenceCoder.init, arguments: Set<Image>.self,
                Image.IdentifierCoder.init, .lossy, properties: \Item.id
            )
            let images: Set<Image>
            let id: String

            @Codable
            struct Image: Identifiable, Hashable {
                var id: String { identifier }

                @IgnoreCoding
                private(set) var identifier: String!
                let width: Int
                let height: Int

                struct IdentifierCoder: HelperCoder {
                    let id: String

                    func decode(from decoder: any Decoder) throws -> Image {
                        var image = try Image(from: decoder)
                        image.identifier = id
                        return image
                    }

                    func encode(_ value: Image, to encoder: any Encoder) throws
                    {
                        var image = value
                        image.identifier = nil
                        try image.encode(to: encoder)
                    }
                }
            }
        }
        #endif

        @Test("Generates macro expansion with @Codable for struct (CodedByActionTests #55)")
        func expansion() {
            assertMacroExpansion(
                """
                @Codable
                struct Item: Identifiable {
                    let title: String
                    @CodedBy(
                        SequenceCoder.init, arguments: Set<Image>.self,
                        Image.IdentifierCoder.init, .lossy, properties: \\Item.id
                    )
                    let images: Set<Image>
                    let id: String

                    @Codable
                    struct Image: Identifiable, Hashable {
                        var id: String { identifier }

                        @IgnoreCoding
                        private(set) var identifier: String!
                        let width: Int
                        let height: Int

                        struct IdentifierCoder: HelperCoder {
                            let id: String

                            func decode(from decoder: any Decoder) throws -> Image {
                                var image = try Image(from: decoder)
                                image.identifier = id
                                return image
                            }

                            func encode(_ value: Image, to encoder: any Encoder) throws
                            {
                                var image = value
                                image.identifier = nil
                                try image.encode(to: encoder)
                            }
                        }
                    }
                }
                """,
                expandedSource:
                    """
                    struct Item: Identifiable {
                        let title: String
                        let images: Set<Image>
                        let id: String
                        struct Image: Identifiable, Hashable {
                            var id: String { identifier }
                            private(set) var identifier: String!
                            let width: Int
                            let height: Int

                            struct IdentifierCoder: HelperCoder {
                                let id: String

                                func decode(from decoder: any Decoder) throws -> Image {
                                    var image = try Image(from: decoder)
                                    image.identifier = id
                                    return image
                                }

                                func encode(_ value: Image, to encoder: any Encoder) throws
                                {
                                    var image = value
                                    image.identifier = nil
                                    try image.encode(to: encoder)
                                }
                            }
                        }
                    }

                    extension Item.Image: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.width = try container.decode(Int.self, forKey: CodingKeys.width)
                            self.height = try container.decode(Int.self, forKey: CodingKeys.height)
                        }
                    }

                    extension Item.Image: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.width, forKey: CodingKeys.width)
                            try container.encode(self.height, forKey: CodingKeys.height)
                        }
                    }

                    extension Item.Image {
                        enum CodingKeys: String, CodingKey {
                            case width = "width"
                            case height = "height"
                        }
                    }

                    extension Item: Decodable {
                        init(from decoder: any Decoder) throws {
                            let container = try decoder.container(keyedBy: CodingKeys.self)
                            self.title = try container.decode(String.self, forKey: CodingKeys.title)
                            self.id = try container.decode(String.self, forKey: CodingKeys.id)
                            self.images = try { () -> (_, _, _, _) -> _ in
                                    SequenceCoder.init
                            }()(Set<Image>.self,
                                    Image.IdentifierCoder.init, .lossy, self.id).decode(from: container, forKey: CodingKeys.images)
                        }
                    }

                    extension Item: Encodable {
                        func encode(to encoder: any Encoder) throws {
                            var container = encoder.container(keyedBy: CodingKeys.self)
                            try container.encode(self.title, forKey: CodingKeys.title)
                            try { () -> (_, _, _, _) -> _ in
                                    SequenceCoder.init
                            }()(Set<Image>.self,
                                    Image.IdentifierCoder.init, .lossy, self.id).encode(self.images, to: &container, atKey: CodingKeys.images)
                            try container.encode(self.id, forKey: CodingKeys.id)
                        }
                    }

                    extension Item {
                        enum CodingKeys: String, CodingKey {
                            case title = "title"
                            case images = "images"
                            case id = "id"
                        }
                    }
                    """
            )
        }
    }
}

private func dogJSON(version: Int?) -> Data? {
    let versionStr =
        if let version {
            "\"version\": \(version),"
        } else {
            ""
        }
    return """
        {
          "name": "Dog",
          \(versionStr)
          "info": {
            "tag": 12
          }
        }
        """.data(using: .utf8)
}

private func itemJSON(id: String) -> Data? {
    """
    {
      "id": "\(id)",
      "title": "Great",
      "images": {
        "original": {
          "height": 1080,
          "width": 1920
        },
        "small": {
          "height": 108,
          "width": 192
        }
      }
    }
    """.data(using: .utf8)
}

private func itemImagesJSON(id: String, count: UInt) -> Data? {
    let imagesJSON = (0..<count).map { _ in
        return "{\"height\": 1080,\"width\": 1920}"
    }.joined(separator: ",")
    return """
        {
          "id": "\(id)",
          "title": "Great",
          "images": [
                \(imagesJSON)
           ]
        }
        """.data(using: .utf8)
}
