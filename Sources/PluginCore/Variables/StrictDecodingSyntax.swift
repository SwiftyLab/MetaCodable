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
