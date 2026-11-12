# Shared by provision.sh, prepare-run.sh and self-sign-up.sh. Source it; do not run it.
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

# Exits if the volume holding $STATE_DIR (or, before it exists, its nearest existing parent) has less free space
# than COGNITO_CLIENT_INTEG_MIN_FREE_GIB, a whole number of GiB, 2 when unset or empty; 0 skips the check. With a full disk
# the AWS CLI binary itself crashes, part-way through a change, and says only that its launcher failed.
# Run it before any AWS call. Prints a path, never an identifier.
require_free_disk() {
    local minimum="${COGNITO_CLIENT_INTEG_MIN_FREE_GIB:-2}" dir="$STATE_DIR" free_kib
    if [[ ! "$minimum" =~ ^[0-9]{1,6}$ ]]; then
        echo "Refusing: COGNITO_CLIENT_INTEG_MIN_FREE_GIB must be a whole number of GiB (0 skips the check)." >&2
        exit 1
    fi
    minimum=$((10#$minimum))
    (( minimum > 0 )) || return 0
    while [[ ! -d "$dir" && "$dir" != "/" && "$dir" != "." ]]; do
        dir=$(dirname "$dir")
    done
    free_kib=$(python3 -c "import shutil,sys;print(shutil.disk_usage(sys.argv[1]).free // 1024)" "$dir" 2>/dev/null \
        || true)
    if [[ ! "$free_kib" =~ ^[0-9]+$ ]]; then
        echo "Refusing: could not read the free space on the volume holding $STATE_DIR. Set" \
            "COGNITO_CLIENT_INTEG_MIN_FREE_GIB=0 to skip this check." >&2
        exit 1
    fi
    if (( free_kib < minimum * 1024 * 1024 )); then
        echo "Refusing: only $((free_kib / 1024)) MiB free on the volume holding $STATE_DIR, under the" \
            "$minimum GiB minimum. With a full disk the AWS CLI itself crashes, part-way through a change. Free" \
            "some space, or set COGNITO_CLIENT_INTEG_MIN_FREE_GIB to another whole number of GiB (0 skips the" \
            "check)." >&2
        exit 1
    fi
}

# The credential types `aws configure list` reports for credentials the profile itself configures: keys in the shared
# credentials or config file, IAM Identity Center (sso), an `aws login` session, a credential_process, a role_arn it
# assumes (from a source_profile or a credential_source), and a role_arn it assumes with a web_identity_token_file.
# Each was set up in the profile, so it acts in the account the profile was made for. The rest (env, container-role,
# iam-role, ec2-credentials-file, boto-config) are what the CLI falls back to when the profile holds none.
PROFILE_CREDENTIAL_TYPES=(shared-credentials-file config-file sso login custom-process assume-role
    assume-role-with-web-identity)

# The type `aws configure list` reports for the access key of the profile AWS_PROFILE names: "None" when it resolves
# no credentials, "" when the command fails (a profile that does not exist, say). Reads the table of the CLI's current
# releases ("access_key : <value> : <type> : <location>") and of older ones (the same columns, spaces only). Prints a
# credential type, never a key; the CLI masks the key anyway.
credential_type() {
    local list line pattern='^[[:space:]]*access_key[[:space:]:]+[^[:space:]]+[[:space:]:]+([^[:space:]]+)'
    list=$(command aws configure list 2>/dev/null) || return 0
    while IFS= read -r line; do
        line="${line//<not set>/<not-set>}"
        if [[ "$line" =~ $pattern ]]; then
            printf '%s' "${BASH_REMATCH[1]}"
            return 0
        fi
    done <<<"$list"
}

# Exits if $STATE_DIR/state.json records an account other than the caller's, so a profile for
# another account can never act on this sandbox's recorded resources (or mint a second sandbox under
# the same state directory). Sets ACCOUNT, which is never printed. Run before any mutating call.
# With no account recorded yet (the first provision.sh), nothing else checks the account, so it also exits, before
# any call to an AWS service, unless AWS_PROFILE is set, none of the variables that give the CLI credentials of their
# own is exported, and the profile holds credentials of its own. The variables are AWS_ACCESS_KEY_ID,
# AWS_SECRET_ACCESS_KEY and AWS_SESSION_TOKEN (exported keys, which the CLI takes over every profile), AWS_ROLE_ARN and
# AWS_WEB_IDENTITY_TOKEN_FILE (a web identity role, common on CI runners and EKS, which it takes before the profile's
# own credentials), and any AWS_CONTAINER_CREDENTIALS_* (container credentials). The profile check reads `aws configure
# list`, which resolves the profile's credentials the way every other call does and makes no call to an AWS service
# (fetching an assumed role's, IAM Identity Center's or a login session's credentials aside), and accepts only
# PROFILE_CREDENTIAL_TYPES.
# A profile that holds none (only a region, say) would leave the CLI to fall back to an EC2 instance role, container
# credentials, AWS_CREDENTIAL_FILE or the boto files, and a first run would then build the sandbox in that account and
# record it. It does not check that the profile is the sandbox account's: the profile named is trusted to be.
require_recorded_account() {
    local recorded="" exported=() variable credentials_from reason
    if [[ -f "$STATE_DIR/state.json" ]]; then
        recorded=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('account',''))" "$STATE_DIR/state.json")
    fi
    if [[ -z "$recorded" && -z "${AWS_PROFILE:-}" ]]; then
        echo "Refusing: no account is recorded in $STATE_DIR/state.json yet. Set AWS_PROFILE to the sandbox" \
            "account's profile (see the integration README); a first run never uses the CLI's default credentials." >&2
        exit 1
    fi
    if [[ -z "$recorded" ]]; then
        # shellcheck disable=SC2046  # the variable names, one a word
        for variable in AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_ROLE_ARN \
            AWS_WEB_IDENTITY_TOKEN_FILE $(compgen -e | grep '^AWS_CONTAINER_CREDENTIALS_' || true); do
            [[ -z "${!variable:-}" ]] || exported+=("$variable")
        done
        if (( ${#exported[@]} > 0 )); then
            echo "Refusing: no account is recorded in $STATE_DIR/state.json yet, and the environment exports ${exported[*]}." \
                "The AWS CLI takes exported keys and a web identity role over the profile AWS_PROFILE names, and" \
                "container credentials whenever that profile holds no credentials of its own. Unset them for the" \
                "first run." >&2
            exit 1
        fi
        credentials_from=$(credential_type)
        if [[ " ${PROFILE_CREDENTIAL_TYPES[*]} " != *" ${credentials_from:-unknown} "* ]]; then
            case "$credentials_from" in
                "") reason="the CLI cannot resolve the profile's credentials (a missing profile, an expired sign-in)" ;;
                None) reason="the profile AWS_PROFILE names resolves no credentials" ;;
                *) reason="the profile AWS_PROFILE names takes its credentials from $credentials_from" ;;
            esac
            echo "Refusing: no account is recorded in $STATE_DIR/state.json yet, and $reason" \
                "(\`aws configure list\`). A first run uses only credentials the profile holds itself (keys, sso," \
                "login, credential_process or a role_arn): without them the CLI falls back to an EC2 instance role," \
                "container credentials or a legacy credentials file, and the run would build the sandbox in that" \
                "account." >&2
            exit 1
        fi
    fi
    ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
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
