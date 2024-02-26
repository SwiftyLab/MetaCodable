# ``MetaCodableConfig/Scan``

@Metadata {
    @DocumentationExtension(mergeBehavior: override)
}

The source file scan option for `MetaProtocolCodable` build tool plugin.

## Overview

This option can accept any of the following values, depending on which the source files scanned by `MetaProtocolCodable` build tool plugin is controlled:

- `target`: Source files present in the `MetaProtocolCodable` build tool plugin target are scanned rest of the files are ignored.
- `direct`: Source files present in the `MetaProtocolCodable` build tool plugin target and its direct dependencies are scanned rest of the files are ignored.
- `local`: Source files present in the `MetaProtocolCodable` build tool plugin target and only its direct dependencies which are local dependencies are scanned rest of the files are ignored.
- `recursive`: Source files present in the `MetaProtocolCodable` build tool plugin target and all its dependencies are scanned rest of the files are ignored.
