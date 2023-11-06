## [1.1.0](https://github.com/SwiftyLab/MetaCodable/compare/v1.0.0...v1.1.0) (2023-11-06)


### 🚀 Features

* **`HelperCoders`:** added base64 data  decoding/encoding helpers ([bee7cc4](https://github.com/SwiftyLab/MetaCodable/commit/bee7cc4a00af53eaeb7c7179e6b9d01e79c8c7b3))
* **`HelperCoders`:** added basic data types decoding helpers ([6089cb5](https://github.com/SwiftyLab/MetaCodable/commit/6089cb5a9fdbd8a41f7471c0c8ade819f36306f5))
* **`HelperCoders`:** added conditional and property wrapper based helpers ([4542ac2](https://github.com/SwiftyLab/MetaCodable/commit/4542ac2e9c05cd1c54b9b06a95022f63a18edc5d))
* **`HelperCoders`:** added date decoding/encoding helpers ([ae9ed44](https://github.com/SwiftyLab/MetaCodable/commit/ae9ed449d56a8057fe6dd3721643fa07f4403dcd))
* **`HelperCoders`:** added non-confirming floats decoding/encoding helpers ([6f8241a](https://github.com/SwiftyLab/MetaCodable/commit/6f8241ab9add0f33941332b26044ba081d001e26))
* added non-variadic generics support ([#23](https://github.com/SwiftyLab/MetaCodable/issues/23)) ([b615251](https://github.com/SwiftyLab/MetaCodable/commit/b615251ffd23fd2bda56d201eab9865b4bd73557))


### 🐛 Fixes

* fixed build failure with `ExistentialAny` upcoming feature (by @Midbin) ([#34](https://github.com/SwiftyLab/MetaCodable/issues/34)) ([db55d96](https://github.com/SwiftyLab/MetaCodable/commit/db55d9696cc676f9b0e099352bb8b35c09631be9))
* fixed default value not respected for optional types ([#36](https://github.com/SwiftyLab/MetaCodable/issues/36)) ([4eb999c](https://github.com/SwiftyLab/MetaCodable/commit/4eb999cd76676e5f4d012435de123bdc1b6d08b5))
* fixed failure in structs with static members (by @Midbin) ([#37](https://github.com/SwiftyLab/MetaCodable/issues/37)) ([e256e12](https://github.com/SwiftyLab/MetaCodable/commit/e256e12a85896449cdbd092b9bd3ac2f0a13b1f7))
* fixed optional value decoding failure with `HelperCoder` when value doesn't exist ([#35](https://github.com/SwiftyLab/MetaCodable/issues/35)) ([ad19d4d](https://github.com/SwiftyLab/MetaCodable/commit/ad19d4d55cb9966071316b9d91b158137c0898db))


### 📚 Documentation

* **README:** added `HelperCoders` usage ([#38](https://github.com/SwiftyLab/MetaCodable/issues/38)) ([8da6282](https://github.com/SwiftyLab/MetaCodable/commit/8da6282f8c4ff79b3bf8f68929172126055082ab))


### ✅ Tests

* added `swift-syntax` temporary fix for extension macros testing ([#33](https://github.com/SwiftyLab/MetaCodable/issues/33)) ([5344f13](https://github.com/SwiftyLab/MetaCodable/commit/5344f133a6458fa20458427e8f3fed252907fda4))

## [1.0.0](https://github.com/SwiftyLab/MetaCodable/compare/v1.0.0-alpha.2...v1.0.0) (2023-09-20)


### ⚠ BREAKING CHANGES

* use `MemberInit` macro for memberwise initializer(s)
* replaced `CodablePath` with `CodedAt`
* replaced `CodableCompose` with `CodedAt` without args
* renamed `ExternalHelperCoder` to `HelperCoder`
* replaced `default:` with `@Default`
* replaced `helper:` with `@CodedBy`

### 🚀 Features

* added decoding/encoding ignore attributes ([#16](https://github.com/SwiftyLab/MetaCodable/issues/16)) ([94855a0](https://github.com/SwiftyLab/MetaCodable/commit/94855a08cf6f259d4aa5806949518bac76b5a19c))
* added initialized variable ignore option ([#17](https://github.com/SwiftyLab/MetaCodable/issues/17)) ([6cd519e](https://github.com/SwiftyLab/MetaCodable/commit/6cd519ebe6344efee01cb779954b6e5345043647))
* added options for custom key case style ([#18](https://github.com/SwiftyLab/MetaCodable/issues/18)) ([5cc1a93](https://github.com/SwiftyLab/MetaCodable/commit/5cc1a933323cb3659db4cc008075c03346302f46))
* made initialized mutable variables initialization optional in member-wise initializers ([#15](https://github.com/SwiftyLab/MetaCodable/issues/15)) ([12f3177](https://github.com/SwiftyLab/MetaCodable/commit/12f3177ec942ec82f8466788c19ba360f6e66186))


### 🐛 Fixes

* only ignore computed properties with getter in decoding/encoding ([#11](https://github.com/SwiftyLab/MetaCodable/issues/11)) ([a6bc3a2](https://github.com/SwiftyLab/MetaCodable/commit/a6bc3a2068c958c14b2b4bc85d075d937083b5a6)), closes [#10](https://github.com/SwiftyLab/MetaCodable/issues/10)


### 🔥 Refactorings

* migrated to extension macro ([#21](https://github.com/SwiftyLab/MetaCodable/issues/21)) ([74e6a67](https://github.com/SwiftyLab/MetaCodable/commit/74e6a673baf4a914e66ef9fe7f0e3cccb4852208))
* modify macro implementation ([#12](https://github.com/SwiftyLab/MetaCodable/issues/12)) ([8d61676](https://github.com/SwiftyLab/MetaCodable/commit/8d6167680dc0300b95ccddf5bda36c00239bcbcb))

## [1.0.0-alpha.2](https://github.com/SwiftyLab/MetaCodable/compare/v1.0.0-alpha.1...v1.0.0-alpha.2) (2023-06-30)


### 🐛 Fixes

* added robust grouped variable declaration type detection ([#3](https://github.com/SwiftyLab/MetaCodable/issues/3)) ([0cc623f](https://github.com/SwiftyLab/MetaCodable/commit/0cc623f746242eeb1762bb752b473bfe8c9105d3))
* ignore default immutable initialized and computed properties in decoding/encoding ([#2](https://github.com/SwiftyLab/MetaCodable/issues/2)) ([9ac898f](https://github.com/SwiftyLab/MetaCodable/commit/9ac898fd0aba9758c61d73505afba17ceb08c0b7))


### 📚 Documentation

* improved usage documentation ([#5](https://github.com/SwiftyLab/MetaCodable/issues/5)) ([7086c41](https://github.com/SwiftyLab/MetaCodable/commit/7086c41d94e0e2fc72c921e0d87c651d98c8a550))

## [1.0.0-alpha.1](https://github.com/SwiftyLab/MetaCodable/compare/498d7633fc6003d742d78d4fbc965d753db7ee29...v1.0.0-alpha.1) (2023-06-21)


### 🚀 Features

* added `Codable` generation macro with ([498d763](https://github.com/SwiftyLab/MetaCodable/commit/498d7633fc6003d742d78d4fbc965d753db7ee29))


### 📚 Documentation

* add project info and contributing guidelines ([915d32c](https://github.com/SwiftyLab/MetaCodable/commit/915d32ca7c1e275d6619c419d69a8ff659806242))


### 💄 Styles

* add development with vscode support ([323a94a](https://github.com/SwiftyLab/MetaCodable/commit/323a94a3a1e824a2b93c1aecb51d47a90c0ec3e3))

