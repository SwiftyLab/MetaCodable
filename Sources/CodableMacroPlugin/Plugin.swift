@_implementationOnly import SwiftCompilerPlugin
@_implementationOnly import SwiftSyntaxMacros

/// The compiler plugin that exposes all the macro type defined.
///
/// New macro types should be added to `providingMacros`
/// array.
@main
struct MetaCodablePlugin: CompilerPlugin {
    /// All the macros provided by this macro plugin.
    ///
    /// New macro types should be added here.
    let providingMacros: [Macro.Type] = [
        CodedAt.self,
        CodedIn.self,
        CodedBy.self,
        Default.self,
        IgnoreCoding.self,
        IgnoreDecoding.self,
        IgnoreEncoding.self,
        Codable.self,
        MemberInit.self,
        CodingKeys.self,
        IgnoreCodingInitialized.self,
    ]
}
