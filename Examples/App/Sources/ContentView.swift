import SwiftUI
import MetaCodable
import HelperCoders

public struct ContentView: View {
    public init() {}

    public var body: some View {
        Text("Hello, World!")
            .padding()
    }
}

@Codable
struct Container {
    @CodedBy(ValueCoder<Bool>())
    let bool: Bool
    @CodedBy(SequenceCoder(output: [String].self))
    let data: [String]
    @CodedAt("identifier")
    let id: String
    @CodedIn("data")
    let type: String
}
