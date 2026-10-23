#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Self-test for code_sink_key.py, the CI code sink key's expiry reminder, over records in a temporary directory and a
# fixed "today": no AWS call, no credentials, and the committed record is only read.
#
#   bash infra/ci/test_code_sink_key.sh
#
# It checks that a key with more than 30 days left passes; that one within 30 days, on its last day, or expired
# fails, with a GitHub warning or error that says how to renew it; that no record, or one that does not read, is its
# own status (3) with a warning; that `record` writes the date of an expiry in epoch seconds; and that the committed
# record reads (a date, or null until the owner records it).
set -euo pipefail
CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$CI_DIR/code_sink_key.py"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
unset CCIT_CI_KEY_RECORD
RECORD="$WORK/record.json"

failures=0
check() {
    local name="$1"
    shift
    if "$@"; then echo "ok - $name"; else echo "FAIL - $name"; failures=$((failures + 1)); fi
}

# Runs code_sink_key.py; sets OUT and STATUS.
run() {
    STATUS=0
    OUT=$(python3 "$SCRIPT" "$@" 2>&1) || STATUS=$?
}

recorded() { printf '{"expires": "%s"}\n' "$1" > "$RECORD"; }

more_than_30_days_left_passes() {
    recorded 2027-10-22
    run check --today 2027-09-21 --record "$RECORD" --github
    (( STATUS == 0 )) && [[ "$OUT" == "The CI code sink's API key expires on 2027-10-22, in 31 days." ]]
}

within_30_days_fails_with_a_warning() {
    local today
    recorded 2027-10-22
    for today in 2027-09-22 2027-10-22; do
        run check --today "$today" --record "$RECORD" --github
        (( STATUS == 1 )) && [[ "$OUT" == "::warning::The CI code sink's API key expires on 2027-10-22, in "* ]] \
            && [[ "$OUT" == *"provision-ci.sh --apply --scope all"* ]] || { echo "$today: $OUT"; return 1; }
    done
    run check --today 2027-09-22 --record "$RECORD"
    (( STATUS == 1 )) && [[ "$OUT" == "The CI code sink's API key expires on 2027-10-22, in 30 days."* ]]
}

an_expired_key_fails_with_an_error() {
    recorded 2027-10-22
    run check --today 2027-10-23 --record "$RECORD" --github
    (( STATUS == 1 )) && [[ "$OUT" == "::error::The CI code sink's API key expired on 2027-10-22"* ]] \
        && [[ "$OUT" == *"replaced by hand"* ]]
}

no_record_is_its_own_status() {
    local content
    rm -f "$RECORD"
    run check --record "$RECORD" --github
    (( STATUS == 3 )) && [[ "$OUT" == "::warning::The CI code sink's API key has no recorded expiry"* ]] || return 1
    for content in '{"expires": null}' '{"expires": "soon"}' 'not json' '[]'; do
        printf '%s\n' "$content" > "$RECORD"
        run check --record "$RECORD"
        (( STATUS == 3 )) || { echo "$content: $STATUS $OUT"; return 1; }
    done
    CCIT_CI_KEY_RECORD="$WORK/missing.json" run check
    (( STATUS == 3 ))
}

record_writes_the_date() {
    rm -f "$RECORD"
    # 2027-10-22T12:00:00Z
    run record 1824206400 --record "$RECORD"
    (( STATUS == 0 )) && [[ "$OUT" == 2027-10-22 ]] && jq -e '. == {expires: "2027-10-22"}' "$RECORD" >/dev/null \
        && [[ ! -e "$RECORD.tmp" ]] || return 1
    run record soon --record "$RECORD"
    (( STATUS == 2 ))
}

the_committed_record_reads() {
    jq -e 'keys == ["expires"] and (.expires == null or (.expires | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")))' \
        "$CI_DIR/code-sink-key-expiry.json" >/dev/null
}

check "a key with more than 30 days left passes" more_than_30_days_left_passes
check "a key within its last 30 days fails, with a warning that says how to extend it" within_30_days_fails_with_a_warning
check "an expired key fails, with an error that says what to replace" an_expired_key_fails_with_an_error
check "no record, or one that does not read, is status 3 with a warning" no_record_is_its_own_status
check "record writes the expiry's date" record_writes_the_date
check "the committed record is a date, or null" the_committed_record_reads

if (( failures > 0 )); then
    echo "$failures failed"
    exit 1
fi
echo "All passed"
