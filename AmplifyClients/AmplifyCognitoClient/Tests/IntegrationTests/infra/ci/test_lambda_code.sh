#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Self-test for lambda_code.py, the CI Lambdas' code and drift check, over a copy of infra/'s Lambda sources in a
# temporary directory: no AWS call (the "deployed" zips are local files, given as file:// URLs, which
# CCIT_CI_TEST_FILE_CODE_URLS lets through), and the committed baseline is only read.
#
#   bash infra/ci/test_lambda_code.sh
#
# It checks that a zip is deterministic (the same bytes from another checkout time, files dated 1980, mode 644) and
# holds only the function's files; that the custom sender's holds node_modules but not npm's .package-lock.json;
# that compare reads the deployed zips file by file: a function deployed from this checkout is in sync, so is one
# whose zip holds the same files compressed and dated otherwise (its CodeSha256 only noted), and one with other
# files is DRIFT, by name, with the files that differ, never a hash or a URL; that a URL that is not https:// on an
# amazonaws.com host (or file:// outside the self-tests), or a download that is no zip, is refused; that record
# shows the same and writes nothing without --accept-deployed, and with it the deployed files, which compare then
# accepts until the sources change; that check-baseline is 0 with the recorded sources, 1 once one changed, 3 with
# no baseline; that an unexpected error is status 4, never 1; and that the committed baseline, when there is one,
# names this checkout's sources.
set -euo pipefail
CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA="$(cd "$CI_DIR/.." && pwd)"
SCRIPT="$CI_DIR/lambda_code.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
unset CCIT_CI_LAMBDA_BASELINE
# A copy of the sources, so a test can change one.
COPY="$WORK/infra"
mkdir -p "$COPY/lambda" "$COPY/ci/lambda"
cp -R "$INFRA/lambda/triggers" "$INFRA/lambda/custom-sender" "$COPY/lambda/"
cp -R "$INFRA/ci/lambda/discard-sender" "$INFRA/ci/lambda/new-password-reset" "$COPY/ci/lambda/"
rm -rf "$COPY/lambda/custom-sender/node_modules"
export CCIT_CI_INFRA_DIR="$COPY" CCIT_CI_TEST_FILE_CODE_URLS=1
BASELINE="$WORK/baseline.json"
SUFFIXES=(create-auth-challenge custom-sender define-auth-challenge discard-sender new-password-reset pre-sign-up
          pre-sign-up-confirmable verify-auth-challenge)

failures=0
check() {
    local name="$1"
    shift
    if "$@"; then echo "ok - $name"; else echo "FAIL - $name"; failures=$((failures + 1)); fi
}

run() {
    STATUS=0
    OUT=$(python3 "$SCRIPT" "$@" 2>&1) || STATUS=$?
}

sha() { python3 -c 'import base64,hashlib,sys;print(base64.b64encode(hashlib.sha256(open(sys.argv[1],"rb").read()).digest()).decode())' "$1"; }

# A custom sender build, as provision-ci.sh's `npm ci` leaves it (with npm's own .package-lock.json).
BUILD="$WORK/build"
mkdir -p "$BUILD/node_modules/dependency"
cp "$COPY/lambda/custom-sender/index.mjs" "$COPY/lambda/custom-sender/package.json" "$BUILD/"
echo 'export {};' > "$BUILD/node_modules/dependency/index.js"
echo '{}' > "$BUILD/node_modules/.package-lock.json"

# Every function's zip into $1, built from the copy.
build_all() {
    local suffix
    mkdir -p "$1"
    for suffix in "${SUFFIXES[@]}"; do
        if [[ "$suffix" == custom-sender ]]; then
            python3 "$SCRIPT" zip "$suffix" "$1/$suffix.zip" "$BUILD"
        else
            python3 "$SCRIPT" zip "$suffix" "$1/$suffix.zip"
        fi
    done
}

# "Deploys" every zip in $1: a copy of each in $WORK/deployed, and deployed.json naming it by a file:// URL with its
# CodeSha256, as provision-ci.sh writes it from GetFunction.
deploy_all() {
    local suffix json="{}"
    rm -rf "$WORK/deployed"
    mkdir -p "$WORK/deployed"
    for suffix in "${SUFFIXES[@]}"; do
        cp "$1/$suffix.zip" "$WORK/deployed/$suffix.zip"
        json=$(jq -c --arg k "$suffix" --arg s "$(sha "$1/$suffix.zip")" --arg u "file://$WORK/deployed/$suffix.zip" \
            '.[$k] = {codeSha256: $s, location: $u}' <<<"$json")
    done
    printf '%s\n' "$json" > "$WORK/deployed.json"
}

# Replaces deployed function $1's zip: "rezipped", the same files stored and dated 2024; "edited", with the first
# file changed and notes.txt added. Its CodeSha256 in deployed.json follows.
redeploy() {
    python3 - "$WORK/deployed/$1.zip" "$2" <<'PY'
import io, sys, zipfile
path, how = sys.argv[1:]
with zipfile.ZipFile(path) as z:
    files = {n: z.read(n) for n in z.namelist()}
if how == "edited":
    first = sorted(files)[0]
    files[first] += b"\n// edited by hand\n"
    files["notes.txt"] = b"not from the checkout\n"
buffer = io.BytesIO()
with zipfile.ZipFile(buffer, "w", zipfile.ZIP_STORED) as z:
    for n, data in sorted(files.items()):
        z.writestr(zipfile.ZipInfo(n, date_time=(2024, 5, 6, 7, 8, 10)), data)
with open(path, "wb") as f:
    f.write(buffer.getvalue())
PY
    jq -c --arg k "$1" --arg s "$(sha "$WORK/deployed/$1.zip")" '.[$k].codeSha256 = $s' "$WORK/deployed.json" > "$WORK/d" \
        && mv "$WORK/d" "$WORK/deployed.json"
}

# Sets deployed function $1's location to $2.
relocate() {
    jq -c --arg k "$1" --arg u "$2" '.[$k].location = $u' "$WORK/deployed.json" > "$WORK/d" && mv "$WORK/d" "$WORK/deployed.json"
}

zips_are_deterministic_and_hold_only_the_functions_files() {
    build_all "$WORK/a"
    touch -t 202001010000 "$COPY/lambda/triggers/triggers.mjs" "$BUILD/index.mjs"
    chmod 600 "$COPY/lambda/triggers/triggers.mjs"
    build_all "$WORK/b"
    chmod 644 "$COPY/lambda/triggers/triggers.mjs"
    local suffix
    for suffix in "${SUFFIXES[@]}"; do
        cmp -s "$WORK/a/$suffix.zip" "$WORK/b/$suffix.zip" || { echo "$suffix differs"; return 1; }
    done
    python3 - "$WORK/a" <<'PY'
import os, sys, zipfile
root = sys.argv[1]
with zipfile.ZipFile(os.path.join(root, "pre-sign-up.zip")) as z:
    assert z.namelist() == ["triggers.mjs"], z.namelist()
    info = z.getinfo("triggers.mjs")
    assert info.date_time == (1980, 1, 1, 0, 0, 0) and info.external_attr >> 16 == 0o644, info
with zipfile.ZipFile(os.path.join(root, "discard-sender.zip")) as z:
    assert z.namelist() == ["index.mjs"], z.namelist()
with zipfile.ZipFile(os.path.join(root, "custom-sender.zip")) as z:
    assert z.namelist() == ["index.mjs", "node_modules/dependency/index.js", "package.json"], z.namelist()
PY
}

compare_reads_the_deployed_files() {
    build_all "$WORK/z"
    deploy_all "$WORK/z"
    run compare "$WORK/deployed.json" "$WORK/z" --baseline "$BASELINE"
    (( STATUS == 0 )) && [[ "$(grep -c "the deployed files are this checkout's" <<<"$OUT")" == 8 ]] \
        && [[ "$(grep -c "CodeSha256, a note only: the same as this checkout's zip's" <<<"$OUT")" == 8 ]] \
        || { echo "$OUT"; return 1; }
    # The same files in another zip: in sync; only the note tells the CodeSha256 apart.
    redeploy discard-sender rezipped
    run compare "$WORK/deployed.json" "$WORK/z" --baseline "$BASELINE"
    (( STATUS == 0 )) && [[ "$(grep -c "the deployed files are this checkout's" <<<"$OUT")" == 8 ]] \
        && [[ "$(grep -A1 '= ccit-ci-discard-sender' <<<"$OUT")" == *"not this checkout's zip's (the files decide)"* ]] \
        || { echo "$OUT"; return 1; }
    # Other files: DRIFT, by name, with what differs.
    redeploy custom-sender edited
    run compare "$WORK/deployed.json" "$WORK/z" --baseline "$BASELINE" --github
    (( STATUS == 1 )) && [[ "$OUT" == *"::error::DRIFT ccit-ci-custom-sender: the deployed files are neither"* ]] \
        && [[ "$OUT" == *"      changed (1): index.mjs"$'\n'"      only deployed (1): notes.txt"* ]] \
        && [[ "$OUT" == *"carries purpose=amplify-cognito-client-integ"* && "$(grep -c DRIFT <<<"$OUT")" == 1 ]] \
        && [[ "$OUT" != *file:* && "$OUT" != *"$WORK"* && "$OUT" != *"$(sha "$WORK/z/custom-sender.zip")"* ]] \
        && ! grep -qE '[0-9a-f]{64}' <<<"$OUT" || { echo "$OUT"; return 1; }
    # Not deployed, or no zip from this checkout: reported, not drift.
    deploy_all "$WORK/z"
    jq -c '.["discard-sender"] = null' "$WORK/deployed.json" > "$WORK/d2.json"
    rm "$WORK/z/custom-sender.zip"
    run compare "$WORK/d2.json" "$WORK/z" --baseline "$BASELINE"
    (( STATUS == 0 )) && [[ "$OUT" == *"ccit-ci-discard-sender: not deployed"* && "$OUT" == *"ccit-ci-custom-sender: not compared"* ]]
}

only_an_aws_https_url_is_downloaded() {
    local url
    build_all "$WORK/u"
    deploy_all "$WORK/u"
    for url in "https://example.com/code.zip" "https://amazonaws.com.example.com/code.zip" "http://lambda.us-east-1.amazonaws.com/x" \
        "ftp://lambda.amazonaws.com/x"; do
        relocate pre-sign-up "$url"
        run compare "$WORK/deployed.json" "$WORK/u" --baseline "$BASELINE"
        (( STATUS == 1 )) && [[ "$OUT" == *"! ccit-ci-pre-sign-up: the deployed code could not be read: its code location is not an https:// URL on an amazonaws.com host."* ]] \
            && [[ "$OUT" != *"$url"* ]] || { echo "$url: $OUT"; return 1; }
    done
    # file:// only for the self-tests.
    relocate pre-sign-up "file://$WORK/deployed/pre-sign-up.zip"
    STATUS=0
    OUT=$(env -u CCIT_CI_TEST_FILE_CODE_URLS python3 "$SCRIPT" compare "$WORK/deployed.json" "$WORK/u" --baseline "$BASELINE" 2>&1) \
        || STATUS=$?
    (( STATUS == 1 )) && [[ "$(grep -c 'could not be read' <<<"$OUT")" == 8 ]] || { echo "$OUT"; return 1; }
    # A download that is no zip, or none at all.
    echo 'not a zip' > "$WORK/deployed/pre-sign-up.zip"
    relocate discard-sender "file://$WORK/deployed/missing.zip"
    run compare "$WORK/deployed.json" "$WORK/u" --baseline "$BASELINE"
    (( STATUS == 1 )) && [[ "$OUT" == *"! ccit-ci-pre-sign-up: the deployed code could not be read: it is not a zip"* ]] \
        && [[ "$OUT" == *"! ccit-ci-discard-sender: the deployed code could not be read: its zip could not be downloaded"* ]] \
        && [[ "$OUT" != *missing.zip* ]] || { echo "$OUT"; return 1; }
    run record "$WORK/deployed.json" "$WORK/u" --baseline "$BASELINE" --accept-deployed
    (( STATUS == 1 )) && [[ "$OUT" == *"Nothing recorded: a deployed function's code could not be read."* && ! -e "$BASELINE" ]]
}

an_accepted_deployment_is_in_sync_until_its_sources_change() {
    build_all "$WORK/r"
    deploy_all "$WORK/r"
    redeploy pre-sign-up edited
    run compare "$WORK/deployed.json" "$WORK/r" --baseline "$BASELINE"
    (( STATUS == 1 )) || { echo "before the record: $OUT"; return 1; }
    run record "$WORK/deployed.json" "$WORK/r" --baseline "$BASELINE"
    (( STATUS == 1 )) && [[ "$OUT" == *"DRIFT ccit-ci-pre-sign-up"*"changed (1): triggers.mjs"*"Nothing recorded."* ]] \
        && [[ ! -e "$BASELINE" ]] || { echo "record without --accept-deployed: $OUT"; return 1; }
    run record "$WORK/deployed.json" "$WORK/r" --baseline "$BASELINE" --accept-deployed
    (( STATUS == 0 )) && jq -e '.functions | (keys | length == 8) and (.["pre-sign-up"].files | keys == ["notes.txt", "triggers.mjs"])
        and all(.[]; (.sources | test("^[0-9a-f]{64}$")) and (.files | all(.[]; test("^[0-9a-f]{64}$"))))' "$BASELINE" >/dev/null \
        || { echo "record: $OUT"; return 1; }
    run compare "$WORK/deployed.json" "$WORK/r" --baseline "$BASELINE"
    (( STATUS == 0 )) && [[ "$OUT" == *"= ccit-ci-pre-sign-up: the deployed files are the ones the baseline accepted"* ]] \
        && [[ "$(grep -c "the deployed files are this checkout's" <<<"$OUT")" == 7 ]] || { echo "after the record: $OUT"; return 1; }
    run check-baseline --baseline "$BASELINE"
    (( STATUS == 0 )) || { echo "check-baseline: $OUT"; return 1; }
    # triggers.mjs changes: the accepted deployment of pre-sign-up is no longer this checkout's.
    echo '// changed' >> "$COPY/lambda/triggers/triggers.mjs"
    run check-baseline --baseline "$BASELINE" --github
    (( STATUS == 1 )) && [[ "$OUT" == *"::error::CHANGED ccit-ci-pre-sign-up"* && "$OUT" != *discard-sender* ]] \
        && [[ "$OUT" == *"purpose=amplify-cognito-client-integ"* ]] || { echo "check-baseline after the change: $OUT"; return 1; }
    build_all "$WORK/r2"
    run compare "$WORK/deployed.json" "$WORK/r2" --baseline "$BASELINE"
    (( STATUS == 1 )) && [[ "$OUT" == *"DRIFT ccit-ci-pre-sign-up: its sources changed since the baseline accepted"* ]] \
        && [[ "$OUT" == *"= ccit-ci-discard-sender"* ]] || { echo "compare after the change: $OUT"; return 1; }
    cp "$INFRA/lambda/triggers/triggers.mjs" "$COPY/lambda/triggers/triggers.mjs"
}

no_baseline_is_its_own_status() {
    run check-baseline --baseline "$WORK/none.json" --github
    (( STATUS == 3 )) && [[ "$OUT" == "::warning::No CI Lambda deployment is recorded"* ]]
}

an_unexpected_error_is_status_4() {
    echo 'not json' > "$WORK/broken.json"
    run compare "$WORK/broken.json" "$WORK/z" --baseline "$BASELINE"
    (( STATUS == 4 )) && [[ "$OUT" == *Traceback* ]] || { echo "$STATUS $OUT"; return 1; }
    run nothing
    (( STATUS == 2 ))
}

the_committed_baseline_names_this_checkouts_sources() {
    [[ -f "$CI_DIR/lambda-baseline.json" ]] || { echo "  (no committed baseline yet)"; return 0; }
    STATUS=0
    OUT=$(env -u CCIT_CI_INFRA_DIR python3 "$SCRIPT" check-baseline 2>&1) || STATUS=$?
    (( STATUS == 0 )) || { echo "$OUT"; return 1; }
}

check "zips are deterministic and hold only the function's files" zips_are_deterministic_and_hold_only_the_functions_files
check "compare reads the deployed files: the same files in another zip are in sync, other files are DRIFT" \
    compare_reads_the_deployed_files
check "only an https:// URL on an amazonaws.com host is downloaded, and a download that is no zip is refused" \
    only_an_aws_https_url_is_downloaded
check "record writes the deployed files only with --accept-deployed; they are in sync until the sources change" \
    an_accepted_deployment_is_in_sync_until_its_sources_change
check "no baseline is status 3 with a warning" no_baseline_is_its_own_status
check "an unexpected error is status 4, never 1" an_unexpected_error_is_status_4
check "the committed baseline, when there is one, names this checkout's sources" \
    the_committed_baseline_names_this_checkouts_sources

if (( failures > 0 )); then
    echo "$failures failed"
    exit 1
fi
echo "All passed"
