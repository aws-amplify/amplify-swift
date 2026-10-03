#!/usr/bin/env bash
#
# Provisions the Cognito resources the AmplifyCognitoClient integration tests run against:
# one user pool (MFA optional, TOTP enabled), one public app client, one identity pool
# (unauthenticated identities on), two permissionless IAM roles for it, and the test users:
#   alice, bob  confirmed, permanent passwords
#   carol       confirmed, TOTP enrolled and preferred (her secret is carolTotpSecret)
#   dave, erin  reset by prepare-run.sh before every run; this script runs it once at the end
# Then parity.py adds the plugin-parity resources: the trigger and custom-sender
# Lambdas, the KMS key and the code sink (AppSync + DynamoDB), six more user pools from pools/*.json,
# the hosted-UI domain, an identity-only identity pool, the SNS caller role for SMS (only while the
# account's SNS is in the SMS sandbox), and DEVELOPER email from a verified SES domain the account already
# owns (used read-only; never tagged, changed or deleted).
#
# Every resource is tagged purpose=amplify-cognito-client-integ and recorded in $STATE_DIR, so
# teardown.sh can remove exactly these and nothing else. Safe to re-run: it reuses what exists.
#
# Outputs, all OUTSIDE the repo (they are account-specific, and the users' passwords are secrets):
#   $STATE_DIR/state.json            resource ids
#   $STATE_DIR/amplify_outputs.json  the client's configuration
#   $STATE_DIR/<pool>-amplify_outputs.json  one per parity pool, plus hosted-ui, rotation and identity-only
#   $STATE_DIR/users.json            test passwords, carol's TOTP secret, the code sink API key and
#                                    the custom-challenge answer (mode 600)
#
# Every mutating call on an existing resource is preceded by a tag check (infra/lib.sh), and no
# secret or identifier is printed, and no secret is passed to the AWS CLI as an argument.
#
# Usage: AWS_PROFILE=<sandbox-profile> [COGNITO_CLIENT_INTEG_SES_DOMAIN=<domain> | COGNITO_CLIENT_INTEG_SES_EMAIL=<address>]
#        ./provision.sh [region]
set -euo pipefail

REGION="${1:-${AWS_REGION:-us-west-2}}"
INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$INFRA_DIR/lib.sh"
mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"
# stderr passes through redact (lib.sh), so an error cannot print an account, pool or client id.
aws() { command aws --region "$REGION" --output json "$@" 2> >(redact >&2); }

require_cli_history_off
require_recorded_account
# Never while an infra/self-sign-up.sh run holds self sign-up on: provisioning turns it off (parity.py provision
# checks again, under the toggle lock).
python3 "$INFRA_DIR/parity.py" self-sign-up require-idle

# --- User pool -----------------------------------------------------------------------------------
# The id an earlier run recorded wins over the name lookup, which reads only the first page.
USER_POOL_ID=""
if [[ -f "$STATE_DIR/state.json" ]]; then
    USER_POOL_ID=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('userPoolId',''))" "$STATE_DIR/state.json")
fi
if [[ -z "$USER_POOL_ID" ]] || ! aws cognito-idp describe-user-pool --user-pool-id "$USER_POOL_ID" >/dev/null 2>&1; then
    USER_POOL_ID=$(aws cognito-idp list-user-pools --max-results 60 \
        --query "UserPools[?Name=='$NAME'].Id | [0]" --output text)
fi
if [[ "$USER_POOL_ID" == "None" || -z "$USER_POOL_ID" ]]; then
    USER_POOL_ID=$(aws cognito-idp create-user-pool \
        --pool-name "$NAME" \
        --policies 'PasswordPolicy={MinimumLength=12,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=false}' \
        --admin-create-user-config 'AllowAdminCreateUserOnly=true' \
        --deletion-protection INACTIVE \
        --user-pool-tags "$TAG_KEY=$TAG_VALUE" \
        --query 'UserPool.Id' --output text)
    echo "Created user pool $NAME"
else
    require_user_pool_tag "$USER_POOL_ID"
    echo "Reusing user pool $NAME"
fi

# --- MFA: optional, TOTP only (P-1). Users with no MFA preference, like alice and bob, are unaffected.
require_user_pool_tag "$USER_POOL_ID"
aws cognito-idp set-user-pool-mfa-config --user-pool-id "$USER_POOL_ID" \
    --mfa-configuration OPTIONAL \
    --software-token-mfa-configuration Enabled=true >/dev/null

# --- App client: public (no secret), SRP + password + refresh, revocation on ----------------------
CLIENT_ID=$(aws cognito-idp list-user-pool-clients --user-pool-id "$USER_POOL_ID" \
    --query "UserPoolClients[?ClientName=='$NAME-client'].ClientId | [0]" --output text)
if [[ "$CLIENT_ID" == "None" || -z "$CLIENT_ID" ]]; then
    require_user_pool_tag "$USER_POOL_ID"
    CLIENT_ID=$(aws cognito-idp create-user-pool-client \
        --user-pool-id "$USER_POOL_ID" \
        --client-name "$NAME-client" \
        --no-generate-secret \
        --explicit-auth-flows ALLOW_USER_SRP_AUTH ALLOW_USER_PASSWORD_AUTH ALLOW_REFRESH_TOKEN_AUTH \
        --enable-token-revocation \
        --prevent-user-existence-errors ENABLED \
        --query 'UserPoolClient.ClientId' --output text)
    echo "Created app client $NAME-client"
else
    echo "Reusing app client $NAME-client"
fi

# --- Identity pool --------------------------------------------------------------------------------
IDENTITY_POOL_ID=""
if [[ -f "$STATE_DIR/state.json" ]]; then
    IDENTITY_POOL_ID=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('identityPoolId',''))" "$STATE_DIR/state.json")
fi
if [[ -z "$IDENTITY_POOL_ID" ]] || ! aws cognito-identity describe-identity-pool --identity-pool-id "$IDENTITY_POOL_ID" >/dev/null 2>&1; then
    IDENTITY_POOL_ID=$(aws cognito-identity list-identity-pools --max-results 60 \
        --query "IdentityPools[?IdentityPoolName=='${NAME//-/_}'].IdentityPoolId | [0]" --output text)
fi
if [[ "$IDENTITY_POOL_ID" == "None" || -z "$IDENTITY_POOL_ID" ]]; then
    IDENTITY_POOL_ID=$(aws cognito-identity create-identity-pool \
        --identity-pool-name "${NAME//-/_}" \
        --allow-unauthenticated-identities \
        --cognito-identity-providers "ProviderName=cognito-idp.$REGION.amazonaws.com/$USER_POOL_ID,ClientId=$CLIENT_ID,ServerSideTokenCheck=false" \
        --identity-pool-tags "$TAG_KEY=$TAG_VALUE" \
        --query 'IdentityPoolId' --output text)
    echo "Created identity pool ${NAME//-/_}"
else
    require_identity_pool_tag "$IDENTITY_POOL_ID"
    echo "Reusing identity pool ${NAME//-/_}"
    # A reused identity pool may still point at an earlier user pool or app client (after a partial
    # teardown, say). Re-point it only if it differs. UpdateIdentityPool resets every field it is not
    # given, so the whole configuration is passed, tags included.
    PROVIDERS=$(aws cognito-identity describe-identity-pool --identity-pool-id "$IDENTITY_POOL_ID" \
        --query 'CognitoIdentityProviders[].[ProviderName,ClientId]' --output text)
    EXPECTED_PROVIDER=$(printf '%s\t%s' "cognito-idp.$REGION.amazonaws.com/$USER_POOL_ID" "$CLIENT_ID")
    if [[ "$PROVIDERS" != "$EXPECTED_PROVIDER" ]]; then
        require_identity_pool_tag "$IDENTITY_POOL_ID"
        aws cognito-identity update-identity-pool \
            --identity-pool-id "$IDENTITY_POOL_ID" \
            --identity-pool-name "${NAME//-/_}" \
            --allow-unauthenticated-identities \
            --cognito-identity-providers "ProviderName=cognito-idp.$REGION.amazonaws.com/$USER_POOL_ID,ClientId=$CLIENT_ID,ServerSideTokenCheck=false" \
            --identity-pool-tags "$TAG_KEY=$TAG_VALUE" >/dev/null
        require_identity_pool_tag "$IDENTITY_POOL_ID"
        echo "Re-pointed identity pool ${NAME//-/_} at user pool $NAME"
    fi
fi

# --- IAM roles: trust the identity pool, grant nothing -------------------------------------------
# GetCredentialsForIdentity still vends credentials for a role with no policies, which is all the
# tests need, so the roles carry no permissions at all. A reused role must carry the purpose tag and
# no policy of any kind, since the identity pool hands its credentials to unauthenticated guests; its
# trust policy is re-applied so that its `aud` is the current identity pool. A role without the tag is
# never modified. Sets ROLE_ARN directly rather than through $(...), so a guard's `exit` stops the script.
ensure_role() {
    local role_name="$1" amr="$2"
    local trust
    trust=$(cat <<JSON
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Federated":"cognito-identity.amazonaws.com"},
"Action":"sts:AssumeRoleWithWebIdentity","Condition":{"StringEquals":{"cognito-identity.amazonaws.com:aud":"$IDENTITY_POOL_ID"},
"ForAnyValue:StringLike":{"cognito-identity.amazonaws.com:amr":"$amr"}}}]}
JSON
)
    if ! aws iam get-role --role-name "$role_name" >/dev/null 2>&1; then
        aws iam create-role --role-name "$role_name" \
            --assume-role-policy-document "$trust" \
            --tags "Key=$TAG_KEY,Value=$TAG_VALUE" >/dev/null
        echo "Created role $role_name"
    else
        require_role_tag "$role_name"
        require_role_without_policies "$role_name"
        require_role_tag "$role_name"
        aws iam update-assume-role-policy --role-name "$role_name" \
            --policy-document "$trust" >/dev/null
        echo "Reusing role $role_name (trust policy re-applied)"
    fi
    ROLE_ARN=$(aws iam get-role --role-name "$role_name" --query 'Role.Arn' --output text)
}
ensure_role "$NAME-authenticated" "authenticated"
AUTH_ROLE_ARN="$ROLE_ARN"
ensure_role "$NAME-unauthenticated" "unauthenticated"
UNAUTH_ROLE_ARN="$ROLE_ARN"
require_identity_pool_tag "$IDENTITY_POOL_ID"
aws cognito-identity set-identity-pool-roles --identity-pool-id "$IDENTITY_POOL_ID" \
    --roles "authenticated=$AUTH_ROLE_ARN,unauthenticated=$UNAUTH_ROLE_ARN" >/dev/null

# --- Test users -----------------------------------------------------------------------------------
# users.json holds every password the tests use. Each is generated once and then kept, so re-runs
# (and test-without-building) see stable values. Missing keys are added; existing ones never change.
python3 - "$USERS_FILE" <<'PY'
import json, os, secrets, string, sys
path = sys.argv[1]
users = json.load(open(path)) if os.path.exists(path) else {}
alphabet = string.ascii_letters + string.digits
for key, prefix in [("alice", "Aa1"), ("bob", "Bb2"), ("carol", "Cc3"),
                    ("daveTemporary", "Dd4"), ("daveNew", "Dd5"), ("erin", "Ee6")]:
    users.setdefault(key, prefix + "".join(secrets.choice(alphabet) for _ in range(20)))
tmp = path + ".tmp"
with os.fdopen(os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "w") as f:
    json.dump(users, f, sort_keys=True)
    f.write("\n")
os.replace(tmp, path)
os.chmod(path, 0o600)
PY
for user in alice bob carol; do
    if ! user_exists "$USER_POOL_ID" "$user"; then
        create_user "$USER_POOL_ID" "$user"
        echo "Created user $user"
    fi
    set_user_password "$USER_POOL_ID" "$user" "$user" permanent
done

# --- carol: TOTP enrolled and preferred (P-2); skipped if already enrolled ---------------------------
REGION="$REGION" USER_POOL_ID="$USER_POOL_ID" CLIENT_ID="$CLIENT_ID" USERS_FILE="$USERS_FILE" \
    TAG_KEY="$TAG_KEY" TAG_VALUE="$TAG_VALUE" python3 "$INFRA_DIR/enroll_totp.py"

# --- Outputs --------------------------------------------------------------------------------------
# Merged into state.json, so the "parity" section parity.py records survives a re-run.
python3 - "$STATE_DIR/state.json" "$ACCOUNT" "$REGION" "$USER_POOL_ID" "$CLIENT_ID" "$IDENTITY_POOL_ID" \
    "$AUTH_ROLE_ARN" "$UNAUTH_ROLE_ARN" <<'PY'
import json, os, sys
path = sys.argv[1]
state = json.load(open(path)) if os.path.exists(path) else {}
keys = ["account", "region", "userPoolId", "appClientId", "identityPoolId", "authRoleArn", "unauthRoleArn"]
state.update(dict(zip(keys, sys.argv[2:])))
tmp = path + ".tmp"
with os.fdopen(os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "w") as f:
    json.dump(state, f, sort_keys=True, indent=1)
    f.write("\n")
os.replace(tmp, path)
PY
cat > "$STATE_DIR/amplify_outputs.json" <<JSON
{"version":"1.4","auth":{"aws_region":"$REGION","user_pool_id":"$USER_POOL_ID",
"user_pool_client_id":"$CLIENT_ID","identity_pool_id":"$IDENTITY_POOL_ID",
"unauthenticated_identities_enabled":true}}
JSON

# --- Plugin-parity resources (P-5 … P-8, P-6'): Lambdas, code sink, six pools ----------------------
# Needs node/npm (the custom sender vendors the AWS Encryption SDK). Email (P-8) uses a verified SES domain
# the account already owns (COGNITO_CLIENT_INTEG_SES_DOMAIN picks one); COGNITO_CLIENT_INTEG_SES_EMAIL
# creates a tagged address identity instead, whose verification is manual. SMS (P-9) needs the account's
# SNS in the SMS sandbox.
python3 "$INFRA_DIR/parity.py" provision

# --- Per-run users: dave and erin (P-3, P-4) -------------------------------------------------------
"$INFRA_DIR/prepare-run.sh"

echo "Done. State in $STATE_DIR"
