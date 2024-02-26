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
- Allows to read data from additional fallback `CodingKey`s provided with ``CodedAs(_:_:)``.
- Allows to provide default value in case of decoding failures with ``Default(_:)``.
- Allows to create custom decoding/encoding strategies with ``HelperCoder`` and using them with ``CodedBy(_:)``. i.e. ``LossySequenceCoder`` etc.
- Allows specifying different case values with ``CodedAs(_:_:)`` and case value/protocol type identifier type different from `String` with ``CodedAs()``.
- Allows specifying enum-case/protocol type identifier path with ``CodedAt(_:)`` and case content path with ``ContentAt(_:_:)``.
- Allows to ignore specific properties/cases from decoding/encoding with ``IgnoreCoding()``, ``IgnoreDecoding()`` and ``IgnoreEncoding()``.
- Allows to use camel-case names for variables according to [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/#general-conventions), while enabling a type/case to work with different case style keys with ``CodingKeys(_:)``.
- Allows to ignore all initialized properties of a type/case from decoding/encoding with ``IgnoreCodingInitialized()`` unless explicitly asked to decode/encode by attaching any coding attributes, i.e. ``CodedIn(_:)``, ``CodedAt(_:)``,
``CodedBy(_:)``, ``Default(_:)`` etc.
- Allows to generate protocol decoding/encoding ``HelperCoder``s with `MetaProtocolCodable` build tool plugin from ``DynamicCodable`` types.

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

    @Tab("CocoaPods") {

        [CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate `MetaCodable` into your Xcode project using CocoaPods, specify it in your `Podfile`:

        ```ruby
        pod 'MetaCodable'
        ```
    }
}

## Topics

### Essentials

- <doc:/tutorials/Usage>
- <doc:Limitations>

### Macros

- ``Codable()``
- ``MemberInit()``

### Strategies

- ``CodedAt(_:)``
- ``CodedIn(_:)``
- ``Default(_:)``
- ``CodedBy(_:)``
- ``CodedAs()``
- ``CodedAs(_:_:)``
- ``ContentAt(_:_:)``
- ``IgnoreCoding()``
- ``IgnoreDecoding()``
- ``IgnoreEncoding()``
- ``CodingKeys(_:)``
- ``IgnoreCodingInitialized()``

### Helpers

- ``HelperCoder``
- ``LossySequenceCoder``

### Dynamic Coding

- ``DynamicCodable``
- ``DynamicCodableIdentifier``
- ``MetaCodableConfig``
