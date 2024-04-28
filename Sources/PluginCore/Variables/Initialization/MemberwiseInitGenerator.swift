import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// A type responsible for generating memberwise
/// initialization declarations for `Codable` macro.
///
/// This type tracks required and optional initializations
/// and generates multiple initialization declarations
/// if any optional initialization variables present.
package struct MemberwiseInitGenerator {
    /// A type indicating various configurations available
    /// for `MemberwiseInitGenerator`.
    ///
    /// These options are used as customization
    /// performed on the final generated initialization
    /// declarations.
    struct Options {
        /// The default list of modifiers to be applied to generated
        /// initialization declarations.
        let modifiers: DeclModifierListSyntax
    }

    /// A type representing initialization of single variable.
    ///
    /// Multiple variables and based on their initialization types,
    /// instances of this type is tracked and final initialization
    /// declarations are generated.
    struct Item {
        /// The function parameter for the initialization function.
        ///
        /// This function parameter needs to be added
        /// to the initialization function when generating
        /// initializer.
        let param: FunctionParameterSyntax
        /// The code needs to be added to initialization function.
        ///
        /// This code block needs to be added
        /// to the initialization function when
        /// generating initializer.
        let code: CodeBlockItemSyntax
    }

    /// The options to use when generating declarations.
    private let options: Options
    /// The variable initialization item collections tracked.
    ///
    /// For each collection single initialization declaration
    /// is created.
    private let collections: [[Item]]

    /// Creates a new generator with provided options, and empty
    /// initialization collection.
    ///
    /// - Parameter options: The options to use when
    ///   generating declarations.
    /// - Returns: The newly created generator.
    init(options: Options) {
        self.options = options
        self.collections = [[]]
    }

    /// Creates a new generator with provided options, and initialization
    /// collections.
    ///
    /// - Parameters:
    ///   - options: The options to use when generating declarations.
    ///   - collections: The initialization item collections to add.
    ///
    /// - Returns: The newly created generator.
    private init(options: Options, collections: [[Item]]) {
        self.options = options
        self.collections = collections
    }

    /// Updates generator with provided initialization items collections.
    ///
    /// - Parameter collections: The initialization items collections
    ///   to update with.
    /// - Returns: The newly created generator with provided
    ///            initialization items collections.
    func update(with collections: [[Item]]) -> Self {
        return .init(options: options, collections: collections)
    }

    /// Adds the provided required initialization item to generator.
    ///
    /// Adds the provided initialization item to all the initialization items
    /// collections currently present.
    ///
    /// - Parameter item: The required initialization item to add.
    /// - Returns: The newly created generator with initialization item added.
    func add(_ item: Item) -> Self {
        guard !collections.isEmpty else { return self.update(with: [[item]]) }
        var collections = collections
        for index in collections.indices {
            collections[index].append(item)
        }
        return self.update(with: collections)
    }

    /// Adds the provided optional initialization item to generator.
    ///
    /// Creates initialization items collections by adding provided
    /// initialization item to all the initialization items collections
    /// currently present and adds those collections to current collections.
    ///
    /// - Parameter item: The optional initialization item to add.
    /// - Returns: The newly created generator with initialization item added.
    func add(optional item: Item) -> Self {
        guard !collections.isEmpty
        else { return self.update(with: [[], [item]]) }

        var collections = self.collections
        for var newCollection in self.collections {
            newCollection.append(item)
            collections.append(newCollection)
        }
        return self.update(with: collections)
    }

    /// Provides the memberwise initializer declaration(s).
    ///
    /// For each initialization item collection, one declaration
    /// is generated.
    ///
    /// - Parameter context: The context in which to perform
    ///   the macro expansion.
    /// - Returns: The generated initializer declarations.
    func declarations(
        in context: some MacroExpansionContext
    ) -> [InitializerDeclSyntax] {
        return collections.map { items in
            return InitializerDeclSyntax(
                modifiers: options.modifiers,
                signature: .init(
                    parameterClause: .init(
                        parameters: .init {
                            for param in items.map(\.param) { param }
                        }
                    )
                )
            ) {
                for code in items.map(\.code) { code }
            }
        }
    }
}
