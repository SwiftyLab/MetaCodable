# MetaCodable

[![API Docs](http://img.shields.io/badge/Read_the-docs-2196f3.svg)](https://swiftylab.github.io/MetaCodable/documentation/metacodable/)
[![Swift Package Manager Compatible](https://img.shields.io/github/v/tag/SwiftyLab/MetaCodable?label=SPM&color=orange)](https://badge.fury.io/gh/SwiftyLab%2FMetaCodable)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange)](https://img.shields.io/badge/Swift-5-DE5D43)
[![Platforms](https://img.shields.io/badge/Platforms-all-sucess)](https://img.shields.io/badge/Platforms-all-sucess)
[![CI/CD](https://github.com/SwiftyLab/MetaCodable/actions/workflows/main.yml/badge.svg?event=push)](https://github.com/SwiftyLab/MetaCodable/actions/workflows/main.yml)
[![CodeFactor](https://www.codefactor.io/repository/github/swiftylab/metacodable/badge)](https://www.codefactor.io/repository/github/swiftylab/metacodable)
[![codecov](https://codecov.io/gh/SwiftyLab/MetaCodable/branch/main/graph/badge.svg?token=jKxMv5oFeA)](https://codecov.io/gh/SwiftyLab/MetaCodable)
<!-- [![CodeQL](https://github.com/SwiftyLab/MetaCodable/actions/workflows/codeql-analysis.yml/badge.svg?event=schedule)](https://github.com/SwiftyLab/MetaCodable/actions/workflows/codeql-analysis.yml) -->

Supercharge `Swift`'s `Codable` implementations with macros.

## Overview

`MetaCodable` framework exposes custom macros which can be used to generate dynamic `Codable` implementations. The core of the framework is ``Codable()`` macro which generates the implementation aided by data provided with using other macros.


`MetaCodable` aims to supercharge your `Codable` implementations by providing these inbox features:

- Allows custom `CodingKey` value declaration per variable, instead of requiring you to write all the `CodingKey` values with ``CodablePath(_:)`` etc.
- Allows to create flattened model for nested `CodingKey` values with ``CodablePath(_:)`` etc.
- Allows to create composition of multiple `Codable` types with ``CodableCompose()`` etc.
- Allows to provide default value in case of decoding failures with ``CodablePath(default:_:)`` and ``CodableCompose(default:)`` etc.
- Generates member-wise initializer considering the above default value syntax as well.
- Allows to create custom decoding/encoding strategies with ``ExternalHelperCoder``. i.e. ``LossySequenceCoder`` etc.

## Requirements

| Platform | Minimum Swift Version | Installation | Status |
| --- | --- | --- | --- |
| iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+ | 5.9 | Swift Package Manager | Fully Tested |
| Linux | 5.9 | Swift Package Manager | Fully Tested |
| Windows | 5.9 | Swift Package Manager | Fully Tested |

## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding `MetaCodable` as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
.package(url: "https://github.com/SwiftyLab/MetaCodable.git", from: "1.0.0"),
```

Then you can add the `MetaCodable` module product as dependency to the `target`s of your choosing, by adding it to the `dependencies` value of your `target`s.

```swift
.product(name: "MetaCodable", package: "MetaCodable"),
```

## Usage

See the full [documentation](https://swiftylab.github.io/MetaCodable/documentation/metacodable/) for API details and articles on sample scenarios.

## Contributing

If you wish to contribute a change, suggest any improvements,
please review our [contribution guide](CONTRIBUTING.md),
check for open [issues](https://github.com/SwiftyLab/MetaCodable/issues), if it is already being worked upon
or open a [pull request](https://github.com/SwiftyLab/MetaCodable/pulls).

## License

`MetaCodable` is released under the MIT license. [See LICENSE](LICENSE) for details.
