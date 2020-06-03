#!/bin/sh

# Copyright 2018-2020 Amazon.com,
# Inc. or its affiliates. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -e

if ! which node >/dev/null; then
  echo "warning: Node is not installed. Visit https://nodejs.org/en/download/ to install it"
  exit 1
fi

export PATH=$PATH:$(npm bin -g)

AMP_APP_VERSION_MINIMUM="2.17.1"
AMP_APP_VERSION_CURRENT=`npx -q amplify-app --version`
AMP_APP_VERSION_INVALID=0

#TODO: This is vending unicode, need to strip these characters our safely
#      and fix whatever is outputting these characters
#AMP_CLI_VERSION_MINIMUM="4.21.0"
#AMP_CLI_VERSION_CURRENT=`npx -q amplify --version |grep "\."`
#AMP_CLI_VERSION_INVALID=0

VERSION_INVALID=
checkMinVersionCompatibility() {
    VERSION_INVALID=0
    CURR_VERSION_MAJOR=`echo "${1}" | tr  '.' ' ' | awk '{print $1}'`
    CURR_VERSION_MINOR=`echo "${1}" | tr  '.' ' ' | awk '{print $2}'`
    CURR_VERSION_PATCH=`echo "${1}" | tr  '.' ' ' | awk '{print $3}'`

    REQU_VERSION_MAJOR=`echo "${2}" | tr  '.' ' ' | awk '{print $1}'`
    REQU_VERSION_MINOR=`echo "${2}" | tr  '.' ' ' | awk '{print $2}'`
    REQU_VERSION_PATCH=`echo "${2}" | tr  '.' ' ' | awk '{print $3}'`

    if [ -z "${CURR_VERSION_MAJOR}" ] ||
	[ -z "${CURR_VERSION_MINOR}" ] ||
	[ -z "${CURR_VERSION_PATCH}" ] ||
	[ -z "${REQU_VERSION_MAJOR}" ] ||
	[ -z "${REQU_VERSION_MINOR}" ] ||
	[ -z "${REQU_VERSION_PATCH}" ]; then
	VERSION_INVALID=1
	return
    fi

    if [ ${CURR_VERSION_MAJOR} -lt ${REQU_VERSION_MAJOR} ]; then
	VERSION_INVALID=1
	return
    else
	if [ ${CURR_VERSION_MINOR} -lt ${REQU_VERSION_MINOR} ]; then
	    VERSION_INVALID=1
	    return
	else
	    if [ ${CURR_VERSION_PATCH} -lt ${REQU_VERSION_PATCH} ]; then
		VERSION_INVALID=1
		return
	    fi
	fi
    fi
}

checkMinVersionCompatibility "${AMP_APP_VERSION_CURRENT}" "${AMP_APP_VERSION_MINIMUM}"
AMP_APP_VERSION_INVALID=${VERSION_INVALID}

#checkMinVersionCompatibility "${AMP_CLI_VERSION_CURRENT}" "${AMP_CLI_VERSION_MINIMUM}"
#AMP_CLI_VERSION_INVALID=${VERSION_INVALID}

if [ ${AMP_APP_VERSION_INVALID} -eq 1 ]; then
    NPX_AMP_APPCMD="npx amplify-app@latest"
else
    NPX_AMP_APPCMD="npx amplify-app"
fi


if ! test -f ./amplifytools.xcconfig; then
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
