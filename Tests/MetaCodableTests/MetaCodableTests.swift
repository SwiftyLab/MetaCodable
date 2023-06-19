import XCTest
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
@testable import CodableMacroPlugin

final class CodableMacroPluginUnitTests: XCTestCase {
    func testWithoutFieldMacros() throws {
        assertMacroExpansion(
            """
            @Codable
            struct SomeCodable {
                let value: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    let value: String

                    init(value: String) {
                        self.value = value
                    }

                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.decode(String.self, forKey: CodingKeys.value)
                    }

                    func encode(to encoder: Encoder) throws {
                        var container = encoder.container(keyedBy: CodingKeys.self)
                        self.value = try container.encode(self.value, forKey: CodingKeys.value)
                    }

                    enum CodingKeys: String, CodingKey {
                        case value = "value"
                    }
                }
                """,
            macros: ["Codable": CodableMacro.self]
        )
    }
}
