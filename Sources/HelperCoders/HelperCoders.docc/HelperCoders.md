# ``HelperCoders``

@Metadata {
    @Available(swift, introduced: "5.9")
}

Level up ``/MetaCodable``'s generated implementations with helpers assisting common decoding/encoding requirements.

## Overview

`HelperCoders` aims to provide collection of helpers that can be used for common decoding/encoding tasks, reducing boilerplate. Some of the examples include:

- Decoding basic data type (i.e `Bool`, `Int`, `String`) from any other basic data types (i.e `Bool`, `Int`, `String`).
- Custom `Date` decoding/encoding approach, i.e. converting from UNIX timestamp, text formatted date etc.

## Installation

@TabNavigator {
    @Tab("Swift Package Manager") {

        The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

        Once you have your Swift package set up, adding `MetaCodable` as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

        ```swift
        .package(url: "https://github.com/SwiftyLab/MetaCodable.git", from: "1.0.0"),
        ```

        Then you can add the `HelperCoders` module product as dependency to the `target`s of your choosing, by adding it to the `dependencies` value of your `target`s.

        ```swift
        .product(name: "HelperCoders", package: "MetaCodable"),
        ```
    }
}

## Topics

### Basic Data

- ``ValueCoder``
- ``ValueCodingStrategy``
- ``NonConformingCoder``

### Date

- ``Since1970DateCoder``
- ``DateCoder``
- ``ISO8601DateCoder``
- ``DateFormatConverter``
