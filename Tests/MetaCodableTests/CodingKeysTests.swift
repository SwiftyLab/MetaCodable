#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import XCTest

@testable import PluginCore

final class CodingKeysTests: XCTestCase {

    func testMisuseInAbsenceOfCodable() throws {
        assertMacroExpansion(
            """
            @CodingKeys(.snake_case)
            struct SomeCodable {
                let productName: String
                let productCost: String
                let description: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let productName: String
                    let productCost: String
                    let description: String
                }
                """,
            diagnostics: [
                .init(
                    id: CodingKeys.misuseID,
                    message:
                        "@CodingKeys must be used in combination with @Codable",
                    line: 1, column: 1,
                    fixIts: [
                        .init(
                            message: "Remove @CodingKeys attribute"
                        )
                    ]
                )
            ]
        )
    }

    func testMisuseOnDuplicationAbsenceOfCodable() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodingKeys(.PascalCase)
            @CodingKeys(.snake_case)
            struct SomeCodable {
                let productName: String
                let productCost: String
                let description: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let productName: String
                    let productCost: String
                    let description: String
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.productName, forKey: CodingKeys.productName)
                        try container.encode(self.productCost, forKey: CodingKeys.productCost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case productName = "ProductName"
                        case productCost = "ProductCost"
                        case description = "Description"
                    }
                }
                """,
            diagnostics: [
                .init(
                    id: CodingKeys.misuseID,
                    message:
                        "@CodingKeys can only be applied once per declaration",
                    line: 2, column: 1,
                    fixIts: [
                        .init(
                            message: "Remove @CodingKeys attribute"
                        )
                    ]
                ),
                .init(
                    id: CodingKeys.misuseID,
                    message:
                        "@CodingKeys can only be applied once per declaration",
                    line: 3, column: 1,
                    fixIts: [
                        .init(
                            message: "Remove @CodingKeys attribute"
                        )
                    ]
                ),
            ]
        )
    }

    func testCameCaseToPascalCase() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodingKeys(.PascalCase)
            struct SomeCodable {
                let productName: String
                let productCost: String
                let description: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let productName: String
                    let productCost: String
                    let description: String
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.productName, forKey: CodingKeys.productName)
                        try container.encode(self.productCost, forKey: CodingKeys.productCost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case productName = "ProductName"
                        case productCost = "ProductCost"
                        case description = "Description"
                    }
                }
                """
        )
    }

    func testCameCaseToSnakeCase() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodingKeys(.snake_case)
            struct SomeCodable {
                let productName: String
                let productCost: String
                let description: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let productName: String
                    let productCost: String
                    let description: String
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.productName, forKey: CodingKeys.productName)
                        try container.encode(self.productCost, forKey: CodingKeys.productCost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case productName = "product_name"
                        case productCost = "product_cost"
                        case description = "description"
                    }
                }
                """
        )
    }

    func testClassCameCaseToSnakeCase() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodingKeys(.snake_case)
            class SomeCodable {
                let productName: String
                let productCost: String
                let description: String
            }
            """,
            expandedSource:
                """
                class SomeCodable {
                    let productName: String
                    let productCost: String
                    let description: String

                    required init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }

                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.productName, forKey: CodingKeys.productName)
                        try container.encode(self.productCost, forKey: CodingKeys.productCost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }

                    enum CodingKeys: String, CodingKey {
                        case productName = "product_name"
                        case productCost = "product_cost"
                        case description = "description"
                    }
                }

                extension SomeCodable: Decodable {
                }

                extension SomeCodable: Encodable {
                }
                """
        )
    }

    func testEnumCameCaseToSnakeCase() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodingKeys(.snake_case)
            enum SomeEnum {
                @CodingKeys(.kebab－case)
                case bool(_ variableBool: Bool)
                @CodedAs("altInt")
                case int(valInt: Int)
                @CodedAs("altString")
                case string(String)
                case multi(_ variable: Bool, val: Int, String)
            }
            """,
            expandedSource:
                """
                enum SomeEnum {
                    case bool(_ variableBool: Bool)
                    case int(valInt: Int)
                    case string(String)
                    case multi(_ variable: Bool, val: Int, String)
                }

                extension SomeEnum: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: DecodingKeys.self)
                        guard container.allKeys.count == 1 else {
                            let context = DecodingError.Context(
                                codingPath: container.codingPath,
                                debugDescription: "Invalid number of keys found, expected one."
                            )
                            throw DecodingError.typeMismatch(SomeEnum.self, context)
                        }
                        let contentDecoder = try container.superDecoder(forKey: container.allKeys.first.unsafelyUnwrapped)
                        switch container.allKeys.first.unsafelyUnwrapped {
                        case DecodingKeys.bool:
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let variableBool = try container.decode(Bool.self, forKey: CodingKeys.variableBool)
                            self = .bool(_: variableBool)
                        case DecodingKeys.int:
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let valInt = try container.decode(Int.self, forKey: CodingKeys.valInt)
                            self = .int(valInt: valInt)
                        case DecodingKeys.string:
                            let _0 = try String(from: contentDecoder)
                            self = .string(_0)
                        case DecodingKeys.multi:
                            let _2 = try String(from: contentDecoder)
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                            let val = try container.decode(Int.self, forKey: CodingKeys.val)
                            self = .multi(_: variable, val: val, _2)
                        }
                    }
                }

                extension SomeEnum: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        switch self {
                        case .bool(_: let variableBool):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.bool)
                            var container = contentEncoder.container(keyedBy: CodingKeys.self)
                            try container.encode(variableBool, forKey: CodingKeys.variableBool)
                        case .int(valInt: let valInt):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.int)
                            var container = contentEncoder.container(keyedBy: CodingKeys.self)
                            try container.encode(valInt, forKey: CodingKeys.valInt)
                        case .string(let _0):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.string)
                            try _0.encode(to: contentEncoder)
                        case .multi(_: let variable,val: let val,let _2):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.multi)
                            try _2.encode(to: contentEncoder)
                            var container = contentEncoder.container(keyedBy: CodingKeys.self)
                            try container.encode(variable, forKey: CodingKeys.variable)
                            try container.encode(val, forKey: CodingKeys.val)
                        }
                    }
                }

                extension SomeEnum {
                    enum CodingKeys: String, CodingKey {
                        case variableBool = "variable-bool"
                        case bool = "bool"
                        case valInt = "val_int"
                        case int = "altInt"
                        case string = "altString"
                        case variable = "variable"
                        case val = "val"
                        case multi = "multi"
                    }
                    enum DecodingKeys: String, CodingKey {
                        case bool = "bool"
                        case int = "altInt"
                        case string = "altString"
                        case multi = "multi"
                    }
                }
                """
        )
    }

    func testCameCaseToCamelSnakeCase() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodingKeys(.camel_Snake_Case)
            struct SomeCodable {
                let productName: String
                let productCost: String
                let description: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let productName: String
                    let productCost: String
                    let description: String
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.productName, forKey: CodingKeys.productName)
                        try container.encode(self.productCost, forKey: CodingKeys.productCost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case productName = "product_Name"
                        case productCost = "product_Cost"
                        case description = "description"
                    }
                }
                """
        )
    }

    func testCameCaseToScreamingSnakeCase() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodingKeys(.SCREAMING_SNAKE_CASE)
            struct SomeCodable {
                let productName: String
                let productCost: String
                let description: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let productName: String
                    let productCost: String
                    let description: String
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.productName, forKey: CodingKeys.productName)
                        try container.encode(self.productCost, forKey: CodingKeys.productCost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case productName = "PRODUCT_NAME"
                        case productCost = "PRODUCT_COST"
                        case description = "DESCRIPTION"
                    }
                }
                """
        )
    }

    func testCameCaseToKebabCase() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodingKeys(.kebab－case)
            struct SomeCodable {
                let productName: String
                let productCost: String
                let description: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let productName: String
                    let productCost: String
                    let description: String
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.productName, forKey: CodingKeys.productName)
                        try container.encode(self.productCost, forKey: CodingKeys.productCost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case productName = "product-name"
                        case productCost = "product-cost"
                        case description = "description"
                    }
                }
                """
        )
    }

    func testCameCaseToScreamingKebabCase() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodingKeys(.SCREAMING－KEBAB－CASE)
            struct SomeCodable {
                let productName: String
                let productCost: String
                let description: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let productName: String
                    let productCost: String
                    let description: String
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.productName, forKey: CodingKeys.productName)
                        try container.encode(self.productCost, forKey: CodingKeys.productCost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case productName = "PRODUCT-NAME"
                        case productCost = "PRODUCT-COST"
                        case description = "DESCRIPTION"
                    }
                }
                """
        )
    }

    func testCameCaseToTrainCase() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodingKeys(.Train－Case)
            struct SomeCodable {
                let productName: String
                let productCost: String
                let description: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let productName: String
                    let productCost: String
                    let description: String
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.productName, forKey: CodingKeys.productName)
                        try container.encode(self.productCost, forKey: CodingKeys.productCost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case productName = "Product-Name"
                        case productCost = "Product-Cost"
                        case description = "Description"
                    }
                }
                """
        )
    }

    func testSnakeCaseToCameCase() throws {
        assertMacroExpansion(
            """
            @Codable
            @CodingKeys(.camelCase)
            struct SomeCodable {
                let product_name: String
                let product_cost: String
                let description: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let product_name: String
                    let product_cost: String
                    let description: String
                }

                extension SomeCodable: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.product_name = try container.decode(String.self, forKey: CodingKeys.product_name)
                        self.product_cost = try container.decode(String.self, forKey: CodingKeys.product_cost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.product_name, forKey: CodingKeys.product_name)
                        try container.encode(self.product_cost, forKey: CodingKeys.product_cost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                }

                extension SomeCodable {
                    enum CodingKeys: String, CodingKey {
                        case product_name = "productName"
                        case product_cost = "productCost"
                        case description = "description"
                    }
                }
                """
        )
    }

    func testEnumCasesSupport() throws {
        assertMacroExpansion(
            """
            @Codable
            enum SomeEnum {
                @CodingKeys(.snake_case)
                case bool(_ variable: Bool)
                @CodingKeys(.PascalCase)
                @CodedAs("altInt")
                case int(val: Int)
                @CodingKeys(.kebab－case)
                @CodedAs("altString")
                case string(String)
                case multi(_ variable: Bool, val: Int, String)
            }
            """,
            expandedSource:
                """
                enum SomeEnum {
                    case bool(_ variable: Bool)
                    case int(val: Int)
                    case string(String)
                    case multi(_ variable: Bool, val: Int, String)
                }

                extension SomeEnum: Decodable {
                    init(from decoder: any Decoder) throws {
                        let container = try decoder.container(keyedBy: DecodingKeys.self)
                        guard container.allKeys.count == 1 else {
                            let context = DecodingError.Context(
                                codingPath: container.codingPath,
                                debugDescription: "Invalid number of keys found, expected one."
                            )
                            throw DecodingError.typeMismatch(SomeEnum.self, context)
                        }
                        let contentDecoder = try container.superDecoder(forKey: container.allKeys.first.unsafelyUnwrapped)
                        switch container.allKeys.first.unsafelyUnwrapped {
                        case DecodingKeys.bool:
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                            self = .bool(_: variable)
                        case DecodingKeys.int:
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let val = try container.decode(Int.self, forKey: CodingKeys.val)
                            self = .int(val: val)
                        case DecodingKeys.string:
                            let _0 = try String(from: contentDecoder)
                            self = .string(_0)
                        case DecodingKeys.multi:
                            let _2 = try String(from: contentDecoder)
                            let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                            let variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                            let val = try container.decode(Int.self, forKey: CodingKeys.__macro_local_3valfMu0_)
                            self = .multi(_: variable, val: val, _2)
                        }
                    }
                }

                extension SomeEnum: Encodable {
                    func encode(to encoder: any Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        switch self {
                        case .bool(_: let variable):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.bool)
                            var container = contentEncoder.container(keyedBy: CodingKeys.self)
                            try container.encode(variable, forKey: CodingKeys.variable)
                        case .int(val: let val):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.int)
                            var container = contentEncoder.container(keyedBy: CodingKeys.self)
                            try container.encode(val, forKey: CodingKeys.val)
                        case .string(let _0):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.string)
                            try _0.encode(to: contentEncoder)
                        case .multi(_: let variable,val: let val,let _2):
                            let contentEncoder = container.superEncoder(forKey: CodingKeys.multi)
                            try _2.encode(to: contentEncoder)
                            var container = contentEncoder.container(keyedBy: CodingKeys.self)
                            try container.encode(variable, forKey: CodingKeys.variable)
                            try container.encode(val, forKey: CodingKeys.__macro_local_3valfMu0_)
                        }
                    }
                }

                extension SomeEnum {
                    enum CodingKeys: String, CodingKey {
                        case variable = "variable"
                        case bool = "bool"
                        case val = "Val"
                        case int = "altInt"
                        case string = "altString"
                        case __macro_local_3valfMu0_ = "val"
                        case multi = "multi"
                    }
                    enum DecodingKeys: String, CodingKey {
                        case bool = "bool"
                        case int = "altInt"
                        case string = "altString"
                        case multi = "multi"
                    }
                }
                """
        )
    }
}
#endif
