#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Self sign-up on the sandbox's parity pools, for the length of one local run. It is off at rest:
# provision.sh creates and updates the pools with it off, and preflight (prepare-run.sh) treats off as normal.
#
#   on -- <command…>  takes a lease for this run and turns self sign-up on for every recorded parity pool, runs
#                     the command with COGNITO_CLIENT_INTEG_SELF_SIGN_UP=on (and
#                     TEST_RUNNER_COGNITO_CLIENT_INTEG_SELF_SIGN_UP=on, which xcodebuild passes to the test
#                     runner), then releases the lease through a trap on EXIT, INT, TERM and HUP, however the
#                     command ends. Self sign-up is turned off when no other run's lease remains. INT, TERM and
#                     HUP are forwarded to the command (once; once more only if it came as the command was being
#                     started, when a forward can be lost), and one that arrives while parity.py changes the pools
#                     stops the run once the change is done. It exits with the command's status, or 128 + the signal.
#                     The release needs neither stdout nor stderr: piping the output (`| xcbeautify`) is fine, and
#                     so is a terminal that closes.
#   off [--force]     turns it off. For recovery, after a run that could not release (a kill -9). It refuses while
#                     a live run holds a lease, unless --force.
#
# Rules:
#   - It refuses to run on CI (CI or GITHUB_ACTIONS set): CI's backends are the plugin's, never this sandbox.
#   - `on` refuses, before any call, with under 2 GiB free on the volume holding the state directory
#     (COGNITO_CLIENT_INTEG_MIN_FREE_GIB sets another minimum, 0 none). `off` does not check it.
#   - `on` refuses, before any change, unless every recorded parity pool carries purpose=amplify-cognito-client-integ.
#     parity.py checks the tag again before each change, and `off` skips (and reports) any pool without it.
#   - The flag changes only through `parity.py self-sign-up on|release|off`, under a lock, which sends each pool's
#     full configuration back with only self sign-up changed (UpdateUserPool resets any field it is not sent). It
#     holds Ctrl-C off once it holds the lock, so a toggle is never cut half-way, and exits 128 + the signal once
#     the change is done; this script acts on the signal after it. A Ctrl-C while `on` still waits for the lock
#     stops it at once, with nothing changed.
#   - Overlapping runs share self sign-up: each holds a lease, and the last to end turns it off. provision.sh
#     refuses while a lease is held.
#
# Usage:
#   AWS_PROFILE=<sandbox-profile> infra/self-sign-up.sh on -- <command> [arguments…]
#   AWS_PROFILE=<sandbox-profile> infra/self-sign-up.sh off [--force]
# Environment for the command goes after `--`, for example
#   infra/self-sign-up.sh on -- env COGNITO_CLIENT_INTEG_DIR="$DIR" xcodebuild test …
set -euo pipefail

INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$INFRA_DIR/lib.sh"

RUN_VARIABLE="COGNITO_CLIENT_INTEG_SELF_SIGN_UP"

usage() {
    echo "Usage: $0 on -- <command> [arguments…]" >&2
    echo "       $0 off [--force]" >&2
    exit 64
}

refuse_on_ci() {
    local name
    for name in CI GITHUB_ACTIONS; do
        if [[ -n "${!name:-}" ]]; then
            echo "Refusing: $name is set. Self sign-up is changed only for a local run against the sandbox," \
                "never on CI." >&2
            exit 1
        fi
    done
}

# parity.py's `on` and `release` need this script's token: its PID, as the parent of the python process.
SELF_SIGN_UP_WRAPPER_VARIABLE="COGNITO_CLIENT_INTEG_SELF_SIGN_UP_WRAPPER"
parity() {
    env "$SELF_SIGN_UP_WRAPPER_VARIABLE=$$" python3 "$INFRA_DIR/parity.py" "$@"
}

refuse_on_ci
[[ $# -ge 1 ]] || usage

case "$1" in
    off)
        [[ $# -eq 1 || ( $# -eq 2 && "$2" == "--force" ) ]] || usage
        parity self-sign-up "$@"
        exit 0
        ;;
    on)
        shift
        [[ "${1:-}" == "--" ]] || usage
        shift
        [[ $# -ge 1 ]] || usage
        ;;
    *)
        usage
        ;;
esac

if [[ "${!RUN_VARIABLE:-}" == "on" ]]; then
    echo "Refusing: already inside a self-sign-up.sh run; its trap releases self sign-up when it ends." >&2
    exit 1
fi

# Before any change: free disk for the AWS CLI (COGNITO_CLIENT_INTEG_MIN_FREE_GIB, lib.sh; `off`, the recovery, does
# not check it), the caller's account, CLI history, and every recorded parity pool's tag.
require_free_disk
STATE="$STATE_DIR/state.json"
[[ -f "$STATE" ]] || { echo "No $STATE; run infra/provision.sh first." >&2; exit 1; }
REGION=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['region'])" "$STATE")
aws() { command aws --region "$REGION" --output json "$@" 2> >(redact >&2); }
require_cli_history_off
require_recorded_account
POOL_IDS=$(python3 - "$STATE" <<'PY'
import json, sys
pools = json.load(open(sys.argv[1])).get("parity", {}).get("pools", {})
for key in sorted(pools):
    if pools[key].get("userPoolId"):
        print(pools[key]["userPoolId"])
PY
)
[[ -n "$POOL_IDS" ]] || { echo "No parity pool is recorded in $STATE; run infra/provision.sh first." >&2; exit 1; }
while read -r pool_id; do
    require_user_pool_tag "$pool_id"
done <<< "$POOL_IDS"

child=""
signalled=""
pending=""
resend=""
young=""

# INT, TERM and HUP: remembered for the exit status, and forwarded to the process group of the job that runs (first
# `parity.py self-sign-up on`, then the command; see launch). One that arrives before the job's PID is known is kept
# in `pending`, and forwarded once the PID is known.
# A forward can be lost: one that reaches the job's process after its fork but before its exec is dropped there. So a
# forward made while the job may not have exec'd yet (from `pending`, or in its first second, while the `young` timer
# runs) is sent once more, half a second later (wait_for_job). A later forward never is: a command that handles the
# signal and takes time to stop (xcodebuild, whose second SIGINT aborts it hard) gets exactly one.
# shellcheck disable=SC2329 # invoked by the INT, TERM and HUP traps
on_signal() {
    signalled=$2
    if [[ -n "$child" ]]; then
        kill -"$1" -- "-$child" 2>/dev/null || true
        if [[ -z "$young" ]] || kill -0 "$young" 2>/dev/null; then
            resend=$1
        fi
    else
        pending=$1
    fi
}

# One line on stderr, never failing. In the trap, stdout may be a pipe whose reader has died (a Ctrl-C on
# `self-sign-up.sh on -- … | xcbeautify` stops the reader too), and stdout and stderr a terminal that has hung up;
# under `set -e`, a failed echo would end the trap before the release.
# shellcheck disable=SC2329 # invoked by release
note() {
    echo "$@" >&2 2>/dev/null || true
}

# From here on, however the script ends, the run's lease is released, and self sign-up is turned off unless
# another run still holds it. Set before `on`, which records the lease before any change, so that an `on` that
# fails part-way is undone too. While it releases, INT, TERM and HUP are ignored, and so is SIGPIPE; parity.py, which
# starts with them ignored, keeps them ignored, so a signal cannot change its status. Nothing in it writes to stdout:
# parity.py writes to a log in $STATE_DIR, copied to stderr once it has finished, so that no dead stdout or stderr can
# reach it.
# shellcheck disable=SC2329 # invoked by the EXIT trap
release() {
    local status=$? log report checked kept=""
    trap '' INT TERM HUP PIPE
    trap - EXIT
    if [[ -n "$child" ]] && kill -0 "$child" 2>/dev/null; then
        kill -TERM -- "-$child" 2>/dev/null || true
        wait "$child" 2>/dev/null || true
    fi
    note "Releasing self sign-up for this run (off once no other run holds it)"
    log="$STATE_DIR/self-sign-up-release.$$.log"
    (umask 077 && : >"$log") 2>/dev/null || log=/dev/null
    if parity self-sign-up release </dev/null >>"$log" 2>&1; then
        cat "$log" >&2 2>/dev/null || true
        [[ "$log" == /dev/null ]] || rm -f "$log" 2>/dev/null || true
    else
        cat "$log" >&2 2>/dev/null || true
        # The release did not finish (parity.py was killed, say): read the pools again, and say what it left.
        if report=$(parity self-sign-up status </dev/null 2>&1); then checked=0; else checked=$?; fi
        printf '%s\n' "$report" >>"$log" 2>/dev/null || true
        note "$report"
        [[ "$log" == /dev/null ]] || kept=" Its output is in $log."
        case $checked in
            0) note "The release did not finish, but every parity pool has self sign-up off and its MFA as" \
                "provisioned: nothing is left to do.$kept" ;;
            3) note "The release did not finish, and the pools above are not at rest: run infra/self-sign-up.sh" \
                "off, and infra/provision.sh for an MFA configuration that differs.$kept" ;;
            4) note "The release did not finish, but self sign-up is on only for the other runs above, which" \
                "still hold it: the last of them to end turns it off. Use off --force only if one is stuck.$kept" ;;
            *) note "The release did not finish, and the pools could not be read, so self sign-up may still be" \
                "on: run infra/self-sign-up.sh off.$kept" ;;
        esac
        [[ $status -ne 0 ]] || status=1
    fi
    exit "$status"
}
trap release EXIT
trap 'on_signal INT 130' INT
trap 'on_signal TERM 143' TERM
trap 'on_signal HUP 129' HUP

# launch <hook> <command…>: runs the command in the background, as a job of its own (job control on just for the
# launch), so that it starts with INT and QUIT at their defaults rather than ignored, in its own process group, and a
# signal reaches this script's traps at once rather than when the job ends (Ctrl-C reaches this script, which forwards
# it to the job's whole group). The job cannot read the terminal. Sets `child`, and starts the `young` timer: one
# second, in a process group of its own, so that Ctrl-C does not end it early.
# <hook> "command" arms COGNITO_CLIENT_INTEG_SELF_SIGN_UP_TEST_SIGNAL, a test-only hook, inert unless set:
# test_self_sign_up.sh sets it to "before" or "after" to pin the forwarding, and the script then sends itself SIGTERM
# just before or just after the command's `child=$!`. Unset, or any other value, it does nothing. Never set it outside
# that test.
launch() {
    local hook=$1
    shift
    young=""
    set -m
    "$@" &
    signal_self_at "$hook" before
    child=$!
    signal_self_at "$hook" after
    sleep 1 >/dev/null 2>&1 &
    young=$!
    set +m
    # A signal handled before `child=$!` was not forwarded: forward it now (and once more, as the job is young).
    if [[ -n "$pending" ]]; then
        kill -"$pending" -- "-$child" 2>/dev/null || true
        resend=$pending
        pending=""
    fi
}

signal_self_at() {
    [[ "$1" == command && "${COGNITO_CLIENT_INTEG_SELF_SIGN_UP_TEST_SIGNAL:-}" == "$2" ]] || return 0
    kill -TERM $$
}

# wait_for_job: waits until the job `launch` started has ended, and sets `status` to its exit status. A trapped
# signal ends `wait` early (status > 128) while the job still runs: it waits again, after the one re-send a young
# forward is owed.
wait_for_job() {
    local signal_name
    while :; do
        if [[ -n "$resend" ]]; then
            signal_name=$resend
            resend=""
            sleep 0.5
            if kill -0 "$child" 2>/dev/null; then
                kill -"$signal_name" -- "-$child" 2>/dev/null || true
            fi
        fi
        wait "$child"
        status=$?
        kill -0 "$child" 2>/dev/null || break
    done
    child=""
    kill -TERM "$young" 2>/dev/null || true
}

set +e

# `parity.py self-sign-up on` runs as a job too, not in the foreground: bash 3.2 can drop a SIGINT that reaches it
# just as its foreground command exits, while `wait` always lets the trap see it. parity.py must be this script's
# child (its token), so it is launched as one simple command. It holds INT, TERM and HUP while it changes the pools,
# then exits 128 + the first it held: that ends the run as the signal itself would.
launch parity env "$SELF_SIGN_UP_WRAPPER_VARIABLE=$$" python3 "$INFRA_DIR/parity.py" self-sign-up on
wait_for_job
case $status in
    0) ;;
    129 | 130 | 143) signalled=${signalled:-$status} ;;
    *) exit "$status" ;;
esac
[[ -z "$signalled" ]] || exit "$signalled"

launch command env "$RUN_VARIABLE=on" "TEST_RUNNER_$RUN_VARIABLE=on" "$@"
wait_for_job
set -e
exit "${signalled:-$status}"
