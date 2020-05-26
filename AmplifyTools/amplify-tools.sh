#!/bin/sh

# Copyright 2018-2020 Amazon.com,
# Inc. or its affiliates. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -e
export PATH=$PATH:$(npm bin -g)

if ! which node >/dev/null; then
  echo "warning: Node is not installed. Visit https://nodejs.org/en/download/ to install it"
  exit 1
elif ! test -f ./amplifytools.xcconfig; then
  npx amplify-app --platform ios
fi

. amplifytools.xcconfig
amplifyPush=$push
amplifyModelgen=$modelgen
amplifyProfile=$profile
amplifyAccessKey=$accessKeyId
amplifySecretKey=$secretAccessKey
amplifyRegion=$region
amplifyEnvName=$envName

if $amplifyModelgen; then
  echo "modelgen is set to true, generating Swift models from schema.graphql..."
  amplify codegen model
  # calls amplify-app again so the Xcode project is updated with the generated models
  npx amplify-app --platform ios
fi

if [ -z "$amplifyAccessKey" ] || [ -z "$amplifySecretKey" ] || [ -z "$amplifyRegion" ]; then

  AWSCLOUDFORMATIONCONFIG="{\
  \"configLevel\":\"project\",\
  \"useProfile\":true,\
  \"profileName\":\"${amplifyProfile}\"\
}"
else
  AWSCLOUDFORMATIONCONFIG="{\
  \"configLevel\":\"project\",\
  \"useProfile\":true,\
  \"profileName\":\"${amplifyProfile}\",\
  \"accessKeyId\":\"${amplifyAccessKeyId}\",\
  \"secretAccessKey\":\"${amplifySecretAccessKey}\",\
  \"region\":\"${amplifyRegion}\"\
}"
fi

if [ -z "$amplifyEnvName" ]; then
  AMPLIFY="{\"envName\":\"amplify\"}"
else
  AMPLIFY="{\"envName\":\"${amplifyEnvName}\"}"
fi
PROVIDERS="{\
  \"awscloudformation\":$AWSCLOUDFORMATIONCONFIG\
}"

if $amplifyPush; then
  if test -f ./amplify/.config/local-env-info.json; then
    amplify push --yes
  else
    amplify init --amplify $AMPLIFY --providers $PROVIDERS --yes
  fi
fi
