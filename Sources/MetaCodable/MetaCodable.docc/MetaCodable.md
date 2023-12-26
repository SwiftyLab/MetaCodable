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
- Allows to provide default value in case of decoding failures with ``Default(_:)``.
- Allows to create custom decoding/encoding strategies with ``HelperCoder`` and using them with ``CodedBy(_:)``. i.e. ``LossySequenceCoder`` etc.
- Allows to ignore specific properties from decoding/encoding with ``IgnoreCoding()``, ``IgnoreDecoding()`` and ``IgnoreEncoding()``.
- Allows to use camel-case names for variables according to [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/#general-conventions), while enabling a type to work with different case style keys with ``CodingKeys(_:)``.
- Allows to ignore all initialized properties of a type from decoding/encoding with ``IgnoreCodingInitialized()`` unless explicitly asked to decode/encode by attaching any coding attributes, i.e. ``CodedIn(_:)``, ``CodedAt(_:)``,
``CodedBy(_:)``, ``Default(_:)`` etc.

 [**See the limitations for this macro**](<doc:Limitations>).

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

### Macros

- ``Codable()``
- ``MemberInit()``

### Strategies

- ``CodedAt(_:)``
- ``CodedIn(_:)``
- ``Default(_:)``
- ``CodedBy(_:)``
- ``CodedAs(_:)``
- ``TaggedAt(_:_:)``
- ``IgnoreCoding()``
- ``IgnoreDecoding()``
- ``IgnoreEncoding()``
- ``CodingKeys(_:)``
- ``IgnoreCodingInitialized()``

### Helpers

- ``HelperCoder``
- ``LossySequenceCoder``
