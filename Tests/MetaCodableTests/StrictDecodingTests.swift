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

    @Codable
    struct PermissivePayload {
        let name: String
    }

    struct PermissivePayloadCoder: HelperCoder {
        typealias Coded = PermissivePayload

        func decode(from decoder: Decoder) throws -> PermissivePayload {
            try PermissivePayload(from: decoder)
        }
    }

    @Test
    func strictInternalEnumsValidateWildcardKeyedPayloads() throws {
        try expectDataCorrupted(
            StrictWildcardKeyedInternalCommand.self,
            json: #"{"type":"item","name":"n","extra":true}"#,
            containing: ["extra"]
        )
    }

    @Test
    func strictInternalEnumsAllowDiscriminatorKeysInWildcardPayloads() throws {
        let data = Data(
            #"{"type":"item","name":"n","count":1}"#.utf8
        )
        let decoded = try JSONDecoder().decode(
            StrictWildcardDelegatedInternalCommand.self,
            from: data
        )
        if case .item(let value) = decoded {
            #expect(value.name == "n")
            #expect(value.count == 1)
        } else {
            Issue.record("Expected wildcard delegated item case")
        }
    }

    @Test
    func strictOptionalPayloadsPreserveDateAndDataStrategies() throws {
        enum StrategyKeys: String, CodingKey {
            case date
            case data
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.container(keyedBy: StrategyKeys.self)
            let timestamp = try container.decode(
                Double.self, forKey: .date
            )
            return Date(timeIntervalSince1970: timestamp)
        }
        decoder.dataDecodingStrategy = .custom { decoder in
            let container = try decoder.container(keyedBy: StrategyKeys.self)
            let value = try container.decode(String.self, forKey: .data)
            return try #require(Data(base64Encoded: value))
        }

        let date = try decoder.decode(
            StrictOptionalStrategyCommand.self,
            from: Data(#"{"type":"date","date":123}"#.utf8)
        )
        if case .date(let value) = date {
            #expect(value?.timeIntervalSince1970 == 123)
        } else {
            Issue.record("Expected date case")
        }

        let data = try decoder.decode(
            StrictOptionalStrategyCommand.self,
            from: Data(#"{"type":"data","data":"AQI="}"#.utf8)
        )
        if case .data(let value) = data {
            #expect(value == Data([1, 2]))
        } else {
            Issue.record("Expected data case")
        }
    }

    @Test
    func strictInternalEnumsAllowDiscriminatorKeysInStrictDirectPayloads()
        throws
    {
        let data = Data(
            #"{"type":"item","name":"n","count":1}"#.utf8
        )
        let decoded = try JSONDecoder().decode(
            StrictStrictDelegatedInternalCommand.self,
            from: data
        )
        if case .item(let value) = decoded {
            #expect(value.name == "n")
            #expect(value.count == 1)
        } else {
            Issue.record("Expected strict delegated item case")
        }
    }

    @Test
    func strictInternalEnumsAllowDiscriminatorKeysInOptionalPayloads()
        throws
    {
        let data = Data(
            #"{"type":"item","name":"n","count":1}"#.utf8
        )
        let decoded = try JSONDecoder().decode(
            StrictOptionalDelegatedInternalCommand.self,
            from: data
        )
        if case .item(let value) = decoded {
            #expect(value?.name == "n")
            #expect(value?.count == 1)
        } else {
            Issue.record("Expected optional delegated item case")
        }
    }

    @Test
    func strictInternalEnumsAllowMixedDirectAndKeyedPayloads() throws {
        let data = Data(
            #"{"type":"item","name":"n","count":1}"#.utf8
        )
        let permissive = try JSONDecoder().decode(
            StrictMixedInternalCommand.self,
            from: data
        )
        if case .item(let payload, let count) = permissive {
            #expect(payload.name == "n")
            #expect(count == 1)
        } else {
            Issue.record("Expected mixed delegated item case")
        }

        let strict = try JSONDecoder().decode(
            StrictMixedStrictInternalCommand.self,
            from: data
        )
        if case .item(let payload, let count) = strict {
            #expect(payload.name == "n")
            #expect(count == 1)
        } else {
            Issue.record("Expected mixed strict delegated item case")
        }
    }

    @Test
    func strictNestedAdjacentEnumsAllowDelegatedPayloadKeys() throws {
        let data = Data(
            #"{"meta":{"kind":"item","name":"n"}}"#.utf8
        )
        let decoded = try JSONDecoder().decode(
            StrictNestedAdjacentCommand.self,
            from: data
        )
        if case .item(let value) = decoded {
            #expect(value.name == "n")
        } else {
            Issue.record("Expected nested adjacent item case")
        }
    }

    @Codable
    @Inherits(decodable: false, encodable: false)
    class PermissiveNestedClassBase {
        var nestedOnly: String = ""

        init() {}
    }

    @Codable
    @Inherits(decodable: true, encodable: true)
    class PermissiveNestedClass: PermissiveNestedClassBase {
        override init() {
            super.init()
        }
    }

    struct PermissiveNestedClassCoder: HelperCoder {
        typealias Coded = PermissiveNestedClass

        func decode(from decoder: Decoder) throws -> PermissiveNestedClass {
            try PermissiveNestedClass(from: decoder)
        }
    }

    @Codable(rejectUnknownKeys: true)
    struct StrictMixedDirectRecord {
        @CodedAt
        let payload: StrictDecodingTests.PermissivePayload
        let count: Int
    }

    @Codable(rejectUnknownKeys: true)
    struct StrictOptionalMixedDirectRecord {
        @CodedAt
        let payload: StrictDecodingTests.PermissivePayload?
        let count: Int
    }

    @Codable(rejectUnknownKeys: true)
    struct StrictMixedDescendantRecord {
        @CodedAt
        let payload: StrictDecodingTests.PermissivePayload
        @CodedIn("details")
        let count: Int
    }

    @Codable(rejectUnknownKeys: true)
    struct StrictMixedNestedDirectRecord {
        @CodedAt("payload")
        let payload: StrictDecodingTests.PermissivePayload
        @CodedIn("payload")
        let count: Int
    }

    @Codable(rejectUnknownKeys: true)
    struct StrictMixedNestedDefaultRecord {
        @Default(StrictDecodingTests.PermissivePayload(name: "fallback"))
        @CodedAt("payload")
        let payload: StrictDecodingTests.PermissivePayload
        @Default(0)
        @CodedIn("payload")
        let count: Int
    }

    @Codable(rejectUnknownKeys: true)
    struct StrictMixedNestedOptionalRecord {
        @CodedAt("payload")
        let payload: StrictDecodingTests.PermissivePayload?
        @CodedIn("payload")
        let count: Int?
    }

    @Codable(rejectUnknownKeys: true)
    struct StrictOptionalDictionaryRecord {
        @CodedAt
        let payload: [String: Int]?
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

    @Codable
    struct StrictEnvelope {
        let item: StrictDecodingTests.StrictNestedChild
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
    class StrictBaseForPermissiveChild {
        var base: String = ""

        init() {}
    }

    @Codable
    @Inherits(decodable: true, encodable: true)
    class PermissiveStrictChild: StrictBaseForPermissiveChild {
        var child: String = ""

        override init() {
            super.init()
        }
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: false, encodable: false)
    class StrictScalarBase {
        @CodedAt
        var value: String = ""

        init() {}
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: true, encodable: true)
    class StrictScalarChild: StrictScalarBase {
        override init() {
            super.init()
        }
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: false, encodable: false)
    class StrictOptionalDirectBase {
        @CodedAt
        var payload: StrictRecord? = nil

        init() {}
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: true, encodable: true)
    class StrictOptionalDirectChild: StrictOptionalDirectBase {
        var child: String = ""

        override init() {
            super.init()
        }
    }

    @Codable
    @Inherits(decodable: false, encodable: false)
    class PermissiveOptionalDirectBase {
        @CodedAt
        var payload: StrictRecord? = nil

        init() {}
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: true, encodable: true)
    class StrictOptionalDirectChildOfPermissive:
        PermissiveOptionalDirectBase
    {
        var child: String = ""

        override init() {
            super.init()
        }
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: false, encodable: false)
    class StrictMixedDirectBase {
        @CodedAt("payload")
        var payload: StrictDecodingTests.PermissivePayload =
            .init(name: "")
        @CodedIn("payload")
        var count: Int = 0

        init() {}
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: true, encodable: true)
    class StrictMixedDirectChild: StrictMixedDirectBase {
        var child: String = ""

        override init() {
            super.init()
        }
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: false, encodable: false)
    class StrictOptionalScalarBase {
        @CodedAt
        var value: String? = nil

        init() {}
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: true, encodable: true)
    class StrictOptionalScalarChild: StrictOptionalScalarBase {
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
    @Inherits(decodable: false, encodable: false)
    class StrictStructuralBase {
        @CodedIn("payload")
        var base: String = ""

        init() {}
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: true, encodable: true)
    class StrictStructuralChild: StrictStructuralBase {
        @CodedIn("payload", "details")
        var value: String = ""

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

    @Codable
    @Inherits(decodable: false, encodable: false)
    class PermissiveEmptyBase {
        var base: String = ""

        init() {}
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: true, encodable: true)
    class StrictEmptyChild: PermissiveEmptyBase {
        override init() {
            super.init()
        }
    }

    @Codable
    @Inherits(decodable: false, encodable: false)
    class EmptyPermissiveBase {
        init() {}
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: true, encodable: true)
    class StrictEmptyHierarchyChild: EmptyPermissiveBase {
        override init() {
            super.init()
        }
    }

    @Codable
    @Inherits(decodable: false, encodable: false)
    class PermissiveHelperBase {
        var base: String = ""

        init() {}
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: true, encodable: true)
    class StrictHelperChild: PermissiveHelperBase {
        @CodedBy(PermissivePayloadCoder())
        var payload: PermissivePayload = .init(name: "")

        override init() {
            super.init()
        }
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: false, encodable: false)
    class StrictNestedScopeBase {
        init() {}
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: true, encodable: true)
    class StrictNestedScopeChild: StrictNestedScopeBase {
        @CodedBy(PermissiveNestedClassCoder())
        var payload: PermissiveNestedClass = .init()

        override init() {
            super.init()
        }
    }

    struct ManualSuperPayload: Swift.Decodable {
        let value: String
    }

    class ManualSuper: Swift.Decodable {
        var superValue: String = ""

        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: ManualKeys.self)
            superValue = try ManualSuperPayload(
                from: container.superDecoder()
            ).value
        }

        enum ManualKeys: String, CodingKey {
            case superValue = "super"
        }
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: true, encodable: false)
    class StrictManualSuperChild: ManualSuper {
        var child: String = ""
    }

    @Codable
    @Inherits(decodable: false, encodable: false)
    class PermissiveNestedBase {
        @CodedIn("payload")
        var base: String = ""

        init() {}
    }

    @Codable(rejectUnknownKeys: true)
    @Inherits(decodable: true, encodable: true)
    class StrictPermissiveNestedChild: PermissiveNestedBase {
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
    enum StrictDelegatedInternalCommand {
        case item(StrictDecodingTests.PermissivePayload)
    }

    @Codable(rejectUnknownKeys: true)
    @CodedAt("type")
    enum StrictStrictDelegatedInternalCommand {
        case item(StrictDecodingTests.StrictRecord)
    }

    @Codable(rejectUnknownKeys: true)
    @CodedAt("type")
    enum StrictWildcardDelegatedInternalCommand {
        case item(_: StrictDecodingTests.StrictRecord)
    }

    @Codable(rejectUnknownKeys: true)
    @CodedAt("type")
    enum StrictWildcardKeyedInternalCommand {
        case item(_ name: String)
    }

    @Codable(rejectUnknownKeys: true)
    @CodedAt("type")
    enum StrictOptionalDelegatedInternalCommand {
        case item(StrictDecodingTests.StrictRecord?)
    }

    @Codable(rejectUnknownKeys: true)
    @CodedAt("type")
    enum StrictOptionalStrategyCommand {
        case date(Date?)
        case data(Data?)
    }

    @Codable(rejectUnknownKeys: true)
    @CodedAt("type")
    enum StrictMixedInternalCommand {
        case item(
            StrictDecodingTests.PermissivePayload,
            count: Int
        )
    }

    @Codable(rejectUnknownKeys: true)
    @CodedAt("type")
    enum StrictMixedStrictInternalCommand {
        case item(
            StrictDecodingTests.StrictRecord,
            count: Int
        )
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
    @UnTagged
    enum StrictMixedUntaggedCommand: Equatable {
        case text(String)
        case record(value: Int)
    }

    @Codable(rejectUnknownKeys: true)
    @UnTagged
    enum StrictDelegatedUntaggedCommand {
        case record(StrictDecodingTests.StrictRecord)
        case number(value: Int)
    }

    @Codable(rejectUnknownKeys: true)
    @UnTagged
    enum StrictTransactionalUntaggedCommand {
        case number(value: Int)
        case record(StrictDecodingTests.PermissivePayload, count: Int)
    }

    @Codable(rejectUnknownKeys: true)
    @UnTagged
    enum StrictOptionalDecimalCommand {
        case decimal(Decimal?)
    }

    @Codable(rejectUnknownKeys: true)
    @CodedAt("meta", "kind")
    @ContentAt("meta")
    enum StrictNestedAdjacentCommand {
        case item(StrictDecodingTests.PermissivePayload)
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
    func strictInternalEnumsRejectKeysFromOtherCases() throws {
        try expectDataCorrupted(
            StrictInternalCommand.self,
            json: #"{"type":"load","key":"key","value":123}"#,
            containing: ["value"]
        )
    }

    @Test
    func strictInternalEnumsAllowDelegatedPayloadKeys() throws {
        let data = Data(
            #"{"type":"item","name":"n"}"#.utf8
        )
        let decoded = try JSONDecoder().decode(
            StrictDelegatedInternalCommand.self, from: data
        )
        if case .item(let value) = decoded {
            #expect(value.name == "n")
        } else {
            Issue.record("Expected delegated item case")
        }
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
    func strictChildOfPermissiveInheritanceAcceptsBaseKeys() throws {
        let data = Data(#"{"base":"base","child":"child"}"#.utf8)
        let decoded = try JSONDecoder().decode(
            PermissiveStrictChild.self, from: data
        )
        #expect(decoded.base == "base")
        #expect(decoded.child == "child")
    }

    @Test
    func strictMixedDirectAndKeyedRecordsAllowDelegatedKeys() throws {
        let data = Data(#"{"name":"n","count":1}"#.utf8)
        let decoded = try JSONDecoder().decode(
            StrictMixedDirectRecord.self, from: data
        )
        #expect(decoded.payload.name == "n")
        #expect(decoded.count == 1)

        try expectDataCorrupted(
            StrictMixedDirectRecord.self,
            json: #"{"name":"n","count":1,"extra":true}"#,
            containing: ["extra"]
        )
    }

    @Test
    func strictMixedOptionalAndDescendantRecordsCompileAndDecode() throws {
        let optional = try JSONDecoder().decode(
            StrictOptionalMixedDirectRecord.self,
            from: Data(#"{"name":"n","count":1}"#.utf8)
        )
        #expect(optional.payload?.name == "n")
        #expect(optional.count == 1)

        let descendant = try JSONDecoder().decode(
            StrictMixedDescendantRecord.self,
            from: Data(#"{"name":"n","details":{"count":1}}"#.utf8)
        )
        #expect(descendant.payload.name == "n")
        #expect(descendant.count == 1)
    }

    @Test
    func strictMixedNestedDirectAndKeyedRecordsAllowDelegatedKeys() throws {
        let data = Data(
            #"{"payload":{"name":"n","count":1}}"#.utf8
        )
        let decoded = try JSONDecoder().decode(
            StrictMixedNestedDirectRecord.self,
            from: data
        )
        #expect(decoded.payload.name == "n")
        #expect(decoded.count == 1)

        try expectDataCorrupted(
            StrictMixedNestedDirectRecord.self,
            json: #"{"payload":{"name":"n","count":1,"extra":true}}"#,
            containing: ["extra"]
        )
    }

    @Test
    func strictMixedNestedDefaultsAndOptionalsPreserveFallbacks() throws {
        let defaults = try JSONDecoder().decode(
            StrictMixedNestedDefaultRecord.self,
            from: Data("{}".utf8)
        )
        #expect(defaults.payload.name == "fallback")
        #expect(defaults.count == 0)

        let nulls = try JSONDecoder().decode(
            StrictMixedNestedOptionalRecord.self,
            from: Data(#"{"payload":null}"#.utf8)
        )
        #expect(nulls.payload == nil)
        #expect(nulls.count == nil)

        try expectDataCorrupted(
            StrictMixedNestedDefaultRecord.self,
            json: #"{"payload":{"name":"n","count":1,"extra":true}}"#,
            containing: ["extra"]
        )
        try expectDataCorrupted(
            StrictMixedNestedOptionalRecord.self,
            json: #"{"payload":{"name":"n","count":1,"extra":true}}"#,
            containing: ["extra"]
        )
    }

    @Test
    func strictScalarClassHierarchiesRemainScalar() throws {
        let data = Data(#""scalar""#.utf8)
        let decoded = try JSONDecoder().decode(
            StrictScalarChild.self, from: data
        )
        #expect(decoded.value == "scalar")
    }

    @Test
    func strictOptionalScalarClassHierarchiesAllowNull() throws {
        let decoded = try JSONDecoder().decode(
            StrictOptionalScalarChild.self,
            from: Data("null".utf8)
        )
        #expect(decoded.value == nil)
    }

    @Test
    func strictInheritedOptionalDirectPayloadPreservesMetadata() throws {
        let data = Data(
            #"{"name":"n","count":1,"child":"c"}"#.utf8
        )
        let decoded = try JSONDecoder().decode(
            StrictOptionalDirectChild.self,
            from: data
        )
        #expect(decoded.payload?.name == "n")
        #expect(decoded.payload?.count == 1)
        #expect(decoded.child == "c")
    }

    @Test
    func
        strictInheritedOptionalDirectPayloadFromPermissiveBasePreservesMetadata()
        throws
    {
        let data = Data(
            #"{"name":"n","count":1,"child":"c"}"#.utf8
        )
        let decoded = try JSONDecoder().decode(
            StrictOptionalDirectChildOfPermissive.self,
            from: data
        )
        #expect(decoded.payload?.name == "n")
        #expect(decoded.payload?.count == 1)
        #expect(decoded.child == "c")
    }

    @Test
    func strictInheritedMixedDirectPayloadPreservesMetadata() throws {
        let decoded = try JSONDecoder().decode(
            StrictMixedDirectChild.self,
            from: Data(
                #"{"payload":{"name":"n","count":1},"child":"c"}"#.utf8
            )
        )
        #expect(decoded.payload.name == "n")
        #expect(decoded.count == 1)
        #expect(decoded.child == "c")
    }

    @Test
    func strictOptionalDictionaryPayloadPreservesKeyDecodingStrategy() throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(
            StrictOptionalDictionaryRecord.self,
            from: Data(#"{"some_key":1}"#.utf8)
        )
        #expect(decoded.payload?["some_key"] == 1)
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
    func strictNestedInheritedHelperUsesItsOwnKeyScope() throws {
        let validData = Data(
            #"{"payload":{"nestedOnly":"nested"}}"#.utf8
        )
        let decoded = try JSONDecoder().decode(
            StrictNestedScopeChild.self,
            from: validData
        )
        #expect(decoded.payload.nestedOnly == "nested")

        try expectDataCorrupted(
            StrictNestedScopeChild.self,
            json: #"{"payload":{"nestedOnly":"nested"},"nestedOnly":"root"}"#,
            containing: ["nestedOnly"]
        )
    }

    @Test
    func strictManualSuperclassSuperDecoderKeysRemainSupported() throws {
        let data = Data(
            #"{"super":{"value":"super"},"child":"child"}"#.utf8
        )
        let decoded = try JSONDecoder().decode(
            StrictManualSuperChild.self,
            from: data
        )
        #expect(decoded.superValue == "super")
        #expect(decoded.child == "child")
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
    func strictStructuralInheritanceDoesNotSkipDeeperPaths() throws {
        try expectDataCorrupted(
            StrictStructuralChild.self,
            json: """
                {
                    "payload": {
                        "base": "base",
                        "details": {
                            "value": "value",
                            "extra": true
                        }
                    }
                }
                """,
            containing: ["extra"]
        )
    }

    @Test
    func strictNestedClassValidationNormalizesEnclosingCodingPaths() throws {
        try expectDataCorrupted(
            StrictEnvelope.self,
            json: """
                {
                    "item": {
                        "payload": {
                            "base": "base",
                            "child": "child",
                            "extra": true
                        }
                    }
                }
                """,
            containing: ["extra"]
        )
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
    func strictEmptyChildValidatesInheritedKeyedContainers() throws {
        let data = Data(#"{"base":"base"}"#.utf8)
        let decoded = try JSONDecoder().decode(
            StrictEmptyChild.self, from: data
        )
        #expect(decoded.base == "base")

        try expectDataCorrupted(
            StrictEmptyChild.self,
            json: #"{"base":"base","extra":true}"#,
            containing: ["extra"]
        )
    }

    @Test
    func strictEmptyHierarchyChildRejectsObjectKeys() throws {
        _ = try JSONDecoder().decode(
            StrictEmptyHierarchyChild.self,
            from: Data(#"{}"#.utf8)
        )

        try expectDataCorrupted(
            StrictEmptyHierarchyChild.self,
            json: #"{"extra":true}"#,
            containing: ["extra"]
        )
    }

    @Test
    func strictHelperPayloadOwnsItsNestedKeys() throws {
        let data = Data(
            #"{"base":"base","payload":{"name":"name","extra":true}}"#.utf8
        )
        let decoded = try JSONDecoder().decode(
            StrictHelperChild.self, from: data
        )
        #expect(decoded.payload.name == "name")

        try expectDataCorrupted(
            StrictHelperChild.self,
            json: #"{"base":"base","payload":{"name":"name"},"extra":true}"#,
            containing: ["extra"]
        )
    }

    @Test
    func strictChildOfPermissiveClassValidatesInheritedNestedContainers() throws
    {
        try expectDataCorrupted(
            StrictPermissiveNestedChild.self,
            json: #"{"child":"c","payload":{"base":"b","extra":true}}"#,
            containing: ["extra"]
        )
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
    func strictMixedUntaggedEnumsAllowScalarCases() throws {
        let data = Data(#""hello""#.utf8)
        let decoded = try JSONDecoder().decode(
            StrictMixedUntaggedCommand.self, from: data
        )
        #expect(decoded == .text("hello"))
    }

    @Test
    func strictMixedUntaggedEnumsPreserveUnknownKeyErrors() throws {
        try expectDataCorrupted(
            StrictMixedUntaggedCommand.self,
            json: #"{"value":1,"extra":true}"#,
            containing: ["extra"]
        )
    }

    @Test
    func strictUntaggedEnumsAllowDelegatedStrictObjects() throws {
        let data = Data(#"{"name":"n","count":1}"#.utf8)
        let decoded = try JSONDecoder().decode(
            StrictDelegatedUntaggedCommand.self, from: data
        )
        if case .record(let value) = decoded {
            #expect(value.name == "n")
            #expect(value.count == 1)
        } else {
            Issue.record("Expected delegated record case")
        }
    }

    @Test
    func strictUntaggedAttemptsRollbackFailedMetadata() throws {
        let data = Data(#"{"name":"n","count":1}"#.utf8)
        let decoded = try JSONDecoder().decode(
            StrictTransactionalUntaggedCommand.self,
            from: data
        )
        if case .record(let payload, let count) = decoded {
            #expect(payload.name == "n")
            #expect(count == 1)
        } else {
            Issue.record("Expected transactional record case")
        }
    }

    @Test
    func strictOptionalDecimalPayloadUsesSingleValueDecoding() throws {
        let decoded = try JSONDecoder().decode(
            StrictOptionalDecimalCommand.self,
            from: Data("123.45".utf8)
        )
        if case .decimal(let value) = decoded {
            #expect(value == Decimal(string: "123.45"))
        } else {
            Issue.record("Expected decimal case")
        }
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
