#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Probes what live Cognito returns when a refresh token is re-presented under refresh-token rotation
# (docs/design/issues/rollback-behaviours.md §1). Self-contained: it creates its own throwaway
# user pool (tagged purpose=amplify-cognito-client-integ and probe=rotation-reuse), one public app client
# with rotation on, and one user; runs the cases; and deletes all three in an EXIT trap, each deletion
# after checking the pool still carries both tags. It never reads or changes the shared sandbox pools.
#
# Cases, on the GetTokensFromRefreshToken API (the one rotation requires):
#   1  R0 -> R1                                   (expected to succeed)
#   2  R0 again, after the grace period + 10 s   (the rotated-away token)
#   3  R1 -> R2                                   (after case 2: is the rest of the lineage still alive?)
#   4  R1 again, after the grace period + 10 s
#   5  RevokeToken(R2), then R2
#   6  extra: InitiateAuth REFRESH_TOKEN_AUTH with a fresh, live refresh token on the rotation client
#      (records whatever it returns; Cognito refuses ALLOW_REFRESH_TOKEN_AUTH on a client with rotation
#      on, so the client allows ALLOW_USER_PASSWORD_AUTH only and refreshes via GetTokensFromRefreshToken)
#
# Output is limited to case names, success/failure, HTTP statuses, error codes and, when it consists of
# plain words only, Cognito's error message. Tokens stay in the probe's memory; the password lives in a
# mode-600 file in a mode-700 temporary directory that the trap removes. No identifier is printed (AWS CLI
# errors pass through lib.sh's redact).
#
# Usage: AWS_PROFILE=<sandbox-profile> ./probe-rotation-reuse.sh [region]
#        GRACE_SECONDS (default 5, at most 60) sets RetryGracePeriodSeconds.
set -euo pipefail
# The caller names the sandbox profile; there is no default. require_recorded_account below still
# refuses any account other than the one in state.json.
if [[ -z "${AWS_PROFILE:-}" ]]; then
    echo "Refusing: AWS_PROFILE is not set. Run as AWS_PROFILE=<sandbox-profile> $0 [region]." >&2
    exit 1
fi
export AWS_PROFILE

INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$INFRA_DIR/lib.sh"
umask 077

REGION="${1:-${AWS_REGION:-}}"
if [[ -z "$REGION" && -f "$STATE_DIR/state.json" ]]; then
    REGION=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('region',''))" "$STATE_DIR/state.json")
fi
REGION="${REGION:-us-west-2}"
GRACE_SECONDS="${GRACE_SECONDS:-5}"
[[ "$GRACE_SECONDS" =~ ^[0-9]+$ && "$GRACE_SECONDS" -le 60 ]] || { echo "GRACE_SECONDS must be 0-60" >&2; exit 1; }
PROBE_TAG_KEY="probe"
PROBE_TAG_VALUE="rotation-reuse"
USERNAME="probe-rotation-user"
aws() { command aws --region "$REGION" --output json "$@" 2> >(redact >&2); }

require_cli_history_off
require_recorded_account

WORK=$(umask 077 && mktemp -d)
POOL_ID=""
CLIENT_ID=""
USER_CREATED=""

# Exits unless the probe's pool carries both purpose=amplify-cognito-client-integ and probe=rotation-reuse.
require_probe_tags() {
    local tags
    tags=$(aws cognito-idp list-tags-for-resource \
        --resource-arn "arn:aws:cognito-idp:$REGION:$ACCOUNT:userpool/$POOL_ID" \
        --query "[Tags.$TAG_KEY, Tags.$PROBE_TAG_KEY]" --output text 2>/dev/null || true)
    if [[ "$tags" != "$TAG_VALUE"$'\t'"$PROBE_TAG_VALUE" ]]; then
        echo "Refusing: the probe pool is not tagged $TAG_KEY=$TAG_VALUE and $PROBE_TAG_KEY=$PROBE_TAG_VALUE." >&2
        exit 1
    fi
}

cleanup() {
    local status=$?
    set +e
    if [[ -n "$POOL_ID" ]]; then
        if (require_probe_tags); then
            if [[ -n "$USER_CREATED" ]]; then
                aws cognito-idp admin-delete-user --user-pool-id "$POOL_ID" --username "$USERNAME" >/dev/null \
                    && echo "Deleted probe user"
            fi
            if [[ -n "$CLIENT_ID" ]]; then
                (require_probe_tags) && aws cognito-idp delete-user-pool-client --user-pool-id "$POOL_ID" \
                    --client-id "$CLIENT_ID" >/dev/null && echo "Deleted probe app client"
            fi
            (require_probe_tags) && aws cognito-idp delete-user-pool --user-pool-id "$POOL_ID" >/dev/null \
                && echo "Deleted probe user pool"
            if aws cognito-idp describe-user-pool --user-pool-id "$POOL_ID" >/dev/null 2>&1; then
                echo "WARNING: the probe user pool still exists; delete it by hand (tag probe=$PROBE_TAG_VALUE)." >&2
                status=1
            fi
        else
            echo "WARNING: left the probe pool alone (tag check failed); find it by tag probe=$PROBE_TAG_VALUE." >&2
            status=1
        fi
    fi
    rm -rf "$WORK"
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# --- Pool, client, user ----------------------------------------------------------------------------
POOL_ID=$(aws cognito-idp create-user-pool \
    --pool-name "$NAME-probe-rotation-reuse-$(date +%s)" \
    --admin-create-user-config AllowAdminCreateUserOnly=true \
    --deletion-protection INACTIVE \
    --user-pool-tags "$TAG_KEY=$TAG_VALUE,$PROBE_TAG_KEY=$PROBE_TAG_VALUE" \
    --query 'UserPool.Id' --output text)
echo "Created probe user pool"
require_probe_tags

CLIENT_ID=$(aws cognito-idp create-user-pool-client \
    --user-pool-id "$POOL_ID" \
    --client-name "$NAME-probe-rotation" \
    --no-generate-secret \
    --explicit-auth-flows ALLOW_USER_PASSWORD_AUTH \
    --enable-token-revocation \
    --prevent-user-existence-errors ENABLED \
    --refresh-token-rotation "Feature=ENABLED,RetryGracePeriodSeconds=$GRACE_SECONDS" \
    --query 'UserPoolClient.ClientId' --output text)
echo "Created probe app client: rotation" \
    "$(aws cognito-idp describe-user-pool-client --user-pool-id "$POOL_ID" --client-id "$CLIENT_ID" \
        --query 'UserPoolClient.[RefreshTokenRotation.Feature, RefreshTokenRotation.RetryGracePeriodSeconds]' \
        --output text | tr '\t' ' ' | sed 's/ / grace=/')"

python3 - "$WORK/password" <<'PY'
import os, secrets, string, sys
alphabet = string.ascii_letters + string.digits
password = "Aa1!" + "".join(secrets.choice(alphabet) for _ in range(28))
with os.fdopen(os.open(sys.argv[1], os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "w") as f:
    f.write(password)
PY
require_probe_tags
aws cognito-idp admin-create-user --user-pool-id "$POOL_ID" --username "$USERNAME" \
    --message-action SUPPRESS >/dev/null
USER_CREATED=1
python3 - "$WORK/password" "$POOL_ID" "$USERNAME" > "$WORK/set-password.json" <<'PY'
import json, sys
print(json.dumps({"UserPoolId": sys.argv[2], "Username": sys.argv[3],
                  "Password": open(sys.argv[1]).read(), "Permanent": True}))
PY
require_probe_tags
aws cognito-idp admin-set-user-password --cli-input-json "file://$WORK/set-password.json" >/dev/null
rm -f "$WORK/set-password.json"
echo "Created probe user"

# --- Probe -----------------------------------------------------------------------------------------
# The unsigned Cognito user pools JSON API, called directly so the HTTP status is visible and the
# tokens never leave this process.
REGION="$REGION" CLIENT_ID="$CLIENT_ID" USERNAME="$USERNAME" GRACE_SECONDS="$GRACE_SECONDS" \
    python3 - "$WORK/password" <<'PY'
import json, os, re, sys, time, urllib.error, urllib.request

REGION, CLIENT_ID, USERNAME = os.environ["REGION"], os.environ["CLIENT_ID"], os.environ["USERNAME"]
WAIT = int(os.environ["GRACE_SECONDS"]) + 10
PASSWORD = open(sys.argv[1]).read()
ENDPOINT = f"https://cognito-idp.{REGION}.amazonaws.com/"
PLAIN = re.compile(r"^[A-Za-z][A-Za-z .,'-]{0,99}$")


def call(operation, body):
    """Returns (http_status, error_code or None, plain message or None, response or None)."""
    request = urllib.request.Request(ENDPOINT, data=json.dumps(body).encode(), method="POST", headers={
        "Content-Type": "application/x-amz-json-1.1",
        "X-Amz-Target": f"AWSCognitoIdentityProviderService.{operation}"})
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return response.status, None, None, json.loads(response.read() or b"{}")
    except urllib.error.HTTPError as error:
        try:
            payload = json.loads(error.read() or b"{}")
        except ValueError:
            payload = {}
        code = str(payload.get("__type", "?")).split("#")[-1]
        message = payload.get("message") or payload.get("Message") or ""
        return error.code, code, message if PLAIN.match(message) else "(message withheld)", None


def report(case, result):
    status, code, message, _ = result
    if code is None:
        print(f"{case}: HTTP {status} OK")
    else:
        print(f"{case}: HTTP {status} {code} ({message})")


def sign_in():
    result = call("InitiateAuth", {"ClientId": CLIENT_ID, "AuthFlow": "USER_PASSWORD_AUTH",
                                   "AuthParameters": {"USERNAME": USERNAME, "PASSWORD": PASSWORD}})
    report("sign-in (InitiateAuth USER_PASSWORD_AUTH)", result)
    if result[1] is not None:
        sys.exit(1)
    return result[3]["AuthenticationResult"]["RefreshToken"]


def refresh(case, token):
    result = call("GetTokensFromRefreshToken", {"ClientId": CLIENT_ID, "RefreshToken": token})
    report(case, result)
    if result[1] is None:
        new = result[3].get("AuthenticationResult", {}).get("RefreshToken")
        print(f"    new refresh token returned: {bool(new)}; differs from the one presented: {bool(new) and new != token}")
        return new
    return None


r0 = sign_in()
r1 = refresh("case 1  R0 -> R1", r0)
if not r1:
    sys.exit("case 1 returned no rotated refresh token; the remaining cases need one")
print(f"    waiting {WAIT} s (grace + 10)")
time.sleep(WAIT)
refresh("case 2  R0 again after grace", r0)
r2 = refresh("case 3  R1 -> R2 (after case 2)", r1)
if not r2:
    print("    case 3 failed: the lineage did not survive case 2; continuing on a fresh sign-in")
    r1 = refresh("case 3b fresh R0' -> R1'", sign_in())
    r2 = refresh("case 3c R1' -> R2'", r1) if r1 else None
    if not r2:
        sys.exit("no live R1/R2 pair; stopping")
print(f"    waiting {WAIT} s (grace + 10)")
time.sleep(WAIT)
refresh("case 4  R1 again after grace", r1)
report("case 5a RevokeToken(R2)", call("RevokeToken", {"ClientId": CLIENT_ID, "Token": r2}))
refresh("case 5b R2 after revoke", r2)
live = sign_in()
report("case 6  InitiateAuth REFRESH_TOKEN_AUTH on the rotation client",
       call("InitiateAuth", {"ClientId": CLIENT_ID, "AuthFlow": "REFRESH_TOKEN_AUTH",
                             "AuthParameters": {"REFRESH_TOKEN": live}}))
PY
echo "Probe done"
