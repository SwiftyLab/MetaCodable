@_exported import XCTest

/// Dummy swift-testing `Test` macro.
@attached(peer)
@available(swift 5.9)
public macro Test() = #externalMacro(module: "TestingMacroPlugin", type: "Test")

/// Dummy swift-testing `Test` macro.
@attached(peer)
@available(swift 5.9)
public macro Test<S: Sequence>(arguments: S) =
    #externalMacro(module: "TestingMacroPlugin", type: "Test")

/// Dummy swift-testing `Tag` macro.
@attached(accessor)
@available(swift 5.9)
public macro Tag() = #externalMacro(module: "TestingMacroPlugin", type: "Tag")

/// Dummy swift-testing `require` macro.
///
/// This expands to `XCTUnwrap`.
@freestanding(expression)
@available(swift 5.9)
public macro require<T>(
    _ value: T?, sourceLocation: Issue.Location? = nil
) -> T =
    #externalMacro(module: "TestingMacroPlugin", type: "RequireOptional")

/// Dummy swift-testing `expect` macro.
///
/// This expands to:
/// * `XCTAssertEqual` if condition is an equality check.
/// * `XCTAssertTrue` otherwise.
@freestanding(expression)
@available(swift 5.9)
public macro expect(_ expression: Bool) =
    #externalMacro(module: "TestingMacroPlugin", type: "Expect")

/// Dummy swift-testing `expect(throws:)` macro.
///
/// This expands to `XCTAssertThrowsError` and uses `XCTAssertTrue`
/// for validating error type in `errorHandler`.
@freestanding(expression)
@available(swift 5.9)
public macro expect(throws: Error.Type, in call: () throws -> Void) =
    #externalMacro(module: "TestingMacroPlugin", type: "ExpectThrows")
