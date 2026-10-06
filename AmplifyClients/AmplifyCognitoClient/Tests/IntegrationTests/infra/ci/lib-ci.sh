# shellcheck shell=bash
# shellcheck disable=SC2034  # the constants and MUTATE_OUT are read by the scripts that source this file
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Shared by provision-ci.sh and its self-test. Source it; do not run it.
#
# The rules every caller relies on:
#   - Every AWS call goes through aws_into, which always passes --region "$CI_REGION" and masks the CLI's error
#     output (`mask`: lib.sh's `redact`, plus the bucket and the account as literal text).
#   - Every mutating call goes through `mutate`, which refuses a resource whose name is not this script's
#     (`is_ours`: the ccit-ci- prefix), and in plan mode (the default) only prints the call, masked.
#   - Before a mutating call on a resource that already exists, the caller checks its purpose tag
#     (`require_ours`), so nothing without the tag is ever changed or deleted.
#   - Secrets reach the CLI through --cli-input-json, from a mode-600 file in $CI_WORK (`input_file`), never argv.

CI_PREFIX="ccit-ci"
CI_TAG_KEY="purpose"
CI_TAG_VALUE="amplify-cognito-client-integ"
# The S3 subfolder under <config>/auth/ that CI downloads with the plugin's files, and that only the client's CI
# jobs read (ci-overlay.sh).
CI_S3_FOLDER="cognito-client-ci"
CI_IDENTITY_POOL="ccit_ci_default"
CI_KMS_ALIAS="alias/ccit-ci-senders"
CI_SSM_ANSWER="/ccit-ci/custom-challenge-answer"
CI_SSM_TEMPORARY="/ccit-ci/new-password-temporary"
CI_NEW_PASSWORD_USER_COUNT=12

# Set by the caller: CI_REGION, CI_WORK (a mode-700 directory, removed on exit), CI_MODE (plan or apply).
# Set by `require_caller`: CI_ACCOUNT (never printed). Set by `parse_config_url`: CI_BUCKET, CI_PREFIX_PATH.
CI_ACCOUNT="${CI_ACCOUNT:-}"
CI_BUCKET="${CI_BUCKET:-}"
CI_PREFIX_PATH="${CI_PREFIX_PATH:-}"
CI_MUTATIONS=0
AWS_ERR=""
AWS_ERR_CODE=""

# A key-value store over plain variables (bash 3.2 has no associative arrays): kv_set MAP KEY VALUE, kv_get MAP KEY
# [DEFAULT]. The key is folded to a variable name.
kv_name() {
    printf '%s_%s' "$1" "$(printf '%s' "$2" | tr -c 'A-Za-z0-9_' '_')"
}

kv_set() {
    printf -v "$(kv_name "$1" "$2")" '%s' "$3"
}

kv_get() {
    local name
    name=$(kv_name "$1" "$2")
    printf '%s' "${!name:-${3:-}}"
}

die() {
    echo "Refusing: $*" >&2
    exit 1
}

say() {
    printf '%s\n' "$*"
}

sed_literal() {
    printf '%s' "$1" | sed -e 's/[][\\.*^$#/]/\\&/g'
}

# Masks identifiers: lib.sh's `redact`, then the bucket and the account as literal text, then AWS access key ids.
# The literal expressions are built once they are known (mask_init, after parse_config_url and require_caller).
MASK_SED=(-e 's/(A[SK]IA)[A-Z0-9]{12,}/\1<key>/g')
mask_init() {
    MASK_SED=(-e 's/(A[SK]IA)[A-Z0-9]{12,}/\1<key>/g')
    if [[ -n "$CI_BUCKET" ]]; then
        MASK_SED+=(-e "s#$(sed_literal "$CI_BUCKET")#<bucket>#g")
    fi
    if [[ -n "$CI_ACCOUNT" ]]; then
        MASK_SED+=(-e "s#$(sed_literal "$CI_ACCOUNT")#<account>#g")
    fi
}

mask() {
    redact | sed -E "${MASK_SED[@]}"
}

# Runs `aws <args>` in $CI_REGION with JSON output (stdin closed), and puts its stdout in the variable named $1.
# Outside apply mode only get-, list-, describe- and head- calls are allowed. On failure,
# AWS_ERR_CODE is the service's error code (`An error occurred (<code>)`) and AWS_ERR the last lines of the
# CLI's error output, masked. Returns the CLI's status. Not in a subshell, so the globals reach the caller.
aws_into() {
    local __var="$1" __err __out __status=0
    shift
    # A dry run, a snapshot and a teardown dry run read only: any other verb here is a bug, and stops the script.
    if [[ "${CI_MODE:-plan}" != "apply" ]]; then
        case "${2:-}" in
            get-*|list-*|describe-*|head-*) ;;
            *) die "a dry run makes read calls only, and aws ${1:-} ${2:-} is not one." ;;
        esac
    fi
    # One call at a time, so one file in the private $CI_WORK serves every call's stderr.
    __err="$CI_WORK/.stderr"
    __out=$(command aws --region "$CI_REGION" --output json "$@" 2>"$__err" </dev/null) || __status=$?
    AWS_ERR_CODE=""
    AWS_ERR=""
    if (( __status != 0 )); then
        AWS_ERR_CODE=$(sed -nE 's/.*An error occurred \(([A-Za-z0-9.]+)\).*/\1/p' "$__err" | head -n 1)
        AWS_ERR=$(mask < "$__err" | tail -n 3)
    fi
    : > "$__err"
    printf -v "$__var" '%s' "$__out"
    return "$__status"
}

# A read the script cannot do without: dies with the masked error.
read_aws() {
    local __target="$1"
    shift
    aws_into "$__target" "$@" || die "aws $1 $2 failed (${AWS_ERR_CODE:-no code}): ${AWS_ERR:-no output}"
}

# Every page of a list call that pages with --next-token and NextToken, and must be given --max-results: the
# Cognito list calls (ListUserPools requires it). Giving it turns the CLI's own pagination off, so this asks for
# each page in turn, 60 items at a time, and puts in the variable named $1 one document, {"<$2>": [every page's
# items]}. $2 is the response's list field (UserPools, IdentityPools, UserPoolClients); the call follows. Every
# other list call the scripts make is one the CLI paginates itself (they give it no page size or token).
read_all_pages() {
    local __target="$1" __field="$2" __page="" __token="" __items="[]" __pages=0
    shift 2
    while :; do
        if [[ -n "$__token" ]]; then
            read_aws __page "$@" --max-results 60 --next-token "$__token"
        else
            read_aws __page "$@" --max-results 60
        fi
        __items=$(jq -c --argjson a "$__items" --arg f "$__field" '$a + (.[$f] // [])' <<<"$__page")
        __token=$(jq -r '.NextToken // empty' <<<"$__page")
        __pages=$((__pages + 1))
        [[ -n "$__token" ]] || break
        (( __pages < 1000 )) || die "aws $1 $2 returned more than 1000 pages."
    done
    printf -v "$__target" '%s' "$(jq -n -c --arg f "$__field" --argjson a "$__items" '{($f): $a}')"
}

# A read whose resource may not exist: returns 1, with the variable empty, when the error code is one of $2
# (space-separated). Any other failure dies.
read_aws_or_missing() {
    local __target="$1" __codes=" $2 "
    shift 2
    if aws_into "$__target" "$@"; then
        return 0
    fi
    if [[ -n "$AWS_ERR_CODE" && "$__codes" == *" $AWS_ERR_CODE "* ]]; then
        printf -v "$__target" '%s' ""
        return 1
    fi
    die "aws $1 $2 failed (${AWS_ERR_CODE:-no code}): ${AWS_ERR:-no output}"
}

# Whether $1 is a name (or S3 key) this script creates: the only names `mutate` accepts.
is_ours() {
    local name="$1"
    case "$name" in
        "$CI_PREFIX"-*|"/aws/lambda/$CI_PREFIX"-*|"alias/$CI_PREFIX"-*|"/$CI_PREFIX/"*|"${CI_PREFIX//-/_}"_*) return 0 ;;
    esac
    if [[ -n "$CI_PREFIX_PATH" && "$name" == "$CI_PREFIX_PATH/auth/$CI_S3_FOLDER/$CI_PREFIX"-* ]]; then
        return 0
    fi
    return 1
}

# Writes JSON ($1) to a new mode-600 file in $CI_WORK and prints its path, for --cli-input-json file://. It runs in
# the caller's command substitution, so it numbers the file by the caller's shell and the time, and never reuses one.
INPUT_SEQ=0
input_file() {
    local path
    INPUT_SEQ=$((INPUT_SEQ + 1))
    path="$CI_WORK/.input.$$.$RANDOM$RANDOM.$INPUT_SEQ"
    while [[ -e "$path" ]]; do
        path="$path.x"
    done
    (umask 077 && printf '%s' "$1" > "$path")
    printf '%s' "$path"
}

# One CLI argument as the plan prints it, before the whole line is masked: a --cli-input-json file as the keys it
# sets (never their values), a zip as <zip>, a file in $CI_WORK by its name only.
render_arg() {
    local arg="$1"
    case "$arg" in
        file://*) printf '<input: %s>' "$(jq -r 'keys | join(",")' "${arg#file://}" 2>/dev/null || echo '?')" ;;
        fileb://*.zip) printf '<zip>' ;;
        fileb://*) printf '<file %s>' "${arg##*/}" ;;
        "$CI_WORK"/*) printf '<work>/%s' "${arg##*/}" ;;
        *) printf '%s' "$arg" ;;
    esac
}

# Runs a mutating call on resource $1 (its name, which must be ours), described by $2; the call follows `--`.
# Plan mode prints it, masked, and runs nothing. Apply mode runs it and puts its output in MUTATE_OUT; a failure
# dies, unless its error code is in MUTATE_TOLERATE (space-separated), when it returns 1.
MUTATE_OUT=""
MUTATE_TOLERATE=""
mutate() {
    local name="$1" description="$2" rendered="" arg
    shift 2
    [[ "${1:-}" == "--" ]] || die "mutate needs -- before the call"
    shift
    is_ours "$name" || die "$(printf '%s' "$name" | mask) is not a ccit-ci- resource; this script never changes one."
    CI_MUTATIONS=$((CI_MUTATIONS + 1))
    if [[ "$CI_MODE" != "apply" ]]; then
        for arg in "$@"; do
            rendered+=" $(render_arg "$arg")"
        done
        say "  + $description"
        printf '      aws%s\n' "$rendered" | mask
        MUTATE_OUT=""
        return 0
    fi
    say "  + $description"
    if aws_into MUTATE_OUT "$@"; then
        return 0
    fi
    if [[ -n "$AWS_ERR_CODE" && " $MUTATE_TOLERATE " == *" $AWS_ERR_CODE "* ]]; then
        return 1
    fi
    die "$description failed (${AWS_ERR_CODE:-no code}): ${AWS_ERR:-no output}"
}

# `mutate`, retried while IAM has not yet propagated a role created seconds ago, when the service answers with one of
# the error codes in $3 (space-separated). $1 is the number of attempts, $2 the seconds between them; the rest is
# `mutate`'s arguments. Any other error dies at once.
mutate_with_retry() {
    local attempts="$1" pause="$2" codes="$3" i
    shift 3
    for (( i = 1; i <= attempts; i++ )); do
        if MUTATE_TOLERATE="$codes" mutate "$@"; then
            return 0
        fi
        (( i < attempts )) || die "$2 failed after $attempts attempts (${AWS_ERR_CODE:-no code}): ${AWS_ERR:-no output}"
        sleep "$pause"
    done
}

# The purpose tag of an existing resource ("" without one). $1 is its kind, $2 its id (or name, or ARN, as each
# service lists tags by).
tag_value() {
    local kind="$1" id="$2" out=""
    case "$kind" in
        user-pool)
            read_aws out cognito-idp describe-user-pool --user-pool-id "$id"
            jq -r --arg k "$CI_TAG_KEY" '.UserPool.UserPoolTags[$k] // ""' <<<"$out" ;;
        identity-pool)
            read_aws out cognito-identity list-tags-for-resource \
                --resource-arn "arn:aws:cognito-identity:$CI_REGION:$CI_ACCOUNT:identitypool/$id"
            jq -r --arg k "$CI_TAG_KEY" '.Tags[$k] // ""' <<<"$out" ;;
        role)
            read_aws out iam list-role-tags --role-name "$id"
            jq -r --arg k "$CI_TAG_KEY" '[.Tags[]? | select(.Key == $k) | .Value][0] // ""' <<<"$out" ;;
        lambda)
            read_aws out lambda list-tags --resource "arn:aws:lambda:$CI_REGION:$CI_ACCOUNT:function:$id"
            jq -r --arg k "$CI_TAG_KEY" '.Tags[$k] // ""' <<<"$out" ;;
        kms)
            read_aws out kms list-resource-tags --key-id "$id"
            jq -r --arg k "$CI_TAG_KEY" '[.Tags[]? | select(.TagKey == $k) | .TagValue][0] // ""' <<<"$out" ;;
        table)
            read_aws out dynamodb list-tags-of-resource --resource-arn "arn:aws:dynamodb:$CI_REGION:$CI_ACCOUNT:table/$id"
            jq -r --arg k "$CI_TAG_KEY" '[.Tags[]? | select(.Key == $k) | .Value][0] // ""' <<<"$out" ;;
        appsync)
            read_aws out appsync list-tags-for-resource --resource-arn "$id"
            jq -r --arg k "$CI_TAG_KEY" '.tags[$k] // ""' <<<"$out" ;;
        log-group)
            read_aws out logs list-tags-for-resource --resource-arn "arn:aws:logs:$CI_REGION:$CI_ACCOUNT:log-group:$id"
            jq -r --arg k "$CI_TAG_KEY" '.tags[$k] // ""' <<<"$out" ;;
        ssm)
            read_aws out ssm list-tags-for-resource --resource-type Parameter --resource-id "$id"
            jq -r --arg k "$CI_TAG_KEY" '[.TagList[]? | select(.Key == $k) | .Value][0] // ""' <<<"$out" ;;
        rule)
            read_aws out events list-tags-for-resource --resource-arn "arn:aws:events:$CI_REGION:$CI_ACCOUNT:rule/$id"
            jq -r --arg k "$CI_TAG_KEY" '[.Tags[]? | select(.Key == $k) | .Value][0] // ""' <<<"$out" ;;
        s3-object)
            read_aws out s3api get-object-tagging --bucket "$CI_BUCKET" --key "$id"
            jq -r --arg k "$CI_TAG_KEY" '[.TagSet[]? | select(.Key == $k) | .Value][0] // ""' <<<"$out" ;;
        *) die "unknown resource kind $kind" ;;
    esac
}

# Dies unless the existing resource named $3 (kind $1, id $2) is ours: the ccit-ci- name and the purpose tag.
require_ours() {
    local kind="$1" id="$2" name="$3" tag
    is_ours "$name" || die "$kind $(printf '%s' "$name" | mask) is not a ccit-ci- resource."
    tag=$(tag_value "$kind" "$id")
    [[ "$tag" == "$CI_TAG_VALUE" ]] \
        || die "$kind $(printf '%s' "$name" | mask) exists without $CI_TAG_KEY=$CI_TAG_VALUE: it is not this script's, and it is never changed. Rename or remove it by hand first."
}

# Reads s3://<bucket>/<path> from COGNITO_CLIENT_INTEG_CI_CONFIG_URL (the AWS_S3_BUCKET_INTEG_V2 secret's value):
# sets CI_BUCKET and CI_PREFIX_PATH (no trailing slash).
parse_config_url() {
    local url="${COGNITO_CLIENT_INTEG_CI_CONFIG_URL:-}"
    [[ -n "$url" ]] || die "set COGNITO_CLIENT_INTEG_CI_CONFIG_URL to s3://<bucket>/<path>, the value of CI's AWS_S3_BUCKET_INTEG_V2 (the folder that holds auth/)."
    url="${url%/}"
    [[ "$url" =~ ^s3://([a-z0-9][a-z0-9.-]{1,61}[a-z0-9])/([A-Za-z0-9._/-]+)$ ]] \
        || die "COGNITO_CLIENT_INTEG_CI_CONFIG_URL must be s3://<bucket>/<path>, with the path to the folder that holds auth/."
    CI_BUCKET="${BASH_REMATCH[1]}"
    CI_PREFIX_PATH="${BASH_REMATCH[2]}"
    [[ "$CI_PREFIX_PATH" != *..* && "$CI_PREFIX_PATH" != */ ]] || die "COGNITO_CLIENT_INTEG_CI_CONFIG_URL has an unusable path."
    mask_init
}

# Sets CI_ACCOUNT from the caller's identity. Prints nothing identifying.
require_caller() {
    local out
    read_aws out sts get-caller-identity
    CI_ACCOUNT=$(jq -r '.Account' <<<"$out")
    [[ "$CI_ACCOUNT" =~ ^[0-9]{12}$ ]] || die "could not read the caller's account."
    mask_init
}

# Dies unless the AWS CLI is at least 2.26.7, the first whose Cognito model has RefreshTokenRotation.
require_cli_version() {
    local version
    version=$(command aws --version 2>&1 | sed -nE 's#^aws-cli/([0-9]+\.[0-9]+\.[0-9]+).*#\1#p')
    [[ -n "$version" ]] || die "could not read the AWS CLI's version."
    if ! printf '%s\n%s\n' "2.26.7" "$version" | sort -V -C; then
        die "AWS CLI $version is older than 2.26.7, which the rotation client's RefreshTokenRotation needs."
    fi
}
