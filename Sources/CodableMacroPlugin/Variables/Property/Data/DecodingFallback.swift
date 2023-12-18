@_implementationOnly import SwiftSyntax

/// Represents possible fallback options for decoding failure.
///
/// When decoding fails for variable, variable can have fallback
/// to throw the failure error or handle it completely or handle
/// it only when variable is missing or `null`.
enum DecodingFallback {
    /// Represents no fallback option.
    ///
    /// Indicates decoding failure error
    /// is thrown without any handling.
    case `throw`
    /// Represents fallback option for missing
    /// or `null` value.
    ///
    /// Indicates if variable data is missing or `null`,
    /// provided fallback syntax will be used for initialization.
    case ifMissing(CodeBlockItemListSyntax)
    /// Represents fallback option handling
    /// decoding failure completely.
    ///
    /// Indicates for any type of failure error in decoding,
    /// provided fallback syntax will be used for initialization.
    case ifError(CodeBlockItemListSyntax)

    /// Provides the code block list syntax for decoding provided
    /// container applying current fallback options.
    ///
    /// - Parameters:
    ///   - container: The container to decode from.
    ///   - key: The key from where to decode.
    ///   - decoding: The nested container decoding
    ///     code block generator.
    ///
    /// - Returns: The generated code block.
    func represented(
        decodingContainer container: TokenSyntax,
        fromKey key: CaseMap.Key,
        nestedDecoding decoding: (TokenSyntax) -> CodeBlockItemListSyntax
    ) -> CodeBlockItemListSyntax {
        let nestedContainer: TokenSyntax = "\(key.raw)_\(container)"
        return CodeBlockItemListSyntax {
            switch self {
            case .throw:
                """
                let \(nestedContainer) = try \(container).nestedContainer(keyedBy: \(key.type), forKey: \(key.expr))
                """
                decoding(nestedContainer)
            case .ifMissing(let fallbacks):
                try! IfExprSyntax(
                    """
                    if (try? \(container).decodeNil(forKey: \(key.expr))) == false
                    """
                ) {
                    """
                    let \(nestedContainer) = try \(container).nestedContainer(keyedBy: \(key.type), forKey: \(key.expr))
                    """
                    decoding(nestedContainer)
                } else: {
                    fallbacks
                }
            case .ifError(let fallbacks):
                try! IfExprSyntax(
                    """
                    if let \(nestedContainer) = try? \(container).nestedContainer(keyedBy: \(key.type), forKey: \(key.expr))
                    """
                ) {
                    decoding(nestedContainer)
                } else: {
                    fallbacks
                }
            }
        }
    }
}

extension DecodingFallback {
    /// The combined fallback option for all variable elements.
    ///
    /// Represents the fallback to use when decoding container
    /// of all the element variables fails.
    ///
    /// - Parameter fallbacks: The fallback values to combine.
    /// - Returns: The aggregated fallback value.
    static func aggregate<C: Collection>(
        fallbacks: C
    ) -> Self where C.Element == Self {
        var aggregated = C.Element.ifError(.init())
        for fallback in fallbacks {
            switch (aggregated, fallback) {
            case (_, .throw), (.throw, _):
                return .throw
            case (.ifMissing(var a), .ifMissing(let f)),
                (.ifMissing(var a), .ifError(let f)),
                (.ifError(var a), .ifMissing(let f)):
                a.append(contentsOf: f)
                aggregated = .ifMissing(a)
            case (.ifError(var a), .ifError(let f)):
                a.append(contentsOf: f)
                aggregated = .ifError(a)
            }
        }
        return aggregated
    }
}
