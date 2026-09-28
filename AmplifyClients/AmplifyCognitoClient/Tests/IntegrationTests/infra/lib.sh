# Shared by provision.sh and prepare-run.sh. Source it; do not run it.
#
# Every mutating call these scripts make is preceded by one of the require_*_tag guards, which read
# the resource's tags and exit unless it carries purpose=amplify-cognito-client-integ. Secrets
# (passwords, TOTP secrets, tokens) reach the AWS CLI through --cli-input-json, from a mode-600 file
# in $STATE_DIR that is deleted straight after the call, rather than as arguments. They are never echoed.
# Neither are identifiers: the scripts print resource names, and the AWS CLI's error output passes
# through `redact`, which masks account, pool, client and key ids.

NAME="amplify-cognito-client-integ"
TAG_KEY="purpose"
TAG_VALUE="$NAME"
# The one override for the fixtures directory, shared with the host app's "Copy sandbox configuration" phase.
STATE_DIR="${COGNITO_CLIENT_INTEG_DIR:-$HOME/.amplify-cognito-client-integ}"
USERS_FILE="$STATE_DIR/users.json"

# Masks identifiers in AWS CLI error output: IAM role and session names, SES identities, hosted-UI
# domains, identity pool ids, user pool ids, UUIDs (key ids), AppSync API keys, 26-character ids (app
# clients, AppSync APIs), 12-digit account ids and email addresses.
# Each script's aws() wrapper sends stderr through it.
redact() {
    sed -E \
        -e 's#(assumed-role|role|user|federated-user)/[A-Za-z0-9_+=,.@-]+(/[A-Za-z0-9_+=,.@-]+)?#\1/<name>#g' \
        -e 's#identity/[^ "'"'"',]+#identity/<name>#g' \
        -e 's/[a-z0-9-]+\.auth\.[a-z0-9-]+\.amazoncognito\.com/<hosted-ui-domain>/g' \
        -e 's/[a-z]{2}-[a-z]+-[0-9]:[0-9a-f-]{36}/<identity-pool>/g' \
        -e 's/[a-z]{2}-[a-z]+-[0-9]_[A-Za-z0-9]{6,}/<user-pool>/g' \
        -e 's/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/<id>/g' \
        -e 's/da2-[a-z0-9]{20,}/<api-key>/g' \
        -e 's/(^|[^a-z0-9])[a-z0-9]{26}([^a-z0-9]|$)/\1<id>\2/g' \
        -e 's/[0-9]{12}/<account>/g' \
        -e 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/<email>/g'
}

# Exits unless AWS_PROFILE names the profile to use. The scripts never pick a profile themselves (no
# default, no fallback to the CLI's default profile), so a run can only act on the account it was
# explicitly pointed at. Call it first, before any AWS call.
require_aws_profile() {
    if [[ -z "${AWS_PROFILE:-}" ]]; then
        echo "error: set AWS_PROFILE to the profile of the sandbox account (see the integration README);" \
            "these scripts never pick a profile themselves." >&2
        exit 1
    fi
}

# Exits if AWS CLI history is on. With `cli_history = enabled`, the CLI records every call's
# parameters and response in ~/.aws/cli/history/history.db, and the parameters these scripts pass
# through --cli-input-json are passwords, tokens and carol's TOTP secret.
require_cli_history_off() {
    local history
    history=$(command aws configure get cli_history 2>/dev/null || true)
    if [[ "$history" == "enabled" ]]; then
        echo "Refusing: AWS CLI history is enabled (cli_history = enabled), and it would record the" \
            "secrets these scripts send. Turn it off for this profile first." >&2
        exit 1
    fi
}

# Exits if $STATE_DIR/state.json records an account other than the caller's, so a profile for
# another account can never act on this sandbox's recorded resources (or mint a second sandbox under
# the same state directory). Sets ACCOUNT, which is never printed. Run before any mutating call.
require_recorded_account() {
    local recorded=""
    ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    if [[ -f "$STATE_DIR/state.json" ]]; then
        recorded=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('account',''))" "$STATE_DIR/state.json")
    fi
    if [[ -n "$recorded" && "$recorded" != "$ACCOUNT" ]]; then
        echo "Refusing: $STATE_DIR/state.json belongs to an account other than the caller's. Use that" \
            "account's profile, or point COGNITO_CLIENT_INTEG_DIR at another directory." >&2
        exit 1
    fi
    if [[ -n "$recorded" ]]; then
        echo "Account matches state.json; region $REGION"
    else
        echo "No account recorded yet; region $REGION"
    fi
}

# Exits unless user pool $1 carries the purpose tag.
require_user_pool_tag() {
    local tag
    tag=$(aws cognito-idp describe-user-pool --user-pool-id "$1" \
        --query "UserPool.UserPoolTags.$TAG_KEY" --output text 2>/dev/null || true)
    if [[ "$tag" != "$TAG_VALUE" ]]; then
        echo "Refusing: the user pool is not tagged $TAG_KEY=$TAG_VALUE." >&2
        exit 1
    fi
}

# Exits unless identity pool $1 carries the purpose tag.
require_identity_pool_tag() {
    local tag arn
    arn="arn:aws:cognito-identity:$REGION:$ACCOUNT:identitypool/$1"
    tag=$(aws cognito-identity list-tags-for-resource --resource-arn "$arn" \
        --query "Tags.$TAG_KEY" --output text 2>/dev/null || true)
    if [[ "$tag" != "$TAG_VALUE" ]]; then
        echo "Refusing: the identity pool is not tagged $TAG_KEY=$TAG_VALUE." >&2
        exit 1
    fi
}

# Exits unless IAM role $1 carries the purpose tag.
require_role_tag() {
    local tag
    tag=$(aws iam list-role-tags --role-name "$1" \
        --query "Tags[?Key=='$TAG_KEY'].Value | [0]" --output text 2>/dev/null || true)
    if [[ "$tag" != "$TAG_VALUE" ]]; then
        echo "Refusing: role $1 is not tagged $TAG_KEY=$TAG_VALUE." >&2
        exit 1
    fi
}

# Exits if IAM role $1 has any attached or inline policy: the sandbox roles must grant nothing.
require_role_without_policies() {
    local attached inline
    attached=$(aws iam list-attached-role-policies --role-name "$1" \
        --query 'length(AttachedPolicies)' --output text)
    inline=$(aws iam list-role-policies --role-name "$1" --query 'length(PolicyNames)' --output text)
    if [[ "$attached" != "0" || "$inline" != "0" ]]; then
        echo "Refusing: role $1 has $attached attached and $inline inline policies; it must have none." >&2
        exit 1
    fi
}

# Runs `aws <args> --cli-input-json` with the JSON read from stdin, via a mode-600 file in $STATE_DIR
# that is removed afterwards. (The CLI cannot read --cli-input-json from /dev/stdin.) It runs in a
# subshell whose EXIT trap removes the file, and INT or TERM exit that subshell, so the file is removed
# on an interrupt too.
aws_with_input() (
    input=$(umask 077 && mktemp "$STATE_DIR/.cli-input.XXXXXX")
    trap 'rm -f "$input"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    cat > "$input"
    aws "$@" --cli-input-json "file://$input"
)

# Reads one string field of users.json. Never print the result.
users_field() {
    python3 - "$USERS_FILE" "$1" <<'PY'
import json, sys
value = json.load(open(sys.argv[1])).get(sys.argv[2])
if not isinstance(value, str) or not value:
    sys.exit(f"{sys.argv[2]} is missing from users.json; run infra/provision.sh.")
print(value)
PY
}

# Whether user $2 exists in pool $1. Read-only.
user_exists() {
    aws cognito-idp admin-get-user --user-pool-id "$1" --username "$2" >/dev/null 2>&1
}

# Creates user $2 in pool $1 without sending a message. Guarded.
create_user() {
    require_user_pool_tag "$1"
    aws cognito-idp admin-create-user --user-pool-id "$1" --username "$2" \
        --message-action SUPPRESS >/dev/null
}

# Sets user $2's password in pool $1 to users.json field $3. $4 is "permanent" or "temporary".
# The password never appears as an argument. Guarded.
set_user_password() {
    local pool="$1" user="$2" field="$3" mode="$4"
    require_user_pool_tag "$pool"
    python3 - "$USERS_FILE" "$pool" "$user" "$field" "$mode" <<'PY' |
import json, sys
path, pool, user, field, mode = sys.argv[1:]
print(json.dumps({
    "UserPoolId": pool,
    "Username": user,
    "Password": json.load(open(path))[field],
    "Permanent": mode == "permanent",
}))
PY
        aws_with_input cognito-idp admin-set-user-password >/dev/null
}
