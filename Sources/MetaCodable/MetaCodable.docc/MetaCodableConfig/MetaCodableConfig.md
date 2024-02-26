# ``MetaCodableConfig``

@Metadata {
    @DocumentationExtension(mergeBehavior: override)
}

The configuration file providing additional customization options for `MetaProtocolCodable` build tool plugin.

## Overview

The data present in this file can be either of `plist` or `json` format. The name of the configuration file can be of any format as long as removing non-alphanumeric characters and lowercasing the name matches `metacodableconfig` text, i.e. following names are supported:

- `MetaCodableConfig.plist`
- `meta_codable_config.json`
- `meta-codable-config.json` etc.

- Important: The file must be added at the target root directory for Swift packages and for Xcode targets the file must be part of the target.

- Tip: The option names/keys provided in this file are also case-insensitive. i.e. `Scan`, `scan`, `SCAN` are all valid option names for ``Scan``.

## Topics

### Options

- ``Scan``
