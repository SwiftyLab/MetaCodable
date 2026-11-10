import SwiftSyntax
import SwiftSyntaxBuilder

private func escapedStringLiteral(_ value: String) -> String {
    value.reduce(into: "") { result, character in
        switch character {
        case "\\":
            result += "\\\\"
        case "\"":
            result += "\\\""
        case "\n":
            result += "\\n"
        case "\r":
            result += "\\r"
        case "\t":
            result += "\\t"
        default:
            result.append(character)
        }
    }
}

package func strictDecodingPathKey(_ components: [String]) -> String {
    components.map { "\($0.utf8.count):\($0)" }.joined(separator: "|")
}

/// Generates validation for unsupported keys at a keyed decoding container.
package func strictDecodingValidationSyntax(
    decoder: ExprSyntax,
    allowedKeys: [String]?
) -> CodeBlockItemListSyntax {
    guard let allowedKeys else { return [] }
    let keys = allowedKeys.map {
        "\"\(escapedStringLiteral($0))\""
    }.joined(separator: ", ")
    return CodeBlockItemListSyntax {
        "try \(decoder).rejectUnknownKeys(allowedKeys: [\(raw: keys)], type: Self.self)"
    }
}

/// Generates conditional validation for mixed scalar/keyed enum decoding.
package func strictDecodingConditionalValidationSyntax(
    decoder: ExprSyntax,
    keyType: ExprSyntax,
    allowedKeys: [String]
) -> CodeBlockItemListSyntax {
    let validation = strictDecodingValidationSyntax(
        decoder: decoder, allowedKeys: allowedKeys
    )
    return CodeBlockItemListSyntax {
        try! IfExprSyntax(
            "if (try? \(decoder).container(keyedBy: \(keyType))) != nil"
        ) {
            validation
        }
    }
}
/// Generates a dictionary literal for strict decoding key metadata.
package func strictDecodingMetadataSyntax(
    _ metadata: [String: [String]]
) -> ExprSyntax {
    let entries = metadata.keys.sorted().map { path in
        let keys = metadata[path, default: []].map {
            "\"\(escapedStringLiteral($0))\""
        }.joined(separator: ", ")
        return "\"\(escapedStringLiteral(path))\": [\(keys)]"
    }.joined(separator: ", ")
    return ExprSyntax(stringLiteral: "[\(entries)]")
}
