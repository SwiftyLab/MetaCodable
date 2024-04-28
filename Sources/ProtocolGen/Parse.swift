import ArgumentParser
import Foundation
import PluginCore
import SwiftParser
import SwiftSyntax

extension ProtocolGen {
    /// Fetches swift source files provided as input.
    ///
    /// Generated `SourceData` from parsing is stored
    /// in output file path.
    struct Parse: AsyncParsableCommand {
        /// Configuration for this command, including custom help text.
        static let configuration = CommandConfiguration(
            abstract: """
                Parse source files syntax to intermediate representation, final syntax is generated from this representation.
                """
        )

        /// The path swift source of file to parse.
        ///
        /// Must be absolute path.
        @Argument(help: "The path to input source file parsed.")
        var input: String
        /// The path to store generated parsed data.
        ///
        /// Must be absolute path.
        @Option(help: "The path to output intermediate file generated.")
        var output: String

        /// Parses a protocol declaration.
        ///
        /// Gets the macro attributes data attached to protocol declaration.
        ///
        /// - Parameter declaration: The declaration to parse.
        /// - Returns: The generated data.
        func parse(declaration: ProtocolDeclSyntax) -> SourceData {
            let codable = declaration.attributes.contains { attribute in
                return switch attribute {
                case .attribute(let attr):
                    PluginCore.Codable(from: attr) != nil
                default:
                    false
                }
            }
            guard codable else { return .init(protocols: [:]) }
            let attributes = declaration.attributes.compactMap { attribute in
                return switch attribute {
                case .attribute(let attr):
                    attr.trimmedDescription
                default:
                    nil
                }
            }
            let protocolData = SourceData.ProtocolData(
                types: [:], attributes: Set(attributes)
            )
            return .init(protocols: [declaration.name.text: protocolData])
        }

        /// Parses a declaration generating `SourceData`.
        ///
        /// Gets the macro attributes data attached to protocol declaration
        /// and the conformed types for protocols.
        ///
        /// - Parameter declaration: The declaration to parse.
        /// - Returns: The generated data.
        func parse(declaration: DeclSyntax) -> SourceData {
            let declTypes: [InheritableDeclSyntax.Type] = [
                StructDeclSyntax.self,
                EnumDeclSyntax.self,
                ClassDeclSyntax.self,
                ActorDeclSyntax.self,
                ExtensionDeclSyntax.self,
            ]
            let declType = declTypes.first { declaration.is($0) }
            guard
                let declType, let decl = declaration.as(declType)
            else {
                guard
                    let decl = declaration.as(ProtocolDeclSyntax.self)
                else { return .init(protocols: [:]) }
                return parse(declaration: decl)
            }

            typealias ProtocolData = SourceData.ProtocolData
            let inheritedTypes = decl.inheritanceClause?.inheritedTypes
            let protocols: [String: ProtocolData] =
                inheritedTypes?.reduce(
                    into: [:]
                ) { partialResult, inheritedType in
                    let newType = decl.currentType.trimmedDescription
                    let attributes = Set(
                        decl.attributes.map(\.trimmedDescription))
                    let `protocol` = inheritedType.type.trimmedDescription
                    if var data = partialResult[`protocol`] {
                        if let existing = data.types[newType] {
                            data.types[newType] = existing.union(attributes)
                        } else {
                            data.types[newType] = attributes
                        }
                        partialResult[`protocol`] = data
                    } else {
                        let typeData = [newType: attributes]
                        let newData = ProtocolData(
                            types: typeData, attributes: []
                        )
                        partialResult[`protocol`] = newData
                    }
                } ?? [:]
            let data = SourceData(protocols: protocols)
            let childDatas = decl.memberBlock.members.map { member in
                return parse(declaration: member.decl)
            }
            return data.merging(childDatas, in: decl.currentType)
        }

        /// The behavior or functionality of this command.
        ///
        /// Performs parsing of swift source files and storing
        /// `SourceData` in JSON format in `output` file path.
        func run() async throws {
            let input = Config.url(forFilePath: input)
            let output = Config.url(forFilePath: output)
            let sourceData = try Data(contentsOf: input)
            let sourceText = String(data: sourceData, encoding: .utf8)!
            let sourceFile = Parser.parse(source: sourceText)
            let data = sourceFile.statements.reduce(
                into: SourceData(protocols: [:])
            ) { partialResult, block in
                switch block.item {
                case .decl(let decl):
                    let data = parse(declaration: decl)
                    partialResult = partialResult.merging(data)
                default:
                    return
                }
            }
            try JSONEncoder().encode(data).write(to: output)
        }
    }
}
