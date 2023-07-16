# ``MetaCodable``

@Metadata {
    @Available(swift, introduced: "5.9")
}

Supercharge `Swift`'s `Codable` implementations with macros.

## Overview

`MetaCodable` framework exposes custom macros which can be used to generate dynamic `Codable` implementations. The core of the framework is ``Codable()`` macro which generates the implementation aided by data provided with using other macros.


`MetaCodable` aims to supercharge your `Codable` implementations by providing these inbox features:

- Allows custom `CodingKey` value declaration per variable, instead of requiring you to write all the `CodingKey` values with ``CodedAt(_:)`` passing single argument.
- Allows to create flattened model for nested `CodingKey` values with ``CodedAt(_:)`` and ``CodedIn(_:)``.
- Allows to create composition of multiple `Codable` types with ``CodedAt(_:)`` passing no arguments.
- Allows to provide default value in case of decoding failures with ``CodedAt(_:default:)`` and ``CodedIn(_:default:)`` etc.
- Generates member-wise initializer considering the above default value syntax as well.
- Allows to create custom decoding/encoding strategies with ``HelperCoder`` and using them with ``CodedAt(_:helper:)`` and ``CodedIn(_:helper:)``. i.e. ``LossySequenceCoder`` etc.

## Installation

@TabNavigator {
    @Tab("Swift Package Manager") {

        The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

        Once you have your Swift package set up, adding `MetaCodable` as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

        ```swift
        .package(url: "https://github.com/SwiftyLab/MetaCodable.git", from: "1.0.0"),
        ```

        Then you can add the `MetaCodable` module product as dependency to the `target`s of your choosing, by adding it to the `dependencies` value of your `target`s.

        ```swift
        .product(name: "MetaCodable", package: "MetaCodable"),
        ```
    }
}

## Topics

### Implementation

- ``Codable()``

### Strategies

- ``CodedAt(_:)``
- ``CodedAt(_:default:)``
- ``CodedAt(_:helper:)``
- ``CodedAt(_:default:helper:)``
- ``CodedIn(_:)``
- ``CodedIn(_:default:)``
- ``CodedIn(_:helper:)``
- ``CodedIn(_:default:helper:)``

### Helpers

- ``HelperCoder``
- ``LossySequenceCoder``
