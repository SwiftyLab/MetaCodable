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

/// Generates registration for class keys used by inherited strict decoding.
package func strictDecodingRegistrationSyntax(
    keys: [String]
) -> CodeBlockItemListSyntax {
    let values = keys.map {
        let value =
            $0
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(value)\""
    }.joined(separator: ", ")
    return CodeBlockItemListSyntax {
        "MetaCodableStrictDecodingRegistry.register(type: Self.self, keys: [\(raw: values)])"
    }
}
