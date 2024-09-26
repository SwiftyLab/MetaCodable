# Contributing Guidelines

This document contains information and guidelines about contributing to this project.
Please read it before you start participating.

_See also: [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md)_

## Submitting Pull Requests

You can contribute by fixing bugs or adding new features. For larger code changes, we first recommend discussing them in our [Github issues](https://github.com/SwiftyLab/MetaCodable/issues). When submitting a pull request, please add relevant tests and ensure your changes don't break any existing tests (see [Automated Tests](#automated-tests) below).

### Things you will need

* Linux, Mac OS (preferred), or Windows.
* Git
* [Swift](https://www.swift.org/getting-started/#installing-swift)
* Optional
  * Xcode and [CocoaPods], to test [CocoaPods] integration
  * [Node], to use helper scripts in [package.json](package.json) folder.

### Setting up dev environment

#### VSCode

This repository contains necessary configurations and extesnions required for development in VSCode.

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

GitHub action is already setup to run tests on pull requests targeting `main` branch. However, to reduce heavy usage of GitHub runners, run the following commands in your terminal to test:

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
