#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Adds, beside the plugin's CI backends and never in place of them, the Cognito resources the client's
# integration tests need on CI and the plugin's backends do not have (README, "CI's additive resources"):
#
#   ccit-ci-email-alias   a device-alias pool (email as the username, devices always remembered, 5-minute tokens)
#                         whose pre-sign-up trigger confirms test sign-ups, with the code sink: DV-10…19 and the
#                         email-alias parity check
#   ccit-ci-default       a default pool as the sandbox's (infra/pools/default.json): custom-auth triggers,
#                         new-password users kept fresh by a scheduled Lambda, the code sink, a rotation client,
#                         and an identity pool with guest access: CA-1…3, CH-1, P-3, the fixture check, AT-2's
#                         second half, RP-3, RT-1 and RT-2
#
# Every resource is named ccit-ci-… (identity pool ccit_ci_default, parameters /ccit-ci/…) and tagged
# purpose=amplify-cognito-client-integ. The script finds them by name, creates only what is missing, refuses any
# resource with one of its names that lacks the tag, and never changes or deletes anything else: every mutating
# call goes through `mutate` (lib-ci.sh), which refuses a name that is not ccit-ci-. Codes go to a custom email
# and SMS sender, so Cognito sends no email and no SMS for these pools.
#
#   infra/ci/provision-ci.sh [--dry-run | --apply] [--upload] [--scope all|email-alias]
#       --dry-run (the default) reads the account and prints every call it would make, identifiers masked;
#       --apply makes them, then writes the client's configuration files into a new private directory (mode 600
#       files); --upload also uploads them to <config>/auth/cognito-client-ci/, refusing any key that exists.
#       --scope email-alias provisions only the device-alias pool and what it needs.
#   infra/ci/provision-ci.sh snapshot
#       read-only: hashes every existing resource the script must not touch into
#       $CCIT_CI_DISCOVERY_DIR/snapshot-<time>.json (default /tmp/ci-disc), mode 600
#   infra/ci/provision-ci.sh verify-unchanged <before.json> <after.json> [--allow-foreign-additions]
#       no AWS call: fails on any changed or removed resource, and on any added one that is not ccit-ci-
#   infra/ci/provision-ci.sh teardown [--dry-run | --apply]
#       deletes only the resources above, each after its tag check (the KMS key is scheduled for deletion in
#       7 days); a dry run by default
#
# Environment: COGNITO_CLIENT_INTEG_CI_CONFIG_URL, s3://<bucket>/<path>, the value of CI's AWS_S3_BUCKET_INTEG_V2
# (the folder that holds auth/); CCIT_CI_REGION, default us-east-1; the AWS credentials of the CI account.
# Nothing printed names an account, pool, client, key, bucket or secret. Needs the AWS CLI 2.26.7 or later, jq,
# python3, and for --apply node and npm (the custom sender's `npm ci`).
# shellcheck source-path=SCRIPTDIR
set -euo pipefail
CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA="$(cd "$CI_DIR/.." && pwd)"
# shellcheck source=../lib.sh
source "$INFRA/lib.sh"
# shellcheck source=lib-ci.sh
source "$CI_DIR/lib-ci.sh"

CI_REGION="${CCIT_CI_REGION:-us-east-1}"
CI_MODE="plan"
UPLOAD=0
SCOPE="all"
COMMAND="provision"
ALLOW_FOREIGN=0
POSITIONAL=()

usage() {
    sed -n '/^#   infra\/ci\/provision-ci.sh/,/^# Environment/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
    exit 2
}

while (( $# > 0 )); do
    case "$1" in
        --dry-run) CI_MODE="plan" ;;
        --apply) CI_MODE="apply" ;;
        --upload) UPLOAD=1 ;;
        --scope) [[ $# -ge 2 ]] || usage; SCOPE="$2"; shift ;;
        --allow-foreign-additions) ALLOW_FOREIGN=1 ;;
        snapshot|verify-unchanged|teardown) COMMAND="$1" ;;
        -h|--help) usage ;;
        -*) usage ;;
        *) POSITIONAL+=("$1") ;;
    esac
    shift
done
[[ "$SCOPE" == "all" || "$SCOPE" == "email-alias" ]] || usage
[[ "$CI_REGION" =~ ^[a-z]{2}-[a-z]+-[0-9]$ ]] || die "CCIT_CI_REGION is not a region."

if [[ "$COMMAND" == "verify-unchanged" ]]; then
    (( ${#POSITIONAL[@]} == 2 )) || usage
    args=(verify "${POSITIONAL[0]}" "${POSITIONAL[1]}")
    (( ALLOW_FOREIGN )) && args+=(--allow-foreign-additions)
    exec python3 "$CI_DIR/snapshot.py" "${args[@]}"
fi
(( ${#POSITIONAL[@]} == 0 )) || usage
if [[ "$COMMAND" != "provision" && "$UPLOAD" == 1 ]]; then
    usage
fi

for tool in jq python3 shasum zip; do
    command -v "$tool" >/dev/null || die "$tool is not on PATH."
done
command -v aws >/dev/null || die "the AWS CLI is not on PATH."

CI_WORK=$(mktemp -d "${TMPDIR:-/tmp}/ccit-ci-work.XXXXXX")
chmod 700 "$CI_WORK"
trap 'rm -rf "$CI_WORK"' EXIT

require_cli_history_off
require_cli_version
parse_config_url
require_caller

# --- Names ------------------------------------------------------------------------------------------------

POOL_KEYS=(email-alias)
[[ "$SCOPE" == "all" ]] && POOL_KEYS=(email-alias default)
ALL_POOL_KEYS=(email-alias default)
TRIGGERS_ALL=(pre-sign-up define-auth-challenge create-auth-challenge verify-auth-challenge)

pool_name() { printf '%s-%s' "$CI_PREFIX" "$1"; }
fn_name() { printf '%s-%s' "$CI_PREFIX" "$1"; }
role_name() { printf '%s-%s' "$CI_PREFIX" "$1"; }
fn_arn() { printf 'arn:aws:lambda:%s:%s:function:%s' "$CI_REGION" "$CI_ACCOUNT" "$(fn_name "$1")"; }
role_arn() { printf 'arn:aws:iam::%s:role/%s' "$CI_ACCOUNT" "$(role_name "$1")"; }
pool_arn() { printf 'arn:aws:cognito-idp:%s:%s:userpool/%s' "$CI_REGION" "$CI_ACCOUNT" "$1"; }
log_group() { printf '/aws/lambda/%s' "$(fn_name "$1")"; }
log_group_arn() { printf 'arn:aws:logs:%s:%s:log-group:%s' "$CI_REGION" "$CI_ACCOUNT" "$(log_group "$1")"; }
ssm_arn() { printf 'arn:aws:ssm:%s:%s:parameter%s' "$CI_REGION" "$CI_ACCOUNT" "$1"; }
new_id() { printf '<new %s>' "$1"; }
is_new() { [[ "$1" == "<new "* ]]; }
# What Cognito answers while the SMS role it was just given has not propagated yet.
SMS_ROLE_CODES="InvalidSmsRoleTrustRelationshipException InvalidSmsRoleAccessPolicyException"
TABLE="$(fn_name codes)"
API_NAME="$(fn_name codes)"
RULE="$(fn_name new-password-reset)"
S3_FOLDER_KEY="$CI_PREFIX_PATH/auth/$CI_S3_FOLDER"

# The functions in scope, with each one's handler, role and code.
functions_in_scope() {
    printf '%s\n' pre-sign-up custom-sender
    if [[ "$SCOPE" == "all" ]]; then
        printf '%s\n' define-auth-challenge create-auth-challenge verify-auth-challenge new-password-reset
    fi
}
fn_handler() {
    case "$1" in
        pre-sign-up) echo triggers.preSignUp ;;
        define-auth-challenge) echo triggers.defineAuthChallenge ;;
        create-auth-challenge) echo triggers.createAuthChallenge ;;
        verify-auth-challenge) echo triggers.verifyAuthChallenge ;;
        custom-sender|new-password-reset) echo index.handler ;;
    esac
}
fn_role() {
    case "$1" in
        custom-sender) echo sender-exec ;;
        new-password-reset) echo reset-exec ;;
        *) echo trigger-exec ;;
    esac
}
new_password_users() {
    local i
    for (( i = 1; i <= CI_NEW_PASSWORD_USER_COUNT; i++ )); do
        printf '%s-new-password-%d\n' "$CI_PREFIX" "$i"
    done
}

# --- State found or planned (ids are placeholders while a resource is only planned) ----------------------

# POOL_ID <pool key>, CLIENT_ID <pool key>/<client>, and what a dry run has planned for a role it will create
# (PLANNED_TRUST, PLANNED_POLICY <role>) are kept with kv_set and kv_get: bash 3.2, macOS's, has no associative
# arrays.
KMS_PLANNED_POLICY="" RESET_CREATED=0
KMS_KEY_ID="" KMS_KEY_ARN="" API_ID="" API_ARN="" API_URL="" API_KEY="" IDENTITY_POOL_ID=""
ANSWER="" TEMPORARY="" SMS_EXTERNAL_ID=""

# --- Read-only checks first -------------------------------------------------------------------------------

preflight() {
    local out roles quota apis pools identity rules sandbox
    read_aws out iam get-account-summary
    roles=$(jq -r '.SummaryMap.Roles' <<<"$out")
    quota=$(jq -r '.SummaryMap.RolesQuota' <<<"$out")
    read_aws out appsync list-graphql-apis
    apis=$(jq -r '.graphqlApis | length' <<<"$out")
    read_aws out cognito-idp list-user-pools --max-results 60
    pools=$(jq -r '.UserPools | length' <<<"$out")
    read_aws out cognito-identity list-identity-pools --max-results 60
    identity=$(jq -r '.IdentityPools | length' <<<"$out")
    read_aws out events list-rules
    rules=$(jq -r '.Rules | length' <<<"$out")
    read_aws out sns get-sms-sandbox-account-status
    sandbox=$(jq -r '.IsInSandbox' <<<"$out")
    say "Account headroom (read-only): IAM roles $roles of $quota, AppSync APIs $apis (default quota 25)," \
        "user pools $pools, identity pools $identity, EventBridge rules $rules; SNS in the SMS sandbox: $sandbox"
    (( quota - roles >= 50 )) || die "fewer than 50 IAM roles are left under the account's quota; this adds 7."
    (( apis <= 22 )) || die "$apis AppSync APIs exist; this adds one, and the default quota is 25. Raise it first."
    (( rules <= 250 )) || die "$rules EventBridge rules exist on the default bus; this adds one."
}

# --- Policies ---------------------------------------------------------------------------------------------

lambda_trust() {
    jq -n -c --arg a "$CI_ACCOUNT" '{Version: "2012-10-17", Statement: [{Effect: "Allow",
        Principal: {Service: "lambda.amazonaws.com"}, Action: "sts:AssumeRole",
        Condition: {StringEquals: {"aws:SourceAccount": $a}}}]}'
}

logs_statement() {
    local arns=() suffix
    for suffix in "$@"; do
        arns+=("$(log_group_arn "$suffix"):*")
    done
    printf '%s\n' "${arns[@]}" | jq -R . | jq -s -c '{Sid: "WriteOwnLogs", Effect: "Allow",
        Action: ["logs:CreateLogStream", "logs:PutLogEvents"], Resource: .}'
}

# The pool ARNs a policy names. `early` (before the pools are made): the existing ccit-ci- pools when every pool in
# scope exists, else none, which the policies read as the account's pools, by pattern, while one is about to be
# created. `final` (after): every ccit-ci- pool, a planned one included, so a dry run shows the narrowing too.
scoped_pool_arns() {
    local when="$1" key arns=()
    if [[ "$when" == "early" ]]; then
        for key in "${POOL_KEYS[@]}"; do
            if [[ -z "$(kv_get POOL_ID "$key")" ]] || is_new "$(kv_get POOL_ID "$key")"; then
                printf '[]'
                return
            fi
        done
    fi
    for key in "${ALL_POOL_KEYS[@]}"; do
        if [[ -n "$(kv_get POOL_ID "$key")" ]] && { [[ "$when" == "final" ]] || ! is_new "$(kv_get POOL_ID "$key")"; }; then
            arns+=("$(pool_arn "$(kv_get POOL_ID "$key")")")
        fi
    done
    (( ${#arns[@]} > 0 )) || { printf '[]'; return; }
    printf '%s\n' "${arns[@]}" | jq -R . | jq -s -c 'sort'
}

# The default pool's ARN, the only pool that names the SMS role, as `scoped_pool_arns` reads it: [] early while it
# is about to be created.
default_pool_arns() {
    local id
    id=$(kv_get POOL_ID default)
    if [[ -z "$id" ]] || { [[ "$1" == "early" ]] && is_new "$id"; }; then
        printf '[]'
        return
    fi
    jq -n -c --arg a "$(pool_arn "$id")" '[$a]'
}

kms_policy() {
    jq -n -c --arg a "$CI_ACCOUNT" --arg r "$CI_REGION" --argjson arns "$1" '
        (if ($arns | length) > 0 then {ArnEquals: {"aws:SourceArn": $arns}}
         else {ArnLike: {"aws:SourceArn": "arn:aws:cognito-idp:\($r):\($a):userpool/*"}} end) as $source
        | {Version: "2012-10-17", Id: "ccit-ci-senders", Statement: [
            {Sid: "AccountAdministration", Effect: "Allow", Principal: {AWS: "arn:aws:iam::\($a):root"},
             Action: "kms:*", Resource: "*"},
            {Sid: "CognitoEncryptsCodes", Effect: "Allow", Principal: {Service: "cognito-idp.amazonaws.com"},
             Action: ["kms:CreateGrant", "kms:Encrypt"], Resource: "*",
             Condition: ({StringEquals: {"aws:SourceAccount": $a}} + $source)}]}'
}

sender_policy() {
    local ids
    ids=$(jq -c 'map(split("/")[-1])' <<<"$1")
    jq -n -c --arg r "$CI_REGION" --arg key "$KMS_KEY_ARN" --arg api "$API_ARN" --argjson ids "$ids" \
        --argjson logs "$(logs_statement custom-sender)" '
        {Version: "2012-10-17", Statement: [$logs,
            {Sid: "DecryptCodes", Effect: "Allow", Action: "kms:Decrypt", Resource: $key,
             Condition: (if ($ids | length) > 0 then {StringEquals: {"kms:EncryptionContext:userpool-id": $ids}}
                         else {StringLike: {"kms:EncryptionContext:userpool-id": "\($r)_*"}} end)},
            {Sid: "PublishCodes", Effect: "Allow", Action: "appsync:GraphQL",
             Resource: "\($api)/types/Mutation/fields/createMfaInfo"}]}'
}

trigger_policy() {
    local suffixes=(pre-sign-up)
    [[ "$SCOPE" == "all" ]] && suffixes+=(define-auth-challenge create-auth-challenge verify-auth-challenge)
    jq -n -c --argjson logs "$(logs_statement "${suffixes[@]}")" '{Version: "2012-10-17", Statement: [$logs]}'
}

appsync_trust() {
    jq -n -c --arg a "$CI_ACCOUNT" --arg api "$API_ARN" '{Version: "2012-10-17", Statement: [{Effect: "Allow",
        Principal: {Service: "appsync.amazonaws.com"}, Action: "sts:AssumeRole",
        Condition: {StringEquals: {"aws:SourceAccount": $a}, ArnEquals: {"aws:SourceArn": $api}}}]}'
}

appsync_policy() {
    jq -n -c --arg t "arn:aws:dynamodb:$CI_REGION:$CI_ACCOUNT:table/$TABLE" '{Version: "2012-10-17", Statement: [{
        Sid: "CodesTable", Effect: "Allow", Action: ["dynamodb:PutItem", "dynamodb:Query"], Resource: $t}]}'
}

# Cognito's SNS caller role, as the plugin's Gen2 backends' (`sns:Publish` on `*`; Cognito refuses narrower).
# It never sends: every pool that names it has the custom SMS sender.
sms_trust() {
    jq -n -c --arg a "$CI_ACCOUNT" --arg r "$CI_REGION" --arg x "$SMS_EXTERNAL_ID" --argjson arns "$1" '
        (if ($arns | length) > 0 then {ArnEquals: {"aws:SourceArn": $arns}}
         else {ArnLike: {"aws:SourceArn": "arn:aws:cognito-idp:\($r):\($a):userpool/*"}} end) as $source
        | {Version: "2012-10-17", Statement: [{Effect: "Allow", Principal: {Service: "cognito-idp.amazonaws.com"},
           Action: "sts:AssumeRole",
           Condition: ({StringEquals: {"sts:ExternalId": $x, "aws:SourceAccount": $a}} + $source)}]}'
}

sms_policy() {
    jq -n -c '{Version: "2012-10-17", Statement: [{Sid: "CognitoSendsSms", Effect: "Allow", Action: "sns:Publish",
        Resource: "*"}]}'
}

reset_policy() {
    jq -n -c --arg pool "$(pool_arn "$(kv_get POOL_ID "default")")" --arg p "$(ssm_arn "$CI_SSM_TEMPORARY")" \
        --argjson logs "$(logs_statement new-password-reset)" '{Version: "2012-10-17", Statement: [$logs,
        {Sid: "ResetNewPasswordUsers", Effect: "Allow", Action: ["cognito-idp:AdminGetUser",
            "cognito-idp:AdminCreateUser", "cognito-idp:AdminDeleteUser", "cognito-idp:AdminSetUserPassword"],
         Resource: $pool},
        {Sid: "ReadTemporaryPassword", Effect: "Allow", Action: "ssm:GetParameter", Resource: $p}]}'
}

identity_trust() {
    jq -n -c --arg id "$IDENTITY_POOL_ID" --arg amr "$1" '{Version: "2012-10-17", Statement: [{Effect: "Allow",
        Principal: {Federated: "cognito-identity.amazonaws.com"}, Action: "sts:AssumeRoleWithWebIdentity",
        Condition: {StringEquals: {"cognito-identity.amazonaws.com:aud": $id},
                    "ForAnyValue:StringLike": {"cognito-identity.amazonaws.com:amr": $amr}}}]}'
}

same_json() {
    [[ "$(jq -S -c . <<<"$1")" == "$(jq -S -c . <<<"$2")" ]]
}

tags_json() {
    jq -n -c --arg k "$CI_TAG_KEY" --arg v "$CI_TAG_VALUE" '{($k): $v}'
}

# --- Log groups -------------------------------------------------------------------------------------------

ensure_log_group() {
    local name out group
    name=$(log_group "$1")
    read_aws out logs describe-log-groups --log-group-name-prefix "$name"
    group=$(jq -c --arg n "$name" '[.logGroups[] | select(.logGroupName == $n)][0] // empty' <<<"$out")
    if [[ -z "$group" ]]; then
        mutate "$name" "create log group $name" -- logs create-log-group --log-group-name "$name" \
            --tags "$CI_TAG_KEY=$CI_TAG_VALUE"
    else
        require_ours log-group "$name" "$name"
        say "  = log group $name"
    fi
    if [[ "$(jq -r '.retentionInDays // empty' <<<"${group:-null}")" != "7" ]]; then
        mutate "$name" "keep $name for 7 days" -- logs put-retention-policy --log-group-name "$name" \
            --retention-in-days 7
    fi
}

# --- KMS key ----------------------------------------------------------------------------------------------

ensure_kms_key() {
    local out key_id policy
    policy=$(kms_policy "$(scoped_pool_arns early)")
    read_aws out kms list-aliases
    key_id=$(jq -r --arg a "$CI_KMS_ALIAS" '[.Aliases[] | select(.AliasName == $a) | .TargetKeyId][0] // empty' <<<"$out")
    if [[ -z "$key_id" ]]; then
        mutate "$CI_KMS_ALIAS" "create the KMS key for the custom senders' codes" -- kms create-key \
            --description "ccit-ci: Cognito custom sender codes" --policy "file://$(input_file "$policy")" \
            --tags "TagKey=$CI_TAG_KEY,TagValue=$CI_TAG_VALUE"
        if [[ "$CI_MODE" == "apply" ]]; then
            KMS_KEY_ID=$(jq -r '.KeyMetadata.KeyId' <<<"$MUTATE_OUT")
            KMS_KEY_ARN=$(jq -r '.KeyMetadata.Arn' <<<"$MUTATE_OUT")
        else
            KMS_KEY_ID=$(new_id "kms key")
            KMS_KEY_ARN="arn:aws:kms:$CI_REGION:$CI_ACCOUNT:key/$KMS_KEY_ID"
            KMS_PLANNED_POLICY="$policy"
        fi
        mutate "$CI_KMS_ALIAS" "name it $CI_KMS_ALIAS" -- kms create-alias --alias-name "$CI_KMS_ALIAS" \
            --target-key-id "$KMS_KEY_ID"
        return
    fi
    KMS_KEY_ID="$key_id"
    require_ours kms "$KMS_KEY_ID" "$CI_KMS_ALIAS"
    read_aws out kms describe-key --key-id "$KMS_KEY_ID"
    [[ "$(jq -r '.KeyMetadata.KeyState' <<<"$out")" == "Enabled" ]] || die "the KMS key $CI_KMS_ALIAS is not enabled."
    KMS_KEY_ARN=$(jq -r '.KeyMetadata.Arn' <<<"$out")
    say "  = KMS key $CI_KMS_ALIAS"
    ensure_kms_policy "$policy"
}

ensure_kms_policy() {
    local out current
    if is_new "$KMS_KEY_ID"; then
        current="$KMS_PLANNED_POLICY"
    else
        read_aws out kms get-key-policy --key-id "$KMS_KEY_ID" --policy-name default
        current=$(jq -r '.Policy' <<<"$out")
    fi
    if ! same_json "$current" "$1"; then
        is_new "$KMS_KEY_ID" || require_ours kms "$KMS_KEY_ID" "$CI_KMS_ALIAS"
        KMS_PLANNED_POLICY="$1"
        mutate "$CI_KMS_ALIAS" "set the key policy of $CI_KMS_ALIAS to the ccit-ci- pools" -- kms put-key-policy \
            --key-id "$KMS_KEY_ID" --policy-name default --policy "file://$(input_file "$1")"
    fi
}

# --- DynamoDB table and AppSync API (the code sink) ------------------------------------------------------

ensure_table() {
    local out
    if read_aws_or_missing out ResourceNotFoundException dynamodb describe-table --table-name "$TABLE"; then
        require_ours table "$TABLE" "$TABLE"
        say "  = table $TABLE"
        read_aws out dynamodb describe-time-to-live --table-name "$TABLE"
        if [[ "$(jq -r '.TimeToLiveDescription.TimeToLiveStatus' <<<"$out")" =~ ^(ENABLED|ENABLING)$ ]]; then
            return
        fi
    else
        mutate "$TABLE" "create table $TABLE (on demand)" -- dynamodb create-table --table-name "$TABLE" \
            --billing-mode PAY_PER_REQUEST \
            --attribute-definitions AttributeName=username,AttributeType=S AttributeName=code,AttributeType=S \
            --key-schema AttributeName=username,KeyType=HASH AttributeName=code,KeyType=RANGE \
            --tags "Key=$CI_TAG_KEY,Value=$CI_TAG_VALUE"
        [[ "$CI_MODE" == "apply" ]] && read_aws out dynamodb wait table-exists --table-name "$TABLE"
    fi
    mutate "$TABLE" "expire $TABLE's items at expirationTime" -- dynamodb update-time-to-live --table-name "$TABLE" \
        --time-to-live-specification Enabled=true,AttributeName=expirationTime
}

ensure_api() {
    local out api input status i
    read_aws out appsync list-graphql-apis
    api=$(jq -c --arg n "$API_NAME" '[.graphqlApis[] | select(.name == $n)]' <<<"$out")
    (( $(jq 'length' <<<"$api") <= 1 )) || die "more than one AppSync API is named $API_NAME."
    api=$(jq -c '.[0] // empty' <<<"$api")
    if [[ -z "$api" ]]; then
        input=$(jq -n -c --arg n "$API_NAME" --argjson t "$(tags_json)" '{name: $n, authenticationType: "API_KEY",
            additionalAuthenticationProviders: [{authenticationType: "AWS_IAM"}], tags: $t}')
        mutate "$API_NAME" "create AppSync API $API_NAME (API key reads, IAM writes)" -- appsync create-graphql-api \
            --cli-input-json "file://$(input_file "$input")"
        if [[ "$CI_MODE" == "apply" ]]; then
            api=$(jq -c '.graphqlApi' <<<"$MUTATE_OUT")
        else
            API_ID=$(new_id "appsync api")
            API_ARN="arn:aws:appsync:$CI_REGION:$CI_ACCOUNT:apis/$API_ID"
            API_URL="https://<new>.appsync-api.$CI_REGION.amazonaws.com/graphql"
        fi
    fi
    if [[ -n "$api" ]]; then
        API_ID=$(jq -r '.apiId' <<<"$api")
        API_ARN=$(jq -r '.arn' <<<"$api")
        API_URL=$(jq -r '.uris.GRAPHQL' <<<"$api")
        require_ours appsync "$API_ARN" "$API_NAME"
        say "  = AppSync API $API_NAME"
    fi
    status="NOT_APPLICABLE"
    if ! is_new "$API_ID"; then
        read_aws out appsync get-schema-creation-status --api-id "$API_ID"
        status=$(jq -r '.status' <<<"$out")
    fi
    if [[ ! "$status" =~ ^(SUCCESS|ACTIVE|PROCESSING)$ ]]; then
        mutate "$API_NAME" "apply the code sink schema (codesink/schema.graphql)" -- appsync start-schema-creation \
            --api-id "$API_ID" --definition "fileb://$INFRA/codesink/schema.graphql"
    fi
    if [[ "$CI_MODE" == "apply" ]]; then
        for (( i = 0; i < 60; i++ )); do
            read_aws out appsync get-schema-creation-status --api-id "$API_ID"
            status=$(jq -r '.status' <<<"$out")
            [[ "$status" =~ ^(SUCCESS|ACTIVE)$ ]] && return
            [[ "$status" == "FAILED" ]] && die "the code sink schema failed to apply."
            sleep 2
        done
        die "the code sink schema did not finish applying."
    fi
}

ensure_api_resolvers() {
    local out input type field request response spec
    if is_new "$API_ID" || ! read_aws_or_missing out NotFoundException appsync get-data-source --api-id "$API_ID" \
        --name MfaInfoTable; then
        input=$(jq -n -c --arg id "$API_ID" --arg role "$(role_arn appsync-codes)" --arg t "$TABLE" --arg r "$CI_REGION" \
            '{apiId: $id, name: "MfaInfoTable", type: "AMAZON_DYNAMODB", serviceRoleArn: $role,
              dynamodbConfig: {tableName: $t, awsRegion: $r}}')
        mutate_with_retry 15 4 "AccessDeniedException BadRequestException" "$API_NAME" "add the code table as the API's data source" -- appsync create-data-source \
            --cli-input-json "file://$(input_file "$input")"
    fi
    for spec in "Mutation createMfaInfo createMfaInfo.request.vtl item.response.vtl" \
        "Query listMfaInfo listMfaInfo.request.vtl items.response.vtl"; do
        read -r type field request response <<<"$spec"
        if ! is_new "$API_ID" && read_aws_or_missing out NotFoundException appsync get-resolver --api-id "$API_ID" \
            --type-name "$type" --field-name "$field"; then
            continue
        fi
        input=$(jq -n -c --arg id "$API_ID" --arg t "$type" --arg f "$field" \
            --rawfile req "$INFRA/codesink/$request" --rawfile res "$INFRA/codesink/$response" \
            '{apiId: $id, typeName: $t, fieldName: $f, kind: "UNIT", dataSourceName: "MfaInfoTable",
              requestMappingTemplate: $req, responseMappingTemplate: $res}')
        mutate "$API_NAME" "add the $type.$field resolver" -- appsync create-resolver \
            --cli-input-json "file://$(input_file "$input")"
    done
}

# The tests' read-only API key: one that lives at least 30 more days is reused, else a new one, for 364 days.
ensure_api_key() {
    local out now expires
    now=$(date +%s)
    if ! is_new "$API_ID"; then
        read_aws out appsync list-api-keys --api-id "$API_ID"
        API_KEY=$(jq -r --argjson soon "$((now + 30 * 86400))" \
            '[.apiKeys[] | select(.description == "ccit-ci tests" and .expires > $soon)] | sort_by(.expires) | last | .id // empty' <<<"$out")
        if [[ -n "$API_KEY" ]]; then
            say "  = the code sink API key (lives at least 30 more days)"
            return
        fi
    fi
    expires=$((now + 364 * 86400))
    mutate "$API_NAME" "create the tests' read-only API key, for 364 days" -- appsync create-api-key \
        --api-id "$API_ID" --description "ccit-ci tests" --expires "$expires"
    if [[ "$CI_MODE" == "apply" ]]; then
        API_KEY=$(jq -r '.apiKey.id' <<<"$MUTATE_OUT")
    else
        API_KEY=$(new_id "api key")
    fi
}

# --- IAM roles --------------------------------------------------------------------------------------------

# Ensures role $1 (a suffix) with trust $2 and, unless $3 is empty, exactly one inline policy $3; a role that has
# any other policy is refused.
ensure_role() {
    local suffix="$1" trust="$2" policy="$3" role out attached inline input
    role=$(role_name "$suffix")
    if [[ -n "$(kv_get PLANNED_TRUST "$role")" ]]; then
        # Planned in this dry run: compare with what was planned.
        if ! same_json "$(kv_get PLANNED_TRUST "$role")" "$trust"; then
            mutate "$role" "set the trust of $role" -- iam update-assume-role-policy --role-name "$role" \
                --policy-document "file://$(input_file "$trust")"
            kv_set PLANNED_TRUST "$role" "$trust"
        fi
        if [[ -n "$policy" ]] && ! same_json "$(kv_get PLANNED_POLICY "$role" null)" "$policy"; then
            put_role_policy "$role" "$policy"
        fi
        return 0
    fi
    if read_aws_or_missing out NoSuchEntity iam get-role --role-name "$role"; then
        require_ours role "$role" "$role"
        say "  = role $role"
        if ! same_json "$(jq -c '.Role.AssumeRolePolicyDocument' <<<"$out")" "$trust"; then
            mutate "$role" "set the trust of $role" -- iam update-assume-role-policy --role-name "$role" \
                --policy-document "file://$(input_file "$trust")"
        fi
        read_aws out iam list-attached-role-policies --role-name "$role"
        attached=$(jq -r '.AttachedPolicies | length' <<<"$out")
        read_aws out iam list-role-policies --role-name "$role"
        inline=$(jq -r --arg p "$role-policy" '[.PolicyNames[] | select(. != $p)] | length' <<<"$out")
        (( attached == 0 && inline == 0 )) || die "role $role carries a policy this script did not put there."
        if [[ -z "$policy" ]]; then
            [[ "$(jq -r '.PolicyNames | length' <<<"$out")" == 0 ]] || die "role $role must have no policy."
            return 0
        fi
        if read_aws_or_missing out NoSuchEntity iam get-role-policy --role-name "$role" --policy-name "$role-policy" \
            && same_json "$(jq -c '.PolicyDocument' <<<"$out")" "$policy"; then
            return 0
        fi
    else
        input=$(jq -n -c --arg n "$role" --arg t "$trust" --arg k "$CI_TAG_KEY" --arg v "$CI_TAG_VALUE" \
            '{RoleName: $n, AssumeRolePolicyDocument: $t, Description: "ccit-ci: Cognito client CI resources",
              Tags: [{Key: $k, Value: $v}]}')
        mutate "$role" "create role $role" -- iam create-role --cli-input-json "file://$(input_file "$input")"
        [[ "$CI_MODE" == "apply" ]] || kv_set PLANNED_TRUST "$role" "$trust"
        [[ -n "$policy" ]] || return 0
    fi
    put_role_policy "$role" "$policy"
}

put_role_policy() {
    local role="$1" policy="$2" input
    input=$(jq -n -c --arg n "$role" --arg d "$policy" '{RoleName: $n, PolicyName: "\($n)-policy", PolicyDocument: $d}')
    mutate "$role" "set the one inline policy of $role" -- iam put-role-policy \
        --cli-input-json "file://$(input_file "$input")"
    [[ "$CI_MODE" == "apply" ]] || kv_set PLANNED_POLICY "$role" "$policy"
}

ensure_sms_external_id() {
    local out
    if read_aws_or_missing out NoSuchEntity iam get-role --role-name "$(role_name cognito-sms)"; then
        SMS_EXTERNAL_ID=$(jq -r '.Role.AssumeRolePolicyDocument.Statement[0].Condition.StringEquals["sts:ExternalId"] // empty' <<<"$out")
        [[ -n "$SMS_EXTERNAL_ID" ]] || die "role $(role_name cognito-sms) has no external id in its trust."
    else
        SMS_EXTERNAL_ID=$(openssl rand -hex 16)
    fi
}

# --- Secrets (SSM SecureString parameters, the account itself as the script's state) ---------------------

# Sets the variable named $1 to parameter $2's value, creating it from command $3 when missing.
ensure_secret() {
    local var="$1" name="$2" generator="$3" out value input
    if read_aws_or_missing out ParameterNotFound ssm get-parameter --name "$name"; then
        require_ours ssm "$name" "$name"
        read_aws out ssm get-parameter --name "$name" --with-decryption
        value=$(jq -r '.Parameter.Value' <<<"$out")
        say "  = parameter $name"
    else
        if [[ "$CI_MODE" == "apply" ]]; then
            value=$($generator)
        else
            value=$(new_id "secret")
        fi
        input=$(jq -n -c --arg n "$name" --arg v "$value" --arg k "$CI_TAG_KEY" --arg t "$CI_TAG_VALUE" \
            '{Name: $n, Value: $v, Type: "SecureString", Description: "ccit-ci: Cognito client CI resources",
              Tags: [{Key: $k, Value: $t}]}')
        mutate "$name" "store $name (SecureString)" -- ssm put-parameter --cli-input-json "file://$(input_file "$input")"
    fi
    printf -v "$var" '%s' "$value"
}

generate_answer() {
    openssl rand -base64 24 | tr -d '\n/+='
}

generate_temporary() {
    printf 'Tt1!%s' "$(openssl rand -hex 16)"
}

# --- Lambdas ----------------------------------------------------------------------------------------------

# The zip for function $1 into $CI_WORK, built once per code: the sandbox's triggers.mjs, the sandbox's custom
# sender (npm ci), or this directory's new-password reset.
zip_for() {
    local suffix="$1" zip build
    case "$suffix" in
        custom-sender) zip="$CI_WORK/custom-sender.zip" ;;
        new-password-reset) zip="$CI_WORK/new-password-reset.zip" ;;
        *) zip="$CI_WORK/triggers.zip" ;;
    esac
    if [[ ! -f "$zip" && "$CI_MODE" == "apply" ]]; then
        case "$suffix" in
            custom-sender)
                command -v npm >/dev/null || die "npm is not on PATH; the custom sender needs npm ci."
                build="$CI_WORK/custom-sender"
                mkdir -p "$build"
                cp "$INFRA"/lambda/custom-sender/{index.mjs,package.json,package-lock.json} "$build/"
                (cd "$build" && npm ci --omit=dev --ignore-scripts --no-audit --no-fund >/dev/null 2>&1) \
                    || die "npm ci for the custom sender failed."
                (cd "$build" && rm -f node_modules/.package-lock.json && zip -q -X -r "$zip" index.mjs package.json node_modules)
                ;;
            new-password-reset)
                (cd "$CI_DIR/lambda/new-password-reset" && zip -q -X "$zip" index.mjs) ;;
            *)
                (cd "$INFRA/lambda/triggers" && zip -q -X "$zip" triggers.mjs) ;;
        esac
    fi
    printf '%s' "$zip"
}

fn_environment() {
    case "$1" in
        create-auth-challenge)
            jq -n -c --arg s "$(printf '%s' "$ANSWER" | shasum -a 256 | cut -d' ' -f1)" \
                '{CUSTOM_CHALLENGE_ANSWER_SHA256: $s}' ;;
        custom-sender)
            jq -n -c --arg k "$KMS_KEY_ARN" --arg u "$API_URL" '{KMS_KEY_ARN: $k, GRAPHQL_API_ENDPOINT: $u}' ;;
        new-password-reset)
            jq -n -c --arg p "$(kv_get POOL_ID "default")" --arg u "$(new_password_users | paste -sd, -)" \
                --arg t "$CI_SSM_TEMPORARY" '{POOL_ID: $p, USERNAMES: $u, TEMP_PASSWORD_PARAMETER: $t,
                    USED_AFTER_MINUTES: "60", REFRESH_AFTER_DAYS: "10"}' ;;
        *) printf '{}' ;;
    esac
}

ensure_function() {
    local suffix="$1" name out input timeout=10 memory=128 environment
    name=$(fn_name "$suffix")
    environment=$(fn_environment "$suffix")
    if read_aws_or_missing out ResourceNotFoundException lambda get-function-configuration --function-name "$name"; then
        require_ours lambda "$name" "$name"
        say "  = Lambda $name"
        if [[ "$suffix" == "create-auth-challenge" ]] && ! is_new "$ANSWER" \
            && ! same_json "$(jq -c '.Environment.Variables // {}' <<<"$out")" "$environment"; then
            die "Lambda $name holds another custom-challenge answer's hash than $CI_SSM_ANSWER: the two disagree."
        fi
        return
    fi
    [[ "$suffix" == "custom-sender" ]] && memory=256
    [[ "$suffix" == "new-password-reset" ]] && timeout=60
    input=$(jq -n -c --arg n "$name" --arg role "$(role_arn "$(fn_role "$suffix")")" --arg h "$(fn_handler "$suffix")" \
        --argjson t "$timeout" --argjson m "$memory" --argjson e "$environment" --argjson tags "$(tags_json)" \
        '{FunctionName: $n, Role: $role, Handler: $h, Runtime: "nodejs22.x", Timeout: $t, MemorySize: $m,
          Architectures: ["arm64"], Environment: {Variables: $e}, Tags: $tags,
          Description: "ccit-ci: Cognito client CI resources"}')
    mutate_with_retry 15 4 "InvalidParameterValueException" "$name" "create Lambda $name (Node.js 22, no reserved concurrency)" -- lambda create-function \
        --zip-file "fileb://$(zip_for "$suffix")" --cli-input-json "file://$(input_file "$input")"
    [[ "$CI_MODE" == "apply" ]] && read_aws out lambda wait function-active-v2 --function-name "$name"
    [[ "$suffix" == "new-password-reset" ]] && RESET_CREATED=1
    return 0
}

# Lets $3 (a service principal) invoke function $1, for source ARN $4 only, as statement $2.
ensure_invoke_permission() {
    local suffix="$1" sid="$2" principal="$3" source="$4" name out
    name=$(fn_name "$suffix")
    if read_aws_or_missing out ResourceNotFoundException lambda get-policy --function-name "$name" \
        && jq -e --arg s "$sid" '.Policy | fromjson | .Statement[] | select(.Sid == $s)' <<<"$out" >/dev/null; then
        return
    fi
    mutate "$name" "let $principal invoke $name ($sid)" -- lambda add-permission --function-name "$name" \
        --statement-id "$sid" --action lambda:InvokeFunction --principal "$principal" --source-arn "$source" \
        --source-account "$CI_ACCOUNT"
}

# --- User pools -------------------------------------------------------------------------------------------

# The pool template's userPool, with the placeholders filled in and this script's checks applied.
pool_definition() {
    local key="$1" variables
    variables=$(jq -n -c --arg pre "$(fn_arn pre-sign-up)" --arg def "$(fn_arn define-auth-challenge)" \
        --arg cre "$(fn_arn create-auth-challenge)" --arg ver "$(fn_arn verify-auth-challenge)" \
        --arg snd "$(fn_arn custom-sender)" --arg kms "$KMS_KEY_ARN" --arg sms "$(role_arn cognito-sms)" \
        --arg ext "$SMS_EXTERNAL_ID" --arg r "$CI_REGION" \
        '{PRE_SIGN_UP_ARN: $pre, DEFINE_AUTH_CHALLENGE_ARN: $def, CREATE_AUTH_CHALLENGE_ARN: $cre,
          VERIFY_AUTH_CHALLENGE_ARN: $ver, CUSTOM_SENDER_ARN: $snd, KMS_KEY_ARN: $kms, SMS_ROLE_ARN: $sms,
          SMS_EXTERNAL_ID: $ext, SMS_REGION: $r}')
    jq -c --argjson v "$variables" 'walk(if type == "string"
        then gsub("\\$\\{(?<name>[A-Z_]+)\\}"; $v[.name] // error("unknown placeholder \(.name)")) else . end)' \
        "$INFRA/pools/$key.json"
}

ensure_pool() {
    local key="$1" name template pool out ids input lambda mfa desired_mfa client client_name spec
    name=$(pool_name "$key")
    template=$(pool_definition "$key")
    pool=$(jq -c '.userPool' <<<"$template")
    # Nothing is ever sent: both custom senders and the key, whenever the pool could send email or SMS.
    jq -e '.LambdaConfig.CustomEmailSender.LambdaArn and .LambdaConfig.CustomSMSSender.LambdaArn
        and .LambdaConfig.KMSKeyID and (.AdminCreateUserConfig.AllowAdminCreateUserOnly == false)' <<<"$pool" >/dev/null \
        || die "pools/$key.json must name both custom senders and the KMS key."
    read_aws out cognito-idp list-user-pools --max-results 60
    ids=$(jq -c --arg n "$name" '[.UserPools[] | select(.Name == $n) | .Id]' <<<"$out")
    (( $(jq 'length' <<<"$ids") <= 1 )) || die "more than one user pool is named $name."
    kv_set POOL_ID "$key" "$(jq -r '.[0] // empty' <<<"$ids")"
    if [[ -n "$(kv_get POOL_ID "$key")" ]]; then
        require_ours user-pool "$(kv_get POOL_ID "$key")" "$name"
        say "  = user pool $name"
    else
        input=$(jq -c --arg n "$name" --argjson t "$(tags_json)" '. + {PoolName: $n, UserPoolTags: $t}' <<<"$pool")
        mutate_with_retry 18 10 "$SMS_ROLE_CODES" "$name" "create user pool $name (pools/$key.json, self sign-up on, custom senders)" -- \
            cognito-idp create-user-pool --cli-input-json "file://$(input_file "$input")"
        if [[ "$CI_MODE" == "apply" ]]; then
            kv_set POOL_ID "$key" "$(jq -r '.UserPool.Id' <<<"$MUTATE_OUT")"
        else
            kv_set POOL_ID "$key" "$(new_id "user pool $name")"
        fi
    fi

    for lambda in $(jq -r '.LambdaConfig | .. | strings | select(startswith("arn:aws:lambda:"))' <<<"$pool" | sort -u); do
        ensure_invoke_permission "${lambda##*:function:"$CI_PREFIX"-}" "cognito-$key" cognito-idp.amazonaws.com \
            "$(pool_arn "$(kv_get POOL_ID "$key")")"
    done

    desired_mfa=$(jq -c '.mfa' <<<"$template")
    # A new pool's MFA is off until it is set.
    mfa="OFF"
    if ! is_new "$(kv_get POOL_ID "$key")"; then
        read_aws out cognito-idp get-user-pool-mfa-config --user-pool-id "$(kv_get POOL_ID "$key")"
        mfa=$(jq -r '.MfaConfiguration' <<<"$out")
    fi
    if [[ "$mfa" != "$(jq -r '.MfaConfiguration' <<<"$desired_mfa")" ]]; then
        is_new "$(kv_get POOL_ID "$key")" || require_ours user-pool "$(kv_get POOL_ID "$key")" "$name"
        input=$(jq -c --arg id "$(kv_get POOL_ID "$key")" '. + {UserPoolId: $id}' <<<"$desired_mfa")
        mutate_with_retry 18 10 "$SMS_ROLE_CODES" "$name" "set the MFA configuration of $name" -- cognito-idp set-user-pool-mfa-config \
            --cli-input-json "file://$(input_file "$input")"
    fi

    out='{"UserPoolClients": []}'
    if ! is_new "$(kv_get POOL_ID "$key")"; then
        read_aws out cognito-idp list-user-pool-clients --user-pool-id "$(kv_get POOL_ID "$key")" --max-results 60
    fi
    for client in $(pool_clients "$key"); do
        client_name="$name-$client"
        kv_set CLIENT_ID "$key/$client" "$(jq -r --arg n "$client_name" '[.UserPoolClients[] | select(.ClientName == $n) | .ClientId][0] // empty' <<<"$out")"
        if [[ -n "$(kv_get CLIENT_ID "$key/$client")" ]]; then
            say "  = app client $client_name"
            continue
        fi
        spec=$(jq -c --arg c "$client" --arg n "$client_name" --arg id "$(kv_get POOL_ID "$key")" \
            '.appClients[$c] + {ClientName: $n, UserPoolId: $id, GenerateSecret: false}' <<<"$template")
        is_new "$(kv_get POOL_ID "$key")" || require_ours user-pool "$(kv_get POOL_ID "$key")" "$name"
        mutate "$client_name" "create app client $client_name (public, pools/$key.json \`$client\`)" -- \
            cognito-idp create-user-pool-client --cli-input-json "file://$(input_file "$spec")"
        if [[ "$CI_MODE" == "apply" ]]; then
            kv_set CLIENT_ID "$key/$client" "$(jq -r '.UserPoolClient.ClientId' <<<"$MUTATE_OUT")"
        else
            kv_set CLIENT_ID "$key/$client" "$(new_id "app client $client_name")"
        fi
    done
}

# The app clients each pool gets: the one its outputs name, and on default the rotation client.
pool_clients() {
    case "$1" in
        default) echo plugin rotation ;;
        email-alias) echo client ;;
    esac
}

# --- Identity pool (default) ------------------------------------------------------------------------------

ensure_identity_pool() {
    local out input providers current auth unauth
    providers=$(jq -n -c --arg p "cognito-idp.$CI_REGION.amazonaws.com/$(kv_get POOL_ID "default")" \
        --arg c "$(kv_get CLIENT_ID "default/plugin")" '[{ProviderName: $p, ClientId: $c, ServerSideTokenCheck: false}]')
    read_aws out cognito-identity list-identity-pools --max-results 60
    IDENTITY_POOL_ID=$(jq -r --arg n "$CI_IDENTITY_POOL" '[.IdentityPools[] | select(.IdentityPoolName == $n) | .IdentityPoolId]
        | if length > 1 then error("more than one") else .[0] // empty end' <<<"$out") \
        || die "more than one identity pool is named $CI_IDENTITY_POOL."
    if [[ -n "$IDENTITY_POOL_ID" ]]; then
        require_ours identity-pool "$IDENTITY_POOL_ID" "$CI_IDENTITY_POOL"
        read_aws out cognito-identity describe-identity-pool --identity-pool-id "$IDENTITY_POOL_ID"
        current=$(jq -c '[.CognitoIdentityProviders[]? | {ProviderName, ClientId, ServerSideTokenCheck: (.ServerSideTokenCheck // false)}]' <<<"$out")
        same_json "$current" "$providers" && [[ "$(jq -r '.AllowUnauthenticatedIdentities' <<<"$out")" == "true" ]] \
            || die "identity pool $CI_IDENTITY_POOL does not federate $(pool_name default)'s plugin client with guest access."
        say "  = identity pool $CI_IDENTITY_POOL"
    else
        input=$(jq -n -c --arg n "$CI_IDENTITY_POOL" --argjson p "$providers" --argjson t "$(tags_json)" \
            '{IdentityPoolName: $n, AllowUnauthenticatedIdentities: true, CognitoIdentityProviders: $p,
              IdentityPoolTags: $t}')
        mutate "$CI_IDENTITY_POOL" "create identity pool $CI_IDENTITY_POOL (guest access, $(pool_name default))" -- \
            cognito-identity create-identity-pool --cli-input-json "file://$(input_file "$input")"
        if [[ "$CI_MODE" == "apply" ]]; then
            IDENTITY_POOL_ID=$(jq -r '.IdentityPoolId' <<<"$MUTATE_OUT")
        else
            IDENTITY_POOL_ID=$(new_id "identity pool")
        fi
    fi
    ensure_role identity-authenticated "$(identity_trust authenticated)" ""
    ensure_role identity-unauthenticated "$(identity_trust unauthenticated)" ""
    auth=$(role_arn identity-authenticated)
    unauth=$(role_arn identity-unauthenticated)
    if ! is_new "$IDENTITY_POOL_ID"; then
        read_aws out cognito-identity get-identity-pool-roles --identity-pool-id "$IDENTITY_POOL_ID"
        if [[ "$(jq -r '.Roles.authenticated // ""' <<<"$out") $(jq -r '.Roles.unauthenticated // ""' <<<"$out")" == "$auth $unauth" ]]; then
            return
        fi
        require_ours identity-pool "$IDENTITY_POOL_ID" "$CI_IDENTITY_POOL"
    fi
    input=$(jq -n -c --arg id "$IDENTITY_POOL_ID" --arg a "$auth" --arg u "$unauth" \
        '{IdentityPoolId: $id, Roles: {authenticated: $a, unauthenticated: $u}}')
    mutate_with_retry 15 4 "InvalidParameterException" "$CI_IDENTITY_POOL" "give $CI_IDENTITY_POOL its two permissionless roles" -- \
        cognito-identity set-identity-pool-roles --cli-input-json "file://$(input_file "$input")"
}

# --- New-password users (default) -------------------------------------------------------------------------

ensure_reset_schedule() {
    local out rule_arn target fn
    fn=$(fn_name new-password-reset)
    rule_arn="arn:aws:events:$CI_REGION:$CI_ACCOUNT:rule/$RULE"
    if read_aws_or_missing out ResourceNotFoundException events describe-rule --name "$RULE"; then
        require_ours rule "$RULE" "$RULE"
        say "  = schedule $RULE"
    else
        mutate "$RULE" "schedule $fn every 10 minutes" -- events put-rule --name "$RULE" \
            --schedule-expression "rate(10 minutes)" --state ENABLED \
            --description "ccit-ci: keeps the new-password users fresh" --tags "Key=$CI_TAG_KEY,Value=$CI_TAG_VALUE"
    fi
    ensure_invoke_permission new-password-reset events-schedule events.amazonaws.com "$rule_arn"
    target=""
    if read_aws_or_missing out ResourceNotFoundException events list-targets-by-rule --rule "$RULE"; then
        target=$(jq -r --arg a "$(fn_arn new-password-reset)" '[.Targets[] | select(.Arn == $a)][0].Id // empty' <<<"$out")
    fi
    if [[ -z "$target" ]]; then
        mutate "$RULE" "point the schedule at Lambda $fn" -- events put-targets --rule "$RULE" \
            --targets "Id=new-password-reset,Arn=$(fn_arn new-password-reset)"
    fi
}

# Creates (or resets) the users now, so they exist before the first run: one invocation of the reset.
run_reset_once() {
    local fn out
    fn=$(fn_name new-password-reset)
    if (( RESET_CREATED == 0 )); then
        say "  = $fn exists; its schedule keeps the users fresh"
        return 0
    fi
    out="$CI_WORK/reset-result.json"
    mutate "$fn" "run $fn once, so the ${CI_NEW_PASSWORD_USER_COUNT} new-password users exist" -- lambda invoke \
        --function-name "$fn" --cli-binary-format raw-in-base64-out --payload '{}' "$out"
    if [[ "$CI_MODE" == "apply" ]]; then
        [[ "$(jq -r '.FunctionError // empty' <<<"$MUTATE_OUT")" == "" ]] || die "$fn failed; see its log group."
        say "    new-password users: $(jq -r 'to_entries | group_by(.value) | map("\(.[0].value) \(length)") | join(", ")' "$out")"
    fi
}

# --- The client's configuration files ---------------------------------------------------------------------

outputs_document() {
    local key="$1" client="$2"
    jq -c --arg r "$CI_REGION" --arg p "$(kv_get POOL_ID "$key")" --arg c "$(kv_get CLIENT_ID "$key/$client")" '
        .userPool as $u | .mfa as $m
        | {version: "1.4", auth: {aws_region: $r, user_pool_id: $p, user_pool_client_id: $c,
            username_attributes: ($u.UsernameAttributes // []), user_verification_types: ($u.AutoVerifiedAttributes // []),
            mfa_configuration: ({"OFF": "NONE", "OPTIONAL": "OPTIONAL", "ON": "REQUIRED"}[$m.MfaConfiguration]),
            mfa_methods: ([if $m.SmsMfaConfiguration then "SMS" else empty end,
                           if $m.SoftwareTokenMfaConfiguration.Enabled then "TOTP" else empty end,
                           if $m.EmailMfaConfiguration then "EMAIL" else empty end]),
            password_policy: ($u.Policies.PasswordPolicy | {min_length: .MinimumLength,
                require_lowercase: .RequireLowercase, require_uppercase: .RequireUppercase,
                require_numbers: .RequireNumbers, require_symbols: .RequireSymbols}),
            unauthenticated_identities_enabled: false}}' "$INFRA/pools/$key.json"
}

with_code_sink() {
    jq -c --arg r "$CI_REGION" --arg u "$API_URL" --arg k "$API_KEY" '. + {data: {aws_region: $r, url: $u, api_key: $k,
        default_authorization_type: "API_KEY", authorization_types: []}}'
}

write_private_json() {
    (umask 077 && jq -S . > "$1")
    chmod 600 "$1"
}

# Writes the files the client's CI jobs read (ci-overlay.sh maps them to the plugin's names, in a directory of
# their own) into $CONFIG_DIR. Never a plugin file name.
write_config() {
    CONFIG_DIR=$(mktemp -d "${TMPDIR:-/tmp}/ccit-ci-config.XXXXXX")
    chmod 700 "$CONFIG_DIR"
    outputs_document email-alias client | with_code_sink | write_private_json "$CONFIG_DIR/ccit-ci-email-alias-amplify_outputs.json"
    if [[ "$SCOPE" == "all" ]]; then
        outputs_document default plugin | with_code_sink \
            | jq -c --arg id "$IDENTITY_POOL_ID" '.auth += {identity_pool_id: $id, unauthenticated_identities_enabled: true}' \
            | write_private_json "$CONFIG_DIR/ccit-ci-default-amplify_outputs.json"
        outputs_document default rotation | write_private_json "$CONFIG_DIR/ccit-ci-rotation-amplify_outputs.json"
        jq -n --arg a "$ANSWER" --arg u "$(new_password_users | paste -sd, -)" --arg t "$TEMPORARY" \
            '{custom_challenge_answer: $a, new_password_required_usernames: $u, new_password_required_temporary_password: $t}' \
            | write_private_json "$CONFIG_DIR/ccit-ci-default-credentials.json"
    fi
    say "Wrote the client's CI configuration (mode 600) into $CONFIG_DIR:"
    find "$CONFIG_DIR" -type f -exec basename {} \; | sort | sed 's/^/  /'
}

config_files() {
    printf '%s\n' ccit-ci-email-alias-amplify_outputs.json
    if [[ "$SCOPE" == "all" ]]; then
        printf '%s\n' ccit-ci-default-amplify_outputs.json ccit-ci-rotation-amplify_outputs.json ccit-ci-default-credentials.json
    fi
}

# Uploads every file to <config>/auth/cognito-client-ci/, a folder no plugin test reads, only when none of the
# keys exists (checked first, then again by S3 itself with If-None-Match), tagged.
upload_config() {
    local file key out existing=0
    for file in $(config_files); do
        key="$S3_FOLDER_KEY/$file"
        if read_aws_or_missing out "404 NoSuchKey NotFound" s3api head-object --bucket "$CI_BUCKET" --key "$key"; then
            say "  ! s3://<bucket>/…/auth/$CI_S3_FOLDER/$file exists"
            existing=1
        fi
    done
    (( existing == 0 )) || die "a key already exists under auth/$CI_S3_FOLDER/; nothing was uploaded, and nothing is ever overwritten."
    for file in $(config_files); do
        key="$S3_FOLDER_KEY/$file"
        mutate "$key" "upload auth/$CI_S3_FOLDER/$file (new key only)" -- s3api put-object --bucket "$CI_BUCKET" \
            --key "$key" --body "${CONFIG_DIR:-<config-dir>}/$file" --content-type application/json \
            --if-none-match '*' --tagging "$CI_TAG_KEY=$CI_TAG_VALUE"
    done
}

# --- provision --------------------------------------------------------------------------------------------

provision() {
    local suffix key early policy out id
    if [[ "$CI_MODE" == "apply" ]]; then
        say "Applying (scope $SCOPE): every call below is made."
    else
        say "Dry run (scope $SCOPE): no change is made. '+' is a call --apply would make, '=' a resource that exists."
    fi
    preflight

    # Pools that exist already (read-only), so the policies are narrowed to them when nothing is to be created.
    read_aws out cognito-idp list-user-pools --max-results 60
    for key in "${ALL_POOL_KEYS[@]}"; do
        id=$(jq -r --arg n "$(pool_name "$key")" '[.UserPools[] | select(.Name == $n) | .Id][0] // empty' <<<"$out")
        [[ -n "$id" ]] && kv_set POOL_ID "$key" "$id"
    done
    early=$(scoped_pool_arns early)

    say "Logs, key and code sink:"
    while read -r suffix; do
        ensure_log_group "$suffix"
    done < <(functions_in_scope)
    ensure_kms_key
    ensure_table
    ensure_api

    say "Roles:"
    ensure_role trigger-exec "$(lambda_trust)" "$(trigger_policy)"
    ensure_role sender-exec "$(lambda_trust)" "$(sender_policy "$early")"
    ensure_role appsync-codes "$(appsync_trust)" "$(appsync_policy)"
    if [[ "$SCOPE" == "all" ]]; then
        ensure_sms_external_id
        ensure_role cognito-sms "$(sms_trust "$(default_pool_arns early)")" "$(sms_policy)"
    fi
    ensure_api_resolvers
    ensure_api_key

    if [[ "$SCOPE" == "all" ]]; then
        say "Secrets:"
        ensure_secret ANSWER "$CI_SSM_ANSWER" generate_answer
        ensure_secret TEMPORARY "$CI_SSM_TEMPORARY" generate_temporary
    fi

    say "Lambdas:"
    while read -r suffix; do
        [[ "$suffix" == "new-password-reset" ]] || ensure_function "$suffix"
    done < <(functions_in_scope)

    say "User pools:"
    for key in "${POOL_KEYS[@]}"; do
        ensure_pool "$key"
    done

    say "Narrowing the key, the sender's decrypt and the SMS role to the ccit-ci- pools:"
    policy=$(scoped_pool_arns final)
    ensure_kms_policy "$(kms_policy "$policy")"
    ensure_role sender-exec "$(lambda_trust)" "$(sender_policy "$policy")"
    [[ "$SCOPE" == "all" ]] && ensure_role cognito-sms "$(sms_trust "$(default_pool_arns final)")" "$(sms_policy)"

    if [[ "$SCOPE" == "all" ]]; then
        say "Identity pool:"
        ensure_identity_pool
        say "New-password users:"
        ensure_role reset-exec "$(lambda_trust)" "$(reset_policy)"
        ensure_function new-password-reset
        ensure_reset_schedule
        run_reset_once
    fi

    if [[ "$CI_MODE" == "apply" ]]; then
        write_config
    else
        say "Would write into a new private directory (mode 600): $(config_files | paste -sd' ' -)"
    fi
    if (( UPLOAD )); then
        say "Upload:"
        upload_config
    fi
    if [[ "$CI_MODE" == "apply" ]]; then
        say "Done: $CI_MUTATIONS calls made."
        (( UPLOAD )) || say "Not uploaded. Check the files, then run again with --apply --upload."
    else
        say "Planned: $CI_MUTATIONS calls. Nothing was changed."
    fi
}

# --- snapshot ---------------------------------------------------------------------------------------------

# Appends one resource to the snapshot's raw list: kind, id, name (both masked before anything prints them) and
# its document.
record() {
    jq -n -c --arg kind "$1" --arg id "$2" --arg name "$3" --argjson doc "$4" \
        '{kind: $kind, id: $id, name: $name, doc: $doc}' >> "$RAW"
}

snapshot() {
    local dir="${CCIT_CI_DISCOVERY_DIR:-/tmp/ci-disc}" stamp out pool pools clients client describe lambdas arn doc
    local identity_pools identity name client_name
    umask 077
    mkdir -p "$dir"
    chmod 700 "$dir"
    stamp=$(date -u +%Y%m%dT%H%M%SZ)
    RAW="$CI_WORK/raw.ndjson"
    : > "$RAW"
    say "Snapshot (read-only) of the account's existing resources, region $CI_REGION:"

    read_aws out cognito-idp list-user-pools --max-results 60
    pools=$(jq -r '.UserPools[] | "\(.Id) \(.Name)"' <<<"$out")
    lambdas=""
    while read -r pool name; do
        [[ -n "$pool" ]] || continue
        read_aws describe cognito-idp describe-user-pool --user-pool-id "$pool"
        record user-pool "$pool" "$name" "$(jq -c '.UserPool | del(.EstimatedNumberOfUsers)' <<<"$describe")"
        lambdas+=$(jq -r '.UserPool.LambdaConfig // {} | .. | strings | select(startswith("arn:aws:lambda:"))' <<<"$describe")$'\n'
        read_aws out cognito-idp get-user-pool-mfa-config --user-pool-id "$pool"
        record user-pool-mfa "$pool" "$name" "$out"
        read_aws out cognito-idp list-user-pool-clients --user-pool-id "$pool" --max-results 60
        clients=$(jq -r '.UserPoolClients[] | "\(.ClientId) \(.ClientName)"' <<<"$out")
        record user-pool-clients "$pool" "$name" "$(jq -c '[.UserPoolClients[].ClientId] | sort' <<<"$out")"
        while read -r client client_name; do
            [[ -n "$client" ]] || continue
            read_aws doc cognito-idp describe-user-pool-client --user-pool-id "$pool" --client-id "$client"
            record user-pool-client "$pool/$client" "$name/$client_name" "$(jq -c '.UserPoolClient' <<<"$doc")"
        done <<<"$clients"
    done <<<"$pools"

    # A trigger that cannot be read (deleted, or in another region or account) is recorded by its error code, so a
    # change in that shows too.
    for arn in $(printf '%s' "$lambdas" | sort -u); do
        if aws_into doc lambda get-function-configuration --function-name "$arn"; then
            doc=$(jq -c 'del(.State, .StateReason, .StateReasonCode, .LastUpdateStatus, .LastUpdateStatusReason,
                .LastUpdateStatusReasonCode)' <<<"$doc")
        else
            doc=$(jq -n -c --arg e "${AWS_ERR_CODE:-unknown}" '{error: $e}')
        fi
        record trigger-lambda "$arn" "${arn##*:function:}" "$doc"
        if aws_into doc lambda get-policy --function-name "$arn"; then
            doc=$(jq -c '.Policy | fromjson' <<<"$doc")
        else
            doc=$(jq -n -c --arg e "${AWS_ERR_CODE:-unknown}" '{error: $e}')
        fi
        record trigger-lambda-policy "$arn" "${arn##*:function:}" "$doc"
    done

    read_aws out cognito-identity list-identity-pools --max-results 60
    identity_pools=$(jq -r '.IdentityPools[] | "\(.IdentityPoolId) \(.IdentityPoolName)"' <<<"$out")
    while read -r identity name; do
        [[ -n "$identity" ]] || continue
        read_aws doc cognito-identity describe-identity-pool --identity-pool-id "$identity"
        record identity-pool "$identity" "$name" "$doc"
        read_aws doc cognito-identity get-identity-pool-roles --identity-pool-id "$identity"
        record identity-pool-roles "$identity" "$name" "$doc"
    done <<<"$identity_pools"

    read_aws out s3api list-objects-v2 --bucket "$CI_BUCKET" --prefix "$CI_PREFIX_PATH/auth/"
    jq -c --arg p "$CI_PREFIX_PATH/" '.Contents[]? | {kind: "s3-object", id: .Key, name: (.Key | ltrimstr($p)),
        doc: {Key, ETag, Size, LastModified, StorageClass}}' <<<"$out" >> "$RAW"

    # Wider nets: every role, function, alias, API, table and rule, so an unexpected change anywhere shows.
    read_aws out iam list-roles
    jq -c '.Roles[] | {kind: "iam-role", id: .RoleId, name: .RoleName, doc: (. | del(.RoleLastUsed))}' <<<"$out" >> "$RAW"
    read_aws out lambda list-functions
    jq -c '.Functions[] | {kind: "lambda", id: .FunctionArn, name: .FunctionName, doc: (. | del(.State, .StateReason,
        .StateReasonCode, .LastUpdateStatus, .LastUpdateStatusReason, .LastUpdateStatusReasonCode))}' <<<"$out" >> "$RAW"
    read_aws out kms list-aliases
    jq -c '.Aliases[] | {kind: "kms-alias", id: .AliasArn, name: .AliasName, doc: .}' <<<"$out" >> "$RAW"
    read_aws out appsync list-graphql-apis
    jq -c '.graphqlApis[] | {kind: "appsync-api", id: .apiId, name: .name, doc: .}' <<<"$out" >> "$RAW"
    read_aws out dynamodb list-tables
    jq -c '.TableNames[] | {kind: "dynamodb-table", id: ., name: ., doc: {name: .}}' <<<"$out" >> "$RAW"
    read_aws out events list-rules
    jq -c '.Rules[] | {kind: "events-rule", id: .Arn, name: .Name, doc: .}' <<<"$out" >> "$RAW"

    python3 "$CI_DIR/snapshot.py" build "$RAW" "$dir/snapshot-$stamp.json" "$CI_TAG_VALUE"
}

# --- teardown ---------------------------------------------------------------------------------------------

teardown() {
    local out key file id suffix role fn
    if [[ "$CI_MODE" == "apply" ]]; then
        say "Teardown: deleting the ccit-ci- resources, each after its tag check."
    else
        say "Teardown dry run: nothing is deleted. '-' is a call teardown --apply would make."
    fi
    for file in ccit-ci-email-alias-amplify_outputs.json ccit-ci-default-amplify_outputs.json \
        ccit-ci-rotation-amplify_outputs.json ccit-ci-default-credentials.json; do
        key="$S3_FOLDER_KEY/$file"
        if read_aws_or_missing out "404 NoSuchKey NotFound" s3api head-object --bucket "$CI_BUCKET" --key "$key"; then
            require_ours s3-object "$key" "$key"
            mutate "$key" "delete auth/$CI_S3_FOLDER/$file" -- s3api delete-object --bucket "$CI_BUCKET" --key "$key"
        fi
    done
    if read_aws_or_missing out ResourceNotFoundException events describe-rule --name "$RULE"; then
        require_ours rule "$RULE" "$RULE"
        mutate "$RULE" "remove $RULE's target" -- events remove-targets --rule "$RULE" --ids new-password-reset
        mutate "$RULE" "delete schedule $RULE" -- events delete-rule --name "$RULE"
    fi
    read_aws out cognito-identity list-identity-pools --max-results 60
    for id in $(jq -r --arg n "$CI_IDENTITY_POOL" '.IdentityPools[] | select(.IdentityPoolName == $n) | .IdentityPoolId' <<<"$out"); do
        require_ours identity-pool "$id" "$CI_IDENTITY_POOL"
        mutate "$CI_IDENTITY_POOL" "delete identity pool $CI_IDENTITY_POOL" -- cognito-identity delete-identity-pool \
            --identity-pool-id "$id"
    done
    read_aws out cognito-idp list-user-pools --max-results 60
    for key in "${ALL_POOL_KEYS[@]}"; do
        for id in $(jq -r --arg n "$(pool_name "$key")" '.UserPools[] | select(.Name == $n) | .Id' <<<"$out"); do
            require_ours user-pool "$id" "$(pool_name "$key")"
            mutate "$(pool_name "$key")" "delete user pool $(pool_name "$key") (its clients and users with it)" -- \
                cognito-idp delete-user-pool --user-pool-id "$id"
        done
    done
    for suffix in "${TRIGGERS_ALL[@]}" custom-sender new-password-reset; do
        fn=$(fn_name "$suffix")
        if read_aws_or_missing out ResourceNotFoundException lambda get-function-configuration --function-name "$fn"; then
            require_ours lambda "$fn" "$fn"
            mutate "$fn" "delete Lambda $fn" -- lambda delete-function --function-name "$fn"
        fi
    done
    read_aws out appsync list-graphql-apis
    for id in $(jq -r --arg n "$API_NAME" '.graphqlApis[] | select(.name == $n) | .arn' <<<"$out"); do
        require_ours appsync "$id" "$API_NAME"
        mutate "$API_NAME" "delete AppSync API $API_NAME" -- appsync delete-graphql-api --api-id "${id##*/}"
    done
    if read_aws_or_missing out ResourceNotFoundException dynamodb describe-table --table-name "$TABLE"; then
        require_ours table "$TABLE" "$TABLE"
        mutate "$TABLE" "delete table $TABLE" -- dynamodb delete-table --table-name "$TABLE"
    fi
    for suffix in trigger-exec sender-exec appsync-codes cognito-sms reset-exec identity-authenticated \
        identity-unauthenticated; do
        role=$(role_name "$suffix")
        if read_aws_or_missing out NoSuchEntity iam get-role --role-name "$role"; then
            require_ours role "$role" "$role"
            read_aws out iam list-attached-role-policies --role-name "$role"
            [[ "$(jq -r '.AttachedPolicies | length' <<<"$out")" == 0 ]] || die "role $role has an attached policy."
            read_aws out iam list-role-policies --role-name "$role"
            for file in $(jq -r '.PolicyNames[]' <<<"$out"); do
                [[ "$file" == "$role-policy" ]] || die "role $role has an inline policy this script did not put there."
                mutate "$role" "delete the inline policy of $role" -- iam delete-role-policy --role-name "$role" \
                    --policy-name "$file"
            done
            mutate "$role" "delete role $role" -- iam delete-role --role-name "$role"
        fi
    done
    for file in "$CI_SSM_ANSWER" "$CI_SSM_TEMPORARY"; do
        if read_aws_or_missing out ParameterNotFound ssm get-parameter --name "$file"; then
            require_ours ssm "$file" "$file"
            mutate "$file" "delete parameter $file" -- ssm delete-parameter --name "$file"
        fi
    done
    read_aws out kms list-aliases
    id=$(jq -r --arg a "$CI_KMS_ALIAS" '[.Aliases[] | select(.AliasName == $a) | .TargetKeyId][0] // empty' <<<"$out")
    if [[ -n "$id" ]]; then
        require_ours kms "$id" "$CI_KMS_ALIAS"
        mutate "$CI_KMS_ALIAS" "delete alias $CI_KMS_ALIAS" -- kms delete-alias --alias-name "$CI_KMS_ALIAS"
        mutate "$CI_KMS_ALIAS" "schedule the key's deletion in 7 days" -- kms schedule-key-deletion --key-id "$id" \
            --pending-window-in-days 7
    fi
    for suffix in "${TRIGGERS_ALL[@]}" custom-sender new-password-reset; do
        file=$(log_group "$suffix")
        read_aws out logs describe-log-groups --log-group-name-prefix "$file"
        if jq -e --arg n "$file" '.logGroups[] | select(.logGroupName == $n)' <<<"$out" >/dev/null; then
            require_ours log-group "$file" "$file"
            mutate "$file" "delete log group $file" -- logs delete-log-group --log-group-name "$file"
        fi
    done
    if [[ "$CI_MODE" == "apply" ]]; then
        say "Teardown done: $CI_MUTATIONS calls made."
    else
        say "Teardown planned: $CI_MUTATIONS calls. Nothing was deleted."
    fi
}

case "$COMMAND" in
    provision|teardown)
        # --apply runs the whole dry run first, quietly, so a refusal anywhere (a ccit-ci- name without the tag, an
        # S3 key that exists, too little quota) stops it before its first change.
        if [[ "$CI_MODE" == "apply" ]]; then
            say "Checking with a dry run first; nothing is changed if it refuses."
            ( CI_MODE="plan"; "$COMMAND" >/dev/null ) || die "the dry run refused (above); nothing was changed."
        fi
        "$COMMAND"
        ;;
    snapshot) snapshot ;;
esac
