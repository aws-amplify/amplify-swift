#!/bin/bash

set -e

GIT_URL="${UPDATE_MODELS_GIT_URL:-git@github.com:aws/aws-models.git}"
OUTPUT_DIR="../aws-models"

if [ ! -d ${OUTPUT_DIR} ]; then
    echo "Could not find ${OUTPUT_DIR}"
    echo "  Are you running the script in the right location?"
    exit 1
fi

TEMPDIR=`mktemp -d`
fetchGitHubRepo() {
    mkdir -p ${TEMPDIR}
    pushd ${TEMPDIR}
    git clone ${GIT_URL}
    # git clone git@github.com:aws/aws-models.git
    # git clone https://github.com/aws/aws-models.git
    popd
}
cleanup() {
    rm -Rf ${TEMPDIR}
}


#if [ ! -d ${TEMPDIR} ]; then
fetchGitHubRepo
#else
#    echo "No need to fetch new models"
#fi

JSON_MODEL_FILES=`find ${TEMPDIR}/aws-models |grep -e "smithy\/model\.json$"`

# Delete all current model files before copying latest models in.
# This ensures that removed models will not be included in the next release.
rm -rf $OUTPUT_DIR/*

for model in ${JSON_MODEL_FILES}; do
  SDK_ID=`jq -r '.shapes[] | select (.type == "service") | .traits."aws.api#service".sdkId' $model`
  FILENAME=`echo "$SDK_ID" | tr -d "," | tr '[:upper:]' '[:lower:]' | tr " " "-"`
  cp -v "$model" "${OUTPUT_DIR}/${FILENAME}.json"
done

cleanup

