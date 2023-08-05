import XCTest
@testable import CodableMacroPlugin

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
                    init(productName: String, productCost: String, description: String) {
                        self.productName = productName
                        self.productCost = productCost
                        self.description = description
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.productName, forKey: CodingKeys.productName)
                        try container.encode(self.productCost, forKey: CodingKeys.productCost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                    enum CodingKeys: String, CodingKey {
                        case productName = "ProductName"
                        case productCost = "ProductCost"
                        case description = "Description"
                    }
                }
                extension SomeCodable: Codable {
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
                    init(productName: String, productCost: String, description: String) {
                        self.productName = productName
                        self.productCost = productCost
                        self.description = description
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.productName, forKey: CodingKeys.productName)
                        try container.encode(self.productCost, forKey: CodingKeys.productCost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                    enum CodingKeys: String, CodingKey {
                        case productName = "ProductName"
                        case productCost = "ProductCost"
                        case description = "Description"
                    }
                }
                extension SomeCodable: Codable {
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
                    init(productName: String, productCost: String, description: String) {
                        self.productName = productName
                        self.productCost = productCost
                        self.description = description
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                    func encode(to encoder: Encoder) throws {
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
                extension SomeCodable: Codable {
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
                    init(productName: String, productCost: String, description: String) {
                        self.productName = productName
                        self.productCost = productCost
                        self.description = description
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.productName, forKey: CodingKeys.productName)
                        try container.encode(self.productCost, forKey: CodingKeys.productCost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                    enum CodingKeys: String, CodingKey {
                        case productName = "product_Name"
                        case productCost = "product_Cost"
                        case description = "description"
                    }
                }
                extension SomeCodable: Codable {
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
                    init(productName: String, productCost: String, description: String) {
                        self.productName = productName
                        self.productCost = productCost
                        self.description = description
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.productName, forKey: CodingKeys.productName)
                        try container.encode(self.productCost, forKey: CodingKeys.productCost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                    enum CodingKeys: String, CodingKey {
                        case productName = "PRODUCT_NAME"
                        case productCost = "PRODUCT_COST"
                        case description = "DESCRIPTION"
                    }
                }
                extension SomeCodable: Codable {
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
                    init(productName: String, productCost: String, description: String) {
                        self.productName = productName
                        self.productCost = productCost
                        self.description = description
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.productName, forKey: CodingKeys.productName)
                        try container.encode(self.productCost, forKey: CodingKeys.productCost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                    enum CodingKeys: String, CodingKey {
                        case productName = "product-name"
                        case productCost = "product-cost"
                        case description = "description"
                    }
                }
                extension SomeCodable: Codable {
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
                    init(productName: String, productCost: String, description: String) {
                        self.productName = productName
                        self.productCost = productCost
                        self.description = description
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.productName, forKey: CodingKeys.productName)
                        try container.encode(self.productCost, forKey: CodingKeys.productCost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                    enum CodingKeys: String, CodingKey {
                        case productName = "PRODUCT-NAME"
                        case productCost = "PRODUCT-COST"
                        case description = "DESCRIPTION"
                    }
                }
                extension SomeCodable: Codable {
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
                    init(productName: String, productCost: String, description: String) {
                        self.productName = productName
                        self.productCost = productCost
                        self.description = description
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.productName = try container.decode(String.self, forKey: CodingKeys.productName)
                        self.productCost = try container.decode(String.self, forKey: CodingKeys.productCost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.productName, forKey: CodingKeys.productName)
                        try container.encode(self.productCost, forKey: CodingKeys.productCost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                    enum CodingKeys: String, CodingKey {
                        case productName = "Product-Name"
                        case productCost = "Product-Cost"
                        case description = "Description"
                    }
                }
                extension SomeCodable: Codable {
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
                    init(product_name: String, product_cost: String, description: String) {
                        self.product_name = product_name
                        self.product_cost = product_cost
                        self.description = description
                    }
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.product_name = try container.decode(String.self, forKey: CodingKeys.product_name)
                        self.product_cost = try container.decode(String.self, forKey: CodingKeys.product_cost)
                        self.description = try container.decode(String.self, forKey: CodingKeys.description)
                    }
                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        try container.encode(self.product_name, forKey: CodingKeys.product_name)
                        try container.encode(self.product_cost, forKey: CodingKeys.product_cost)
                        try container.encode(self.description, forKey: CodingKeys.description)
                    }
                    enum CodingKeys: String, CodingKey {
                        case product_name = "productName"
                        case product_cost = "productCost"
                        case description = "description"
                    }
                }
                extension SomeCodable: Codable {
                }
                """
        )
    }
}
