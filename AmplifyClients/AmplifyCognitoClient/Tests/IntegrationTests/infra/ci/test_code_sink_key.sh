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
# fails, with a GitHub warning or error that says how to renew it (extended in place before the expiry; after it, a
# new key, recorded only once the uploaded files that name the old one are replaced; on the expiry date, both); that
# the window's edges (32, 31, 30, 1, 0 and -1 days left) are where provision-ci.sh's reuse threshold, `reuse-days`,
# makes a rerun extend every key it warns about; that no record, or one that does
# not read, is its own status (3) with a warning; that an unexpected error is 4, never 1; that `record` writes the
# date of an expiry in epoch seconds; and that the committed record reads (a date, or null until the owner records
# it).
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
    for today in 2027-09-22 2027-10-21; do
        run check --today "$today" --record "$RECORD" --github
        (( STATUS == 1 )) && [[ "$OUT" == "::warning::The CI code sink's API key expires on 2027-10-22, in "* ]] \
            && [[ "$OUT" == *"provision-ci.sh --apply --scope all"* ]] || { echo "$today: $OUT"; return 1; }
    done
    run check --today 2027-09-22 --record "$RECORD"
    (( STATUS == 1 )) && [[ "$OUT" == "The CI code sink's API key expires on 2027-10-22, in 30 days."* ]]
}

# The expired message is self-consistent: no extending (an expired key cannot be), a new key, and the uploaded files
# that name the old one deleted, after their tag check, and uploaded again before the new expiry is recorded.
an_expired_key_fails_with_an_error() {
    recorded 2027-10-22
    run check --today 2027-10-23 --record "$RECORD" --github
    (( STATUS == 1 )) && [[ "$OUT" == "::error::The CI code sink's API key expired on 2027-10-22"* ]] \
        && [[ "$OUT" == *"An expired key cannot be extended."*"makes a new one"* ]] \
        && [[ "$OUT" == *"ccit-ci-default-amplify_outputs.json and ccit-ci-email-alias-codes-amplify_outputs.json"* ]] \
        && [[ "$OUT" == *"carries purpose=amplify-cognito-client-integ, delete both by hand"*"--upload"* ]] \
        && [[ "$OUT" != *"extends it"* && "$OUT" != *"in place"* ]]
}

# Within the 30 days, the message says the rerun extends the same key, and never that the files need replacing.
a_key_within_its_last_days_is_extended_in_place() {
    recorded 2027-10-22
    run check --today 2027-10-01 --record "$RECORD"
    (( STATUS == 1 )) && [[ "$OUT" == *"extends it in place to 364 days from then (the same key"* ]] \
        && [[ "$OUT" != *"delete"* && "$OUT" != *"cannot be extended"* ]]
}

# The edges of the window, by days left: 32 and 31 pass, 30 to 1 warn and say to extend, 0 (the expiry date, whose
# hour the record does not hold) is an error that gives both the extension and the replacement, and -1 the
# replacement only. reuse-days is one more than the 30: a key the check gives 30 days can live up to a second short
# of 31 days from now, so provision-ci.sh, which reuses only a key that lives more than reuse-days, extends it.
the_window_edges_match_the_reuse_threshold() {
    local today expected
    recorded 2027-10-22
    for today in 2027-09-20:0:none 2027-09-21:0:none 2027-09-22:1:warning 2027-10-21:1:warning 2027-10-22:1:both \
        2027-10-23:1:replace; do
        expected="${today#*:}"
        run check --today "${today%%:*}" --record "$RECORD" --github
        (( STATUS == ${expected%%:*} )) || { echo "$today: $STATUS $OUT"; return 1; }
        case "${expected#*:}" in
            none) [[ "$OUT" == "The CI code sink's API key expires on 2027-10-22, in 3"[12]" days." ]] ;;
            warning) [[ "$OUT" == "::warning::"*"extends it in place"* && "$OUT" != *"cannot be extended"* ]] ;;
            both) [[ "$OUT" == "::error::The CI code sink's API key expires today, 2027-10-22"*"If it has not expired yet, rerun"*"extends it in place"*"If it has,"*"An expired key cannot be extended."*"--upload"* ]] ;;
            replace) [[ "$OUT" == "::error::"*"An expired key cannot be extended."* && "$OUT" != *"extends it"* ]] ;;
        esac || { echo "$today: $OUT"; return 1; }
    done
    run reuse-days
    (( STATUS == 0 )) && [[ "$OUT" == 31 ]]
}

# A failure of the script itself is status 4 (its traceback printed), never 1, which the reminder reads as "renew".
an_unexpected_error_is_status_4() {
    recorded 2027-10-22
    run check --today not-a-date --record "$RECORD"
    (( STATUS == 4 )) && [[ "$OUT" == *Traceback* ]]
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
check "a key within its last 30 days is to be extended in place, the same key" a_key_within_its_last_days_is_extended_in_place
check "the window's edges (32, 31, 30, 1, 0, -1 days) match provision-ci.sh's reuse threshold" \
    the_window_edges_match_the_reuse_threshold
check "an unexpected error is status 4, never 1" an_unexpected_error_is_status_4
check "no record, or one that does not read, is status 3 with a warning" no_record_is_its_own_status
check "record writes the expiry's date" record_writes_the_date
check "the committed record is a date, or null" the_committed_record_reads

if (( failures > 0 )); then
    echo "$failures failed"
    exit 1
fi
echo "All passed"
