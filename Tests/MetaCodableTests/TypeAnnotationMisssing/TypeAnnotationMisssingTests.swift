#if SWIFT_SYNTAX_EXTENSION_MACRO_FIXED
import SwiftDiagnostics
import XCTest

@testable import PluginCore

final class TypeAnnotationMisssingTests: XCTestCase {

    func testBuiltinTypeInferred() throws {
        assertMacroExpansion(
            """
            @MemberInit
            struct SomeCodable {
                var int = 0
                var float = 0.1 as Float
                var double = Double(0.11)
                var string = "hello"
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var int = 0
                    var float = 0.1 as Float
                    var double = Double(0.11)
                    var string = "hello"

                    init(int: Int = 0, float: Float = 0.1 as Float, double: Double = Double(0.11), string: String = "hello") {
                        self.int = int
                        self.float = float
                        self.double = double
                        self.string = string
                    }
                }
                """
        )
    }

    func testBuiltinTypeInferredWithDefaultAttribute() throws {
        assertMacroExpansion(
            """
            @MemberInit
            struct SomeCodable {
                @Default(10)
                var int = 0
                var float = 0.1 as Float
                var double = Double(0.11)
                let string: String
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var int = 0
                    var float = 0.1 as Float
                    var double = Double(0.11)
                    let string: String

                    init(int: Int = 10, float: Float = 0.1 as Float, double: Double = Double(0.11), string: String) {
                        self.int = int
                        self.float = float
                        self.double = double
                        self.string = string
                    }
                }
                """
        )
    }
    
    func testBuiltinTypeInferredWithMultipleBinding() throws {
        assertMacroExpansion(
            """
            @MemberInit
            struct SomeCodable {
                @Default(10)
                var int = 0
                var float = Float(0.1), string = ""
            }
            """,
            expandedSource:
                """
                struct SomeCodable {
                    var int = 0
                    var float = Float(0.1), string = ""

                    init(int: Int = 10, float: Float = Float(0.1), string: String = "") {
                        self.int = int
                        self.float = float
                        self.string = string
                    }
                }
                """
        )
    }
}
#endif
