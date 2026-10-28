#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Self-test for prepare-run.sh's create_user_unless_created: a user created, one an overlapping run created first
# (which must not stop the run), and any other error (which must); and for erin's reset (reset_erin_until_set): a
# password set on an erin another run has just deleted starts the reset again, up to ERIN_ATTEMPTS times, and any
# other error stops it at once; and for the report (report_user): erin missing while another run resets her is
# reported, but dave missing, or any other error for either user, stops it with the redacted error. A fake `aws` on
# PATH answers; no AWS call is made and prepare-run.sh itself never runs.
#
#   bash infra/test_prepare_run.sh
set -euo pipefail
P="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/prepare-run.sh"
BIN=$(mktemp -d)
trap 'rm -rf "$BIN"' EXIT
cat > "$BIN/aws" <<'EOF'
#!/usr/bin/env bash
case "$FAKE" in
  created) echo '{"User": {}}' ;;
  exists) echo "An error occurred (UsernameExistsException) when calling the AdminCreateUser operation: User account already exists" >&2; exit 254 ;;
  denied) echo "An error occurred (AccessDeniedException) when calling the AdminCreateUser operation: denied" >&2; exit 254 ;;
  status) echo "CONFIRMED" ;;
  missing) echo "An error occurred (UserNotFoundException) when calling the AdminGetUser operation: User does not exist." >&2; exit 254 ;;
  expired) echo "An error occurred (ExpiredTokenException) when calling the AdminGetUser operation: expired for xx-test-1_Placeholder1" >&2; exit 254 ;;
esac
EOF
chmod +x "$BIN/aws"
export PATH="$BIN:$PATH"
# shellcheck disable=SC2034  # read by the function under test
REGION=xx-test-1 USER_POOL_ID=placeholder-pool
redact() { cat; }
require_user_pool_tag() { :; }
eval "$(python3 - "$P" <<'PY'
import sys
s = open(sys.argv[1]).read()
for name in ("create_user_unless_created() {", "set_password_unless_gone() {", "reset_erin() {",
             "reset_erin_until_set() {", "report_user() {", "ERIN_ATTEMPTS="):
    start = s.index(name)
    print(s[start:s.index("\n", start) + 1] if name.endswith("=") else s[start:s.index("\n}\n", start) + 3])
PY
)"
export FAKE=created
[[ $(create_user_unless_created erin) == "Created user erin" ]] || { echo "FAIL created"; exit 1; }
echo "ok created"
export FAKE=exists
[[ $(create_user_unless_created erin) == "erin: already created by another run" ]] || { echo "FAIL exists"; exit 1; }
echo "ok created by another run first does not stop the run"
export FAKE=denied
if out=$( (create_user_unless_created erin) 2>&1 ); then
    echo "FAIL denied read as '$out'"
    exit 1
fi
[[ "$out" == *AccessDeniedException* ]] || { echo "FAIL denied: '$out'"; exit 1; }
echo "ok any other error stops"

# erin's reset, over stubs: she exists, the delete and create succeed, and set_user_password answers from SET_ANSWERS,
# one word a call (ok, gone or denied; the last word repeats).
export FAKE=created
user_exists() { return 0; }
sleep() { :; }
set_user_password() {
    local answer
    answer=$(head -n 1 "$SET_ANSWERS")
    [[ $(wc -l < "$SET_ANSWERS") -le 1 ]] || sed -i '' 1d "$SET_ANSWERS" 2>/dev/null || sed -i 1d "$SET_ANSWERS"
    echo "set" >> "$SET_CALLS"
    case "$answer" in
        ok) return 0 ;;
        gone) echo "An error occurred (UserNotFoundException) when calling the AdminSetUserPassword operation: User does not exist." >&2; return 254 ;;
        denied) echo "An error occurred (AccessDeniedException) when calling the AdminSetUserPassword operation: denied" >&2; return 254 ;;
    esac
}
SET_ANSWERS="$BIN/answers" SET_CALLS="$BIN/calls"
reset_case() { printf '%s\n' "$@" > "$SET_ANSWERS"; : > "$SET_CALLS"; }

reset_case gone gone ok
out=$(reset_erin_until_set 2>&1) || { echo "FAIL erin deleted twice: '$out'"; exit 1; }
[[ $(grep -c . "$SET_CALLS") == 3 && $(grep -c "resetting her again" <<<"$out") == 2 ]] \
    || { echo "FAIL erin deleted twice: $(grep -c . "$SET_CALLS") sets: '$out'"; exit 1; }
echo "ok erin deleted by another run before her password was set is reset again, until it is set"

reset_case gone
if out=$( (reset_erin_until_set) 2>&1 ); then echo "FAIL erin always deleted: succeeded"; exit 1; fi
[[ $(grep -c . "$SET_CALLS") == "$ERIN_ATTEMPTS" && "$out" == *"each of $ERIN_ATTEMPTS times"* ]] \
    || { echo "FAIL erin always deleted: $(grep -c . "$SET_CALLS") sets: '$out'"; exit 1; }
echo "ok erin deleted every time stops after ERIN_ATTEMPTS ($ERIN_ATTEMPTS) resets"

reset_case denied
if out=$( (reset_erin_until_set) 2>&1 ); then echo "FAIL erin's password denied: succeeded"; exit 1; fi
[[ $(grep -c . "$SET_CALLS") == 1 && "$out" == *AccessDeniedException* ]] \
    || { echo "FAIL erin's password denied: $(grep -c . "$SET_CALLS") sets: '$out'"; exit 1; }
echo "ok any other error setting erin's password stops at once"

# The report, with lib.sh's own redact.
eval "$(python3 - "$(dirname "$P")/lib.sh" <<'PY'
import sys
s = open(sys.argv[1]).read()
start = s.index("redact() {")
print(s[start:s.index("\n}\n", start) + 3])
PY
)"
export FAKE=status
[[ $(report_user dave) == "dave: CONFIRMED" ]] || { echo "FAIL report status"; exit 1; }
echo "ok a user's status is reported"
export FAKE=missing
[[ $(report_user erin) == "erin: not found (another run is resetting her)" ]] || { echo "FAIL erin missing"; exit 1; }
echo "ok erin missing while another run resets her is reported, not fatal"
if out=$( (report_user dave) 2>&1 ); then echo "FAIL dave missing read as '$out'"; exit 1; fi
[[ "$out" == *UserNotFoundException* && "$out" != *"another run"* ]] || { echo "FAIL dave missing: '$out'"; exit 1; }
echo "ok dave missing stops with the error"
export FAKE=expired
for user in dave erin; do
    if out=$( (report_user "$user") 2>&1 ); then echo "FAIL $user expired read as '$out'"; exit 1; fi
    [[ "$out" == *ExpiredTokenException*"<user-pool>"* && "$out" != *Placeholder1* && "$out" != *"another run"* ]] \
        || { echo "FAIL $user expired: '$out'"; exit 1; }
done
echo "ok any other error, for either user, stops with the redacted error"
