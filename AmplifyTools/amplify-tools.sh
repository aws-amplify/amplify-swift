#!/bin/sh

# Copyright 2018-2020 Amazon.com,
# Inc. or its affiliates. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -e
export PATH=$PATH:$(npm bin -g)

MIN_SUPPORTED_VERSION_MAJOR=2
MIN_SUPPORTED_VERSION_MINOR=17
MIN_SUPPORTED_VERSION_PATCH=1

CURR_VERSION=`npx -q amplify-app --version`
CURR_VERSION_MAJOR=`echo ${CURR_VERSION} | tr  '.' ' ' | awk '{print $1}'`
CURR_VERSION_MINOR=`echo ${CURR_VERSION} | tr  '.' ' ' | awk '{print $2}'`
CURR_VERSION_PATCH=`echo ${CURR_VERSION} | tr  '.' ' ' | awk '{print $3}'`
LOCAL_AMPAPP_VERSION_INVALID=0

checkVersionAmplifyApp() {
    if [ ${CURR_VERSION_MAJOR} -lt ${MIN_SUPPORTED_VERSION_MAJOR} ]; then
	LOCAL_AMPAPP_VERSION_INVALID=1
	return
    else
	if [ ${CURR_VERSION_MINOR} -lt ${MIN_SUPPORTED_VERSION_MINOR} ]; then
	    LOCAL_AMPAPP_VERSION_INVALID=1
	    return
	else
	    if [ ${CURR_VERSION_PATCH} -lt ${MIN_SUPPORTED_VERSION_PATCH} ]; then
		LOCAL_AMPAPP_VERSION_INVALID=1
		return
	    fi
	fi
    fi
}
checkVersionAmplifyApp

if [ ${LOCAL_AMPAPP_VERSION_INVALID} -eq 1 ]; then
    NPX_AMP_APPCMD="npx amplify-app@latest"
else
    NPX_AMP_APPCMD="npx amplify-app"
fi

if ! which node >/dev/null; then
  echo "warning: Node is not installed. Visit https://nodejs.org/en/download/ to install it"
  exit 1
elif ! test -f ./amplifytools.xcconfig; then
  ${NPX_AMP_APPCMD} --platform ios
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
  ${NPX_AMP_APPCMD} --platform ios
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
