#!/usr/bin/env bash
#
# Removes exactly the resources provision.sh created, as recorded in $STATE_DIR/state.json: first the
# plugin-parity resources (parity.py teardown: the six pools and their domain, the identity-only pool,
# the Lambdas and their log groups, the code sink API and table, the roles, the KMS key, which is
# scheduled for deletion in 7 days, and the SES identity), then the base user pool, identity pool
# and roles. Each is checked for the purpose=amplify-cognito-client-integ tag first and skipped if it
# lacks it, so this cannot delete anything it did not create. It prints names, never identifiers.
# Destructive: run it deliberately. Any failed deletion stops the script before state.json is removed
# (plain commands under `set -e`: a failing command inside `a && b` would not stop it).
#
# Usage: AWS_PROFILE=<sandbox-profile> ./teardown.sh
set -euo pipefail
INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$INFRA_DIR/lib.sh"
require_aws_profile
STATE="$STATE_DIR/state.json"
[[ -f "$STATE" ]] || { echo "No $STATE; nothing to tear down."; exit 0; }
get() { python3 -c "import json,sys;print(json.load(open(sys.argv[1]))[sys.argv[2]])" "$STATE" "$1"; }
REGION=$(get region); TAG="$TAG_VALUE"
aws() { command aws --region "$REGION" --output json "$@" 2> >(redact >&2); }

require_cli_history_off
require_recorded_account

# The plugin suites' configuration files point at these resources: put back what they replaced first.
# plugin-configs.py --remove exits non-zero if it had to leave a file (replaced or edited since), and
# then nothing is torn down.
# A manifest that exists but does not parse stops the teardown: it may list your backups.
MANIFEST="$STATE_DIR/plugin-configs-manifest.json"
if [[ -f "$MANIFEST" ]]; then
    written=$(python3 -c "import json,sys;print(len(json.load(open(sys.argv[1]))['written']))" "$MANIFEST") || {
        echo "Refusing: $MANIFEST exists but cannot be read; fix it (or run plugin-configs.py --remove) first." >&2
        exit 1
    }
    if [[ "$written" != "0" ]]; then
        python3 "$INFRA_DIR/plugin-configs.py" --remove
    fi
fi

# Prints resource's purpose tag (the rest of the arguments are the AWS CLI call that reads it), or
# "__gone__" when the resource no longer exists. Any other failure (throttling, an expired session, a
# denied call) returns 1: the caller stops, so state.json is never removed while a resource may remain.
read_tag() {
    local out status err
    err=$(mktemp)
    set +e
    out=$(command aws --region "$REGION" --output text "$@" 2>"$err")
    status=$?
    set -e
    if (( status != 0 )); then
        if grep -Eq "NotFound|NoSuchEntity" "$err"; then
            rm -f "$err"
            echo "__gone__"
            return 0
        fi
        redact < "$err" >&2
        rm -f "$err"
        echo "Refusing: could not read the tags; nothing more is deleted and state.json is kept." >&2
        return 1
    fi
    rm -f "$err"
    echo "$out"
}

if python3 -c "import json,sys;sys.exit(0 if json.load(open(sys.argv[1])).get('parity') else 1)" "$STATE"; then
    python3 "$INFRA_DIR/parity.py" teardown
fi

UP=$(get userPoolId); IP=$(get identityPoolId)
UP_ARN="arn:aws:cognito-idp:$REGION:$ACCOUNT:userpool/$UP"
tag=$(read_tag cognito-idp list-tags-for-resource --resource-arn "$UP_ARN" --query "Tags.purpose") || exit 1
if [[ "$tag" == "$TAG" ]]; then
    aws cognito-idp delete-user-pool --user-pool-id "$UP"
    echo "Deleted user pool $NAME"
elif [[ "$tag" == "__gone__" ]]; then echo "User pool $NAME is already gone"
else echo "Skipped user pool $NAME: tag missing"; fi

IP_ARN="arn:aws:cognito-identity:$REGION:$ACCOUNT:identitypool/$IP"
tag=$(read_tag cognito-identity list-tags-for-resource --resource-arn "$IP_ARN" --query "Tags.purpose") || exit 1
if [[ "$tag" == "$TAG" ]]; then
    aws cognito-identity delete-identity-pool --identity-pool-id "$IP"
    echo "Deleted identity pool ${NAME//-/_}"
elif [[ "$tag" == "__gone__" ]]; then echo "Identity pool ${NAME//-/_} is already gone"
else echo "Skipped identity pool ${NAME//-/_}: tag missing"; fi

for role in "$TAG-authenticated" "$TAG-unauthenticated"; do
    tag=$(read_tag iam list-role-tags --role-name "$role" --query "Tags[?Key=='purpose'].Value | [0]") || exit 1
    if [[ "$tag" == "$TAG" ]]; then
        aws iam delete-role --role-name "$role"
        echo "Deleted role $role"
    elif [[ "$tag" == "__gone__" ]]; then echo "Role $role is already gone"
    else echo "Skipped role $role: tag missing"; fi
done
rm -f "$STATE" "$STATE_DIR/amplify_outputs.json"
echo "Done. $STATE_DIR/users.json kept; delete it by hand if wanted."
if [[ -d "$STATE_DIR/plugin-configs-backup" ]]; then
    echo "$STATE_DIR/plugin-configs-backup holds copies of the files plugin-configs.py replaced (the owner's" \
        "originals): keep $STATE_DIR until you no longer need them."
fi
