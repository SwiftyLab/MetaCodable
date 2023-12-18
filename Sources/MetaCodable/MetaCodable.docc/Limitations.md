# Limitations

All the usage limitations for ``MetaCodable``.

## Overview

Currently all the limitations of this library and possible workarounds and future plans are listed below. Most of these limitations depend on the data `Swift` provides to ``MetaCodable`` to perform macro expansion.

### Why strict typing is necessary?

`Swift` doesn't provide any type inference data, so to know type of variables ``Codable()`` needs types to be explicitly specified in the code. i.e. following code will not work and will cause error while macro expansion:

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
