/// Dummy swift-testing `Tag` type.
public struct Tag {}

/// Dummy swift-testing `Tag` type.
public struct Issue {
    /// Dummy swift-testing `record` method implementation.
    ///
    /// Passes the error message and source location to `XCTFail`.
    ///
    /// - Parameters:
    ///   - message: The failure message.
    ///   - sourceLocation: The optional source code location.
    ///   - fileID: The identifier of file, method invoked from.
    ///   - filePath: The path to file, method invoked from.
    ///   - line: The source code line, method invoked from.
    ///   - column: The source code column, method invoked from.
    public static func record(
        _ message: Message, sourceLocation: Location? = nil,
        fileID: StaticString = #fileID, filePath: StaticString = #filePath,
        line: UInt = #line, column: UInt = #column
    ) {
        XCTFail(
            message.rawValue, file: sourceLocation?.filePath ?? filePath,
            line: sourceLocation?.line ?? line
        )
    }

    /// Dummy swift-testing `Tag` type.
    public struct Message: ExpressibleByStringLiteral, RawRepresentable {
        /// The actual message.
        public var rawValue: String

        /// Create from a message literal.
        ///
        /// - Parameter rawValue: The actual message.
        public init(stringLiteral rawValue: String) {
            self.rawValue = rawValue
        }

        /// Create from a message value.
        ///
        /// - Parameter rawValue: The actual message.
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    /// Dummy swift-testing `Tag` type.
    public struct Location {
        /// The identifier of file source code belongs to.
        let fileID: StaticString
        /// The path to file source code belongs to.
        let filePath: StaticString
        /// The line source code belongs to.
        let line: UInt
        /// The column source code belongs to.
        let column: UInt

        /// Create location from provided parameters.
        ///
        /// - Parameters:
        ///   - fileID: The identifier of file source code belongs to.
        ///   - filePath: The path to file source code belongs to.
        ///   - line: The line source code belongs to.
        ///   - column: The column source code belongs to.
        public init(
            fileID: StaticString, filePath: StaticString,
            line: UInt, column: UInt
        ) {
            self.fileID = fileID
            self.filePath = filePath
            self.line = line
            self.column = column
        }
    }
}
