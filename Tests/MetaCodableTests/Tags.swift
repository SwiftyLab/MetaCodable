import Testing

// MARK: Test Tags

/// Test tags for organizing and filtering `MetaCodable` tests.
extension Tag {
    
    // MARK: Macro
    
    /// Tests for `@Codable` macro
    @Tag static var codable: Self
    
    /// Tests for `@CodedAt` macro
    @Tag static var codedAt: Self
    
    /// Tests for `@CodedIn` macro
    @Tag static var codedIn: Self
    
    /// Tests for `@CodedBy` macro
    @Tag static var codedBy: Self
    
    /// Tests for `@CodedAs` macro
    @Tag static var codedAs: Self
    
    /// Tests for `@CodingKeys` macro
    @Tag static var codingKeys: Self
    
    /// Tests for `@Default` macro
    @Tag static var `default`: Self
    
    /// Tests for `@IgnoreCoding` macro
    @Tag static var ignoreCoding: Self
    
    /// Tests for `@IgnoreDecoding` macro
    @Tag static var ignoreDecoding: Self
    
    /// Tests for `@IgnoreEncoding` macro
    @Tag static var ignoreEncoding: Self
    
    /// Tests for `@IgnoreCodingInitialized` macro
    @Tag static var ignoreCodingInitialized: Self
    
    /// Tests for `@ContentAt` macro
    @Tag static var contentAt: Self
    
    /// Tests for `@UnTagged` macro
    @Tag static var untagged: Self
    
    /// Tests for `@MemberInit` macro
    @Tag static var memberInit: Self
    
    /// Tests for `@Inherits` macro
    @Tag static var inherits: Self
    
    // MARK: Test Type
    
    /// Tests that verify macro expansion output
    @Tag static var macroExpansion: Self
    
    /// Tests for encoding functionality
    @Tag static var encoding: Self
    
    /// Tests for decoding functionality
    @Tag static var decoding: Self
    
    /// Tests for error handling and diagnostics
    @Tag static var errorHandling: Self
    
    /// Integration tests combining multiple features
    @Tag static var integration: Self
    
    // MARK: Feature
    
    /// Tests for `HelperCoder` and related types
    @Tag static var helperCoders: Self
    
    /// Tests for dynamic coding features
    @Tag static var dynamicCoding: Self
    
    /// Tests for inheritance support
    @Tag static var inheritance: Self
    
    /// Tests for generics support
    @Tag static var generics: Self
    
    /// Tests for access modifier handling
    @Tag static var accessModifiers: Self
    
    /// Tests for `Optional`/`nil` handling
    @Tag static var optionals: Self
    
    /// Tests for `enum` types
    @Tag static var enums: Self
    
    /// Tests for `struct` types
    @Tag static var structs: Self
    
    /// Tests for `class` types
    @Tag static var classes: Self
    
    /// Tests for `RawRepresentable` types
    @Tag static var rawRepresentable: Self
    
    // MARK: Coverage
    
    /// Tests created specifically for coverage improvement
    @Tag static var coverage: Self
    
    // MARK: Helper Coder
    
    /// Tests for date coders
    @Tag static var dateCoder: Self
    
    /// Tests for data coders (`Base64`)
    @Tag static var dataCoder: Self
    
    /// Tests for sequence coders
    @Tag static var sequenceCoder: Self
    
    /// Tests for lossy sequence handling
    @Tag static var lossySequence: Self
    
    /// Tests for value coders
    @Tag static var valueCoder: Self
    
    /// Tests for non-conforming coders
    @Tag static var nonConformingCoder: Self
    
    /// Tests for conditional coders
    @Tag static var conditionalCoder: Self
}
