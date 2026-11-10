import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder

/// Generates validation for unsupported keys at a keyed decoding container.
package func strictDecodingValidationSyntax(
    decoder: ExprSyntax,
    allowedKeys: [String]?
) -> CodeBlockItemListSyntax {
    guard let allowedKeys else { return [] }
    let keys = allowedKeys.map {
        let value =
            $0
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(value)\""
    }.joined(separator: ", ")
    return CodeBlockItemListSyntax {
        "try \(decoder).rejectUnknownKeys(allowedKeys: [\(raw: keys)], type: Self.self)"
    }
}

/// Generates a dictionary literal for strict decoding key metadata.
package func strictDecodingMetadataSyntax(
    _ metadata: [String: [String]]
) -> ExprSyntax {
    let entries = metadata.keys.sorted().map { path in
        let keys = metadata[path, default: []].map {
            let value =
                $0
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(value)\""
        }.joined(separator: ", ")
        return "\"\(path)\": [\(keys)]"
    }.joined(separator: ", ")
    return ExprSyntax(stringLiteral: "[\(entries)]")
}
