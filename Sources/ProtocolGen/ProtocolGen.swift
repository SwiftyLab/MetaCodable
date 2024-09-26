import ArgumentParser
import Foundation
import SwiftSyntax

/// The default file manager used for this module.
#if swift(>=6)
nonisolated(unsafe) internal var fileManager = FileManager.default
#else
internal var fileManager = FileManager.default
#endif

/// The root command for this module that can be executed asynchronously.
///
/// Declares all the sub commands available for this module.
@main
struct ProtocolGen: AsyncParsableCommand {
    /// Configuration for this command, including subcommands and custom
    /// help text.
    ///
    /// All the new subcommands must be added to `subcommands` list.
    static let configuration = CommandConfiguration(
        abstract: "A tool for generating protocol decoding/encoding syntax.",
        subcommands: [Fetch.self, Parse.self, Generate.self]
    )
}

extension ProtocolGen {
    /// The intermediate source parsed data.
    ///
    /// This data is generated from each source file and stored.
    /// Finally, all this data aggregated to generate syntax.
    struct SourceData: Codable {
        /// The data for each protocol.
        ///
        /// Represents types conforming to protocol, and attributes
        /// attached to protocol declaration.
        struct ProtocolData: Codable {
            /// All the conforming type data stored.
            ///
            /// The attributes attached to type is associated
            /// with type name.
            var types: [String: Set<String>]
            /// The attributes attached to protocol declaration.
            ///
            /// Used for preserving macro attributes to generate
            /// syntax for decoding protocol.
            var attributes: Set<String>
        }

        /// All the protocol data stored.
        ///
        /// The data of protocol is associated with its name.
        var protocols: [String: ProtocolData]

        /// Creates new `SourceData` merging current data
        /// with provided data.
        ///
        /// The protocol data are merged keeping conformed types
        /// and attributes provided by each.
        ///
        /// - Parameter data: The data to merge.
        /// - Returns: The merged data.
        func merging(_ data: Self) -> Self {
            return .aggregate(datas: [self, data])
        }

        /// Creates new `SourceData` merging current data
        /// with provided datas.
        ///
        /// The protocol data are merged keeping conformed types
        /// and attributes provided by current data and the for the
        /// new datas types are nested inside provided type.
        ///
        /// - Parameters:
        ///   - datas: The data list to merge.
        ///   - type: The type new data are name-spaced in.
        ///
        /// - Returns: The merged data.
        func merging(_ datas: [Self], in type: TypeSyntax) -> Self {
            var datas = datas.map { data in
                let protocols = data.protocols.mapValues { data in
                    let types = Dictionary(
                        uniqueKeysWithValues: data.types
                            .map { childType, attributes in
                                let type = type.trimmedDescription
                                let newType = "\(type).\(childType)"
                                return (newType, attributes)
                            }
                    )
                    return ProtocolData(
                        types: types, attributes: data.attributes
                    )
                }
                return Self(protocols: protocols)
            }
            datas.append(self)
            return .aggregate(datas: datas)
        }

        /// Creates new `SourceData` merging all datas.
        ///
        /// The protocol datas are merged keeping conformed types
        /// and attributes provided by all.
        ///
        /// - Parameter datas: The datas to merge.
        /// - Returns: The new data.
        static func aggregate(datas: [Self]) -> Self {
            return datas.reduce(
                into: Self.init(protocols: [:])
            ) { partialResult, data in
                partialResult.protocols.merge(data.protocols) { old, new in
                    let types = old.types.merging(new.types) { old, new in
                        return old.union(new)
                    }
                    let attributes = old.attributes.union(new.attributes)
                    return .init(types: types, attributes: attributes)
                }
            }
        }
    }
}
