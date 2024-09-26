import ArgumentParser
import Foundation
import PluginCore
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

extension ProtocolGen {
    /// Generates protocols decoding/encoding syntax.
    ///
    /// Aggregates all generated `SourceData` and generates
    /// `HelperCoder`s for decoding `Codable` protocols.
    struct Generate: AsyncParsableCommand {
        /// Configuration for this command, including custom help text.
        static let configuration = CommandConfiguration(
            abstract: """
                Generate decoding/encoding syntax from intermediate representations.
                """
        )

        /// The paths to stored `SourceData`s to aggregate.
        ///
        /// Must be absolute paths.
        @Argument(help: "The paths to input intermediate files.")
        var inputs: [String]
        /// The modules that will be imported in generated syntax.
        ///
        /// Can be omitted in case of syntax generated for single target.
        @Option(help: "The modules need to be imported in generated syntax.")
        var module: [String] = []
        /// The path to store generated decoding/encoding syntax.
        ///
        /// Must be absolute path.
        @Option(help: "The path to output syntax file generated.")
        var output: String

        /// Fetch `SourceData` from the provided paths.
        ///
        /// Stored data is read from each path and aggregated.
        ///
        /// - Parameter input: The paths to read data from.
        /// - Returns: The aggregated data.
        func fetchInputData(input: [URL]) async throws -> SourceData {
            let dataType = SourceData.self
            return try await withThrowingTaskGroup(of: dataType) { group in
                for path in input {
                    group.addTask {
                        let data = try Data(contentsOf: path)
                        return try JSONDecoder().decode(dataType, from: data)
                    }
                }

                var datas: [SourceData] = []
                datas.reserveCapacity(input.count)
                for try await data in group {
                    datas.append(data)
                }
                var data = SourceData.aggregate(datas: datas)
                data.protocols = data.protocols.filter { _, value in
                    return !value.types.isEmpty && !value.attributes.isEmpty
                }
                return data
            }
        }

        /// Generates decode method from provided data.
        ///
        /// The code is used for method implementation while
        /// the method data used for method definition.
        ///
        /// - Parameters:
        ///   - protocol: The protocol for which method generated.
        ///   - method: The decode method data.
        ///   - code: The code for the method implementation.
        ///
        /// - Returns: The method declaration.
        func decodeMethod(
            for protocol: TokenSyntax, method: TypeCodingLocation.Method,
            code: CodeBlockItemListSyntax
        ) -> FunctionDeclSyntax {
            let result: TypeSyntax = "\(`protocol`)"
            let arg = FunctionParameterSyntax(
                firstName: method.argLabel, secondName: method.arg,
                type: method.argType
            )

            #if canImport(SwiftSyntax600)
            let signature = FunctionSignatureSyntax(
                parameterClause: .init(parameters: .init([arg])),
                effectSpecifiers: .init(
                    throwsClause: .init(throwsSpecifier: .keyword(.throws))
                ),
                returnClause: .init(type: result)
            )
            #else
            let signature = FunctionSignatureSyntax(
                parameterClause: .init(parameters: .init([arg])),
                effectSpecifiers: .init(throwsSpecifier: .keyword(.throws)),
                returnClause: .init(type: result)
            )
            #endif
            return FunctionDeclSyntax(name: method.name, signature: signature) {
                code
            }
        }

        /// Generates encode method from provided data.
        ///
        /// The code is used for method implementation while
        /// the method data used for method definition.
        ///
        /// - Parameters:
        ///   - protocol: The protocol for which method generated.
        ///   - method: The encode method data.
        ///   - code: The code for the method implementation.
        ///
        /// - Returns: The method declaration.
        func encodeMethod(
            for protocol: TokenSyntax, method: TypeCodingLocation.Method,
            code: CodeBlockItemListSyntax
        ) -> FunctionDeclSyntax {
            let input: TypeSyntax = "\(`protocol`)"
            let paramClause = FunctionParameterClauseSyntax {
                FunctionParameterSyntax(
                    firstName: .wildcardToken(), secondName: "value",
                    type: input
                )
                FunctionParameterSyntax(
                    firstName: method.argLabel, secondName: method.arg,
                    type: method.argType
                )
            }

            #if canImport(SwiftSyntax600)
            let signature = FunctionSignatureSyntax(
                parameterClause: paramClause,
                effectSpecifiers: .init(
                    throwsClause: .init(throwsSpecifier: .keyword(.throws))
                )
            )
            #else
            let signature = FunctionSignatureSyntax(
                parameterClause: paramClause,
                effectSpecifiers: .init(throwsSpecifier: .keyword(.throws))
            )
            #endif
            return FunctionDeclSyntax(name: method.name, signature: signature) {
                code
            }
        }

        /// Creates equivalent enum declaration syntax for provided protocol.
        ///
        /// This declaration is used to generate protocol decoding/encoding
        /// implementation reusing enum implementations.
        ///
        /// - Parameters:
        ///   - protocol: The protocol for which generated.
        ///   - data: The data associated with protocol.
        ///
        /// - Returns: The enum declaration syntax.
        func enumDeclaration(
            for protocol: TokenSyntax, with data: SourceData.ProtocolData
        ) -> EnumDeclSyntax {
            let attributes = AttributeListSyntax {
                for attr in data.attributes {
                    AttributeSyntax(stringLiteral: attr)
                }
            }
            return EnumDeclSyntax(
                attributes: attributes, name: `protocol`,
                memberBlock: MemberBlockSyntax {
                    let cases = data.types.map { type, attributes in
                        let type = TypeSyntax(stringLiteral: type)
                        let param = EnumCaseParameterSyntax(type: type)
                        let attributes = AttributeListSyntax {
                            "@CodedAs(\(type).identifier)"
                            for attribute in attributes {
                                AttributeSyntax(stringLiteral: attribute)
                            }
                        }
                        return EnumCaseDeclSyntax(
                            attributes: attributes,
                            elements: .init {
                                EnumCaseElementSyntax(
                                    name: "",
                                    parameterClause: .init(
                                        parameters: .init { param }
                                    )
                                )
                            }
                        )
                    }

                    for `case` in cases {
                        MemberBlockItemSyntax(decl: `case`)
                    }
                }
            )
        }

        /// Creates enum variable from provided declaration.
        ///
        /// This variable is used to generate protocol decoding/encoding
        /// implementation reusing enum implementations.
        ///
        /// - Parameters:
        ///   - declaration: The enum declaration.
        ///   - context: The context in which to perform the macro expansion.
        ///
        /// - Returns: The created enum variable.
        func enumVariable(
            for declaration: EnumDeclSyntax,
            in context: some MacroExpansionContext
        ) -> EnumVariable {
            let caseDecodeExpr: EnumVariable.CaseCode = { _, variables in
                let args = EnumVariable.decodingArgs(representing: variables)
                return "return \(args)"
            }
            let caseEncodeExpr: EnumVariable.CaseCode = { _, variables in
                let oldArgs = EnumVariable.encodingArgs(representing: variables)
                let args = LabeledExprListSyntax {
                    for (arg, variable) in zip(oldArgs, variables) {
                        let newExpr: ExprSyntax = """
                            \(arg.expression) as \(variable.type)
                            """
                        LabeledExprSyntax(label: arg.label, expression: newExpr)
                    }
                }
                return "\(args)"
            }
            return EnumVariable(
                from: declaration, in: context,
                caseDecodeExpr: caseDecodeExpr, caseEncodeExpr: caseEncodeExpr,
                encodeSwitchExpr: "value", forceDefault: true,
                switcher: EnumVariable.externallyTaggedSwitcher(
                    decodingKeys: CodingKeysMap(
                        typeName: "DecodingKeys",
                        fallbackTypeName: "DynamicCodableIdentifier<String>"
                    )
                ),
                codingKeys: CodingKeysMap(
                    typeName: "CodingKeys",
                    fallbackTypeName: "DynamicCodableIdentifier<String>"
                )
            )
        }

        /// Generates `HelperCoder` for decoding/encoding protocol.
        ///
        /// Protocol data is transformed to equivalent enum declaration
        /// from which the implementation is generated.
        ///
        /// - Parameters:
        ///   - protocol: The protocol for which generated.
        ///   - data: The data associated with protocol.
        ///   - context: The context in which to perform the macro expansion.
        ///
        /// - Returns: The `HelperCoder` implementation declaration.
        func generateHelper(
            for protocol: String, with data: SourceData.ProtocolData,
            in context: some MacroExpansionContext
        ) throws -> StructDeclSyntax {
            let `protocol`: TokenSyntax = .identifier(`protocol`)
            let decl = enumDeclaration(for: `protocol`, with: data)
            let variable = enumVariable(for: decl, in: context)

            let dMethod = TypeCodingLocation.Method.decode(methodName: "decode")
            let dConform = TypeSyntax(stringLiteral: dMethod.protocol)
            let dLocation = TypeCodingLocation(
                method: dMethod, conformance: dConform)
            let dGenerated = variable.decoding(in: context, from: dLocation)
            let eMethod = TypeCodingLocation.Method.encode
            let eConform = TypeSyntax(stringLiteral: eMethod.protocol)
            let eLocation = TypeCodingLocation(
                method: eMethod, conformance: eConform)
            let eGenerated = variable.encoding(in: context, to: eLocation)
            let codingKeys = variable.codingKeys(
                confirmingTo: [dConform, eConform], in: context
            )

            guard
                let dCode = dGenerated?.code, let eCode = eGenerated?.code
            else { fatalError() }
            let inheritanceClause = InheritanceClauseSyntax {
                let type: TypeSyntax = "HelperCoder"
                InheritedTypeSyntax(type: type)
            }
            let genDecl = StructDeclSyntax(
                name: "\(`protocol`)Coder", inheritanceClause: inheritanceClause
            ) {
                decodeMethod(for: `protocol`, method: dMethod, code: dCode)
                encodeMethod(for: `protocol`, method: eMethod, code: eCode)
                for codingKey in codingKeys {
                    codingKey
                }
            }
            return genDecl
        }

        /// The behavior or functionality of this command.
        ///
        /// Generates `HelperCoder` implementations
        /// for stored protocol datas.
        func run() async throws {
            let inputs = inputs.map { Config.url(forFilePath: $0) }

            let data = try await fetchInputData(input: inputs)
            let context = BasicMacroExpansionContext()
            let decls = try data.protocols.map { `protocol`, data in
                try generateHelper(for: `protocol`, with: data, in: context)
            }
            let source = SourceFileSyntax(
                statements: CodeBlockItemListSyntax {
                    ImportDeclSyntax(
                        path: .init {
                            ImportPathComponentSyntax(name: "MetaCodable")
                        }
                    )
                    for mod in module {
                        "import \(raw: mod)"
                    }
                    for decl in decls {
                        decl
                    }
                }
            )

            if fileManager.fileExists(atPath: output) {
                try fileManager.removeItem(atPath: output)
            }
            let sourceText = source.formatted(
                using: .init(
                    indentationWidth: .spaces(4), viewMode: .sourceAccurate
                )
            ).description
            let sourceData = sourceText.data(using: .utf8)
            fileManager.createFile(atPath: output, contents: sourceData)
        }
    }
}
