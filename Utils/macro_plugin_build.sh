#!/usr/bin/env sh

SDK=$(xcrun --show-sdk-path)
echo "swift build --configuration ${CONFIG:=release} --product MacroPlugin --sdk \"$SDK\" --toolchain \"$TOOLCHAIN\" --package-path \"$SRCROOT\" --scratch-path \"${BUILD_DIR}/Macros/MacroPlugin\""
swift build --configuration ${CONFIG:=release} --product MacroPlugin --sdk "$SDK" --toolchain "$TOOLCHAIN" --package-path "$SRCROOT" --scratch-path "${BUILD_DIR}/Macros/MacroPlugin"
