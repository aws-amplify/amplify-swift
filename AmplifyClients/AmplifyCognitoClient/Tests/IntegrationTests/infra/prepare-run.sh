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
#                missing or its self sign-up differs from its template (MISSING, DRIFT).
#
# It never touches alice, bob or carol, and it refuses to run unless the user pool recorded in
# $STATE_DIR/state.json carries purpose=amplify-cognito-client-integ (checked before every mutating
# call). Passwords come from $STATE_DIR/users.json, which provision.sh writes; they stay stable, so
# nothing needs rebuilding (users.json is copied into the test bundle at build time). No secret is
# printed or passed to the AWS CLI as an argument.
#
# Usage: AWS_PROFILE=<sandbox-profile> ./prepare-run.sh
set -euo pipefail

INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$INFRA_DIR/lib.sh"
require_aws_profile

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

# --- dave: FORCE_CHANGE_PASSWORD with the stored temporary password ---------------------------------
if ! user_exists "$USER_POOL_ID" dave; then
    create_user "$USER_POOL_ID" dave
    echo "Created user dave"
fi
set_user_password "$USER_POOL_ID" dave daveTemporary temporary

# --- erin: recreated with the stored permanent password ---------------------------------------------
if user_exists "$USER_POOL_ID" erin; then
    require_user_pool_tag "$USER_POOL_ID"
    # Another runner's prepare-run (or DU-1) may delete erin between the check and this call: she is
    # then already gone, which is the goal. Any other error still stops the script.
    if ! delete_error=$(command aws --region "$REGION" --output json cognito-idp admin-delete-user \
        --user-pool-id "$USER_POOL_ID" --username erin 2>&1 >/dev/null); then
        case "$delete_error" in
            *UserNotFoundException*) echo "erin: already deleted by another run" ;;
            *) printf '%s\n' "$delete_error" | redact >&2; exit 1 ;;
        esac
    fi
fi
create_user "$USER_POOL_ID" erin
set_user_password "$USER_POOL_ID" erin erin permanent

# --- Report (read-only) -----------------------------------------------------------------------------
for user in dave erin; do
    status=$(aws cognito-idp admin-get-user --user-pool-id "$USER_POOL_ID" --username "$user" \
        --query UserStatus --output text)
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
