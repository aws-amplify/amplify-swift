#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Self-test for ci-overlay.sh, over placeholder files in a temporary directory (no AWS call, no real identifier):
#
#   bash infra/ci/test_ci_overlay.sh
#
# It checks that without the subfolder, or without the roles' files, nothing is made; that email-alias replaces only
# the plugin's device-alias file, and extended only adds the client's own files (its outputs, and with them only,
# its credentials and the rotation client's), leaving every plugin file, the default one included, as downloaded;
# that the downloaded directory is never written; that files are mode 600 in a mode-700 directory; that the
# client's own confirming_trigger mark is accepted; and that a file with the sandbox's mark, without a user pool, a
# credentials file with a non-string, or a rotation client on another pool refuses the whole overlay, leaving no
# directory.
set -euo pipefail
CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$CI_DIR/ci-overlay.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
failures=0
pass() { echo "ok - $1"; }
fail() { echo "FAIL - $1"; failures=$((failures + 1)); }
check() {
    local name="$1"
    shift
    if "$@"; then pass "$name"; else fail "$name"; fi
}

outputs() { # pool, client
    printf '{"version":"1.4","auth":{"aws_region":"us-east-1","user_pool_id":"%s","user_pool_client_id":"%s"}}\n' "$1" "$2"
}

# A downloaded configuration: the plugin's nine files (placeholders) and, unless $2 is "none", the subfolder.
download() {
    local dir="$1" sub="$2" name
    mkdir -p "$dir"
    for name in AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json \
        AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json \
        AWSCognitoPluginPasswordlessIntegrationTests-amplify_outputs.json; do
        echo '{"plugin": true}' > "$dir/$name"
    done
    [[ "$sub" == "none" ]] && return
    mkdir -p "$dir/cognito-client-ci"
    outputs us-east-1_PLACEHOLDA clientalias \
        | jq -c '. + {custom: {amplify_cognito_client_integ: {confirming_trigger: true}}}' \
        > "$dir/cognito-client-ci/ccit-ci-email-alias-amplify_outputs.json"
    if [[ "$sub" == "full" ]]; then
        outputs us-east-1_PLACEHOLDD clientdefault > "$dir/cognito-client-ci/ccit-ci-default-amplify_outputs.json"
        outputs us-east-1_PLACEHOLDD clientrotation > "$dir/cognito-client-ci/ccit-ci-rotation-amplify_outputs.json"
        echo '{"custom_challenge_answer":"a","new_password_required_usernames":"u1,u2","new_password_required_temporary_password":"t"}' \
            > "$dir/cognito-client-ci/ccit-ci-default-credentials.json"
    fi
}

snapshot_of() { (cd "$1" && find . -type f -exec shasum {} + | sort); }

run() { # src dest roles; sets OUT and STATUS
    STATUS=0
    OUT=$("$SCRIPT" "$@" 2>&1) || STATUS=$?
}

no_subfolder_makes_nothing() {
    download "$WORK/a" none
    run "$WORK/a" "$WORK/a-out" "email-alias extended"
    (( STATUS == 0 )) && [[ ! -e "$WORK/a-out" ]] && [[ "$OUT" == *"no cognito-client-ci/"* ]]
}

email_alias_only() {
    download "$WORK/b" alias-only
    local before
    before=$(snapshot_of "$WORK/b")
    run "$WORK/b" "$WORK/b-out" "email-alias,extended"
    (( STATUS == 0 )) || return 1
    [[ "$(snapshot_of "$WORK/b")" == "$before" ]] || return 1
    jq -e '.auth.user_pool_id == "us-east-1_PLACEHOLDA"' "$WORK/b-out/AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json" >/dev/null \
        && jq -e '.plugin' "$WORK/b-out/AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json" >/dev/null \
        && jq -e '.custom.amplify_cognito_client_integ.confirming_trigger' "$WORK/b-out/AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json" >/dev/null \
        && [[ ! -e "$WORK/b-out/AmplifyCognitoClientExtendedIntegrationTests-amplify_outputs.json" ]] \
        && [[ ! -e "$WORK/b-out/cognito-client-ci" ]] \
        && [[ "$OUT" == *"extended: no ccit-ci-default-amplify_outputs.json"* ]]
}

full_overlay() {
    download "$WORK/c" full
    local before modes
    before=$(snapshot_of "$WORK/c")
    run "$WORK/c" "$WORK/c-out" "email-alias extended"
    (( STATUS == 0 )) || return 1
    [[ "$(snapshot_of "$WORK/c")" == "$before" ]] || return 1
    modes=$(find "$WORK/c-out" -type f -exec stat -f '%Lp' {} + | sort -u)
    [[ "$modes" == 600 && "$(stat -f '%Lp' "$WORK/c-out")" == 700 ]] || return 1
    jq -e '.plugin' "$WORK/c-out/AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json" >/dev/null \
        && [[ ! -e "$WORK/c-out/AWSCognitoAuthPluginIntegrationTests-amplify_outputs.json" ]] \
        && [[ ! -e "$WORK/c-out/AWSCognitoAuthPluginIntegrationTests-credentials.json" ]] \
        && jq -e '.auth.user_pool_client_id == "clientdefault"' "$WORK/c-out/AmplifyCognitoClientExtendedIntegrationTests-amplify_outputs.json" >/dev/null \
        && jq -e '.custom_challenge_answer == "a"' "$WORK/c-out/AmplifyCognitoClientExtendedIntegrationTests-credentials.json" >/dev/null \
        && jq -e '.auth.user_pool_client_id == "clientrotation"' "$WORK/c-out/AmplifyCognitoClientRotationIntegrationTests-amplify_outputs.json" >/dev/null \
        && jq -e '.plugin' "$WORK/c-out/AWSCognitoPluginPasswordlessIntegrationTests-amplify_outputs.json" >/dev/null \
        && [[ "$(find "$WORK/c-out" -type f | wc -l | tr -d ' ')" == 6 ]] \
        && [[ "$OUT" != *PLACEHOLD* && "$OUT" != *clientdefault* ]]
}

email_alias_alone_adds_nothing_of_the_extended_role() {
    download "$WORK/d" full
    run "$WORK/d" "$WORK/d-out" "email-alias"
    (( STATUS == 0 )) && [[ ! -e "$WORK/d-out/AmplifyCognitoClientExtendedIntegrationTests-amplify_outputs.json" ]] \
        && [[ ! -e "$WORK/d-out/AmplifyCognitoClientExtendedIntegrationTests-credentials.json" ]] \
        && [[ ! -e "$WORK/d-out/AmplifyCognitoClientRotationIntegrationTests-amplify_outputs.json" ]] \
        && [[ "$(find "$WORK/d-out" -type f | wc -l | tr -d ' ')" == 3 ]]
}

extended_alone_leaves_the_alias() {
    download "$WORK/h" full
    run "$WORK/h" "$WORK/h-out" "extended"
    (( STATUS == 0 )) && jq -e '.plugin' "$WORK/h-out/AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json" >/dev/null
}

refuses() { # name of a broken case: sets up $WORK/<case>, expects a refusal and no directory
    local case="$1" pattern="$2"
    download "$WORK/$case" full
    case "$case" in
        marked) jq '.custom.amplify_cognito_client_integ.sandbox = true' \
                    "$WORK/$case/cognito-client-ci/ccit-ci-email-alias-amplify_outputs.json" > "$WORK/x" ;;
        no-pool) echo '{"version":"1.4","auth":{}}' > "$WORK/x" ;;
        not-strings) echo '{"custom_challenge_answer":1,"new_password_required_usernames":"u","new_password_required_temporary_password":"t"}' > "$WORK/x" ;;
        other-pool) outputs us-east-1_OTHERPOOL1 clientrotation > "$WORK/x" ;;
    esac
    case "$case" in
        marked|no-pool) mv "$WORK/x" "$WORK/$case/cognito-client-ci/ccit-ci-email-alias-amplify_outputs.json" ;;
        not-strings) mv "$WORK/x" "$WORK/$case/cognito-client-ci/ccit-ci-default-credentials.json" ;;
        other-pool) mv "$WORK/x" "$WORK/$case/cognito-client-ci/ccit-ci-rotation-amplify_outputs.json" ;;
    esac
    run "$WORK/$case" "$WORK/$case-out" "email-alias extended"
    (( STATUS == 1 )) && [[ ! -e "$WORK/$case-out" ]] && [[ "$OUT" == *"$pattern"* ]]
}

refuses_an_existing_destination() {
    download "$WORK/e" full
    mkdir -p "$WORK/e-out"
    touch "$WORK/e-out/keep"
    run "$WORK/e" "$WORK/e-out" "extended"
    (( STATUS != 0 )) && [[ -f "$WORK/e-out/keep" ]]
}

refuses_a_destination_inside_the_download() {
    download "$WORK/f" full
    run "$WORK/f" "$WORK/f/out" "extended"
    (( STATUS != 0 )) && [[ ! -e "$WORK/f/out" ]]
}

refuses_an_unknown_role() {
    download "$WORK/g" full
    run "$WORK/g" "$WORK/g-out" "default"
    (( STATUS == 2 )) && [[ ! -e "$WORK/g-out" ]]
}

check "no subfolder: nothing is made" no_subfolder_makes_nothing
check "only the email-alias file: that role is overlaid, its mark kept, and nothing of the extended role" email_alias_only
check "every file: email-alias replaces one plugin file, extended adds its own, mode 600 in 700, the download untouched" \
    full_overlay
check "email-alias alone adds nothing of the extended role" email_alias_alone_adds_nothing_of_the_extended_role
check "extended alone leaves the device-alias file the plugin's" extended_alone_leaves_the_alias
check "a file with the sandbox's mark refuses the overlay" refuses marked "sandbox's mark"
check "a file without a user pool refuses the overlay" refuses no-pool "with a user pool"
check "a credentials file with a non-string refuses the overlay" refuses not-strings "object of strings"
check "a rotation client on another pool refuses the overlay" refuses other-pool "another user pool"
check "an existing destination is refused and left as it is" refuses_an_existing_destination
check "a destination inside the download is refused" refuses_a_destination_inside_the_download
check "an unknown role (the retired default) is usage" refuses_an_unknown_role

if (( failures > 0 )); then
    echo "$failures failed"
    exit 1
fi
echo "All passed"
