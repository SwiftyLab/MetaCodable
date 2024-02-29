## [1.3.0](https://github.com/SwiftyLab/MetaCodable/compare/v1.2.1...v1.3.0) (2024-02-29)


### 🚀 Features

* added CocoaPods support ([#1](https://github.com/SwiftyLab/MetaCodable/issues/1)) ([377a87e](https://github.com/SwiftyLab/MetaCodable/commit/377a87e04b6b33f83e4e7e36d68fc3e48a311e81))
* added protocol plugin support for Xcode targets ([#58](https://github.com/SwiftyLab/MetaCodable/issues/58)) ([5cc5919](https://github.com/SwiftyLab/MetaCodable/commit/5cc59195b3dd9ce3d8c14a20f047f5f9204ecd1a))


### 🐛 Fixes

* fixed duplicate `CodingKey`s generated ([#63](https://github.com/SwiftyLab/MetaCodable/issues/63)) ([73c5d1e](https://github.com/SwiftyLab/MetaCodable/commit/73c5d1ec7057aeae18cfcb1f733f5a021dfe7cb6))


### 📚 Documentation

* added tutorials for helper and dynamic decoding/encoding ([#64](https://github.com/SwiftyLab/MetaCodable/issues/64)) ([3f87100](https://github.com/SwiftyLab/MetaCodable/commit/3f8710048fc5ce8b83a244d95bbfca188b8d0a77))

## [1.2.1](https://github.com/SwiftyLab/MetaCodable/compare/v1.2.0...v1.2.1) (2024-01-10)


### 🐛 Fixes

* fixed `IgnoreCoding` failing with `didSet` accessors ([#54](https://github.com/SwiftyLab/MetaCodable/issues/54)) ([bd881c9](https://github.com/SwiftyLab/MetaCodable/commit/bd881c9ed8950e6fc38c4cf90bd32c947fad07cb))

## [1.2.0](https://github.com/SwiftyLab/MetaCodable/compare/v1.1.0...v1.2.0) (2024-01-09)


### 🚀 Features

* added `CodingKey` alias support ([665306f](https://github.com/SwiftyLab/MetaCodable/commit/665306f0a5d9a60da831d408eecb180060f76533))
* added actor support ([97a6057](https://github.com/SwiftyLab/MetaCodable/commit/97a605744b1d55c9b25c67e5c9d0b38da7c588a0))
* added adjacently tagged enum support ([a22e9d1](https://github.com/SwiftyLab/MetaCodable/commit/a22e9d1f8f6134f10be9d8f7b744c95efa16b36c))
* added class support ([4bfeac3](https://github.com/SwiftyLab/MetaCodable/commit/4bfeac3ffe9bf716509f4c67b0514fd8bceda68f))
* added externally tagged enum support ([c1097bb](https://github.com/SwiftyLab/MetaCodable/commit/c1097bb0a040273ac2c581de7475283d5f629d40))
* added internally tagged enum support ([fcdafa8](https://github.com/SwiftyLab/MetaCodable/commit/fcdafa808228896c43ccd9a0cd1486994d1b28b0))
* added protocol support ([535f446](https://github.com/SwiftyLab/MetaCodable/commit/535f446f13304f79f9012a13bafa9faebb58dca0))
* added sequence coding helper ([4ea6ff6](https://github.com/SwiftyLab/MetaCodable/commit/4ea6ff6affa7d94a5ad7bfc19e174ee9e2041620))


### 🐛 Fixes

* fixed empty `CodingKeys` enum generated instead of being skipped ([a28bb9c](https://github.com/SwiftyLab/MetaCodable/commit/a28bb9c25b84ca1670acc7bc248780259f4c0a73))
* fixed error with `private` access modifier on type declaration ([#46](https://github.com/SwiftyLab/MetaCodable/issues/46)) ([d378204](https://github.com/SwiftyLab/MetaCodable/commit/d378204f2675a5e9faf2f4997662e39c529e2ada))
* fixed initialized immutable variables not encoded by default ([#47](https://github.com/SwiftyLab/MetaCodable/issues/47)) ([31db2fd](https://github.com/SwiftyLab/MetaCodable/commit/31db2fdd5cbf0a212d3e798d761940b8552feb42))
* fixed nested decoding with missing container ([#44](https://github.com/SwiftyLab/MetaCodable/issues/44)) ([495cea4](https://github.com/SwiftyLab/MetaCodable/commit/495cea43b419bf8926e03fb7337405de269d2bf7))


### 📚 Documentation

* added sample usage tutorials ([2670fde](https://github.com/SwiftyLab/MetaCodable/commit/2670fde2a028e32a6e689278e307f81730a01cc5))

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

