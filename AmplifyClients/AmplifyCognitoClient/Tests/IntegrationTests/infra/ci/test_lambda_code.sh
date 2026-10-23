#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Self-test for lambda_code.py, the CI Lambdas' code and drift check, over a copy of infra/'s Lambda sources in a
# temporary directory: no AWS call (the deployed CodeSha256s are written by the test), and the committed baseline is
# only read.
#
#   bash infra/ci/test_lambda_code.sh
#
# It checks that a zip is deterministic (the same bytes from another checkout time, files dated 1980, mode 644) and
# holds only the function's files; that the custom sender's holds node_modules but not npm's .package-lock.json;
# that compare finds a function deployed from this checkout in sync, flags one deployed from other code (DRIFT, by
# name, never a hash), and accepts one the baseline records for the same sources but flags it once they change;
# that record writes the baseline; that check-baseline is 0 with the recorded sources, 1 once one changed, 3 with
# no baseline; and that the committed baseline, when there is one, names this checkout's sources.
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
export CCIT_CI_INFRA_DIR="$COPY"
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

# deployed.json with every function's CodeSha256 the zips in $1 give, then $2 for function $3 if given.
deployed_from() {
    local suffix json="{}"
    for suffix in "${SUFFIXES[@]}"; do
        json=$(jq -c --arg k "$suffix" --arg v "$(sha "$1/$suffix.zip")" '.[$k] = $v' <<<"$json")
    done
    [[ -z "${3:-}" ]] || json=$(jq -c --arg k "$3" --arg v "$2" '.[$k] = $v' <<<"$json")
    printf '%s\n' "$json" > "$WORK/deployed.json"
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

compare_finds_drift_by_name() {
    build_all "$WORK/z"
    deployed_from "$WORK/z"
    run compare "$WORK/deployed.json" "$WORK/z" --baseline "$BASELINE"
    (( STATUS == 0 )) && [[ "$(grep -c "the deployed code is this checkout's" <<<"$OUT")" == 8 ]] || { echo "$OUT"; return 1; }
    deployed_from "$WORK/z" "c29tZXRoaW5nIGVsc2U=" pre-sign-up
    run compare "$WORK/deployed.json" "$WORK/z" --baseline "$BASELINE" --github
    (( STATUS == 1 )) && [[ "$OUT" == *"::error::DRIFT ccit-ci-pre-sign-up: the deployed code is neither"* ]] \
        && [[ "$(grep -c DRIFT <<<"$OUT")" == 1 && "$OUT" != *c29tZXRoaW5n* && "$OUT" != *"$(sha "$WORK/z/pre-sign-up.zip")"* ]] \
        || { echo "$OUT"; return 1; }
    # Not deployed, or no zip from this checkout: reported, not drift.
    jq -c '.["discard-sender"] = null' "$WORK/deployed.json" > "$WORK/d2.json"
    rm "$WORK/z/custom-sender.zip"
    run compare "$WORK/d2.json" "$WORK/z" --baseline "$BASELINE"
    [[ "$OUT" == *"ccit-ci-discard-sender: not deployed"* && "$OUT" == *"ccit-ci-custom-sender: not checked"* ]]
}

a_recorded_deployment_is_in_sync_until_its_sources_change() {
    build_all "$WORK/r"
    # Deployed before the zips were deterministic: none of the CodeSha256s is a zip's.
    jq -n -c '{"pre-sign-up": "b2xkLXByZS1zaWduLXVw", "discard-sender": "b2xkLWRpc2NhcmQ=", "custom-sender": null}' \
        > "$WORK/deployed.json"
    run compare "$WORK/deployed.json" "$WORK/r" --baseline "$BASELINE"
    (( STATUS == 1 )) || { echo "before the record: $OUT"; return 1; }
    run record "$WORK/deployed.json" --baseline "$BASELINE"
    (( STATUS == 0 )) && jq -e '.functions | keys == ["discard-sender", "pre-sign-up"]
        and all(.[]; (.codeSha256 | type) == "string" and (.sources | test("^[0-9a-f]{64}$")))' "$BASELINE" >/dev/null \
        || { echo "record: $OUT"; return 1; }
    run compare "$WORK/deployed.json" "$WORK/r" --baseline "$BASELINE"
    (( STATUS == 0 )) && [[ "$(grep -c "the recorded deployment of this checkout's sources" <<<"$OUT")" == 2 ]] \
        || { echo "after the record: $OUT"; return 1; }
    run check-baseline --baseline "$BASELINE"
    (( STATUS == 0 )) || { echo "check-baseline: $OUT"; return 1; }
    # triggers.mjs changes: the recorded deployment of pre-sign-up is no longer this checkout's.
    echo '// changed' >> "$COPY/lambda/triggers/triggers.mjs"
    run check-baseline --baseline "$BASELINE" --github
    (( STATUS == 1 )) && [[ "$OUT" == *"::error::CHANGED ccit-ci-pre-sign-up"* && "$OUT" != *discard-sender* ]] \
        || { echo "check-baseline after the change: $OUT"; return 1; }
    build_all "$WORK/r2"
    run compare "$WORK/deployed.json" "$WORK/r2" --baseline "$BASELINE"
    (( STATUS == 1 )) && [[ "$OUT" == *"DRIFT ccit-ci-pre-sign-up: its sources changed since the recorded deployment"* ]] \
        && [[ "$OUT" == *"= ccit-ci-discard-sender"* ]] || { echo "compare after the change: $OUT"; return 1; }
    cp "$INFRA/lambda/triggers/triggers.mjs" "$COPY/lambda/triggers/triggers.mjs"
}

no_baseline_is_its_own_status() {
    run check-baseline --baseline "$WORK/none.json" --github
    (( STATUS == 3 )) && [[ "$OUT" == "::warning::No CI Lambda deployment is recorded"* ]]
}

the_committed_baseline_names_this_checkouts_sources() {
    [[ -f "$CI_DIR/lambda-baseline.json" ]] || { echo "  (no committed baseline yet)"; return 0; }
    STATUS=0
    OUT=$(env -u CCIT_CI_INFRA_DIR python3 "$SCRIPT" check-baseline 2>&1) || STATUS=$?
    (( STATUS == 0 )) || { echo "$OUT"; return 1; }
}

check "zips are deterministic and hold only the function's files" zips_are_deterministic_and_hold_only_the_functions_files
check "compare finds a function deployed from other code, by name" compare_finds_drift_by_name
check "a recorded deployment is in sync until its sources change" a_recorded_deployment_is_in_sync_until_its_sources_change
check "no baseline is status 3 with a warning" no_baseline_is_its_own_status
check "the committed baseline, when there is one, names this checkout's sources" \
    the_committed_baseline_names_this_checkouts_sources

if (( failures > 0 )); then
    echo "$failures failed"
    exit 1
fi
echo "All passed"
