#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Self-test for self-sign-up.sh, end to end through parity.py, over a fake `aws` on PATH that keeps each fake
# pool's tag, self sign-up flag and MFA configuration in a file. Like Cognito, the fake's UpdateUserPool resets
# the MFA configuration, so every toggle must restore it. No AWS call is made: the fake is checked to be the
# `aws` the scripts find before anything runs, COGNITO_CLIENT_INTEG_DIR points at a temporary directory with a
# fake state.json (placeholder ids only), and the AWS CLI's config and credential files are /dev/null.
#
#   bash infra/test_self_sign_up.sh
#
# It checks that the script refuses an untagged pool, CI and bad usage; that its trap turns self sign-up off
# after a passing command, a failing one, SIGINT, SIGTERM and SIGHUP, and after an `on` that fails part-way;
# that a Ctrl-C during a toggle loses no MFA configuration; that the trap still turns it off, with every MFA
# configuration, when stdout is a pipe whose reader has died or a terminal that has hung up; that a Ctrl-C while
# `on` waits for the lock stops it at once, with no change and no lease; that a release cut short says whether
# self sign-up is still on, and one STS refuses says so in one line, not a traceback; that two overlapping runs
# share self sign-up, whatever each one's locale and time zone; that `off` is idempotent, refuses while a run
# holds a lease, and skips an untagged pool; that a signal forwarded as the command starts stops it even when the
# first forward is lost, but a later one reaches a command that stops slowly exactly once; that a SIGINT parity.py
# holds while it changes the pools, or one the instant it exits, stops the run; and that a release and
# `off` turn every pool off with the WebAuthn harness's files deleted.
set -euo pipefail
INFRA="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$INFRA/self-sign-up.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
BIN="$WORK/bin"
mkdir -p "$BIN" "$WORK/state"
export FAKE_POOLS="$WORK/pools.json" FAKE_LOG="$WORK/calls.log" FAKE_MARK="$WORK/interrupted"
export COGNITO_CLIENT_INTEG_DIR="$WORK/state"
export AWS_CONFIG_FILE=/dev/null AWS_SHARED_CREDENTIALS_FILE=/dev/null
# No free-disk minimum: this test makes no real AWS call, so a nearly full disk must not fail it (test_free_disk.py
# covers the check).
export COGNITO_CLIENT_INTEG_MIN_FREE_GIB=0
unset AWS_PROFILE CI GITHUB_ACTIONS COGNITO_CLIENT_INTEG_SELF_SIGN_UP TEST_RUNNER_COGNITO_CLIENT_INTEG_SELF_SIGN_UP
unset FAKE_FAIL_ON FAKE_INTERRUPT FAKE_KILL_AT FAKE_FAIL_RELEASE
LEASES="$WORK/state/self-sign-up-leases.json"

cat > "$BIN/aws" <<'EOF'
#!/usr/bin/env python3
"""A fake AWS CLI: just the calls self-sign-up.sh and `parity.py self-sign-up` make, over $FAKE_POOLS."""
import fcntl, json, os, signal, subprocess, sys

args, options = [], {}
argv = sys.argv[1:]
i = 0
while i < len(argv):
    if argv[i].startswith("--"):
        options[argv[i]] = argv[i + 1] if i + 1 < len(argv) else ""
        i += 2
    else:
        args.append(argv[i])
        i += 1
lock = open(os.environ["FAKE_POOLS"] + ".lock", "w")
fcntl.flock(lock, fcntl.LOCK_EX)
sent = json.load(open(options["--cli-input-json"][7:])) if "--cli-input-json" in options else {}
with open(os.environ["FAKE_LOG"], "a") as log:
    flag = sent.get("AdminCreateUserConfig", {}).get("AllowAdminCreateUserOnly")
    log.write(" ".join(args + [options.get("--user-pool-id") or sent.get("UserPoolId", ""),
                               "" if flag is None else ("on" if flag is False else "off")]) + "\n")
pools = json.load(open(os.environ["FAKE_POOLS"]))


def save():
    # Atomically, as the test reads the file while runs are going.
    with open(os.environ["FAKE_POOLS"] + ".tmp", "w") as f:
        json.dump(pools, f)
    os.replace(os.environ["FAKE_POOLS"] + ".tmp", os.environ["FAKE_POOLS"])


def out(value):
    if options.get("--output") == "text" and "--query" in options:
        print(value)
    else:
        print(json.dumps(value))


def fail(code):
    sys.stderr.write(f"An error occurred ({code}) when calling the operation: placeholder\n")
    sys.exit(254)


def pool():
    found = pools.get(options.get("--user-pool-id") or sent.get("UserPoolId"))
    if found is None:
        fail("ResourceNotFoundException")
    return found


if args[:3] == ["configure", "get", "cli_history"]:
    sys.exit(1)
elif args == ["sts", "get-caller-identity"]:
    # FAKE_FAIL_RELEASE: refused for `parity.py self-sign-up release` only (expired credentials, say).
    if os.environ.get("FAKE_FAIL_RELEASE") and "self-sign-up release" in subprocess.run(
            ["ps", "-o", "args=", "-p", str(os.getppid())], capture_output=True, text=True).stdout:
        fail("ExpiredToken")
    out("000000000000" if "--query" in options else {"Account": "000000000000"})
elif args == ["cognito-idp", "describe-user-pool"]:
    p = pool()
    tags = dict(p["tags"], purpose="amplify-cognito-client-integ") if p["tagged"] else dict(p["tags"])
    if "--query" in options:
        out(tags.get("purpose", "None"))
    else:
        out({"UserPool": {"Name": p["name"], "UserPoolTags": tags, "MfaConfiguration": p["mfa"]["MfaConfiguration"],
                          "Policies": {"PasswordPolicy": {"MinimumLength": 10, "TemporaryPasswordValidityDays": 7}},
                          "AdminCreateUserConfig": {"AllowAdminCreateUserOnly": not p["on"],
                                                    "UnusedAccountValidityDays": 7}}})
elif args == ["cognito-idp", "get-user-pool-mfa-config"]:
    out(pool()["mfa"])
elif args == ["cognito-idp", "set-user-pool-mfa-config"]:
    p = pool()
    p["mfa"] = {k: v for k, v in sent.items() if k != "UserPoolId"}
    save()
    # A parity.py killed outright (kill -9) once the FAKE_KILL_AT-th MFA restore is done.
    if os.environ.get("FAKE_KILL_AT") and \
            sum(line.startswith("cognito-idp set-user-pool-mfa-config") for line in open(os.environ["FAKE_LOG"])) \
            == int(os.environ["FAKE_KILL_AT"]):
        os.kill(os.getppid(), signal.SIGKILL)
    out({})
elif args == ["cognito-idp", "update-user-pool"]:
    p = pool()
    turning_on = sent["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"] is False
    # As Cognito: UnusedAccountValidityDays is refused beside TemporaryPasswordValidityDays, and a field not
    # sent is reset (here: refused, so a partial update fails the test).
    if "UnusedAccountValidityDays" in sent["AdminCreateUserConfig"] or "Policies" not in sent:
        fail("InvalidParameterException")
    if turning_on and os.environ.get("FAKE_FAIL_ON") == sent["UserPoolId"]:
        fail("InternalErrorException")
    p["on"] = turning_on
    p["mfa"] = {"MfaConfiguration": "OFF"}
    save()
    if turning_on and os.environ.get("FAKE_INTERRUPT") and not os.path.exists(os.environ["FAKE_MARK"]):
        # Ctrl-C, between the update and the MFA restore: SIGINT to the whole process group.
        open(os.environ["FAKE_MARK"], "w").close()
        signal.signal(signal.SIGINT, signal.SIG_IGN)
        os.killpg(os.getpgrp(), signal.SIGINT)
    out({})
else:
    sys.stderr.write(f"fake aws: unexpected call {args}\n")
    sys.exit(2)
EOF
chmod +x "$BIN/aws"
export PATH="$BIN:$PATH"
[[ "$(command -v aws)" == "$BIN/aws" ]] || { echo "FAIL the fake aws is not first on PATH"; exit 1; }

read -ra KEYS <<< "$(python3 - "$INFRA/parity.py" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("parity", sys.argv[1])
parity = importlib.util.module_from_spec(spec)
spec.loader.exec_module(parity)
print(" ".join(parity.POOLS))
PY
)"
# The relying party provision resolves ${WEBAUTHN_RP_ID} to (the harness's committed webcredentials domain), as
# parity.py's MFA check expects it on the WebAuthn pool. Never printed.
RP_ID=$(python3 - "$INFRA/parity.py" <<'PY'
import importlib.util, sys
spec = importlib.util.spec_from_file_location("parity", sys.argv[1])
parity = importlib.util.module_from_spec(spec)
spec.loader.exec_module(parity)
print(parity.harness_rp_id() or "")
PY
)
[[ -n "$RP_ID" ]] || { echo "FAIL the WebAuthn harness's relying party cannot be resolved"; exit 1; }
python3 - "$WORK/state/state.json" "${KEYS[@]}" <<'PY'
import json, sys
path, keys = sys.argv[1], sys.argv[2:]
json.dump({"account": "000000000000", "region": "xx-test-1", "userPoolId": "placeholder-base",
           "parity": {"pools": {k: {"userPoolId": f"placeholder-{k}"} for k in keys}}}, open(path, "w"))
PY

# reset <on|off> [untagged key]: every fake pool tagged, in that state and with its template's MFA as provision
# applies it (${WEBAUTHN_RP_ID} resolved), except one untagged; no lease, an empty call log.
reset() {
    python3 - "$FAKE_POOLS" "$INFRA/pools" "$RP_ID" "$1" "${2:-}" "${KEYS[@]}" <<'PY'
import json, os, sys
path, templates, rp_id, state, untagged, keys = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6:]
def provisioned(k):
    return json.loads(open(os.path.join(templates, f"{k}.json")).read().replace("${WEBAUTHN_RP_ID}", rp_id))["mfa"]
json.dump({f"placeholder-{k}": {"name": f"amplify-cognito-client-integ-{k}", "tagged": k != untagged,
                                "tags": {"owner": "placeholder"}, "on": state == "on", "mfa": provisioned(k)}
           for k in keys}, open(path, "w"))
PY
    : > "$FAKE_LOG"
    rm -f "$LEASES" "$FAKE_MARK"
}
# all <on|off>: whether every fake pool is in that state.
all() {
    python3 -c "import json,sys;sys.exit(0 if all(p['on'] == (sys.argv[2] == 'on') for p in json.load(open(sys.argv[1])).values()) else 1)" \
        "$FAKE_POOLS" "$1"
}
# mfa_intact: whether every fake pool has its template's MFA configuration, as provision applies it. Names a pool
# that differs, never its configuration (the relying party is a real domain).
mfa_intact() {
    python3 - "$FAKE_POOLS" "$INFRA/pools" "$RP_ID" <<'PY'
import json, os, sys
pools = json.load(open(sys.argv[1]))
for pool_id, pool in pools.items():
    path = os.path.join(sys.argv[2], pool_id[len("placeholder-"):] + ".json")
    template = json.loads(open(path).read().replace("${WEBAUTHN_RP_ID}", sys.argv[3]))["mfa"]
    if pool["mfa"] != template:
        sys.exit(f"{pool_id}: MFA differs from its template's, keys {sorted(pool['mfa'])}")
PY
}
updates() { grep -c "update-user-pool" "$FAKE_LOG" || true; }
leases() { python3 -c "import json,sys;print(len(json.load(open(sys.argv[1]))))" "$LEASES" 2>/dev/null || echo 0; }
pass() { echo "ok $1"; }
fail() { echo "FAIL $1"; exit 1; }
POOL_COUNT=${#KEYS[@]}
# wait_until <command…>: until the command succeeds, for up to 60 s (generous, for a loaded machine).
wait_until() {
    local _
    for _ in $(seq 1 600); do
        if "$@"; then return 0; fi
        sleep 0.1
    done
    return 1
}
# run_in_background <log> <args…>: the script as its own process group (so a signal to the group reaches the
# script and its command, as Ctrl-C does, but not this test); sets PID.
run_in_background() {
    local log=$1
    shift
    set -m
    bash "$SCRIPT" "$@" >"$log" 2>&1 &
    PID=$!
    set +m
}
finish() {
    set +e
    wait "$1"
    STATUS=$?
    set -e
}

# --- refusals --------------------------------------------------------------------------------------------

reset off passwordless
if bash "$SCRIPT" on -- touch "$WORK/ran" >"$WORK/out" 2>&1; then fail "untagged pool: on succeeded"; fi
[[ ! -e "$WORK/ran" ]] || fail "untagged pool: the command ran"
[[ $(updates) == 0 ]] || fail "untagged pool: $(updates) updates"
grep -q "not tagged purpose=amplify-cognito-client-integ" "$WORK/out" || fail "untagged pool: no tag message"
all off || fail "untagged pool: a pool was turned on"
pass "refuses an untagged pool, before any change and without running the command"

for variable in CI GITHUB_ACTIONS; do
    for mode in "on -- touch $WORK/ran" "off"; do
        reset on
        # shellcheck disable=SC2086
        if env "$variable=true" bash "$SCRIPT" $mode >"$WORK/out" 2>&1; then fail "$variable: $mode succeeded"; fi
        [[ ! -s "$FAKE_LOG" ]] || fail "$variable: $mode made a call: $(cat "$FAKE_LOG")"
        [[ ! -e "$WORK/ran" ]] || fail "$variable: the command ran"
        grep -q "never on CI" "$WORK/out" || fail "$variable: no CI message"
    done
done
pass "refuses CI=… and GITHUB_ACTIONS=…, on and off, before any call"

reset off
if bash "$SCRIPT" on >/dev/null 2>&1; then fail "on without a command succeeded"; fi
if bash "$SCRIPT" on true >/dev/null 2>&1; then fail "on without -- succeeded"; fi
if bash "$SCRIPT" sideways >/dev/null 2>&1; then fail "an unknown mode succeeded"; fi
if bash "$SCRIPT" off --now >/dev/null 2>&1; then fail "off with an unknown flag succeeded"; fi
[[ ! -s "$FAKE_LOG" ]] || fail "usage errors made a call"
if COGNITO_CLIENT_INTEG_SELF_SIGN_UP=on bash "$SCRIPT" on -- true >/dev/null 2>&1; then fail "nested run succeeded"; fi
[[ $(updates) == 0 ]] || fail "nested run changed a pool"
if python3 "$INFRA/parity.py" self-sign-up on >"$WORK/out" 2>&1; then fail "parity.py on without the token succeeded"; fi
grep -q "only through infra/self-sign-up.sh" "$WORK/out" || fail "parity.py on: no token message"
[[ $(updates) == 0 ]] || fail "parity.py on without the token changed a pool"
pass "refuses a missing command, a missing --, an unknown mode or flag, a nested run, and parity.py on without the token"

# --- the trap ----------------------------------------------------------------------------------------------

reset off
bash "$SCRIPT" on -- bash -c '
    python3 -c "import json,sys;sys.exit(0 if all(p[\"on\"] for p in json.load(open(sys.argv[1])).values()) else 1)" "$FAKE_POOLS" || exit 11
    [[ "$COGNITO_CLIENT_INTEG_SELF_SIGN_UP" == on && "$TEST_RUNNER_COGNITO_CLIENT_INTEG_SELF_SIGN_UP" == on ]] || exit 12
' >"$WORK/out" 2>&1 || fail "passing command: exit $? ($(tail -3 "$WORK/out"))"
all off || fail "passing command: left on"
[[ $(updates) == $((POOL_COUNT * 2)) ]] || fail "passing command: $(updates) updates, not $((POOL_COUNT * 2))"
mfa_intact || fail "passing command: MFA lost"
[[ $(leases) == 0 ]] || fail "passing command: a lease is left"
pass "a passing command runs with every pool on and both variables set; afterwards every pool is off, with its MFA"

reset off
set +e
bash "$SCRIPT" on -- bash -c 'exit 7' >"$WORK/out" 2>&1
status=$?
set -e
[[ $status == 7 ]] || fail "failing command: exit $status, not 7"
all off || fail "failing command: left on"
mfa_intact || fail "failing command: MFA lost"
pass "a failing command's status is kept, and every pool is off afterwards"

for case in "INT 130 group" "TERM 143 script" "HUP 129 script"; do
    read -r signal_name expected target <<< "$case"
    reset off
    run_in_background "$WORK/out" on -- sleep 300
    wait_until all on || { kill -TERM -- "-$PID" 2>/dev/null || true; fail "$signal_name: never turned on"; }
    sleep 0.3
    started=$SECONDS
    if [[ $target == group ]]; then
        # As Ctrl-C does: the signal to the run's whole process group, the command included.
        kill -"$signal_name" -- "-$PID"
    else
        # To the script alone: it must forward the signal to the command at once.
        kill -"$signal_name" "$PID"
    fi
    finish "$PID"
    [[ $STATUS == "$expected" ]] || fail "$signal_name: exit $STATUS, not $expected ($(tail -3 "$WORK/out"))"
    # Well under the command's 300 s, with room for the release on a loaded machine.
    (( SECONDS - started < 150 )) || fail "$signal_name: the script waited for the command to end by itself"
    all off || fail "$signal_name: left on"
    mfa_intact || fail "$signal_name: MFA lost"
    pass "SIG$signal_name to the $target stops the command at once; every pool is off afterwards, exit $expected"
done

# A signal handled just before `child=$!` (the command runs, its PID is not yet known) and one handled just after
# (on_signal forwards it itself): each reaches the command, which ends at once, well before its 30 s. The script
# signals itself there through its test-only hook. A forward that reaches the command's process between its fork and
# its exec is lost, so the script sends one made then once more, half a second later: the script's `kill` is replaced
# by an exported function that logs each forward (one or two), then forwards it.
for point in before after; do
    reset off
    : >"$WORK/forwards"
    rm -f "$WORK/finished"
    set +e
    (
        # shellcheck disable=SC2329,SC2317 # invoked by the script, as its `kill`
        kill() {
            [[ "$1 ${2:-}" != "-TERM --" ]] || echo "${3:-}" >>"$WORK/forwards"
            builtin kill "$@"
        }
        export -f kill
        export WORK
        # shellcheck disable=SC2016 # expanded by sh, not here
        COGNITO_CLIENT_INTEG_SELF_SIGN_UP_TEST_SIGNAL=$point bash "$SCRIPT" on -- \
            sh -c 'sleep 30 && touch "$0"' "$WORK/finished" >"$WORK/out" 2>&1
    )
    status=$?
    set -e
    [[ $status == 143 ]] || fail "signal $point child=\$!: exit $status, not 143 ($(tail -3 "$WORK/out"))"
    # The command must have been stopped, not left to end by itself: it never finished. (Not timed: on a loaded
    # machine the toggles alone can take longer than the command's 30 s.)
    [[ ! -e "$WORK/finished" ]] || fail "signal $point child=\$!: the command ran to its end"
    forwards=$(grep -c . "$WORK/forwards" || true)
    (( forwards >= 1 && forwards <= 2 )) || fail "signal $point child=\$!: forwarded $forwards time(s)"
    all off || fail "signal $point child=\$!: left on"
done
pass "a signal just before or just after the command's PID is known stops the command at once"

# A command that handles SIGINT and takes time to stop, as xcodebuild does (its second SIGINT aborts it hard): a
# Ctrl-C after the command has started reaches it exactly once, however long it takes to stop.
reset off
rm -f "$WORK/ints" "$WORK/ready"
# shellcheck disable=SC2016 # Python, not shell
run_in_background "$WORK/out" on -- python3 -c '
import os, signal, sys, time
received, ready = sys.argv[1], sys.argv[2]
def record(number, frame):
    with open(received, "a") as f:
        f.write("INT\n")
signal.signal(signal.SIGINT, record)
open(ready, "w").close()
while not os.path.exists(received):
    time.sleep(0.05)
time.sleep(3)
sys.exit(130)' "$WORK/ints" "$WORK/ready"
ready() { [[ -e "$WORK/ready" ]]; }
wait_until ready || { kill -TERM -- "-$PID" 2>/dev/null || true; fail "slow stop: the command never started"; }
# Past the first second after the launch, when a forward can still be lost (and is sent once more).
sleep 1.5
kill -INT -- "-$PID"
finish "$PID"
[[ $STATUS == 130 ]] || fail "slow stop: exit $STATUS, not 130 ($(tail -3 "$WORK/out"))"
[[ $(grep -c INT "$WORK/ints") == 1 ]] || fail "slow stop: the command got $(grep -c INT "$WORK/ints") SIGINTs, not 1"
all off || fail "slow stop: left on"
pass "a Ctrl-C after the command started reaches a command that stops slowly exactly once"

# A Ctrl-C that reaches the run's process group the instant `parity.py self-sign-up on` has changed the pools, just
# before it exits: parity.py holds it, then exits 130, so the run stops there, even where bash itself would drop the
# signal. A `python3` shim first on PATH sends the SIGINT from inside parity.py, when self_sign_up returns.
REAL_PYTHON=$(command -v python3)
mkdir -p "$WORK/shim"
cat > "$WORK/shim/python3" <<SH
#!/usr/bin/env bash
if [[ "\${1:-}" == *parity.py && "\${2:-} \${3:-}" == "self-sign-up on" ]]; then
    exec "$REAL_PYTHON" -c '
import os, runpy, signal, sys
def hook(frame, event, arg):
    if event == "return" and frame.f_code.co_name == "self_sign_up":
        sys.setprofile(None)
        os.killpg(os.getpgrp(), signal.SIGINT)
sys.argv = sys.argv[1:]
sys.setprofile(hook)
runpy.run_path(sys.argv[0], run_name="__main__")
' "\$@"
fi
exec "$REAL_PYTHON" "\$@"
SH
chmod +x "$WORK/shim/python3"
reset off
rm -f "$WORK/ran"
set -m
PATH="$WORK/shim:$PATH" bash "$SCRIPT" on -- touch "$WORK/ran" >"$WORK/out" 2>&1 &
PID=$!
set +m
finish "$PID"
[[ $STATUS == 130 ]] || fail "SIGINT as on exits: exit $STATUS, not 130 ($(tail -3 "$WORK/out"))"
[[ ! -e "$WORK/ran" ]] || fail "SIGINT as on exits: the command ran"
grep -q "SIGINT arrived during self-sign-up on" "$WORK/out" || fail "SIGINT as on exits: parity.py did not hold it"
all off || fail "SIGINT as on exits: left on"
mfa_intact || fail "SIGINT as on exits: MFA lost"
[[ $(leases) == 0 ]] || fail "SIGINT as on exits: a lease is left"
pass "a SIGINT as parity.py's on finishes is held, not dropped: the command never runs, and the run ends 130"

# A Ctrl-C the instant `parity.py self-sign-up on` has exited, after it could hold it: the script waits for parity.py
# as a job, not in the foreground (where bash 3.2 can drop the signal), so its trap sees it and the run ends 130,
# never 0. The shim execs parity.py (it must stay the script's child) with one end of a pipe open; a watcher holding
# the other end sees end-of-file the instant parity.py exits, and sends SIGINT to the script's process group.
cat > "$WORK/shim/python3" <<SH
#!/usr/bin/env bash
if [[ "\${1:-}" == *parity.py && "\${2:-} \${3:-}" == "self-sign-up on" ]]; then
    group=\$(ps -o pgid= -p \$PPID | tr -d ' ')
    exec 9> >(trap '' INT; cat >/dev/null; kill -INT -- "-\$group")
    exec "$REAL_PYTHON" "\$@"
fi
exec "$REAL_PYTHON" "\$@"
SH
reset off
set -m
PATH="$WORK/shim:$PATH" bash "$SCRIPT" on -- true >"$WORK/out" 2>&1 &
PID=$!
set +m
finish "$PID"
[[ $STATUS == 130 ]] || fail "SIGINT after on exits: exit $STATUS, not 130 ($(tail -3 "$WORK/out"))"
all off || fail "SIGINT after on exits: left on"
[[ $(leases) == 0 ]] || fail "SIGINT after on exits: a lease is left"
pass "a SIGINT the instant parity.py's on has exited is not dropped: the run ends 130"

reset off
export FAKE_FAIL_ON=placeholder-passwordless
if bash "$SCRIPT" on -- touch "$WORK/ran" >"$WORK/out" 2>&1; then fail "part-way on: succeeded"; fi
unset FAKE_FAIL_ON
[[ ! -e "$WORK/ran" ]] || fail "part-way on: the command ran"
all off || fail "part-way on: left on"
mfa_intact || fail "part-way on: MFA lost"
python3 - "$FAKE_LOG" "${KEYS[@]}" <<'PY' || fail "part-way on: a pool after the failure was tried"
import sys
log, keys = sys.argv[1], sorted(sys.argv[2:])
tried_on = [line.split()[2] for line in open(log) if line.startswith("cognito-idp update-user-pool") and line.split()[-1] == "on"]
expected = [f"placeholder-{k}" for k in keys[:keys.index("passwordless") + 1]]
sys.exit(0 if tried_on == expected else f"{tried_on} != {expected}")
PY
pass "an on that fails part-way tries no later pool, runs no command, and the trap turns the earlier ones off"

reset off
export FAKE_INTERRUPT=1
run_in_background "$WORK/out" on -- touch "$WORK/ran"
finish "$PID"
unset FAKE_INTERRUPT
[[ -e "$FAKE_MARK" ]] || fail "interrupted toggle: the fake never interrupted"
[[ $STATUS == 130 ]] || fail "interrupted toggle: exit $STATUS, not 130 ($(tail -3 "$WORK/out"))"
[[ ! -e "$WORK/ran" ]] || fail "interrupted toggle: the command ran"
all off || fail "interrupted toggle: left on"
mfa_intact || fail "interrupted toggle: MFA lost"
pass "a Ctrl-C between a toggle's update and its MFA restore loses no MFA configuration, and runs no command"

# --- a dead stdout or terminal (B1) --------------------------------------------------------------------------

# Ctrl-C on `self-sign-up.sh on -- xcodebuild … | xcbeautify`: the pipe's reader dies, then the run gets INT. From
# then on every write to the script's stdout fails: SIGPIPE kills a process that has it at its default, as in a
# terminal, and a write fails with EPIPE where it is ignored (as some launchers leave it). Both, in turn; and with
# stderr in the pipe too (`2>&1 | xcbeautify`).
# with_sigpipe <default|ignored> <command…>: the command with SIGPIPE so (bash cannot reset an ignored signal).
with_sigpipe() {
    python3 -c 'import os, signal, sys
signal.signal(signal.SIGPIPE, signal.SIG_DFL if sys.argv[1] == "default" else signal.SIG_IGN)
os.execvp(sys.argv[2], sys.argv[2:])' "$@"
}
on_done() { [[ $(grep -c "^Self sign-up on on" "$WORK/piped") == "$POOL_COUNT" ]]; }
for case in "default stdout" "ignored stdout" "default both"; do
    read -r disposition piped <<< "$case"
    reset off
    rm -f "$WORK/fifo"
    mkfifo "$WORK/fifo"
    cat "$WORK/fifo" >"$WORK/piped" &
    reader=$!
    set -m
    if [[ $piped == both ]]; then
        with_sigpipe "$disposition" bash "$SCRIPT" on -- sleep 30 >"$WORK/fifo" 2>&1 &
    else
        with_sigpipe "$disposition" bash "$SCRIPT" on -- sleep 30 >"$WORK/fifo" 2>"$WORK/out" &
    fi
    PID=$!
    set +m
    wait_until on_done || { kill -TERM -- "-$PID" 2>/dev/null || true; fail "dead pipe ($case): never on"; }
    kill "$reader"
    wait "$reader" 2>/dev/null || true
    kill -INT -- "-$PID"
    finish "$PID"
    [[ $STATUS == 130 ]] || fail "dead pipe ($case): exit $STATUS, not 130 ($(tail -3 "$WORK/out"))"
    all off || fail "dead pipe ($case): left on"
    mfa_intact || fail "dead pipe ($case): MFA lost"
    [[ $(leases) == 0 ]] || fail "dead pipe ($case): a lease is left"
    if [[ $piped == stdout ]]; then
        grep -q "^Self sign-up off on" "$WORK/out" || fail "dead pipe ($case): the release's output is lost"
    fi
done
pass "a Ctrl-C after the reader of the script's output died: every pool is off afterwards, with its MFA, exit 130"

# A closed terminal: the script runs on a pty, whose master is closed, then SIGHUP. Its stdout and stderr are gone.
reset off
python3 - "$SCRIPT" "$POOL_COUNT" >"$WORK/out" 2>&1 <<'PY' || fail "hung-up tty: $(tail -3 "$WORK/out")"
import os, pty, select, signal, sys, time
script, pool_count = sys.argv[1], int(sys.argv[2])
pid, master = pty.fork()
if pid == 0:
    os.execvp("bash", ["bash", script, "on", "--", "sleep", "30"])
# Until `on` has turned every pool on and returned: the command is running.
output, deadline = b"", time.monotonic() + 60
while output.count(b"Self sign-up on on") < pool_count:
    if time.monotonic() > deadline:
        os.kill(pid, signal.SIGKILL)
        sys.exit("never turned on")
    if select.select([master], [], [], 0.1)[0]:
        output += os.read(master, 4096)
time.sleep(0.3)
os.close(master)
os.kill(pid, signal.SIGHUP)
deadline = time.monotonic() + 60
while True:
    done, status = os.waitpid(pid, os.WNOHANG)
    if done:
        break
    if time.monotonic() > deadline:
        os.kill(pid, signal.SIGKILL)
        sys.exit("the script did not end")
    time.sleep(0.1)
print(f"exit {os.waitstatus_to_exitcode(status)}")
PY
grep -q "^exit 129$" "$WORK/out" || fail "hung-up tty: $(tail -1 "$WORK/out"), not exit 129"
all off || fail "hung-up tty: left on"
mfa_intact || fail "hung-up tty: MFA lost"
[[ $(leases) == 0 ]] || fail "hung-up tty: a lease is left"
pass "SIGHUP after the script's terminal closed: every pool is off afterwards, with its MFA, exit 129"

# --- the lock and a release cut short ------------------------------------------------------------------------

# Another toggle, or a provision, holds the lock; Ctrl-C while `on` waits for it.
reset off
python3 -c 'import fcntl, os, sys, time
fd = os.open(sys.argv[1], os.O_RDWR | os.O_CREAT, 0o600)
fcntl.flock(fd, fcntl.LOCK_EX)
open(sys.argv[2], "w").close()
time.sleep(180)' "$WORK/state/self-sign-up.lock" "$WORK/held" &
holder=$!
held() { [[ -e "$WORK/held" ]]; }
wait_until held || fail "held lock: the holder never took it"
run_in_background "$WORK/out" on -- touch "$WORK/ran"
waiting() { grep -q "Waiting for another self sign-up change" "$WORK/out"; }
wait_until waiting || { kill "$holder"; fail "held lock: on never waited ($(tail -3 "$WORK/out"))"; }
started=$SECONDS
kill -INT -- "-$PID"
ended() { ! kill -0 "$PID" 2>/dev/null; }
if ! wait_until ended; then
    kill "$holder"
    finish "$PID"
    fail "held lock: the Ctrl-C did not stop on while it waited"
fi
finish "$PID"
kill "$holder"
wait "$holder" 2>/dev/null || true
rm -f "$WORK/held"
[[ $STATUS == 130 ]] || fail "held lock: exit $STATUS, not 130 ($(tail -3 "$WORK/out"))"
(( SECONDS - started < 30 )) || fail "held lock: the script took $((SECONDS - started)) s to end"
[[ ! -e "$WORK/ran" ]] || fail "held lock: the command ran"
[[ $(updates) == 0 ]] || fail "held lock: $(updates) updates"
[[ $(leases) == 0 ]] || fail "held lock: a lease is left"
pass "a Ctrl-C while on waits for the lock ends the run at once: no change, no lease, no command, exit 130"

# parity.py killed outright during the release: once after its first MFA restore (later pools are still on), once
# after its last (every pool is off, with its MFA). The script says which, and exits non-zero either way. A toggle
# restores the MFA of every pool whose template's is not plain OFF (the fake's update resets it to that); the last
# pool must be one of them, so that nothing is left to do after the last restore.
RESTORES=$(python3 - "$INFRA/pools" "${KEYS[@]}" <<'PY'
import json, os, sys
keys = sorted(sys.argv[2:])
restored = [k for k in keys if json.load(open(os.path.join(sys.argv[1], f"{k}.json")))["mfa"] != {"MfaConfiguration": "OFF"}]
assert restored and restored[-1] == keys[-1], "the last pool's MFA is plain OFF"
print(len(restored))
PY
)
for case in "1 on" "$RESTORES off"; do
    read -r into_release expected <<< "$case"
    reset off
    set +e
    FAKE_KILL_AT=$((RESTORES + into_release)) bash "$SCRIPT" on -- true >"$WORK/out" 2>&1
    status=$?
    set -e
    [[ $status != 0 ]] || fail "release cut short ($expected): exit 0"
    if [[ $expected == off ]]; then
        all off || fail "release cut short (off): left on"
        grep -q "every parity pool has self sign-up off" "$WORK/out" \
            || fail "release cut short (off): no all-off message ($(tail -3 "$WORK/out"))"
        if grep -q "may still be on\|still on" "$WORK/out"; then fail "release cut short (off): says it may be on"; fi
    else
        all off && fail "release cut short (on): every pool is off"
        grep -q "Self sign-up is still on" "$WORK/out" \
            || fail "release cut short (on): no still-on message ($(tail -3 "$WORK/out"))"
        grep -q "run infra/self-sign-up.sh off" "$WORK/out" || fail "release cut short (on): no remedy"
    fi
done
pass "a release cut short by kill -9 says whether self sign-up is still on, and exits non-zero"

# A release that fails while another run still holds a lease: self sign-up is on for that run, so the script says
# so rather than "run off", and the other run's end turns it off.
reset off
# shellcheck disable=SC2016 # expanded by the inner bash, not here
run_in_background "$WORK/outA" on -- bash -c 'until [[ -e "$0/endF" ]]; do sleep 0.1; done' "$WORK"
pid_f=$PID
held_by_one() { all on && [[ $(leases) == 1 ]]; }
wait_until held_by_one || fail "release under another run: the first run never turned on"
set +e
FAKE_FAIL_RELEASE=1 bash "$SCRIPT" on -- true >"$WORK/out" 2>&1
status=$?
set -e
[[ $status != 0 ]] || fail "release under another run: exit 0"
grep -q "on only for the other runs above" "$WORK/out" || fail "release under another run: $(tail -3 "$WORK/out")"
grep -q "PID $pid_f)" "$WORK/out" || fail "release under another run: the other run is not named"
all on || fail "release under another run: turned off under the other run"
touch "$WORK/endF"
finish "$pid_f"
[[ $STATUS == 0 ]] || fail "release under another run: the other run's exit $STATUS"
all off || fail "release under another run: left on after the other run"
pass "a release that fails while another run holds a lease says self sign-up is on for that run, not run off"

# STS refuses the release alone (expired credentials, say): parity.py says so in one line, not a traceback, and the
# script still reads the pools and says what is left, and exits non-zero.
reset off
set +e
FAKE_FAIL_RELEASE=1 bash "$SCRIPT" on -- true >"$WORK/out" 2>&1
status=$?
set -e
[[ $status != 0 ]] || fail "release refused by STS: exit 0"
if grep -q "Traceback" "$WORK/out"; then fail "release refused by STS: a traceback ($(tail -3 "$WORK/out"))"; fi
[[ $(grep -c "^Could not confirm the AWS account (STS refused): .*ExpiredToken" "$WORK/out") == 1 ]] \
    || fail "release refused by STS: not one account line ($(tail -3 "$WORK/out"))"
grep -q "Self sign-up is still on" "$WORK/out" || fail "release refused by STS: no still-on message"
grep -q "run infra/self-sign-up.sh off" "$WORK/out" || fail "release refused by STS: no remedy"
bash "$SCRIPT" off >/dev/null 2>&1 || fail "release refused by STS: the remedy failed"
all off || fail "release refused by STS: left on after off"
pass "a release refused by STS says so in one line, not a traceback, then what is left, and exits non-zero"

# --- two runs ------------------------------------------------------------------------------------------------

reset off
# A command that runs until <directory>/<name> exists, for runs whose end the test decides.
# shellcheck disable=SC2016 # expanded by the inner bash, not here
UNTIL='until [[ -e "$0/$1" ]]; do sleep 0.1; done'
run_in_background "$WORK/outA" on -- bash -c "$UNTIL" "$WORK" endA
pid_a=$PID
wait_until all on || fail "two runs: A never turned on"
run_in_background "$WORK/outB" on -- bash -c "$UNTIL" "$WORK" endB
pid_b=$PID
two_leases() { [[ $(leases) == 2 ]]; }
wait_until two_leases || fail "two runs: B never took its lease"
touch "$WORK/endB"
finish "$pid_b"
[[ $STATUS == 0 ]] || fail "two runs: B exit $STATUS"
all on || fail "two runs: B's end turned self sign-up off under A"
[[ $(leases) == 1 ]] || fail "two runs: $(leases) leases after B"
if bash "$SCRIPT" off >"$WORK/out" 2>&1; then fail "two runs: off succeeded while A holds a lease"; fi
grep -q "hold self sign-up on" "$WORK/out" || fail "two runs: no lease message from off"
all on || fail "two runs: refused off changed a pool"
touch "$WORK/endA"
finish "$pid_a"
[[ $STATUS == 0 ]] || fail "two runs: A exit $STATUS"
all off || fail "two runs: left on after both"
[[ $(leases) == 0 ]] || fail "two runs: a lease is left"
mfa_intact || fail "two runs: MFA lost"
pass "two overlapping runs: the first to end leaves it on, off refuses meanwhile, the last to end turns it off"

# A run whose lease was taken under one locale and time zone is live under any other: `ps` prints a start time in
# the caller's locale and zone ("Fri  2 Oct 05:54:37" under en_CA, "Fri Oct  2 …" under C).
reset off
set -m
env -u LC_ALL -u LC_TIME LANG=en_CA.UTF-8 TZ=America/Toronto bash "$SCRIPT" on -- bash -c "$UNTIL" "$WORK" endD \
    >"$WORK/outA" 2>&1 &
pid_d=$!
set +m
wait_until all on || fail "locale: never turned on"
one_lease() { [[ $(leases) == 1 ]]; }
wait_until one_lease || fail "locale: no lease"
if env LC_ALL=C TZ=Asia/Tokyo bash "$SCRIPT" off >"$WORK/out" 2>&1; then fail "locale: off succeeded under the run"; fi
grep -q "hold self sign-up on" "$WORK/out" || fail "locale: no lease message from off ($(tail -3 "$WORK/out"))"
all on || fail "locale: off turned self sign-up off under the run"
touch "$WORK/endD"
finish "$pid_d"
[[ $STATUS == 0 ]] || fail "locale: the run's exit $STATUS"
all off || fail "locale: left on after the run"
pass "a run's lease taken under LANG=en_CA and one time zone holds under LC_ALL=C and another: off refuses"

# --- the WebAuthn harness's files missing ----------------------------------------------------------------------

# A copy of infra/ in the repository's layout, with the WebAuthn harness's committed files beside it, so that they
# can really be deleted. `on` reads them (it compares the WebAuthn relying party), but a release and `off` must turn
# every pool off without them.
COPY="$WORK/repo"
IT="AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests"
HARNESS_FILES=("$IT/CognitoClientHostApp/CognitoClientWebAuthnApp.entitlements"
               "$IT/CognitoClientHostApp/CognitoClientHostApp.xcodeproj/project.pbxproj"
               "AmplifyPlugins/Auth/Tests/AuthWebAuthnApp/AuthWebAuthnApp/AuthWebAuthnApp.entitlements")
REPO="$(cd "$INFRA/../../../../.." && pwd)"
mkdir -p "$COPY/$IT"
cp -R "$INFRA" "$COPY/$IT/infra"
rm -rf "$COPY/$IT/infra/__pycache__"
copy_harness() {
    local file
    for file in "${HARNESS_FILES[@]}"; do
        mkdir -p "$(dirname "$COPY/$file")"
        cp "$REPO/$file" "$COPY/$file"
    done
}
remove_harness() {
    local file
    for file in "${HARNESS_FILES[@]}"; do rm -f "$COPY/$file"; done
}
export COPY
export HARNESS_FILES_LIST="${HARNESS_FILES[*]}"
COPIED="$COPY/$IT/infra/self-sign-up.sh"

copy_harness
reset off
# The command deletes the harness's files: the trap's release then runs without them.
# shellcheck disable=SC2016 # expanded by the inner bash, not here
bash "$COPIED" on -- bash -c 'for file in $HARNESS_FILES_LIST; do rm -f "$COPY/$file"; done' >"$WORK/out" 2>&1 \
    || fail "harness removed during the run: exit $? ($(tail -3 "$WORK/out"))"
[[ ! -e "$COPY/${HARNESS_FILES[0]}" ]] || fail "harness removed during the run: the files are still there"
if grep -q "Traceback" "$WORK/out"; then fail "harness removed during the run: a traceback"; fi
all off || fail "harness removed during the run: left on"
mfa_intact || fail "harness removed during the run: MFA lost"
[[ $(leases) == 0 ]] || fail "harness removed during the run: a lease is left"
pass "a release with the WebAuthn harness's files deleted still turns every pool off, with its MFA"

reset on
remove_harness
bash "$COPIED" off >"$WORK/out" 2>&1 || fail "off without the harness: exit $? ($(tail -3 "$WORK/out"))"
all off || fail "off without the harness: left on"
mfa_intact || fail "off without the harness: MFA lost"
pass "off with the WebAuthn harness's files missing turns every pool off, with its MFA"

reset off
if bash "$COPIED" on -- touch "$WORK/ran" >"$WORK/out" 2>&1; then fail "on without the harness: succeeded"; fi
[[ ! -e "$WORK/ran" ]] || fail "on without the harness: the command ran"
[[ $(updates) == 0 ]] || fail "on without the harness: $(updates) updates"
grep -q "webauthn: the relying party pools/webauthn.json names cannot be resolved" "$WORK/out" \
    || fail "on without the harness: no WEBAUTHN gap ($(tail -3 "$WORK/out"))"
if grep -q "Traceback" "$WORK/out"; then fail "on without the harness: a traceback"; fi
pass "on with the WebAuthn harness's files missing refuses before any change, naming them, without a traceback"

# --- off -----------------------------------------------------------------------------------------------------

reset on
bash "$SCRIPT" off >"$WORK/out" 2>&1 || fail "off: exit $?"
all off || fail "off: left on"
[[ $(updates) == "$POOL_COUNT" ]] || fail "off: $(updates) updates"
mfa_intact || fail "off: MFA lost"
: > "$FAKE_LOG"
bash "$SCRIPT" off >"$WORK/out" 2>&1 || fail "off again: exit $?"
[[ $(updates) == 0 ]] || fail "off again: $(updates) updates"
grep -q "already off" "$WORK/out" || fail "off again: no 'already off'"
pass "off turns every pool off, and a second off changes nothing"

reset off
run_in_background "$WORK/outA" on -- bash -c "$UNTIL" "$WORK" endC
pid_c=$PID
wait_until all on || fail "off --force: never turned on"
bash "$SCRIPT" off --force >"$WORK/out" 2>&1 || fail "off --force: exit $?"
all off || fail "off --force: left on"
[[ $(leases) == 0 ]] || fail "off --force: a lease is left"
touch "$WORK/endC"
finish "$pid_c"
[[ $STATUS == 0 ]] || fail "off --force: the run's exit $STATUS"
all off || fail "off --force: on again after the run"
pass "off --force turns it off under a live run, and that run's release then changes nothing"

reset on webauthn
if bash "$SCRIPT" off >"$WORK/out" 2>&1; then fail "off with an untagged pool succeeded"; fi
[[ $(updates) == $((POOL_COUNT - 1)) ]] || fail "off with an untagged pool: $(updates) updates"
python3 -c "import json,sys;sys.exit(0 if json.load(open(sys.argv[1]))['placeholder-webauthn']['on'] else 1)" "$FAKE_POOLS" \
    || fail "off changed the untagged pool"
pass "off turns off every tagged pool, never the untagged one, and exits non-zero"
