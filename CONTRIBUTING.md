# Contributing Guidelines

This document contains information and guidelines about contributing to this project.
Please read it before you start participating.

_See also: [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md)_

## Developer Documentation

Detailed documentation for contributors is available in the [Contributing](Contributing/README.md) folder:

- [Architecture Overview](Contributing/ARCHITECTURE.md) - Core components and system design
- [Macro Processing Pipeline](Contributing/MACRO_PROCESSING.md) - Class hierarchy and code generation
- [Coding Strategies](Contributing/CODING_STRATEGIES.md) - Implementation patterns and helper systems
- [Build Plugin System](Contributing/BUILD_PLUGIN.md) - Plugin architecture and integration
- [Testing and Development](Contributing/TESTING.md) - Testing methodology and best practices
- [Troubleshooting](Contributing/TROUBLESHOOTING.md) - Common issues and solutions

## Submitting Pull Requests

You can contribute by fixing bugs or adding new features. For larger code changes, we first recommend:
1. Review the [Architecture Overview](Contributing/ARCHITECTURE.md) to understand the system
2. Discuss your proposed changes in our [Github issues](https://github.com/SwiftyLab/MetaCodable/issues)
3. Read the relevant documentation in the [Contributing](Contributing/README.md) folder
4. Submit your pull request with appropriate tests (see [Testing](Contributing/TESTING.md))

### Things you will need

* Linux, Mac OS (preferred), or Windows.
* Git
* [Swift](https://www.swift.org/getting-started/#installing-swift)
* Optional
  * Xcode and [CocoaPods], to test [CocoaPods] integration
  * [Node], to use helper scripts in [package.json](package.json) folder.

### Setting up development environment

#### VSCode

This repository contains necessary configurations and extensions required for development in VSCode.

#### Xcode

For development in Xcode you have to set `METACODABLE_CI` environment variable. You can do so by launching Xcode with following command:

```sh
open $PATH_TO_XCODE_INSTALLATION --env METACODABLE_CI=1
# i.e. open /Applications/Xcode.app --env METACODABLE_CI=1
```

> [!IMPORTANT]
> Make sure that Xcode is not running before this command executed.
> Otherwise, this command will have no effect.

### Automated Tests

GitHub action is already setup to run tests on pull requests targeting `main` branch. For detailed testing instructions and methodology, see our [Testing Guide](Contributing/TESTING.md).

To run tests locally and reduce usage of GitHub runners:

| Test category | With [Node] | Manually |
| --- | --- | --- |
| SPM integration | Run `npm run test` | Run `METACODABLE_CI=true swift test` |
| [CocoaPods] integration (Requires Xcode) | Run `npm run pod-lint` | Run `pod lib lint --no-clean --allow-warnings` |

## Developer's Certificate of Origin 1.1

By making a contribution to this project, I certify that:

<ol type='a'>
  <li id='cert-a'>
  The contribution was created in whole or in part by me and I have the right to submit it under the open source license indicated in the file; or
  </li>
  <li id='cert-b'>
  The contribution is based upon previous work that, to the best of my knowledge, is covered under an appropriate open source license and I have the right under that license to submit that work with modifications, whether created in whole or in part by me, under the same open source license (unless I am permitted to submit under a different license), as indicated in the file; or
  </li>
  <li id='cert-c'>
  The contribution was provided directly to me by some other person who certified <a href="#cert-a">(a)</a>, <a href="#cert-b">(b)</a> or <a href="#cert-c">(c)</a> and I have not modified it.
  </li>
  <li id='cert-d'>
  I understand and agree that this project and the contribution are public and that a record of the contribution (including all personal information I submit with it, including my sign-off) is maintained indefinitely and may be redistributed consistent with this project or the open source license(s) involved.
  </li>
</ol>

[CocoaPods]: https://cocoapods.org/
[Node]: https://nodejs.org/
