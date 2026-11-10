import Foundation
import HelperCoders
import MetaCodable
import Testing

@testable import PluginCore

struct StrictDecodingTests {
    @Codable(rejectUnknownKeys: true)
    struct StrictRecord: Equatable {
        let name: String
        let count: Int
    }

    @Codable
    struct PermissiveRecord {
        let name: String
    }

    @ConformDecodable(rejectUnknownKeys: true)
    struct StrictDecodableRecord {
        let value: String
    }

    @ConformEncodable
    struct StrictEncodableRecord {
        let value: String
    }

    @Codable(rejectUnknownKeys: true)
    struct StrictNestedRecord {
        @CodedIn("payload")
        let value: String
    }

    @Codable(rejectUnknownKeys: true)
    struct StrictRenamedRecord {
        @CodedAt("wire_value")
        let value: String
    }

    @Codable(rejectUnknownKeys: true)
    struct StrictDirectRecord {
        @CodedAt
        let value: String
    }

    @Codable(rejectUnknownKeys: true)
    struct StrictDecodedAtRecord {
        @DecodedAt("payload", "wire_value")
        let value: String
    }

    @Codable(rejectUnknownKeys: true)
    struct StrictAliasRecord {
        @CodedAs("legacy_value")
        let value: String
    }

    @Codable(rejectUnknownKeys: true)
    struct StrictDefaultNestedRecord {
        @Default("fallback")
        @CodedIn("payload")
        let value: String
    }

    @Codable(rejectUnknownKeys: true)
    struct StrictIgnoredRecord {
        let value: String
        @IgnoreDecoding
        var ignored: String = "default"
    }

    @Codable(
        commonStrategies: [.codedBy(.valueCoder())],
        rejectUnknownKeys: true
    )
    struct StrictStrategyRecord {
        let value: Int
    }

    @Codable(rejectUnknownKeys: true)
    struct StrictArrayRecord {
        let values: [StrictDecodingTests.StrictRecord]
    }

    @Codable(rejectUnknownKeys: true)
    struct StrictEmptyRecord {}

    @Codable(rejectUnknownKeys: true)
    struct StrictClass {
        var value: String = ""

        init() {}
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: false, encodable: false)
    class StrictBase {
        var base: String = ""

        init() {}
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: true, encodable: true)
    class StrictChild: StrictBase {
        var child: String = ""

        override init() {
            super.init()
        }
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: false, encodable: false)
    class StrictNestedBase {
        @CodedIn("payload")
        var base: String = ""

        init() {}
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: true, encodable: true)
    class StrictNestedChild: StrictNestedBase {
        @CodedIn("payload")
        var child: String = ""

        override init() {
            super.init()
        }
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: true, encodable: true)
    class StrictNestedGrandChild: StrictNestedChild {
        @CodedIn("payload")
        var leaf: String = ""

        override init() {
            super.init()
        }
    }

    @Codable
    @Inherits(decodable: false, encodable: false)
    class PermissiveBase {
        var base: String = ""

        init() {}
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: true, encodable: true)
    class StrictPermissiveChild: PermissiveBase {
        var child: String = ""

        override init() {
            super.init()
        }
    }

    @Codable(rejectUnknownKeys: true)
    actor StrictActor {
        let value: String
    }

    @Codable(rejectUnknownKeys: true)
    enum StrictExternalCommand: Equatable {
        case load(key: String)
        case store(key: String, value: Int)
    }

    @Codable(rejectUnknownKeys: true)
    @CodedAt("type")
    enum StrictInternalCommand: Equatable {
        case load(key: String)
        case store(key: String, value: Int)
    }

    @Codable(rejectUnknownKeys: true)
    @CodedAt("type")
    @ContentAt("content")
    enum StrictAdjacentCommand: Equatable {
        case load(key: String)
        case store(key: String, value: Int)
    }

    @Codable(rejectUnknownKeys: true)
    @UnTagged
    enum StrictUntaggedCommand {
        case first(a: Int)
        case second(b: String)
    }

    @Codable(rejectUnknownKeys: true)
    enum StrictRawCommand: String {
        case ready
    }

    @Codable(rejectUnknownKeys: true)
    @CodedAt("meta", "kind")
    enum StrictNestedRawCommand: String {
        case ready
    }

    @Test
    func strictExpansionAddsValidation() throws {
        assertMacroExpansion(
            """
            @Codable(rejectUnknownKeys: true)
            struct Model {
                let value: String
            }
            """,
            expandedSource:
                """
                struct Model {
                    let value: String
                }

                extension Model: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        try decoder.rejectUnknownKeys(allowedKeys: ["value"], type: Self.self)
                        self.value = try container.decode(String.self, forKey: CodingKeys.value)
                    }
                }

                extension Model: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.value, forKey: CodingKeys.value)
                    }
                }

                extension Model {
                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                    }
                }
                """
        )
    }

    @Test
    func strictRecordRejectsUnknownKeysAndReportsAllKeys() throws {
        try expectDataCorrupted(
            StrictRecord.self,
            json: """
                {
                    "name": "value",
                    "count": 42,
                    "first_extra": true,
                    "second_extra": false
                }
                """,
            containing: ["first_extra", "second_extra"]
        )
    }

    @Test
    func strictRecordDecodesKnownKeys() throws {
        let data = Data(
            """
            {
                "name": "value",
                "count": 42
            }
            """.utf8
        )
        let decoded = try JSONDecoder().decode(StrictRecord.self, from: data)
        #expect(decoded == StrictRecord(name: "value", count: 42))
    }

    @Test
    func conformDecodableRejectsUnknownKeys() throws {
        try expectDataCorrupted(
            StrictDecodableRecord.self,
            json: """
                {
                    "value": "decoded",
                    "extra": true
                }
                """,
            containing: ["extra"]
        )
    }

    @Test
    func permissiveDecodingRemainsUnchanged() throws {
        let data = Data(
            """
            {
                "name": "value",
                "extra": true
            }
            """.utf8
        )
        let decoded = try JSONDecoder().decode(
            PermissiveRecord.self, from: data
        )
        #expect(decoded.name == "value")
    }

    @Test
    func nestedContainersRejectUnknownKeysAtTheirOwnLevel() throws {
        let validData = Data(
            """
            {
                "payload": {
                    "value": "decoded"
                }
            }
            """.utf8
        )
        let valid = try JSONDecoder().decode(
            StrictNestedRecord.self, from: validData
        )
        #expect(valid.value == "decoded")

        try expectDataCorrupted(
            StrictNestedRecord.self,
            json: """
                {
                    "payload": {
                        "value": "decoded",
                        "extra": true
                    }
                }
                """,
            containing: ["extra"]
        )

        try expectDataCorrupted(
            StrictNestedRecord.self,
            json: #"{"payload":{"value":"decoded","payload":true}}"#,
            containing: ["payload"]
        )
    }

    @Test
    func renamedAndAliasKeysRemainSupported() throws {
        let renamedData = Data(#"{"wire_value":"renamed"}"#.utf8)
        let renamed = try JSONDecoder().decode(
            StrictRenamedRecord.self, from: renamedData
        )
        #expect(renamed.value == "renamed")

        let aliasData = Data(#"{"legacy_value":"aliased"}"#.utf8)
        let alias = try JSONDecoder().decode(
            StrictAliasRecord.self, from: aliasData
        )
        #expect(alias.value == "aliased")

        try expectDataCorrupted(
            StrictAliasRecord.self,
            json: #"{"legacy_value":"aliased","extra":true}"#,
            containing: ["extra"]
        )
    }

    @Test
    func strictModeDoesNotRequireKeyedContainersForDirectValues() throws {
        let data = Data(#""direct_value""#.utf8)
        let decoded = try JSONDecoder().decode(
            StrictDirectRecord.self, from: data
        )
        #expect(decoded.value == "direct_value")
    }

    @Test
    func decodedAtNestedKeysRejectUnknownKeys() throws {
        let validData = Data(
            #"{"payload":{"wire_value":"decoded"}}"#.utf8
        )
        let valid = try JSONDecoder().decode(
            StrictDecodedAtRecord.self, from: validData
        )
        #expect(valid.value == "decoded")

        try expectDataCorrupted(
            StrictDecodedAtRecord.self,
            json: #"{"payload":{"wire_value":"decoded","extra":true}}"#,
            containing: ["extra"]
        )
    }

    @Test
    func strictValidationIsNotSwallowedByDefaultFallbacks() throws {
        let missingData = Data(#"{}"#.utf8)
        let missing = try JSONDecoder().decode(
            StrictDefaultNestedRecord.self, from: missingData
        )
        #expect(missing.value == "fallback")

        try expectDataCorrupted(
            StrictDefaultNestedRecord.self,
            json: #"{"payload":{"extra":true}}"#,
            containing: ["extra"]
        )
    }

    @Test
    func ignoredKeysAreUnsupported() throws {
        try expectDataCorrupted(
            StrictIgnoredRecord.self,
            json: #"{"value":"decoded","ignored":"input"}"#,
            containing: ["ignored"]
        )
    }

    @Test
    func commonStrategiesDoNotDisableStrictValidation() throws {
        let validData = Data(#"{"value":"42"}"#.utf8)
        let valid = try JSONDecoder().decode(
            StrictStrategyRecord.self, from: validData
        )
        #expect(valid.value == 42)

        try expectDataCorrupted(
            StrictStrategyRecord.self,
            json: #"{"value":"42","extra":true}"#,
            containing: ["extra"]
        )
    }

    @Test
    func nestedStrictTypesRejectUnknownKeysInsideCollections() throws {
        try expectDataCorrupted(
            StrictArrayRecord.self,
            json: #"{"values":[{"name":"value","count":1,"extra":true}]}"#,
            containing: ["extra"]
        )
    }

    @Test
    func emptyStrictRecordsRejectPresentKeys() throws {
        let validData = Data(#"{}"#.utf8)
        _ = try JSONDecoder().decode(StrictEmptyRecord.self, from: validData)

        try expectDataCorrupted(
            StrictEmptyRecord.self,
            json: #"{"extra":true}"#,
            containing: ["extra"]
        )
    }

    @Test
    func strictClassesRejectUnknownKeys() throws {
        try expectDataCorrupted(
            StrictClass.self,
            json: #"{"value":"decoded","extra":true}"#,
            containing: ["extra"]
        )
    }

    @Test
    func strictClassInheritanceAcceptsTheCombinedKeySet() throws {
        let data = Data(
            #"{"base":"base","child":"child"}"#.utf8
        )
        let decoded = try JSONDecoder().decode(StrictChild.self, from: data)
        #expect(decoded.base == "base")
        #expect(decoded.child == "child")

        try expectDataCorrupted(
            StrictChild.self,
            json: #"{"base":"base","child":"child","extra":true}"#,
            containing: ["extra"]
        )
    }

    @Test
    func strictNestedClassInheritanceMergesContainerPaths() throws {
        let data = Data(
            #"{"payload":{"base":"base","child":"child"}}"#.utf8
        )
        let decoded = try JSONDecoder().decode(
            StrictNestedChild.self, from: data
        )
        #expect(decoded.base == "base")
        #expect(decoded.child == "child")
    }

    @Test
    func strictThreeLevelClassInheritancePreservesDecoderMetadata() throws {
        let data = Data(
            #"{"payload":{"base":"base","child":"child","leaf":"leaf"}}"#.utf8
        )
        let decoded = try JSONDecoder().decode(
            StrictNestedGrandChild.self, from: data
        )
        #expect(decoded.base == "base")
        #expect(decoded.child == "child")
        #expect(decoded.leaf == "leaf")
    }

    @Test
    func strictChildOfPermissiveClassAcceptsSuperclassKeys() throws {
        let data = Data(#"{"base":"base","child":"child"}"#.utf8)
        let decoded = try JSONDecoder().decode(
            StrictPermissiveChild.self, from: data
        )
        #expect(decoded.base == "base")
        #expect(decoded.child == "child")
    }

    @Test
    func strictExternalEnumsRejectUnknownKeys() throws {
        let data = try encodedData(
            StrictExternalCommand.load(key: "key"),
            addingRootKey: "extra"
        )
        try expectDataCorrupted(
            StrictExternalCommand.self,
            data: data,
            containing: ["extra"]
        )
    }

    @Test
    func strictInternalEnumsRejectUnknownKeys() throws {
        let data = try encodedData(
            StrictInternalCommand.load(key: "key"),
            addingRootKey: "extra"
        )
        try expectDataCorrupted(
            StrictInternalCommand.self,
            data: data,
            containing: ["extra"]
        )
    }

    @Test
    func strictAdjacentEnumsRejectUnknownContentKeys() throws {
        let encoded = try JSONEncoder().encode(
            StrictAdjacentCommand.load(key: "key")
        )
        var object = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        var content = try #require(object["content"] as? [String: Any])
        content["extra"] = true
        object["content"] = content
        let data = try JSONSerialization.data(withJSONObject: object)

        try expectDataCorrupted(
            StrictAdjacentCommand.self,
            data: data,
            containing: ["extra"]
        )

        var rootObject = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        rootObject["value"] = 123
        let rootData = try JSONSerialization.data(
            withJSONObject: rootObject
        )
        try expectDataCorrupted(
            StrictAdjacentCommand.self,
            data: rootData,
            containing: ["value"]
        )
    }

    @Test
    func strictUntaggedEnumsValidateEachAttemptedCase() throws {
        try expectDataCorrupted(
            StrictUntaggedCommand.self,
            json: #"{"b":"ok","extra":true}"#,
            containing: ["extra"]
        )
    }

    @Test
    func strictRawValueEnumsRemainScalar() throws {
        let data = Data(#""ready""#.utf8)
        let decoded = try JSONDecoder().decode(
            StrictRawCommand.self, from: data
        )
        #expect(decoded == .ready)
    }

    @Test
    func strictNestedRawValueEnumsValidateTagContainers() throws {
        let validData = Data(#"{"meta":{"kind":"ready"}}"#.utf8)
        let decoded = try JSONDecoder().decode(
            StrictNestedRawCommand.self, from: validData
        )
        #expect(decoded == .ready)

        try expectDataCorrupted(
            StrictNestedRawCommand.self,
            json: #"{"meta":{"kind":"ready","extra":true}}"#,
            containing: ["extra"]
        )
    }

    @Test
    func actorStrictMacroExpansionCompiles() throws {
        _ = StrictActor.self
    }

    private func expectDataCorrupted<T: Decodable>(
        _ type: T.Type,
        json: String,
        containing keys: [String]
    ) throws {
        try expectDataCorrupted(
            type,
            data: Data(json.utf8),
            containing: keys
        )
    }

    private func expectDataCorrupted<T: Decodable>(
        _ type: T.Type,
        data: Data,
        containing keys: [String]
    ) throws {
        do {
            _ = try JSONDecoder().decode(type, from: data)
            Issue.record("Expected decoding to reject unsupported keys")
        } catch let DecodingError.dataCorrupted(context) {
            for key in keys {
                #expect(context.debugDescription.contains(key))
            }
        } catch {
            Issue.record("Expected dataCorrupted, got \(error)")
        }
    }

    private func encodedData<T: Encodable>(
        _ value: T,
        addingRootKey key: String
    ) throws -> Data {
        var object = try #require(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(value)
            ) as? [String: Any]
        )
        object[key] = true
        return try JSONSerialization.data(withJSONObject: object)
    }
}
