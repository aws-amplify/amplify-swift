#!/usr/bin/env bash
#
# Resets the per-run test users. Run it before every run of the integration tests, including before
# an `xcodebuild test-without-building` re-run. Idempotent.
#
#   dave  (P-3)  set to FORCE_CHANGE_PASSWORD with the stored temporary password (daveTemporary).
#                The challenge test changes it to daveNew, so it must be reset each time.
#   erin  (P-4)  deleted if present, then created again with the stored permanent password. The
#                delete-user test deletes her.
#   P-12         in the parity pools only, users the tests created (usernames, or on the email-alias
#                pool emails, starting ccit- or confirm-) more than 24 hours ago are deleted, so the
#                pools stay small. The code sink's table expires codes by itself (TTL).
#   P-14         after P-12: the plugin's DeviceAliasTokenRefreshIntegrationTests user on email-alias,
#                created when missing, its password reset to users.json pluginDeviceAliasPassword.
#   plugin configs  last: plugin-configs.py --refresh, so the plugin suites' files follow a rotated
#                code sink key (only if plugin-configs.py has written them).
#   preflight    after the dave and erin reset, before P-12 (parity pools only), read-only: refuses the
#                rest of the run if any parity pool could deliver a real email or SMS (DEVELOPER email
#                or SMS configured without the custom sender and the KMS key), the SES identity or SNS
#                sandbox changed, a pool-scoped policy is still open to any pool, or a parity pool is
#                missing (MISSING), has self sign-up on outside an infra/self-sign-up.sh run (LEFT-ON), or
#                on against its template or unstated (DRIFT). Self sign-up off is the resting state.
#
# It never touches alice, bob or carol, and it refuses to run unless the user pool recorded in
# $STATE_DIR/state.json carries purpose=amplify-cognito-client-integ (checked before every mutating
# call). Passwords come from $STATE_DIR/users.json, which provision.sh writes; they stay stable, so
# nothing needs rebuilding (users.json is copied into the test bundle at build time). No secret is
# printed or passed to the AWS CLI as an argument. It refuses to start with under 2 GiB free on the volume holding
# $STATE_DIR (COGNITO_CLIENT_INTEG_MIN_FREE_GIB sets another minimum, 0 none).
#
# Overlapping runs (two runners, or a run beside DU-1) are tolerated: a user another run created or deleted first, a
# password set on erin after another run deleted her (the reset is tried again, a few times), and plugin-configs.py
# --refresh, which waits for the other run's.
#
# Usage: AWS_PROFILE=<sandbox-profile> ./prepare-run.sh
set -euo pipefail

INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$INFRA_DIR/lib.sh"
# Before any AWS call: enough free disk for the CLI (COGNITO_CLIENT_INTEG_MIN_FREE_GIB, lib.sh).
require_free_disk

STATE="$STATE_DIR/state.json"
[[ -f "$STATE" ]] || { echo "No $STATE; run infra/provision.sh first." >&2; exit 1; }
[[ -f "$USERS_FILE" ]] || { echo "No $USERS_FILE; run infra/provision.sh first." >&2; exit 1; }
get() { python3 -c "import json,sys;print(json.load(open(sys.argv[1]))[sys.argv[2]])" "$STATE" "$1"; }
REGION=$(get region)
USER_POOL_ID=$(get userPoolId)
aws() { command aws --region "$REGION" --output json "$@" 2> >(redact >&2); }

# Fail before changing anything if the caller is in another account, or the pool or a stored
# password is missing.
require_cli_history_off
require_recorded_account
require_user_pool_tag "$USER_POOL_ID"
for field in daveTemporary daveNew erin; do
    users_field "$field" >/dev/null
done

# Creates user $1 (no message sent), unless an overlapping run created it between this run's check and the call
# (UsernameExistsException): the password reset that follows makes it the user this run needs either way. Any other
# error still stops the script. Guarded.
create_user_unless_created() {
    local create_error
    require_user_pool_tag "$USER_POOL_ID"
    if ! create_error=$(command aws --region "$REGION" --output json cognito-idp admin-create-user \
        --user-pool-id "$USER_POOL_ID" --username "$1" --message-action SUPPRESS 2>&1 >/dev/null); then
        case "$create_error" in
            *UsernameExistsException*) echo "$1: already created by another run" ;;
            *) printf '%s\n' "$create_error" | redact >&2; exit 1 ;;
        esac
        return 0
    fi
    echo "Created user $1"
}

# --- dave: FORCE_CHANGE_PASSWORD with the stored temporary password ---------------------------------
if ! user_exists "$USER_POOL_ID" dave; then
    create_user_unless_created dave
fi
set_user_password "$USER_POOL_ID" dave daveTemporary temporary

# Sets user $1's password to users.json field $2 ($3: permanent or temporary). Returns 1, printing nothing, when the
# user is gone (UserNotFoundException: an overlapping run deleted her between this run's create and this call); any
# other error stops the script. Guarded.
set_password_unless_gone() {
    local set_error
    if ! set_error=$(set_user_password "$USER_POOL_ID" "$1" "$2" "$3" 2>&1 >/dev/null); then
        case "$set_error" in
            *UserNotFoundException*) return 1 ;;
            *) printf '%s\n' "$set_error" >&2; exit 1 ;;
        esac
    fi
}

# --- erin: recreated with the stored permanent password ---------------------------------------------
# Deleted, created and given her password. An overlapping run (another runner's prepare-run.sh, or DU-1) may delete
# her at any point of that: a delete or create it got to first is tolerated, and a password set on a user it has
# since deleted starts the reset again, up to ERIN_ATTEMPTS times, a second apart.
ERIN_ATTEMPTS=5
reset_erin() {
    local delete_error
    if user_exists "$USER_POOL_ID" erin; then
        require_user_pool_tag "$USER_POOL_ID"
        # Already gone, by another run's delete, is the goal. Any other error still stops the script.
        if ! delete_error=$(command aws --region "$REGION" --output json cognito-idp admin-delete-user \
            --user-pool-id "$USER_POOL_ID" --username erin 2>&1 >/dev/null); then
            case "$delete_error" in
                *UserNotFoundException*) echo "erin: already deleted by another run" ;;
                *) printf '%s\n' "$delete_error" | redact >&2; exit 1 ;;
            esac
        fi
    fi
    create_user_unless_created erin
    set_password_unless_gone erin erin permanent
}
reset_erin_until_set() {
    local attempt
    for (( attempt = 1; ; attempt++ )); do
        reset_erin && return 0
        if (( attempt >= ERIN_ATTEMPTS )); then
            echo "erin was deleted by another run each of $ERIN_ATTEMPTS times her password was set; run this" \
                "again once the other run has finished." >&2
            exit 1
        fi
        echo "erin: deleted by another run before her password was set; resetting her again"
        sleep 1
    done
}
reset_erin_until_set

# --- Report (read-only) -----------------------------------------------------------------------------
for user in dave erin; do
    # An overlapping run may be resetting the user right now: a user it has just deleted is reported, not fatal.
    status=$(aws cognito-idp admin-get-user --user-pool-id "$USER_POOL_ID" --username "$user" \
        --query UserStatus --output text 2>/dev/null) || status="not found (another run is resetting it)"
    echo "$user: $status"
done

# --- P-12: test-created users in the parity pools, older than 24 hours ------------------------------
if python3 -c "import json,sys;sys.exit(0 if json.load(open(sys.argv[1])).get('parity') else 1)" "$STATE"; then
    python3 "$INFRA_DIR/parity.py" preflight
    python3 "$INFRA_DIR/parity.py" cleanup
    python3 "$INFRA_DIR/parity.py" plugin-users
    python3 "$INFRA_DIR/parity.py" rotate-key
    # A rotated key would leave the plugin suites' OTP configurations on the old one: rewrite the files
    # plugin-configs.py wrote (only those still as written; a no-op if it wrote none).
    python3 "$INFRA_DIR/plugin-configs.py" --refresh
fi
