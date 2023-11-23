# MetaCodable

[![API Docs](http://img.shields.io/badge/Read_the-docs-2196f3.svg)](https://swiftpackageindex.com/SwiftyLab/MetaCodable/main/documentation/metacodable)
[![Swift Package Manager Compatible](https://img.shields.io/github/v/tag/SwiftyLab/MetaCodable?label=SPM&color=orange)](https://badge.fury.io/gh/SwiftyLab%2FMetaCodable)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange)](https://img.shields.io/badge/Swift-5-DE5D43)
[![Platforms](https://img.shields.io/badge/Platforms-all-sucess)](https://img.shields.io/badge/Platforms-all-sucess)
[![CI/CD](https://github.com/SwiftyLab/MetaCodable/actions/workflows/main.yml/badge.svg)](https://github.com/SwiftyLab/MetaCodable/actions/workflows/main.yml)
[![CodeFactor](https://www.codefactor.io/repository/github/swiftylab/metacodable/badge)](https://www.codefactor.io/repository/github/swiftylab/metacodable)
[![codecov](https://codecov.io/gh/SwiftyLab/MetaCodable/branch/main/graph/badge.svg?token=jKxMv5oFeA)](https://codecov.io/gh/SwiftyLab/MetaCodable)
<!-- [![CodeQL](https://github.com/SwiftyLab/MetaCodable/actions/workflows/codeql-analysis.yml/badge.svg?event=schedule)](https://github.com/SwiftyLab/MetaCodable/actions/workflows/codeql-analysis.yml) -->

Supercharge `Swift`'s `Codable` implementations with macros.

## Overview

`MetaCodable` framework exposes custom macros which can be used to generate dynamic `Codable` implementations. The core of the framework is ``Codable()`` macro which generates the implementation aided by data provided with using other macros.

`MetaCodable` aims to supercharge your `Codable` implementations by providing these inbox features:

- Allows custom `CodingKey` value declaration per variable, instead of requiring you to write all the `CodingKey` values with ``CodedAt(_:)`` passing single argument.
- Allows to create flattened model for nested `CodingKey` values with ``CodedAt(_:)`` and ``CodedIn(_:)``.
- Allows to create composition of multiple `Codable` types with ``CodedAt(_:)`` passing no arguments.
- Allows to provide default value in case of decoding failures with ``Default(_:)``.
- Allows to create custom decoding/encoding strategies with ``HelperCoder`` and using them with ``CodedBy(_:)``. i.e. ``LossySequenceCoder`` and types from ``HelperCoders`` module.
- Allows to ignore specific properties from decoding/encoding with ``IgnoreCoding()``, ``IgnoreDecoding()`` and ``@IgnoreEncoding()``.
- Allows to use camel-case names for variables according to [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/#general-conventions), while enabling a type to work with different case style keys with ``CodingKeys(_:)``.
- Allows to ignore all initialized properties of a type from decoding/encoding with ``IgnoreCodingInitialized()`` unless explicitly asked to decode/encode by attaching any coding attributes, i.e. ``CodedIn(_:)``, ``CodedAt(_:)``,
``CodedBy(_:)``, ``Default(_:)`` etc.

## Requirements

| Platform | Minimum Swift Version | Installation | Status |
| --- | --- | --- | --- |
| iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+ | 5.9 | Swift Package Manager | Fully Tested |
| Linux | 5.9 | Swift Package Manager | Fully Tested |
| Windows | 5.9.1 | Swift Package Manager | Fully Tested |

## Installation

<details>
  <summary><h3>Swift Package Manager</h3></summary>

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding `MetaCodable` as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
.package(url: "https://github.com/SwiftyLab/MetaCodable.git", from: "1.0.0"),
```

Then you can add the `MetaCodable` module product as dependency to the `target`s of your choosing, by adding it to the `dependencies` value of your `target`s.

```swift
.product(name: "MetaCodable", package: "MetaCodable"),
```

</details>

## Usage

`MetaCodable` allows to get rid of boiler plate that was often needed in some typical `Codable` implementations with features like:

<details>
  <summary>Custom `CodingKey` value declaration per variable, instead of requiring you to write for all fields.</summary>

 i.e. in the official [docs](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types#2904057), to define custom `CodingKey` for 2 fields of `Landmark` type you had to write:

```swift
struct Landmark: Codable {
    var name: String
    var foundingYear: Int
    var location: Coordinate
    var vantagePoints: [Coordinate]

    enum CodingKeys: String, CodingKey {
        case name = "title"
        case foundingYear = "founding_date"
        case location
        case vantagePoints
    }
}
```

But with `MetaCodable` all you have to write is this:

```swift
@Codable
struct Landmark {
    @CodedAt("title")
    var name: String
    @CodedAt("founding_date")
    var foundingYear: Int

    var location: Coordinate
    var vantagePoints: [Coordinate]
}
```

</details>

<details>
  <summary>Create flattened model for nested `CodingKey` values.</summary>

i.e. in official [docs](https://developer.apple.com/documentation/foundation/archives_and_serialization/encoding_and_decoding_custom_types#2904058) to decode a JSON like this:

```json
{
  "latitude": 0,
  "longitude": 0,
  "additionalInfo": {
      "elevation": 0
  }
}
```

You had to write all these boilerplate:

```swift
struct Coordinate {
    var latitude: Double
    var longitude: Double
    var elevation: Double

    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case additionalInfo
    }

    enum AdditionalInfoKeys: String, CodingKey {
        case elevation
    }
}

extension Coordinate: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try values.decode(Double.self, forKey: .latitude)
        longitude = try values.decode(Double.self, forKey: .longitude)

        let additionalInfo = try values.nestedContainer(keyedBy: AdditionalInfoKeys.self, forKey: .additionalInfo)
        elevation = try additionalInfo.decode(Double.self, forKey: .elevation)
    }
}

extension Coordinate: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)

        var additionalInfo = container.nestedContainer(keyedBy: AdditionalInfoKeys.self, forKey: .additionalInfo)
        try additionalInfo.encode(elevation, forKey: .elevation)
    }
}
```

But with `MetaCodable` all you have to write is this:

```swift
@Codable
struct Coordinate {
    var latitude: Double
    var longitude: Double

    @CodedAt("additionalInfo", "elevation")
    var elevation: Double
}
```

You can even minimize further using `CodedIn` macro since the final `CodingKey` value is the same as field name:

```swift
@Codable
struct Coordinate {
    var latitude: Double
    var longitude: Double

    @CodedIn("additionalInfo")
    var elevation: Double
}
```

</details>

<details>
  <summary>Provide default value in case of decoding failures.</summary>

Instead of throwing error in case of missing data or type mismatch, you can provide a default value that will be assigned in this case. The following definition with `MetaCodable`:

```swift
@Codable
struct CodableData {
    @Default("some")
    let field: String
}
```

will not throw any error when empty JSON(`{}`) or JSON with type mismatch(`{ "field": 5 }`) is provided. The default value will be assigned in such case.

Also, memberwise initializer can be generated that uses this default value for the field.

```swift
@Codable
@MemberInit
struct CodableData {
    @Default("some")
    let field: String
}
```

The memberwise initializer generated will look like this:

```swift
init(field: String = "some") {
    self.field = field
}
```

</details>

<details>
  <summary>Use or create custom helpers to provide custom decoding/encoding.</summary>

Library provides following helpers that address common custom decoding/encoding needs:

- `LossySequenceCoder` to decode only valid data while ignoring invalid data in a sequence, instead of traditional way of failing decoding entirely.
- `ValueCoder` to decode `Bool`, `Int`, `Double`, `String` etc. basic types even if they are represented in some other type, i.e decoding `Int` from `"1"`, decoding boolean from `"yes"` etc.
- Custom Date decoding/encoding with UNIX timestamp (`Since1970DateCoder`) or date formatters (`DateCoder`, `ISO8601DateCoder`).
- `Base64Coder` to decode/encode data in base64 string representation.

And more, see the full documentation for [`HelperCoders`](https://swiftpackageindex.com/SwiftyLab/MetaCodable/main/documentation/helpercoders) for more details.

You can even create your own by conforming to `HelperCoder`.

</details>

See the full documentation for [`MetaCodable`](https://swiftpackageindex.com/SwiftyLab/MetaCodable/main/documentation/metacodable) and [`HelperCoders`](https://swiftpackageindex.com/SwiftyLab/MetaCodable/main/documentation/helpercoders), for API details and advanced use cases.

## Contributing

If you wish to contribute a change, suggest any improvements,
please review our [contribution guide](CONTRIBUTING.md),
check for open [issues](https://github.com/SwiftyLab/MetaCodable/issues), if it is already being worked upon
or open a [pull request](https://github.com/SwiftyLab/MetaCodable/pulls).

## License

`MetaCodable` is released under the MIT license. [See LICENSE](LICENSE) for details.
