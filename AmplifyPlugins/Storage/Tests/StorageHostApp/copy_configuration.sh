#!/bin/sh

set -e

SOURCE_DIR=$HOME/.aws-amplify/amplify-ios/testconfiguration
DESTINATION_DIR="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/testconfiguration/"

if [ ! -d "$SOURCE_DIR" ]; then
    echo "error: Test configuration directory does not exist: ${SOURCE_DIR}" && exit 1
fi

mkdir -p "$DESTINATION_DIR"
cp -r "$SOURCE_DIR"/*.json $DESTINATION_DIR

exit 0
