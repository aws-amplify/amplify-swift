#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Self-test for fetch-ci-config.sh over a fake `aws` on PATH. No AWS call is made: the fake is checked to be the
# `aws` the script finds before anything runs, HOME is a temporary directory, and the AWS CLI's config and
# credential files are /dev/null. The bucket and profile are placeholders.
#
#   bash infra/test_fetch_ci_config.sh
#
# It checks that the script refuses bad usage, a missing bucket or profile, a bucket with a path, a destination
# that is missing, not empty, or inside the home directory's .aws-amplify (that directory, one below it, a symlink
# into it, or the target of a symlinked .aws-amplify), and leaves that directory untouched; that --dry-run calls
# nothing and prints no bucket or profile; that a download runs CI's command (s3://<bucket>/auth/ <dest>
# --recursive) with the profile, accepting the bucket with or without s3://, and leaves the files mode 600; and
# that a failed download exits non-zero with the CLI's error masked.
set -euo pipefail
INFRA="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$INFRA/fetch-ci-config.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
WORK="$(cd "$WORK" && pwd -P)"
BIN="$WORK/bin"
mkdir -p "$BIN" "$WORK/home/.aws-amplify/amplify-ios/testconfiguration"
export HOME="$WORK/home" FAKE_LOG="$WORK/calls.log"
export AWS_CONFIG_FILE=/dev/null AWS_SHARED_CREDENTIALS_FILE=/dev/null
unset AWS_PROFILE FAKE_FAIL
BUCKET_NAME="fake-ci-bucket.example"
PROFILE_NAME="fake-ci-profile"
OWN_FILE="$HOME/.aws-amplify/amplify-ios/testconfiguration/AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json"
echo '{"own": true}' > "$OWN_FILE"

cat > "$BIN/aws" <<'EOF'
#!/usr/bin/env bash
# A fake AWS CLI: records its arguments, and for `s3 cp <src> <dest> --recursive` writes two files into <dest>.
printf '%s\n' "$*" >> "$FAKE_LOG"
if [[ -n "${FAKE_FAIL:-}" ]]; then
    echo "fatal error: An error occurred (AccessDenied) for s3://fake-ci-bucket.example/auth/ in 123456789012," \
        "profile fake-ci-profile" >&2
    exit 1
fi
[[ "$1 $2" == "s3 cp" ]] || exit 3
dest="$4"
echo '{}' > "$dest/AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json"
echo '{}' > "$dest/AWSCognitoPluginWebAuthnIntegrationTests-amplify_outputs.json"
EOF
chmod +x "$BIN/aws"
export PATH="$BIN:$PATH"
[[ "$(command -v aws)" == "$BIN/aws" ]] || { echo "FAIL: the fake aws is not first on PATH"; exit 1; }

failures=0
pass() { echo "ok - $1"; }
fail() { echo "FAIL - $1"; failures=$((failures + 1)); }

# Runs a check function; reports it by name.
check() {
    local name="$1"
    shift
    if "$@"; then pass "$name"; else fail "$name"; fi
}

# Runs the script; sets OUT (stdout and stderr) and STATUS.
run() {
    STATUS=0
    OUT=$("$SCRIPT" "$@" 2>&1) || STATUS=$?
}

expect_refusal() {
    local name="$1" pattern="$2"
    shift 2
    : > "$FAKE_LOG"
    run "$@"
    if (( STATUS != 0 )) && [[ "$OUT" == *"$pattern"* ]] && [[ ! -s "$FAKE_LOG" ]]; then
        pass "$name"
    else
        fail "$name (status $STATUS, output: $OUT)"
    fi
}

own_set_untouched() {
    [[ "$(cat "$OWN_FILE")" == '{"own": true}' ]] \
        && [[ "$(find "$HOME/.aws-amplify" -type f | wc -l | tr -d ' ')" == 1 ]]
}

refuses_without() {
    local variable="$1" pattern="$2" status=0 out
    mkdir -p "$WORK/d0"
    : > "$FAKE_LOG"
    out=$(env -u "$variable" "$SCRIPT" "$WORK/d0" 2>&1) || status=$?
    (( status != 0 )) && [[ "$out" == *"$pattern"* ]] && [[ ! -s "$FAKE_LOG" ]]
}

refuses_a_bucket_path() {
    local status=0 out
    mkdir -p "$WORK/d0"
    : > "$FAKE_LOG"
    out=$(COGNITO_CLIENT_INTEG_CI_BUCKET="s3://$BUCKET_NAME/auth" "$SCRIPT" "$WORK/d0" 2>&1) || status=$?
    (( status != 0 )) && [[ "$out" == *"no path"* ]] && [[ "$out" != *"$BUCKET_NAME"* ]] && [[ ! -s "$FAKE_LOG" ]]
}

# The home directory's .aws-amplify itself a symlink to a directory elsewhere.
refuses_a_symlinked_home_target() {
    local home2="$WORK/home2" status=0 out
    mkdir -p "$home2" "$WORK/real-amplify/empty"
    ln -s "$WORK/real-amplify" "$home2/.aws-amplify"
    : > "$FAKE_LOG"
    out=$(HOME="$home2" "$SCRIPT" "$WORK/real-amplify/empty" 2>&1) || status=$?
    (( status != 0 )) && [[ "$out" == *"inside ~/.aws-amplify"* ]] && [[ ! -s "$FAKE_LOG" ]]
}

export COGNITO_CLIENT_INTEG_CI_BUCKET="$BUCKET_NAME" COGNITO_CLIENT_INTEG_CI_PROFILE="$PROFILE_NAME"

expect_refusal "no argument is usage" "Usage:"
expect_refusal "two arguments is usage" "Usage:" "$WORK/a" "$WORK/b"
check "a missing bucket is refused" refuses_without COGNITO_CLIENT_INTEG_CI_BUCKET "set COGNITO_CLIENT_INTEG_CI_BUCKET"
check "a missing profile is refused" refuses_without COGNITO_CLIENT_INTEG_CI_PROFILE "COGNITO_CLIENT_INTEG_CI_PROFILE"
check "a bucket with a path is refused, unprinted" refuses_a_bucket_path

expect_refusal "a missing destination is refused" "is not a directory" "$WORK/missing"
mkdir -p "$WORK/full" && touch "$WORK/full/stale.json"
expect_refusal "a non-empty destination is refused" "is not empty" "$WORK/full"

expect_refusal "the home .aws-amplify itself is refused" "inside ~/.aws-amplify" "$HOME/.aws-amplify"
expect_refusal "the plugin's directory is refused" "inside ~/.aws-amplify" \
    "$HOME/.aws-amplify/amplify-ios/testconfiguration"
mkdir -p "$HOME/.aws-amplify/empty"
expect_refusal "an empty directory below the home .aws-amplify is refused" "inside ~/.aws-amplify" \
    "$HOME/.aws-amplify/empty"
ln -s "$HOME/.aws-amplify/empty" "$WORK/link-in"
expect_refusal "a symlink into the home .aws-amplify is refused" "inside ~/.aws-amplify" "$WORK/link-in"
rmdir "$HOME/.aws-amplify/empty"
check "the target of a symlinked home .aws-amplify is refused" refuses_a_symlinked_home_target
check "the refusals left the home .aws-amplify untouched" own_set_untouched

mkdir -p "$WORK/dry"
: > "$FAKE_LOG"
run --dry-run "$WORK/dry"
if (( STATUS == 0 )) && [[ ! -s "$FAKE_LOG" ]] && [[ "$OUT" == *"s3://<bucket>/auth/"* ]] \
    && [[ "$OUT" != *"$BUCKET_NAME"* && "$OUT" != *"$PROFILE_NAME"* ]] && [[ -z "$(ls -A "$WORK/dry")" ]]; then
    pass "--dry-run calls nothing and prints no bucket or profile"
else
    fail "--dry-run calls nothing and prints no bucket or profile (status $STATUS, output: $OUT)"
fi
expect_refusal "--dry-run still refuses the home .aws-amplify" "inside ~/.aws-amplify" --dry-run "$HOME/.aws-amplify"

for form in "$BUCKET_NAME" "s3://$BUCKET_NAME" "s3://$BUCKET_NAME/"; do
    dest="$WORK/dest-$RANDOM"
    mkdir -p "$dest"
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(COGNITO_CLIENT_INTEG_CI_BUCKET="$form" "$SCRIPT" "$dest" 2>&1) || STATUS=$?
    expected="s3 cp s3://$BUCKET_NAME/auth/ $dest --recursive --only-show-errors --profile $PROFILE_NAME"
    modes=$(find "$dest" -type f -exec stat -f '%Lp' {} + | sort -u)
    shown="${form/$BUCKET_NAME/<bucket>}"
    if (( STATUS == 0 )) && [[ "$(cat "$FAKE_LOG")" == "$expected" ]] && [[ "$modes" == 600 ]] \
        && [[ "$OUT" == *"Downloaded 2 files"* ]] && [[ "$OUT" != *"$BUCKET_NAME"* ]]; then
        pass "a download runs CI's command, bucket given as '$shown', files mode 600"
    else
        fail "a download, bucket given as '$shown' (status $STATUS, call: $(cat "$FAKE_LOG"), modes: $modes, output: $OUT)"
    fi
done

mkdir -p "$WORK/failing"
STATUS=0
OUT=$(FAKE_FAIL=1 "$SCRIPT" "$WORK/failing" 2>&1) || STATUS=$?
if (( STATUS != 0 )) && [[ "$OUT" == *"AccessDenied"* && "$OUT" == *"<bucket>"* && "$OUT" == *"<profile>"* ]] \
    && [[ "$OUT" != *"$BUCKET_NAME"* && "$OUT" != *"$PROFILE_NAME"* && "$OUT" != *123456789012* ]]; then
    pass "a failed download exits non-zero with the error masked"
else
    fail "a failed download exits non-zero with the error masked (status $STATUS, output: $OUT)"
fi

check "the home .aws-amplify is untouched at the end" own_set_untouched

if (( failures > 0 )); then
    echo "$failures failed"
    exit 1
fi
echo "All passed"
