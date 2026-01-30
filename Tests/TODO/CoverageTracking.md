# Test Coverage Tracking

This document tracks functions with less than 100% test coverage and their testing status.

## Legend

- ✅ Test created - link to test file provided
- ⏭️ Skipped - reason provided
- 🔄 In progress

---

## MetaCodable Module (20.2% coverage, 341 lines)

### AnyCodableLiteral.swift (0.0% coverage, 210 lines)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| `init()` | 0.0% | ⏭️ | Internal protocol conformance, exercised indirectly through DynamicCodable |
| `init(booleanLiteral:)` | 0.0% | ⏭️ | ExpressibleBy protocol, tested via literal usage |
| `init(integerLiteral:)` | 0.0% | ⏭️ | ExpressibleBy protocol, tested via literal usage |
| `init(floatLiteral:)` | 0.0% | ⏭️ | ExpressibleBy protocol, tested via literal usage |
| `init(stringLiteral:)` | 0.0% | ⏭️ | ExpressibleBy protocol, tested via literal usage |
| `init(extendedGraphemeClusterLiteral:)` | 0.0% | ⏭️ | ExpressibleBy protocol, tested via literal usage |
| `init(unicodeScalarLiteral:)` | 0.0% | ⏭️ | ExpressibleBy protocol, tested via literal usage |
| `hash(into:)` | 0.0% | ⏭️ | Hashable conformance, used in collections |
| `==` operator | 0.0% | ⏭️ | Equatable conformance |
| `<` operator | 0.0% | ⏭️ | Comparable conformance |
| `description` getter | 0.0% | ⏭️ | CustomStringConvertible |
| `debugDescription` getter | 0.0% | ⏭️ | CustomDebugStringConvertible |
| Numeric operators (+, -, *, /) | 0.0% | ⏭️ | Numeric protocol conformance, rarely used directly |
| Range operators | 0.0% | ⏭️ | Used for range-based CodedAs values |

**Decision**: Skip direct testing. `AnyCodableLiteral` is an internal type used for macro processing. Its functionality is exercised through higher-level tests like `CodedAsTests.WithAnyCodableLiteralEnum`.

### CodableCommonStrategy.swift (0.0% coverage, 1 line)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| `init()` | 0.0% | ⏭️ | Empty initializer for strategy protocol |

**Decision**: Skip. Protocol requirement with no implementation logic.

### DynamicCodableIdentifier+CodingKey.swift (22.2% coverage, 36 lines)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| `description` getter | 0.0% | ⏭️ | Debug utility |
| `debugDescription` getter | 0.0% | ⏭️ | Debug utility |
| `intValue` getter | 0.0% | ⏭️ | CodingKey conformance |
| `stringValue` getter | 87.5% | ⏭️ | Nearly full coverage |
| `init(intValue:)` | 0.0% | ✅ | Tested in [DynamicCodableIdentifierTests.swift](../MetaCodableTests/DynamicCodableIdentifierTests.swift) |
| `init(stringValue:)` | 100.0% | ✅ | Already covered |

### DynamicCodableIdentifier+Expressible.swift (42.9% coverage, 21 lines)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| `init(unicodeScalarLiteral:)` | 0.0% | ⏭️ | ExpressibleBy protocol |
| `init(extendedGraphemeClusterLiteral:)` | 0.0% | ⏭️ | ExpressibleBy protocol |
| `init(integerLiteral:)` | 0.0% | ⏭️ | ExpressibleBy protocol |
| `init(floatLiteral:)` | 0.0% | ⏭️ | ExpressibleBy protocol |
| `init(stringLiteral:)` | 100.0% | ✅ | Already covered |
| `init(arrayLiteral:)` | 100.0% | ✅ | Already covered |
| `init(nilLiteral:)` | 100.0% | ✅ | Already covered |

### DynamicCodableIdentifier.swift (62.1% coverage, 29 lines)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| `encode(to:)` | 0.0% | 🔄 | Important - encoding DynamicCodable values |

---

## HelperCoders Module (90.7% coverage, 462 lines)

### HelperCoder.swift (64.3% coverage, 28 lines)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| `decodeIfPresent(from:)` | 0.0% | ✅ | Tested in [HelperCoderTests.swift](../MetaCodableTests/HelperCoderTests.swift) |
| `encode(_:to:)` | 0.0% | ✅ | Tested in [HelperCoderTests.swift](../MetaCodableTests/HelperCoderTests.swift) |
| `encodeIfPresent(_:to:)` | 0.0% | ✅ | Tested in [HelperCoderTests.swift](../MetaCodableTests/HelperCoderTests.swift) |

### HelperCoderStrategy.swift (0.0% coverage, 3 lines)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| `static codedBy(_:)` | 0.0% | ⏭️ | Strategy factory, exercised through macro usage |

### DefaultSequenceElementCoding.swift (25.0% coverage, 24 lines)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| `decodeIfPresent(from:)` | 0.0% | ✅ | Tested in [DefaultSequenceElementCodingTests.swift](../MetaCodableTests/DefaultSequenceElementCodingTests.swift) |
| `decode<A>(from:forKey:)` | 0.0% | ⏭️ | Keyed decoding variant |
| `decodeIfPresent<A>(from:forKey:)` | 0.0% | ✅ | Tested in [DefaultSequenceElementCodingTests.swift](../MetaCodableTests/DefaultSequenceElementCodingTests.swift) |
| `encodeIfPresent(_:to:)` | 0.0% | ✅ | Tested in [DefaultSequenceElementCodingTests.swift](../MetaCodableTests/DefaultSequenceElementCodingTests.swift) |
| `encode<A>(_:to:atKey:)` | 0.0% | ⏭️ | Keyed encoding variant |
| `encodeIfPresent<A>(_:to:atKey:)` | 0.0% | ✅ | Tested in [DefaultSequenceElementCodingTests.swift](../MetaCodableTests/DefaultSequenceElementCodingTests.swift) |
| `decode(from:)` | 100.0% | ✅ | Already covered |
| `encode(_:to:)` | 100.0% | ✅ | Already covered |

### ConditionalCoder.swift (62.5% coverage, 16 lines)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| `decodeIfPresent(from:)` | 0.0% | ✅ | Tested in [ConditionalCoderTests.swift](../MetaCodableTests/ConditionalCoderTests.swift) |
| `encodeIfPresent(_:to:)` | 0.0% | ✅ | Tested in [ConditionalCoderTests.swift](../MetaCodableTests/ConditionalCoderTests.swift) |
| `init(decoder:encoder:)` | 100.0% | ✅ | Already covered |
| `decode(from:)` | 100.0% | ✅ | Already covered |
| `encode(_:to:)` | 100.0% | ✅ | Already covered |

### SequenceCoderConfiguration.swift (86.2% coverage, 80 lines)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| `formSymmetricDifference(_:)` | 0.0% | ⏭️ | OptionSet conformance, rarely used directly |
| `formIntersection(_:)` | 89.5% | ⏭️ | Nearly full coverage |

### SequenceCoder.swift (93.8% coverage, 81 lines)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| `init(elementHelper:configuration:)` | 0.0% | ⏭️ | Convenience initializer, other inits cover functionality |

---

## PluginCore Module

### Definitions.swift (85.3% coverage, 136 lines)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| `static Codable.expansion(of:providingMembersOf:in:)` | 0.0% | ⏭️ | Macro entry point, tested through expansion tests |
| `static MemberInit.expansion(of:providingMembersOf:in:)` | 0.0% | ⏭️ | Macro entry point |
| `static ConformDecodable.expansion(of:providingMembersOf:in:)` | 0.0% | ⏭️ | Macro entry point |
| `static ConformEncodable.expansion(of:providingMembersOf:in:)` | 0.0% | ⏭️ | Macro entry point |

### Decodable+Expansion.swift (64.0% coverage, 50 lines)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| Closures in `expansion` methods | 0.0% | ⏭️ | Internal closures, exercised through macro tests |
| `expansion(of:providingMembersOf:conformingTo:in:)` | 58.8% | ⏭️ | Partial coverage acceptable |

### Encodable+Expansion.swift (64.0% coverage, 50 lines)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| Closures in `expansion` methods | 0.0% | ⏭️ | Internal closures, exercised through macro tests |
| `expansion(of:providingMembersOf:conformingTo:in:)` | 58.8% | ⏭️ | Partial coverage acceptable |

### UnTaggedEnumSwitcher.swift (86.8% coverage, 205 lines)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| `ThrowingSyntaxVisitor.visit(_:)` | 0.0% | ⏭️ | Error handling path |
| `ErrorUsageSyntaxVisitor.visit(_:)` | 0.0% | ⏭️ | Error handling path |
| `keyExpression` closure | 0.0% | ⏭️ | Internal closure |

### ActorVariable.swift (83.9% coverage, 62 lines)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| Closures in `decoding` | 0.0% | ⏭️ | Internal async handling |

### AdjacentlyTaggedEnumSwitcher.swift (85.2% coverage, 61 lines)

| Function | Coverage | Status | Notes |
|----------|----------|--------|-------|
| `CoderVariable.requireDecodable` getter | 0.0% | ⏭️ | Rare path |
| `CoderVariable.requireEncodable` getter | 0.0% | ⏭️ | Rare path |
| `decoding/encoding` methods | 87.5% | ⏭️ | Nearly full coverage |

---

## Test Files with Low Coverage

These are test helper types that don't need direct testing:

- `CodableTests.swift` - Test helper structs (SomeCodable types) at 0.0% are expected
- `CodedByActionTests.swift` - Test helper types at 0.0% are expected
- `VariableDeclarationTests.swift` - Test helper types at 0.0% are expected

---

## Priority Tests to Implement

### High Priority (widely used, 0% coverage)

1. **HelperCoder optional methods** - `decodeIfPresent`, `encode`, `encodeIfPresent`
2. **ConditionalCoder optional methods** - `decodeIfPresent`, `encodeIfPresent`
3. **DynamicCodableIdentifier.encode(to:)** - Encoding dynamic values

### Medium Priority

4. **DefaultSequenceElementCoding optional methods**
5. **DynamicCodableIdentifier+CodingKey.init(intValue:)**

### Low Priority (skip with reason)

- AnyCodableLiteral methods - Internal type, tested indirectly
- ExpressibleBy protocol methods - Standard Swift protocol conformance
- Macro entry points - Tested through expansion tests
- OptionSet methods - Standard Swift conformance

---

## Tests Created

| Test File | Functions Covered | Date |
|-----------|-------------------|------|
| [HelperCoderTests.swift](../MetaCodableTests/HelperCoderTests.swift) | `HelperCoder.decodeIfPresent`, `encode`, `encodeIfPresent` | 2026-01-30 |
| [ConditionalCoderTests.swift](../MetaCodableTests/ConditionalCoderTests.swift) | `ConditionalCoder.decodeIfPresent`, `encodeIfPresent` | 2026-01-30 |
| [DefaultSequenceElementCodingTests.swift](../MetaCodableTests/DefaultSequenceElementCodingTests.swift) | `DefaultSequenceElementCoding` optional methods | 2026-01-30 |
| [DynamicCodableIdentifierTests.swift](../MetaCodableTests/DynamicCodableIdentifierTests.swift) | `DynamicCodableIdentifier` CodingKey methods | 2026-01-30 |

