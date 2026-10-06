#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Builds, for the client's CI jobs only, the test configuration directory their build phases copy from
# (COGNITO_CLIENT_INTEG_DIR): the plugin's files as CI downloaded them, plus, for the roles named in <roles>, the
# client's own CI resources' files (infra/ci/provision-ci.sh), which CI downloads into the cognito-client-ci/
# subfolder. Nothing is written into the downloaded directory, and no plugin job runs this, so the plugin's tests
# read exactly what they read before.
#
#   infra/ci/ci-overlay.sh <testconfiguration-dir> <dest-dir> "<roles>"
#
# <roles> is a space- or comma-separated list of:
#   email-alias  (phase 1) the device-alias role, in place of the plugin's backend:
#                ccit-ci-email-alias-amplify_outputs.json  -> AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json
#   extended     (phase 2) the client's own role SandboxPool.extended, beside the plugin's default role, which stays
#                the plugin's; only the tests that need its extras use it:
#                ccit-ci-default-amplify_outputs.json      -> AmplifyCognitoClientExtendedIntegrationTests-amplify_outputs.json
#                and with it, when present,
#                ccit-ci-default-credentials.json           -> AmplifyCognitoClientExtendedIntegrationTests-credentials.json
#                ccit-ci-rotation-amplify_outputs.json      -> AmplifyCognitoClientRotationIntegrationTests-amplify_outputs.json
#
# Exit 0 with <dest-dir> made (mode 700, files 600) when at least one role was overlaid, and exit 0 with no
# <dest-dir> when there is nothing to overlay (no subfolder, or none of the roles' files): the caller then leaves
# COGNITO_CLIENT_INTEG_DIR unset, and the suites skip on CI as before. A file that does not check out (not JSON,
# no user pool, the sandbox's mark, a credentials file that is not all strings, a rotation client on another
# pool) refuses the whole overlay: exit 1, no <dest-dir>. Prints file names and roles, never their contents.
set -euo pipefail

usage() {
    echo "Usage: infra/ci/ci-overlay.sh <testconfiguration-dir> <dest-dir> \"<roles>\"" >&2
    exit 2
}

[[ $# -eq 3 ]] || usage
SRC="$1"
DEST="$2"
ROLES="${3//,/ }"
SUB="$SRC/cognito-client-ci"

# Every check runs before <dest-dir> is made, so a refusal leaves nothing behind.
refuse() {
    echo "ci-overlay: not overlaid: $*" >&2
    exit 1
}

[[ -d "$SRC" ]] || refuse "$SRC is not a directory."
for role in $ROLES; do
    [[ "$role" == "email-alias" || "$role" == "extended" ]] || usage
done
[[ -n "${ROLES// /}" ]] || usage
if [[ -e "$DEST" ]]; then
    echo "ci-overlay: $DEST exists; give a new directory." >&2
    exit 1
fi
SRC_REAL="$(cd "$SRC" && pwd -P)"
DEST_PARENT="$(cd "$(dirname "$DEST")" && pwd -P)"
case "$DEST_PARENT/" in
    "$SRC_REAL"/*) echo "ci-overlay: $DEST must not be inside $SRC, which the plugin's host apps copy whole." >&2; exit 1 ;;
esac
if [[ ! -d "$SUB" ]]; then
    echo "ci-overlay: no cognito-client-ci/ in the downloaded configuration; the client suites use the plugin's files."
    exit 0
fi

# Checks a Gen2 outputs file: a JSON object naming a user pool, an app client and a region, without the sandbox's
# mark (which would turn the harness's sandbox checks and self sign-up gate on). The client's own marks, such as
# confirming_trigger, are allowed.
check_outputs() {
    jq -e 'type == "object" and (.auth.user_pool_id | type) == "string" and (.auth.user_pool_client_id | type) == "string"
        and (.auth.aws_region | type) == "string" and (.custom.amplify_cognito_client_integ.sandbox != true)' "$1" >/dev/null 2>&1 \
        || refuse "$(basename "$1") is not a Gen2 outputs file with a user pool, an app client and a region, without the sandbox's mark."
}

# The overlay, as "source destination" lines.
PLAN=()
for role in $ROLES; do
    case "$role" in
        email-alias)
            if [[ -f "$SUB/ccit-ci-email-alias-amplify_outputs.json" ]]; then
                check_outputs "$SUB/ccit-ci-email-alias-amplify_outputs.json"
                PLAN+=("ccit-ci-email-alias-amplify_outputs.json AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json")
            else
                echo "ci-overlay: email-alias: no ccit-ci-email-alias-amplify_outputs.json; that role stays the plugin's."
            fi
            ;;
        extended)
            if [[ ! -f "$SUB/ccit-ci-default-amplify_outputs.json" ]]; then
                echo "ci-overlay: extended: no ccit-ci-default-amplify_outputs.json; the tests that need it skip as before."
                continue
            fi
            check_outputs "$SUB/ccit-ci-default-amplify_outputs.json"
            pool=$(jq -r '.auth.user_pool_id' "$SUB/ccit-ci-default-amplify_outputs.json")
            PLAN+=("ccit-ci-default-amplify_outputs.json AmplifyCognitoClientExtendedIntegrationTests-amplify_outputs.json")
            if [[ -f "$SUB/ccit-ci-default-credentials.json" ]]; then
                jq -e 'type == "object" and all(.[]; type == "string")
                    and ([.custom_challenge_answer, .new_password_required_usernames,
                          .new_password_required_temporary_password] | all(type == "string" and length > 0))' \
                    "$SUB/ccit-ci-default-credentials.json" >/dev/null 2>&1 \
                    || refuse "ccit-ci-default-credentials.json is not an object of strings with the three keys the client reads."
                PLAN+=("ccit-ci-default-credentials.json AmplifyCognitoClientExtendedIntegrationTests-credentials.json")
            fi
            if [[ -f "$SUB/ccit-ci-rotation-amplify_outputs.json" ]]; then
                check_outputs "$SUB/ccit-ci-rotation-amplify_outputs.json"
                [[ "$(jq -r '.auth.user_pool_id' "$SUB/ccit-ci-rotation-amplify_outputs.json")" == "$pool" ]] \
                    || refuse "ccit-ci-rotation-amplify_outputs.json names another user pool than ccit-ci-default-amplify_outputs.json."
                PLAN+=("ccit-ci-rotation-amplify_outputs.json AmplifyCognitoClientRotationIntegrationTests-amplify_outputs.json")
            fi
            ;;
    esac
done
if (( ${#PLAN[@]} == 0 )); then
    echo "ci-overlay: nothing to overlay; the client suites use the plugin's files."
    exit 0
fi

umask 077
mkdir -p "$DEST"
chmod 700 "$DEST"
# The plugin's top-level files (never the subfolder), less the one the email-alias role replaces.
for path in "$SRC"/*.json; do
    [[ -f "$path" && ! -L "$path" ]] || continue
    name=$(basename "$path")
    skip=0
    for entry in "${PLAN[@]}"; do
        [[ "${entry#* }" == "$name" ]] && skip=1
    done
    (( skip )) || cp "$path" "$DEST/$name"
done
for entry in "${PLAN[@]}"; do
    cp "$SUB/${entry%% *}" "$DEST/${entry#* }"
    echo "ci-overlay: ${entry#* } <- cognito-client-ci/${entry%% *}"
done
find "$DEST" -type f -exec chmod 600 {} +
echo "ci-overlay: wrote $(find "$DEST" -type f | wc -l | tr -d ' ') files into $DEST"
