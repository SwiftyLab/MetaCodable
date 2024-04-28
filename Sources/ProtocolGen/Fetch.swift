import ArgumentParser
import Foundation

extension ProtocolGen {
    /// Fetches configuration data from file asynchronously.
    ///
    /// Fetches configuration data stored in `json` or `plist` format
    /// from the provided file path.
    struct Fetch: AsyncParsableCommand {
        /// Configuration for this command, including custom help text.
        static let configuration = CommandConfiguration(
            abstract: """
                Fetch configuration file data, and provide in JSON format.
                """
        )

        /// The path to fetch data from.
        ///
        /// Must be absolute path.
        @Argument(help: "The configuration file path.")
        var path: String

        /// The behavior or functionality of this command.
        ///
        /// Performs asynchronous config data fetch and
        /// prints to console in `JSON` format.
        func run() async throws {
            let path = Config.url(forFilePath: path)
            let data = try Data(contentsOf: path)
            let config =
                if let config = try? JSONDecoder().decode(
                    Config.self, from: data
                ) {
                    config
                } else {
                    try PropertyListDecoder().decode(Config.self, from: data)
                }
            let configData = try JSONEncoder().encode(config)
            print(String(data: configData, encoding: .utf8)!)
        }
    }
}
