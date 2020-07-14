#!/bin/sh

# Copyright 2018-2020 Amazon.com,
# Inc. or its affiliates. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0


if ! which node >/dev/null; then
  echo "warning: Node is not installed. Visit https://nodejs.org/en/download/ to install it"
  exit 1
fi

# Check for NVM and make sure it's initialized
NVM_PATH="${HOME}/.nvm/nvm.sh"
if [ -f "${NVM_PATH}" ]; then
  echo "NVM found, initializing it..."
  source "${NVM_PATH}"
fi

set -e

export PATH=$PATH:$(npm bin -g)

# Note the use of tail -1 is important here because when upgrading between versions
# the first time that you run these commands, we have seen this variable take on the value of:
# """
# Scanning for plugins...
# plugin scan successful
# 4.21.0
# """
AMP_APP_VERSION_CURRENT=`npx -q amplify-app --version |tail -1`
AMP_APP_VERSION_MINIMUM="2.17.1"
AMP_APP_VERSION_INVALID=0

AMP_CLI_VERSION_CURRENT=`npx -q amplify --version |tail -1`
AMP_CLI_VERSION_MINIMUM="4.22.0"
AMP_CLI_VERSION_INVALID=0


STRIP_ESCAPE_RESULT=
stripEscapeUtil() {
    STRIP_ESCAPE_RESULT=

    set +e
    HAS_RUBY=0
    which ruby > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
	HAS_RUBY=1
    fi
    set -e

    if [ ${HAS_RUBY} -eq 1 ]; then
	STRIP_ESCAPE_RESULT=`echo "${1}" | ruby -pe 'gsub(/\e\[[0-9;]*m/s, "")'`
    else
	STRIP_ESCAPE_RESULT=`echo "${1}" | npx -q strip-ansi-cli`
    fi
}

VERSION_INVALID=
checkMinVersionCompatibility() {
    VERSION_INVALID=0

    stripEscapeUtil "${1}"
    CURR_VERSION_SAFE="${STRIP_ESCAPE_RESULT}"
    CURR_VERSION_MAJOR=`echo "${CURR_VERSION_SAFE}" | tr  '.' ' ' | awk '{print $1}'`
    CURR_VERSION_MINOR=`echo "${CURR_VERSION_SAFE}" | tr  '.' ' ' | awk '{print $2}'`
    CURR_VERSION_PATCH=`echo "${CURR_VERSION_SAFE}" | tr  '.' ' ' | awk '{print $3}'`

    stripEscapeUtil "${2}"
    REQU_VERSION_SAFE="${STRIP_ESCAPE_RESULT}"
    REQU_VERSION_MAJOR=`echo "${REQU_VERSION_SAFE}" | tr  '.' ' ' | awk '{print $1}'`
    REQU_VERSION_MINOR=`echo "${REQU_VERSION_SAFE}" | tr  '.' ' ' | awk '{print $2}'`
    REQU_VERSION_PATCH=`echo "${REQU_VERSION_SAFE}" | tr  '.' ' ' | awk '{print $3}'`

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

checkMinVersionCompatibility "${AMP_CLI_VERSION_CURRENT}" "${AMP_CLI_VERSION_MINIMUM}"
AMP_CLI_VERSION_INVALID=${VERSION_INVALID}

if [ ${AMP_CLI_VERSION_INVALID} -eq 1 ]; then
    echo "error: Minimum version required of Amplify CLI is not installed."
    echo "  Min required version: (${AMP_CLI_VERSION_MINIMUM})"
    echo "  Found Version: (${AMP_CLI_VERSION_CURRENT})"
    echo ""
    echo "To install the latest version, please run the following command:"
    echo "  npm install -g @aws-amplify/cli@latest"
    exit 1
else
    echo "Found amplify-cli version: (${AMP_CLI_VERSION_CURRENT}), Required: >= (${AMP_CLI_VERSION_MINIMUM})"
fi

echo "Found amplify-app version: (${AMP_APP_VERSION_CURRENT}), Required: >= (${AMP_APP_VERSION_MINIMUM})"
if [ ${AMP_APP_VERSION_INVALID} -eq 1 ]; then
    echo "  Using: npx amplify-app@latest"
    NPX_AMP_APPCMD="npx amplify-app@latest"
else
    echo "  Using: npx amplify-app"
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
