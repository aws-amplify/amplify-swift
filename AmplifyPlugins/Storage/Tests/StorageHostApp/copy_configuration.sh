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

if [ -f "$SOURCE_DIR/AWSAmplifyStressTests-amplifyconfiguration.json" ]; then
    cp "$SOURCE_DIR/AWSAmplifyStressTests-amplifyconfiguration.json" "$DESTINATION_DIR/amplifyconfiguration.json"
    touch "$DESTINATION_DIR/amplify_outputs.json"
    exit 0
fi

if [ -f "$SOURCE_DIR/AWSS3StoragePluginTests-amplifyconfiguration.json" ]; then
    cp "$SOURCE_DIR/AWSS3StoragePluginTests-amplifyconfiguration.json" "$DESTINATION_DIR/amplifyconfiguration.json"
else
    touch "$DESTINATION_DIR/amplifyconfiguration.json"
fi

if [ -f "$SOURCE_DIR/AWSS3StoragePluginTests-amplify_outputs.json" ]; then
    cp "$SOURCE_DIR/AWSS3StoragePluginTests-amplify_outputs.json" "$DESTINATION_DIR/amplify_outputs.json"
else
    touch "$DESTINATION_DIR/amplify_outputs.json"
fi

exit 0

