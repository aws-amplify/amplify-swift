#!/bin/sh

set -e

SOURCE_DIR=$HOME/.aws-amplify/amplify-ios/testconfiguration
DESTINATION_DIR="$SOURCE_ROOT"

if [ -d "$AMPLIFY_CONFIGURATION_PATH" ]; then
    echo "Found AMPLIFY_CONFIGURATION_PATH - copying"
    mkdir -p "$DESTINATION_DIR"
    ditto "$AMPLIFY_CONFIGURATION_PATH" "$DESTINATION_DIR"
    exit 0
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "error: Test configuration directory does not exist: ${SOURCE_DIR}" && exit 1
fi

mkdir -p "$DESTINATION_DIR"
cp "$SOURCE_DIR/AWSS3StoragePluginTests-amplifyconfiguration.json" "$DESTINATION_DIR/amplifyconfiguration.json"

exit 0
