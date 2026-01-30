import MetaCodable
import Testing

@testable import PluginCore

@Suite("Coding Keys Tests")
struct CodingKeysTests {
    @Test("Reports error when @CodingKeys is used without @Codable")
    func misuseInAbsenceOfCodable() throws {
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

    @Test("Reports error when @Codable is applied multiple times (CodingKeysTests #1)")
    func misuseOnDuplicationAbsenceOfCodable() throws {
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

    @Suite("Coding Keys - Came Case To Pascal Case")
    struct CameCaseToPascalCase {
        @Codable
        @CodingKeys(.PascalCase)
        struct SomeCodable {
            let productName: String
            let productCost: String
            let description: String
        }

        @Test("Generates macro expansion with @Codable for struct (CodingKeysTests #68)")
        func expansion() throws {
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
    }

    @Suite("Coding Keys - Came Case To Snake Case")
    struct CameCaseToSnakeCase {
        @Codable
        @CodingKeys(.snake_case)
        struct SomeCodable {
            let productName: String
            let productCost: String
            let description: String
        }

        @Test("Generates macro expansion with @Codable for struct (CodingKeysTests #69)")
        func expansion() throws {
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
    }

    @Suite("Coding Keys - Class Came Case To Snake Case")
    struct ClassCameCaseToSnakeCase {
        @Codable
        @CodingKeys(.snake_case)
        class SomeCodable {
            let productName: String
            let productCost: String
            let description: String
        }

        @Test("Generates macro expansion with @Codable for class (CodingKeysTests #3)")
        func expansion() throws {
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
    }

    @Suite("Coding Keys - Enum Came Case To Snake Case")
    struct EnumCameCaseToSnakeCase {
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

        @Test("Generates macro expansion with @Codable for enum (CodingKeysTests #8)")
        func expansion() throws {
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
                                throw DecodingError.typeMismatch(Self.self, context)
                            }
                            let contentDecoder = try container.superDecoder(forKey: container.allKeys.first.unsafelyUnwrapped)
                            switch container.allKeys.first.unsafelyUnwrapped {
                            case DecodingKeys.bool:
                                let variableBool: Bool
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                variableBool = try container.decode(Bool.self, forKey: CodingKeys.variableBool)
                                self = .bool(_: variableBool)
                            case DecodingKeys.int:
                                let valInt: Int
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                valInt = try container.decode(Int.self, forKey: CodingKeys.valInt)
                                self = .int(valInt: valInt)
                            case DecodingKeys.string:
                                let _0: String
                                _0 = try String(from: contentDecoder)
                                self = .string(_0)
                            case DecodingKeys.multi:
                                let variable: Bool
                                let val: Int
                                let _2: String
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                _2 = try String(from: contentDecoder)
                                variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                                val = try container.decode(Int.self, forKey: CodingKeys.val)
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
                            case .multi(_: let variable, val: let val, let _2):
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
    }

    @Suite("Coding Keys - Came Case To Camel Snake Case")
    struct CameCaseToCamelSnakeCase {
        @Codable
        @CodingKeys(.camel_Snake_Case)
        struct SomeCodable {
            let productName: String
            let productCost: String
            let description: String
        }

        @Test("Generates macro expansion with @Codable for struct (CodingKeysTests #70)")
        func expansion() throws {
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
    }

    @Suite("Coding Keys - Came Case To Screaming Snake Case")
    struct CameCaseToScreamingSnakeCase {
        @Codable
        @CodingKeys(.SCREAMING_SNAKE_CASE)
        struct SomeCodable {
            let productName: String
            let productCost: String
            let description: String
        }

        @Test("Generates macro expansion with @Codable for struct (CodingKeysTests #71)")
        func expansion() throws {
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
    }

    @Suite("Coding Keys - Came Case To Kebab Case")
    struct CameCaseToKebabCase {
        @Codable
        @CodingKeys(.kebab－case)
        struct SomeCodable {
            let productName: String
            let productCost: String
            let description: String
        }

        @Test("Generates macro expansion with @Codable for struct (CodingKeysTests #72)")
        func expansion() throws {
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
    }

    @Suite("Coding Keys - Came Case To Screaming Kebab Case")
    struct CameCaseToScreamingKebabCase {
        @Codable
        @CodingKeys(.SCREAMING－KEBAB－CASE)
        struct SomeCodable {
            let productName: String
            let productCost: String
            let description: String
        }

        @Test("Generates macro expansion with @Codable for struct (CodingKeysTests #73)")
        func expansion() throws {
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
    }

    @Suite("Coding Keys - Came Case To Train Case")
    struct CameCaseToTrainCase {
        @Codable
        @CodingKeys(.Train－Case)
        struct SomeCodable {
            let productName: String
            let productCost: String
            let description: String
        }

        @Test("Generates macro expansion with @Codable for struct (CodingKeysTests #74)")
        func expansion() throws {
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
    }

    @Suite("Coding Keys - Snake Case To Came Case")
    struct SnakeCaseToCameCase {
        @Codable
        @CodingKeys(.camelCase)
        struct SomeCodable {
            let product_name: String
            let product_cost: String
            let description: String
        }

        @Test("Generates macro expansion with @Codable for struct (CodingKeysTests #75)")
        func expansion() throws {
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
    }

    @Suite("Coding Keys - Enum Cases Support")
    struct EnumCasesSupport {
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

        @Test("Generates macro expansion with @Codable for enum (CodingKeysTests #9)")
        func expansion() throws {
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
                                throw DecodingError.typeMismatch(Self.self, context)
                            }
                            let contentDecoder = try container.superDecoder(forKey: container.allKeys.first.unsafelyUnwrapped)
                            switch container.allKeys.first.unsafelyUnwrapped {
                            case DecodingKeys.bool:
                                let variable: Bool
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                                self = .bool(_: variable)
                            case DecodingKeys.int:
                                let val: Int
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                val = try container.decode(Int.self, forKey: CodingKeys.val)
                                self = .int(val: val)
                            case DecodingKeys.string:
                                let _0: String
                                _0 = try String(from: contentDecoder)
                                self = .string(_0)
                            case DecodingKeys.multi:
                                let variable: Bool
                                let val: Int
                                let _2: String
                                let container = try contentDecoder.container(keyedBy: CodingKeys.self)
                                _2 = try String(from: contentDecoder)
                                variable = try container.decode(Bool.self, forKey: CodingKeys.variable)
                                val = try container.decode(Int.self, forKey: CodingKeys.__macro_local_3valfMu0_)
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
                            case .multi(_: let variable, val: let val, let _2):
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
}
