# Limitations

All the usage limitations for ``MetaCodable``.

## Overview

Currently all the limitations of this library and possible workarounds and future plans are listed below. Most of these limitations depend on the data `Swift` provides to ``MetaCodable`` to perform macro expansion.

### Why strict typing is necessary?

`Swift` compiler doesn't provide any type inference data to macros, so to know type of variables ``Codable()`` needs types to be explicitly specified in the code. i.e. following code will not work and will cause error while macro expansion:

```swift
@Codable
struct Model {
    let value = 1
}
```

This is due to ``Codable()`` unable to determine the type of `value`, by specifying the type explicitly expansion is performed successfully:

```swift
@Codable
struct Model {
    let value: Int = 1
}
```

### Why super class Codable conformance not detected?

The ability to pass conformance data to macro for classes when performing member attribute expansion was introduced in [`Swift 5.9.2`](https://github.com/apple/swift-evolution/blob/main/proposals/0407-member-macro-conformances.md). Please make sure to upgrade to this version to have this working.

Even with this it is unable for ``Codable()`` to get clear indication where conformance to `Codable` is implemented by current class or the super class. ``Codable()`` checks current class for the conformance implementation by checking implementation functions and the check will not work if some `typealias` used for `Decoder`/`Encoder` in implementation function definition.

### Why enum-case associated values decoding/encoding are not customizable?

The goal of ``MetaCodable`` is to allow same level of customization for enum-case associated values as it is allowed for `struct`/`class`/`actor` member properties. Unfortunately, as of now, `Swift` doesn't allow macro attributes (or any attributes) to be attached per enum-case arguments.

[A pitch has been created to allow this support in `Swift`](https://forums.swift.org/t/attached-macro-support-for-enum-case-arguments/67952), you can support this pitch on `Swift` forum if this feature will benefit you.

The current workaround is to extract enum-case arguments to separate `struct` and have the customization options in the `struct` itself. i.e. since following isn't possible:

```swift
@Codable
enum SomeEnum {
    case string(@CodedAt("data") String)
}
```

you can convert it to:

```swift
@Codable
enum SomeEnum {
    case string(StringData)

    @Codable
    struct StringData {
        let data: String
    }
}
```

### Why enums with raw value aren't supported?

`Swift` compiler by default generates `Codable` conformance for `enum`s with raw value and `MetaCodable` has nothing extra to add for these type of `enum`s. Hence, in this case the default compiler generated implementation can be used.

### Why actor conformance to Encodable not generated?

For `actor`s ``Codable()`` generates `Decodable` conformance, while `Encodable` conformance isn't generated, only `encode(to:)` method implementation is generated which is isolated to `actor`.

To generate `Encodable` conformance, the `encode(to:)` method must be `nonisolated` to `actor`, and since `encode(to:)` method must be synchronous making it `nonisolated` will prevent accessing mutable properties.

Due to these limitations, `Encodable` conformance isn't generated, users has to implement the conformance manually.

### Why MetaProtocolCodable plugin can't scan Xcode target dependencies?

Currently Swift Package Manager always returns empty list for Xcode target dependencies as noted in [this bug](https://github.com/apple/swift-package-manager/issues/6003). Hence `MetaProtocolCodable` can currently only scan the files from the target or from the project including the target.

### Why macro is breaking with SwiftData class?

Currently during certain customization in SwiftUI, compiler is sending no protocol data to ``Codable()``. Due to this, ``Codable()`` tries to find `Codable` protocol implementation for the class. If no implementation found, ``Codable()`` assumes class inherits conformance from super class, and generates implementation accordingly causing issues like [#56](https://github.com/SwiftyLab/MetaCodable/issues/56).

Until this is fixes from Swift compiler, ``Inherits(decodable:encodable:)`` macro can be used to indicate explicitly that class doesn't inherit `Codable` conformance.

### Why IgnoreEncoding(if:) not supported for types and MetaProtocolCodable plugin?

As of writing, Swift has an [existing bug](https://github.com/apple/swift/issues/68158) which causes error when ``IgnoreEncoding(if:)-7toka`` or ``IgnoreEncoding(if:)-1iuvv`` is attached to a type declaration. [This bug is also being discussed](https://forums.swift.org/t/circular-reference-error-when-using-keypaths-to-properties-with-macros-bug-or-expected-behaviour/69162), and once fixed this feature will be supported by `MetaProtocolCodable` plugin as well.
