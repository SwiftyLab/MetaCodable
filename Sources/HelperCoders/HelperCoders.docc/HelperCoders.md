# ``HelperCoders``

@Metadata {
    @Available(swift, introduced: "5.9")
}

Level up `MetaCodable`'s generated implementations with helpers assisting common decoding/encoding requirements.

## Overview

`HelperCoders` aims to provide collection of helpers that can be used for common decoding/encoding tasks, reducing boilerplate. Some of the examples include:

- Decoding basic data type (i.e `Bool`, `Int`, `String`) from any other basic data types (i.e `Bool`, `Int`, `String`).
- Custom `Date` decoding/encoding approach, i.e. converting from UNIX timestamp, text formatted date etc.
- Custom `Data` decoding/encoding approach, i.e. converting from base64 text etc.
- Decoding/encoding non-confirming floats with text based infinity and not-a-number representations.
- Conditionally decode/encode with two helpers each handling one.
- Using existing property wrappers for custom decoding/encoding.

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

    @Tab("CocoaPods") {

        [CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate `HelperCoders` into your Xcode project using CocoaPods, specify it in your `Podfile`:

        ```ruby
        pod 'MetaCodable/HelperCoders'
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

### Data

- ``Base64Coder``

### Composition

- ``PropertyWrapperCoder``
- ``PropertyWrappable``
- ``ConditionalCoder``

### Sequence

- ``SequenceCoder``
