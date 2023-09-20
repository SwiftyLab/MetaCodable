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

