#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Self-test for provision-ci.sh, end to end over a fake `aws` (fake_aws.py) and a fake `npm` on PATH, which keep
# a fake account in a JSON file: the plugin's resources (a pool with a client and a trigger, an identity pool, a
# role, a Lambda, the auth/ objects) as placeholders, never real identifiers. No AWS call is made: the fake is
# checked to be the `aws` the script finds before anything runs, and the CLI's config and credential files are
# /dev/null.
#
#   bash infra/ci/test_provision_ci.sh
#
# It checks that a dry run (the default) makes only get/list/describe/head calls, plans every resource, names only
# ccit-ci- resources and prints no identifier; that --scope email-alias plans only the device-alias pool and what it
# needs; that a ccit-ci- name without the purpose tag is refused before any change, by a dry run and by --apply;
# that --apply creates everything, tagged, leaves the plugin's resources exactly as they were, narrows the key to the
# four pools, the sender's decrypt to the two it sends for and the SMS role to the default and MFA-required pools,
# makes the code sink key's weekly extension (its function, a role allowed only its logs and the two AppSync key
# calls on the API's ARN, and a weekly rule), and writes the seven files (mode 600, in a mode-700 directory) with
# what the client reads; that a second --apply makes no call; that
# --upload puts only new keys under auth/cognito-client-ci/ and refuses, with no upload, once one exists; that a
# rerun over phase 2 as it was first applied (the script at 80712afe4 when git has it, else skipped) plans and makes
# only the alias-codes and MFA-required pools and what they need, and the key's weekly extension, updates only the
# script's own resources, and
# uploads only the three new files, finding the four uploaded ones byte for byte the same; that a phase-1 --apply
# after phase 2 is refused before any change, naming --scope all, and its dry run plans nothing; that the code sink key is made and extended for 365 days, to the hour, within AppSync's
# bounds (which the fake checks) though AppSync's clock is behind; that a rerun reuses a key that lives more than
# KEY_REUSE_DAYS (120), the one the frozen script made too, extends one that lives fewer in place, and one that has
# expired too, while AppSync keeps it, and makes a new one once AppSync has deleted it or refuses the extension
# (the fake does either), and that then the uploaded files that name the old key are named, and --apply refuses at
# the end, until they are replaced; that the AppSync headroom is checked only by a run that creates the API, against
# CCIT_CI_APPSYNC_API_QUOTA; that a dry run refuses a custom sender to build without npm, and a failed npm ci stops
# --apply before the sender; that lambda-drift downloads each deployed zip and tells a
# Lambda whose files are not this checkout's, which --record --accept-deployed alone accepts; that snapshot and
# verify-unchanged ignore a user count, and fail on a changed, removed or foreign added resource (a foreign role's
# inline policy, key policy, parameter or log group included), but not on a ccit-ci- addition or change, nor on a
# Lambda's runtime version, and that the snapshot's documents hold no secret; that snapshot and lambda-drift refuse
# --apply; that teardown is a dry run by default, deletes only the ccit-ci- resources with
# --apply, refuses an untagged one, and schedules the key's deletion before removing its alias; that a run in another
# region is refused (lambda-drift too, which there would find nothing to compare); that a pool made again gets its
# Lambdas' invoke permissions replaced; that replace takes only the script's pools, is a dry run by default, refuses
# an untagged pool and, through a fake gh, a CI run that reads the pools, and with --apply deletes the pool and what
# names it, then reruns --scope all (phase 1 where phase 2 does not exist); that the fake, as Cognito, makes an SMS
# pool only when the SNS caller role's trust admits it, so that an SMS pool made again (no git history needed) shows
# the trust opened while it is made and narrowed after; and that the library's
# guards refuse a name that is not ccit-ci- and a mutating call in a dry run.
set -euo pipefail
CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$CI_DIR/provision-ci.sh"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
WORK="$(cd "$WORK" && pwd -P)"
BIN="$WORK/bin"
mkdir -p "$BIN" "$WORK/tmp"
# The fake, run by the interpreter itself rather than through /usr/bin/python3's shim: one process per call.
{ printf '#!%s -S\n' "$(python3 -c 'import sys; print(sys.executable)')"; tail -n +2 "$CI_DIR/fake_aws.py"; } > "$BIN/aws"
chmod +x "$BIN/aws"
cat > "$BIN/npm" <<'EOF'
#!/usr/bin/env bash
# A fake npm: `npm ci` makes a node_modules with one file, and nothing is fetched.
mkdir -p node_modules/fake && echo 'export {};' > node_modules/fake/index.js
EOF
chmod +x "$BIN/npm"
# A `date` whose epoch seconds (`date +%s`, the script's clock) run FAKE_DATE_OFFSET seconds ahead, when set.
cat > "$BIN/date" <<'EOF'
#!/usr/bin/env bash
if [[ -n "${FAKE_DATE_OFFSET:-}" && "$*" == "+%s" ]]; then
    echo $(( $(/bin/date +%s) + FAKE_DATE_OFFSET ))
else
    exec /bin/date "$@"
fi
EOF
chmod +x "$BIN/date"
# A `sleep` that returns at once when FAKE_NO_SLEEP is set, so that a run retrying a refusal it waits out (as a role
# Cognito cannot assume yet) fails in seconds.
cat > "$BIN/sleep" <<'EOF'
#!/usr/bin/env bash
[[ -n "${FAKE_NO_SLEEP:-}" ]] || exec /bin/sleep "$@"
EOF
chmod +x "$BIN/sleep"
# A fake gh, for replace's check that no CI run is going: FAKE_GH unset, no run is going; "dispatched", a run of
# integ_test_auth_client.yml is; "called", a queued run of integ_test.yml has a Cognito client job queued; "other",
# a running run of integ_test.yml has only other jobs going; "broken", gh cannot list the runs.
cat > "$BIN/gh" <<'EOF'
#!/usr/bin/env bash
[[ "${FAKE_GH:-}" != broken ]] || { echo "To get started with GitHub CLI, please run:  gh auth login" >&2; exit 4; }
if [[ "$1 $2" == "run list" ]]; then
    case "${FAKE_GH:-}:$*" in
        dispatched:*"-w integ_test_auth_client.yml -s in_progress"*) echo '[{"databaseId": 11}]' ;;
        called:*"-w integ_test.yml -s queued"*) echo '[{"databaseId": 12}]' ;;
        other:*"-w integ_test.yml -s in_progress"*) echo '[{"databaseId": 13}]' ;;
        *) echo '[]' ;;
    esac
elif [[ "$1 $2 $3" == "run view 12" ]]; then
    echo '{"jobs": [{"name": "Auth Cognito Client Integration Tests / iOS Tests | CognitoClientIntegrationTests", "status": "queued"}]}'
elif [[ "$1 $2 $3" == "run view 13" ]]; then
    echo '{"jobs": [{"name": "Auth Integration Tests / iOS Tests | AuthIntegrationTests", "status": "in_progress"},
        {"name": "Auth Cognito Client Integration Tests / iOS Tests | CognitoClientIntegrationTests", "status": "completed"}]}'
else
    exit 1
fi
EOF
chmod +x "$BIN/gh"
export PATH="$BIN:$PATH" FAKE_STATE="$WORK/state.json" FAKE_LOG="$WORK/calls.log" TMPDIR="$WORK/tmp"
export AWS_CONFIG_FILE=/dev/null AWS_SHARED_CREDENTIALS_FILE=/dev/null CCIT_CI_DISCOVERY_DIR="$WORK/disc"
export COGNITO_CLIENT_INTEG_CI_CONFIG_URL="s3://fake-ci-bucket.example/v2/testconfiguration"
# The Lambdas' deployment baseline, never the committed one.
export CCIT_CI_LAMBDA_BASELINE="$WORK/lambda-baseline.json"
# The fake's Code.Location is a file:// URL to the zip it keeps, which lambda_code.py takes only with this set.
export CCIT_CI_TEST_FILE_CODE_URLS=1
# A umask that leaves new files readable by all, so a file the script leaves open to others is one, and is caught
# (lambda_code.py refuses a deployed.json anyone but its owner can read).
umask 022
unset AWS_PROFILE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN CCIT_CI_REGION
[[ "$(command -v aws)" == "$BIN/aws" ]] || { echo "FAIL: the fake aws is not first on PATH"; exit 1; }
ACCOUNT=123456789012
BUCKET=fake-ci-bucket.example
CONFIG_PATH=v2/testconfiguration
PLUGIN_POOL=us-east-1_PluginPool01

failures=0
skipped=0
pass() { echo "ok - $1"; }
fail() { echo "FAIL - $1"; failures=$((failures + 1)); }
check() {
    local name="$1"
    shift
    if "$@"; then pass "$name"; else fail "$name"; fi
}

# The fake account: the plugin's resources, which nothing may change.
fresh_state() {
    local key
    jq -n --arg a "$ACCOUNT" --arg b "$BUCKET" --arg p "$PLUGIN_POOL" '{
      account: $a, bucket: $b,
      pools: {($p): {UserPool: {Id: $p, Name: "amplify-plugin-default", EstimatedNumberOfUsers: 116854,
                                MfaConfiguration: "OPTIONAL", LastModifiedDate: "2025-01-01T00:00:00Z",
                                LambdaConfig: {PreSignUp: "arn:aws:lambda:us-east-1:\($a):function:plugin-pre-sign-up"},
                                UserPoolTags: {}},
                     clients: {"pluginclient0000000000000a": {ClientId: "pluginclient0000000000000a", ClientName: "plugin",
                                                            UserPoolId: $p}},
                     mfa: {MfaConfiguration: "OPTIONAL"}}},
      identity_pools: {"us-east-1:00000000-0000-4000-8000-000000000001": {
          IdentityPoolId: "us-east-1:00000000-0000-4000-8000-000000000001", IdentityPoolName: "plugin_identity",
          AllowUnauthenticatedIdentities: true, roles: {}}},
      roles: {"plugin-role": {Role: {RoleName: "plugin-role", RoleId: "AROAPLUGIN", Arn: "arn:aws:iam::\($a):role/plugin-role",
                                     AssumeRolePolicyDocument: {Version: "2012-10-17", Statement: []}},
                              tags: [], inline: {}, attached: []}},
      lambdas: {"plugin-pre-sign-up": {config: {FunctionName: "plugin-pre-sign-up", State: "Active",
                                                FunctionArn: "arn:aws:lambda:us-east-1:\($a):function:plugin-pre-sign-up"},
                                       tags: {}, policy: []}},
      s3: {}}' > "$FAKE_STATE"
    for key in AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json \
        AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json; do
        jq --arg k "v2/testconfiguration/auth/$key" '.s3[$k] = {etag: "\"e1\"", size: 10, modified: "2026-01-01T00:00:00Z", tags: {}}' \
            "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    done
}

# The plugin's part of the fake account, to compare before and after.
plugin_part() {
    jq -S --arg p "$PLUGIN_POOL" '{pool: .pools[$p], role: .roles["plugin-role"],
        lambda: .lambdas["plugin-pre-sign-up"],
        s3: (.s3 | with_entries(select(.key | contains("cognito-client-ci") | not))),
        identity_plugin: (.identity_pools["us-east-1:00000000-0000-4000-8000-000000000001"])}' "$FAKE_STATE"
}

# Runs the script; sets OUT (stdout and stderr) and STATUS.
run() {
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$("$SCRIPT" "$@" 2>&1) || STATUS=$?
}

# The service calls the last run made, as "<service> <verb>".
calls() {
    sed -nE 's/^--region [a-z0-9-]+ --output json ([a-z0-9-]+) ([a-z0-9-]+).*/\1 \2/p' "$FAKE_LOG"
}

only_reads() {
    ! calls | awk '{print $2}' | grep -vqE '^(get|list|describe|head)-'
}

# No identifier the fake knows reaches the output: the account, the bucket, the config path, a pool, client, key or
# API id.
no_identifiers() {
    [[ "$OUT" != *"$ACCOUNT"* && "$OUT" != *"$BUCKET"* && "$OUT" != *"$CONFIG_PATH"* ]] \
        && [[ "$OUT" != *"$PLUGIN_POOL"* && "$OUT" != *us-east-1_Fake* ]] \
        && ! grep -qE '[0-9a-f]{26}|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|da2-' <<<"$OUT"
}

# Every planned or made call ('+' line) names a ccit-ci- resource.
plus_lines_are_ours() {
    ! grep -E '^  \+ ' <<<"$OUT" | grep -vqE 'ccit-ci-|ccit_ci_|/ccit-ci/|alias/ccit-ci-|cognito-client-ci/|the code sink schema|the tests. read-only API key|the code table|resolver|the KMS key for|expire ccit'
}

usage_is_refused() {
    local args
    for args in "--scope bogus" "--record" "--apply --record" "snapshot --record"; do
        # shellcheck disable=SC2086 # split on purpose: each case is a list of arguments
        run $args
        (( STATUS == 2 )) && { [[ ! -s "$FAKE_LOG" ]] || [[ -z "$(calls)" ]]; } || { echo "$args: $OUT"; return 1; }
    done
}

# snapshot and lambda-drift only read: --apply, which would switch the read-only guard off for them, is a usage error,
# before any AWS call.
read_only_commands_refuse_apply() {
    local command
    for command in snapshot lambda-drift; do
        run --apply "$command"
        (( STATUS == 2 )) && [[ "$OUT" == *"$command is read-only: it takes no --apply."* ]] && [[ -z "$(calls)" ]] \
            || { echo "$command: $OUT"; return 1; }
    done
    run lambda-drift --apply --record --accept-deployed
    (( STATUS == 2 )) && [[ -z "$(calls)" ]]
}

a_missing_config_url_is_refused() {
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(env -u COGNITO_CLIENT_INTEG_CI_CONFIG_URL "$SCRIPT" 2>&1) || STATUS=$?
    (( STATUS == 1 )) && [[ "$OUT" == *"COGNITO_CLIENT_INTEG_CI_CONFIG_URL"* ]] && [[ -z "$(calls)" ]]
}

a_config_url_without_a_path_is_refused() {
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(COGNITO_CLIENT_INTEG_CI_CONFIG_URL="s3://$BUCKET" "$SCRIPT" 2>&1) || STATUS=$?
    (( STATUS == 1 )) && [[ -z "$(calls)" ]] && [[ "$OUT" != *"$BUCKET"* ]]
}

# Phase 1, the default scope: the device-alias pool and exactly what it needs.
PHASE1_PLAN="create log group /aws/lambda/ccit-ci-pre-sign-up
keep /aws/lambda/ccit-ci-pre-sign-up for 7 days
create log group /aws/lambda/ccit-ci-discard-sender
keep /aws/lambda/ccit-ci-discard-sender for 7 days
create the KMS key for the custom senders' codes
name it alias/ccit-ci-senders
create role ccit-ci-trigger-exec
set the one inline policy of ccit-ci-trigger-exec
create Lambda ccit-ci-pre-sign-up (Node.js 22, no reserved concurrency)
create Lambda ccit-ci-discard-sender (Node.js 22, no reserved concurrency)
create user pool ccit-ci-email-alias (pools/email-alias.json, self sign-up on, custom senders)
let cognito-idp.amazonaws.com invoke ccit-ci-discard-sender (cognito-email-alias)
let cognito-idp.amazonaws.com invoke ccit-ci-pre-sign-up (cognito-email-alias)
create app client ccit-ci-email-alias-client (public, pools/email-alias.json \`client\`)
set the key policy of alias/ccit-ci-senders to the ccit-ci- pools"

the_default_dry_run_plans_exactly_phase_1() {
    fresh_state
    local before
    before=$(jq -S . "$FAKE_STATE")
    run
    (( STATUS == 0 )) && only_reads && no_identifiers && plus_lines_are_ours \
        && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] \
        && [[ "$(sed -nE 's/^  \+ //p' <<<"$OUT")" == "$PHASE1_PLAN" ]] \
        && [[ "$OUT" == *"Dry run (scope email-alias)"* && "$OUT" == *"Planned: 15 calls. Nothing was changed."* ]] \
        || { echo "$OUT" | sed -nE 's/^  \+ //p'; return 1; }
}

a_dry_run_of_both_phases_plans_everything() {
    fresh_state
    local before
    before=$(jq -S . "$FAKE_STATE")
    run --scope all
    (( STATUS == 0 )) && only_reads && no_identifiers && plus_lines_are_ours \
        && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] \
        && [[ "$OUT" == *"+ create user pool ccit-ci-default"* && "$OUT" == *"+ create user pool ccit-ci-email-alias"* ]] \
        && [[ "$OUT" == *"+ create identity pool ccit_ci_default"* && "$OUT" == *"+ store /ccit-ci/custom-challenge-answer"* ]] \
        && [[ "$OUT" == *"+ create AppSync API ccit-ci-codes"* && "$OUT" == *"+ create Lambda ccit-ci-custom-sender"* ]] \
        && [[ "$OUT" == *"+ store /ccit-ci/new-password-temporary (SecureString, encrypted with alias/ccit-ci-senders)"* ]] \
        && [[ "$(grep -c 'aws ssm put-parameter --cli-input-json <input: Description,KeyId,Name,Tags,Type,Value>' <<<"$OUT")" == 2 ]] \
        && [[ "$OUT" == *"Nothing was changed."* ]]
}

untagged_name_is_refused() { # mode: "" (dry run) or --apply
    fresh_state
    jq '.pools["us-east-1_Untagged01"] = {UserPool: {Id: "us-east-1_Untagged01", Name: "ccit-ci-email-alias", UserPoolTags: {}},
        clients: {}, mfa: {MfaConfiguration: "OFF"}}' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    local before
    before=$(jq -S . "$FAKE_STATE")
    run "$@"
    (( STATUS == 1 )) && only_reads && [[ "$OUT" == *"exists without purpose=amplify-cognito-client-integ"* ]] \
        && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] && no_identifiers
}

CONFIG=""
config_dir_of() {
    sed -nE 's#^Wrote the client.s CI configuration \(mode 600\) into (.*):$#\1#p' <<<"$1"
}

phase_1_creates_only_the_device_alias_pool() {
    fresh_state
    local before alias
    before=$(plugin_part)
    run --apply --upload
    (( STATUS == 0 )) || { echo "$OUT" | tail -5; return 1; }
    no_identifiers && plus_lines_are_ours && [[ "$(plugin_part)" == "$before" ]] || return 1
    CONFIG=$(config_dir_of "$OUT")
    [[ "$(find "$CONFIG" -type f -exec basename {} \;)" == ccit-ci-email-alias-amplify_outputs.json ]] || return 1
    alias="$CONFIG/ccit-ci-email-alias-amplify_outputs.json"
    jq -e '(.auth.username_attributes == ["email"]) and (.data == null)
        and (.custom == {amplify_cognito_client_integ: {confirming_trigger: true}})' "$alias" >/dev/null || return 1
    [[ "$(calls | grep -c 's3api put-object')" == 1 ]] || return 1
    jq -e '([.pools[] | .UserPool.Name] | sort == ["amplify-plugin-default", "ccit-ci-email-alias"])
        and ([.pools[] | select(.UserPool.Name == "ccit-ci-email-alias") | .UserPool | .UserPoolTier == "LITE"
              and (.LambdaConfig.CustomEmailSender.LambdaArn | endswith(":function:ccit-ci-discard-sender"))
              and (.LambdaConfig.CustomSMSSender.LambdaArn | endswith(":function:ccit-ci-discard-sender"))
              and (.LambdaConfig.PreSignUp | endswith(":function:ccit-ci-pre-sign-up"))
              and (.UserPoolTags.purpose == "amplify-cognito-client-integ")] == [true])
        and ([.lambdas | keys[]] | sort == ["ccit-ci-discard-sender", "ccit-ci-pre-sign-up", "plugin-pre-sign-up"])
        and (.lambdas["ccit-ci-pre-sign-up"].config.Environment.Variables == {REFUSE_CONFIRMATION_USERS: "1"})
        and ([.roles | keys[]] | sort == ["ccit-ci-trigger-exec", "plugin-role"])
        and ((.tables // {}) == {}) and ((.apis // {}) == {}) and ((.ssm // {}) == {}) and ((.rules // {}) == {})
        and ([.identity_pools[] | .IdentityPoolName] == ["plugin_identity"])
        and ([.log_groups | keys[]] == ["/aws/lambda/ccit-ci-discard-sender", "/aws/lambda/ccit-ci-pre-sign-up"])
        and ([.s3 | keys[] | select(contains("cognito-client-ci"))] == ["v2/testconfiguration/auth/cognito-client-ci/ccit-ci-email-alias-amplify_outputs.json"])
        and (([.pools[] | select(.UserPool.Name == "ccit-ci-email-alias") | .UserPool.Arn]) as $a
             | [.kms.keys[] | .policy.Statement[1].Condition.ArnEquals["aws:SourceArn"]] == [$a])' "$FAKE_STATE" >/dev/null
}

# The files the client reads from the alias-codes pool and the capabilities, in $CONFIG: the pool's outputs with
# email as the username, the code sink and no mark; the capabilities, by the client's role names.
alias_codes_files_are_right() {
    local codes="$CONFIG/ccit-ci-email-alias-codes-amplify_outputs.json" default="$CONFIG/ccit-ci-default-amplify_outputs.json"
    jq -e '(.auth.username_attributes == ["email"]) and .data.url and .data.api_key and (.custom == null)
        and (.auth.identity_pool_id == null)' "$codes" >/dev/null || return 1
    [[ "$(jq -r .data.api_key "$codes")" == "$(jq -r .data.api_key "$default")" ]] || return 1
    [[ "$(jq -r .auth.user_pool_id "$codes")" != "$(jq -r .auth.user_pool_id "$default")" ]] || return 1
    jq -e '. == {capabilities: {extended: ["refuses_non_test_users", "reset_password_codes"],
        "email-alias-codes": ["email_alias_codes"]}}' "$CONFIG/ccit-ci-capabilities.json" >/dev/null
}

# The MFA-required pool as made: its template's Essentials and MFA (required, TOTP and SMS), the device-alias pool's
# trigger and the discard sender, the template's `ci` app client only, and the SMS role named; its outputs file names
# that client, MFA required with SMS and TOTP, and no code API or mark.
mfa_required_pool_is_right() {
    local template="$CI_DIR/../pools/mfa-req-totp-sms.json" file="$CONFIG/ccit-ci-mfa-req-totp-sms-amplify_outputs.json"
    jq -e --slurpfile t "$template" '[.pools[] | select(.UserPool.Name == "ccit-ci-mfa-req-totp-sms")] as $p
        | ($p | length == 1) and ($p[0].UserPool | .UserPoolTier == "ESSENTIALS"
            and (.LambdaConfig.PreSignUp | endswith(":function:ccit-ci-pre-sign-up"))
            and (.LambdaConfig.CustomEmailSender.LambdaArn | endswith(":function:ccit-ci-discard-sender"))
            and (.LambdaConfig.CustomSMSSender.LambdaArn | endswith(":function:ccit-ci-discard-sender"))
            and (.SmsConfiguration.SnsCallerArn | endswith(":role/ccit-ci-cognito-sms"))
            and (.UserPoolTags.purpose == "amplify-cognito-client-integ"))
        and ($p[0].mfa.MfaConfiguration == "ON") and ($p[0].mfa.SoftwareTokenMfaConfiguration.Enabled == true)
        and ([$p[0].clients[] | .ClientName] == ["ccit-ci-mfa-req-totp-sms-ci"])
        and ([$p[0].clients[] | .ExplicitAuthFlows] == [$t[0].appClients.ci.ExplicitAuthFlows])
        and ([.lambdas["ccit-ci-discard-sender", "ccit-ci-pre-sign-up"]
              | [.policy[] | select(.Sid == "cognito-mfa-req-totp-sms") | .Condition.ArnLike["AWS:SourceArn"]]]
             == [[$p[0].UserPool.Arn], [$p[0].UserPool.Arn]])' \
        "$FAKE_STATE" >/dev/null || return 1
    jq -e '(.auth.mfa_configuration == "REQUIRED") and (.auth.mfa_methods == ["SMS", "TOTP"]) and (.data == null)
        and (.custom == null) and (.auth.identity_pool_id == null)' "$file" >/dev/null || return 1
    [[ "$(jq -r .auth.user_pool_client_id "$file")" == "$(jq -r '.pools[] | select(.UserPool.Name == "ccit-ci-mfa-req-totp-sms")
        | .clients | keys[0]' "$FAKE_STATE")" ]]
}

# The alias-codes pool as made: Lite, the confirmable trigger (no refusal of ccit-confirm- users), the custom
# sender; the key narrowed to the three pools, the sender's decrypt to the two it sends for, the triggers' role
# writing the new trigger's logs.
alias_codes_pool_is_right() {
    jq -e '([.pools[] | select(.UserPool.Name | startswith("ccit-ci-")) | .UserPool.Arn] | sort) as $arns
        | ([.pools[] | select(.UserPool.Name == "ccit-ci-default" or .UserPool.Name == "ccit-ci-email-alias-codes")
            | .UserPool.Id] | sort) as $senders
        | ([.pools[] | select(.UserPool.Name == "ccit-ci-email-alias-codes") | .UserPool | .UserPoolTier == "LITE"
              and (.LambdaConfig.PreSignUp | endswith(":function:ccit-ci-pre-sign-up-confirmable"))
              and (.LambdaConfig.CustomEmailSender.LambdaArn | endswith(":function:ccit-ci-custom-sender"))
              and (.LambdaConfig.CustomSMSSender.LambdaArn | endswith(":function:ccit-ci-custom-sender"))
              and (.UsernameAttributes == ["email"])
              and (.UserPoolTags.purpose == "amplify-cognito-client-integ")] == [true])
        and (.lambdas["ccit-ci-pre-sign-up-confirmable"].config.Environment.Variables == {})
        and (.lambdas["ccit-ci-pre-sign-up-confirmable"].config.Handler == "triggers.preSignUp")
        and ([.lambdas["ccit-ci-custom-sender"].policy[].Sid] | sort == ["cognito-default", "cognito-email-alias-codes"])
        and ($arns | length == 4)
        and ([.kms.keys[] | .policy.Statement[1].Condition.ArnEquals["aws:SourceArn"]] == [$arns])
        and (.roles["ccit-ci-sender-exec"].inline["ccit-ci-sender-exec-policy"].Statement[1].Condition.StringEquals["kms:EncryptionContext:userpool-id"] == $senders)
        and (.roles["ccit-ci-trigger-exec"].inline["ccit-ci-trigger-exec-policy"].Statement[0].Resource
            | any(contains(":log-group:/aws/lambda/ccit-ci-pre-sign-up-confirmable:")))' "$FAKE_STATE" >/dev/null
}

# Both SSM parameters are encrypted with the ccit-ci key, and the reset Lambda may decrypt the temporary password
# with it, through SSM, for that parameter only.
secrets_use_the_ccit_ci_key() {
    jq -e '(.kms.aliases["alias/ccit-ci-senders"]) as $id | ([.kms.keys | keys[] | select(. == $id)] | length == 1)
        and ([.ssm[] | .key] == ["arn:aws:kms:us-east-1:\(.account):key/\($id)", "arn:aws:kms:us-east-1:\(.account):key/\($id)"])
        and ([.roles["ccit-ci-reset-exec"].inline["ccit-ci-reset-exec-policy"].Statement[]
              | select(.Sid == "DecryptTemporaryPassword")
              | .Action == "kms:Decrypt" and (.Resource | endswith(":key/\($id)"))
                and .Condition.StringEquals["kms:ViaService"] == "ssm.us-east-1.amazonaws.com"
                and (.Condition.StringEquals["kms:EncryptionContext:PARAMETER_ARN"]
                     | endswith(":parameter/ccit-ci/new-password-temporary"))] == [true])' "$FAKE_STATE" >/dev/null
}

# The code sink key's weekly extension as made: the function, from ci/lambda/extend-api-key, told the code sink's API
# and the script's own lifetime, allowance and threshold; its role, allowed only its logs and the two AppSync calls
# on that API's ARN; and the weekly rule, the function its one target and allowed to invoke it from that rule only;
# each tagged.
key_extension_is_right() {
    jq -e '(.apis | to_entries[] | select(.value.api.name == "ccit-ci-codes") | .value.api) as $api
        | .lambdas["ccit-ci-extend-api-key"] as $f | .roles["ccit-ci-key-exec"] as $r | .rules["ccit-ci-extend-api-key"] as $e
        | ($f.config | .Handler == "index.handler" and (.Role | endswith(":role/ccit-ci-key-exec")) and .Timeout == 30
            and .Environment.Variables == {API_ID: $api.apiId, KEY_DAYS: "365", CLOCK_ALLOWANCE_SECONDS: "600",
                                           EXTEND_WITHIN_DAYS: "120"})
        and ($f.tags.purpose == "amplify-cognito-client-integ")
        and ($r.Role.AssumeRolePolicyDocument.Statement == [{Effect: "Allow", Principal: {Service: "lambda.amazonaws.com"},
             Action: "sts:AssumeRole", Condition: {StringEquals: {"aws:SourceAccount": .account}}}])
        and ($r.tags == [{Key: "purpose", Value: "amplify-cognito-client-integ"}]) and ($r.attached == [])
        and ($r.inline | keys == ["ccit-ci-key-exec-policy"])
        and ($r.inline["ccit-ci-key-exec-policy"].Statement == [
             {Sid: "WriteOwnLogs", Effect: "Allow", Action: ["logs:CreateLogStream", "logs:PutLogEvents"],
              Resource: ["arn:aws:logs:us-east-1:\(.account):log-group:/aws/lambda/ccit-ci-extend-api-key:*"]},
             {Sid: "ExtendTestsKey", Effect: "Allow", Action: ["appsync:ListApiKeys", "appsync:UpdateApiKey"],
              Resource: $api.arn}])
        and ($e.rule.ScheduleExpression == "rate(7 days)") and ($e.tags == [{Key: "purpose", Value: "amplify-cognito-client-integ"}])
        and ($e.targets == [{Id: "extend-api-key", Arn: $f.config.FunctionArn}])
        and ($f.policy == [{Sid: "events-schedule", Principal: {Service: "events.amazonaws.com"},
             Condition: {ArnLike: {"AWS:SourceArn": $e.rule.Arn}}}])
        and (.log_groups["/aws/lambda/ccit-ci-extend-api-key"] == {tags: {purpose: "amplify-cognito-client-integ"}, retention: 7})' \
        "$FAKE_STATE" >/dev/null
}

phase_2_adds_the_default_pool_and_keeps_phase_1() {
    local before modes default rotation
    before=$(plugin_part)
    run --apply --scope all --upload
    (( STATUS == 0 )) || { echo "$OUT" | tail -5; return 1; }
    no_identifiers && plus_lines_are_ours && [[ "$(plugin_part)" == "$before" ]] || return 1
    [[ "$OUT" == *"= user pool ccit-ci-email-alias"* && "$OUT" == *"= auth/cognito-client-ci/ccit-ci-email-alias-amplify_outputs.json (uploaded already, the same bytes)"* ]] || return 1
    [[ "$(calls | grep -c 's3api put-object')" == 6 ]] || return 1
    CONFIG=$(config_dir_of "$OUT")
    [[ -d "$CONFIG" && "$(stat -f '%Lp' "$CONFIG")" == 700 ]] || return 1
    modes=$(find "$CONFIG" -type f -exec stat -f '%Lp' {} + | sort -u)
    [[ "$modes" == 600 && "$(find "$CONFIG" -type f | wc -l | tr -d ' ')" == 7 ]] || return 1
    alias_codes_files_are_right && alias_codes_pool_is_right && mfa_required_pool_is_right || return 1
    default="$CONFIG/ccit-ci-default-amplify_outputs.json"
    rotation="$CONFIG/ccit-ci-rotation-amplify_outputs.json"
    jq -e '.auth.identity_pool_id and .auth.unauthenticated_identities_enabled and .data.url and .data.api_key
        and (.auth.mfa_methods == ["SMS", "TOTP"]) and (.custom == null)' "$default" >/dev/null || return 1
    [[ "$(jq -r .auth.user_pool_id "$rotation")" == "$(jq -r .auth.user_pool_id "$default")" ]] || return 1
    [[ "$(jq -r .auth.user_pool_client_id "$rotation")" != "$(jq -r .auth.user_pool_client_id "$default")" ]] || return 1
    jq -e '(keys == ["custom_challenge_answer", "new_password_required_temporary_password", "new_password_required_usernames"])
        and all(.[]; type == "string" and length > 0)
        and (.new_password_required_usernames | split(",") | length == 12)' "$CONFIG/ccit-ci-default-credentials.json" >/dev/null || return 1
    # Everything created is ccit-ci- and tagged.
    jq -e '([.pools[] | select(.UserPool.Name | startswith("ccit-ci-")) | .UserPool.UserPoolTags.purpose] | length == 4 and (unique == ["amplify-cognito-client-integ"]))
        and ([.pools[] | .UserPool.Name] | sort == ["amplify-plugin-default", "ccit-ci-default", "ccit-ci-email-alias", "ccit-ci-email-alias-codes", "ccit-ci-mfa-req-totp-sms"])
        and ([.pools[] | select(.UserPool.Name == "ccit-ci-default") | .UserPool.UserPoolTier] == ["ESSENTIALS"])
        and ([.roles | keys[] | select(startswith("ccit-ci-"))] | length == 8)
        and ([.roles[] | select(.Role.RoleName | startswith("ccit-ci-")) | .tags[0].Value] | unique == ["amplify-cognito-client-integ"])
        and ([.lambdas[] | select(.config.FunctionName | startswith("ccit-ci-")) | .tags.purpose] | length == 9 and (unique == ["amplify-cognito-client-integ"]))
        and ([.lambdas[] | .config.FunctionName] | all(startswith("ccit-ci-") or . == "plugin-pre-sign-up"))
        and ([.ssm | keys[]] == ["/ccit-ci/custom-challenge-answer", "/ccit-ci/new-password-temporary"])
        and ([.identity_pools[] | .IdentityPoolName] | sort == ["ccit_ci_default", "plugin_identity"])' "$FAKE_STATE" >/dev/null || return 1
    # The SMS role is narrowed to the default and MFA-required pools, the two that name it (the key and the decrypt:
    # above).
    jq -e '([.pools[] | select(.UserPool.Name == "ccit-ci-default" or .UserPool.Name == "ccit-ci-mfa-req-totp-sms")
            | .UserPool.Arn] | sort) as $sms
        | .roles["ccit-ci-cognito-sms"].Role.AssumeRolePolicyDocument.Statement[0].Condition.ArnEquals["aws:SourceArn"] == $sms' \
        "$FAKE_STATE" >/dev/null || return 1
    secrets_use_the_ccit_ci_key && key_extension_is_right || return 1
    [[ "$OUT" == *"new-password users: created 12"* ]]
}

a_second_apply_makes_no_call_and_uploads_nothing() {
    run --apply --scope all --upload
    (( STATUS == 0 )) && [[ "$OUT" == *"Done: 0 calls made."* ]] && ! calls | grep -q 'put-object' && no_identifiers
}

# Phase 1 after phase 2: --apply refuses, the default scope and --scope email-alias alike, before its dry run, with
# read calls only and nothing changed, naming the phase-2 resources it found and --scope all. A dry run says --apply
# would refuse, and plans nothing: the triggers' role keeps the phase-2 triggers' log groups.
PHASE_1_REFUSAL="Refusing: phase 2 exists here (ccit-ci-default ccit-ci-email-alias-codes ccit-ci-mfa-req-totp-sms and 15 more), and --scope email-alias, the default, is phase 1: it would make only ccit-ci-pre-sign-up and ccit-ci-discard-sender again, and give only ccit-ci-email-alias its invoke permissions. Run infra/ci/provision-ci.sh --apply --scope all instead."
a_phase_1_apply_after_phase_2_is_refused() {
    local before args
    before=$(jq -S . "$FAKE_STATE")
    for args in "--apply --upload" "--apply --scope email-alias"; do
        # shellcheck disable=SC2086 # split on purpose: each case is a list of arguments
        run $args
        (( STATUS == 1 )) && only_reads && no_identifiers && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] \
            && [[ "$OUT" == *"$PHASE_1_REFUSAL"* && "$OUT" != *"Checking with a dry run first"* ]] \
            || { echo "$args: $OUT" | tail -5; return 1; }
    done
    run
    (( STATUS == 0 )) && only_reads && [[ "$OUT" == *"Note: --apply would refuse: phase 2 exists here"* ]] \
        && [[ "$OUT" == *"Planned: 0 calls."* ]] || { echo "$OUT" | tail -5; return 1; }
    no_identifiers && jq -e '.roles["ccit-ci-trigger-exec"].inline["ccit-ci-trigger-exec-policy"].Statement[0].Resource
        | any(contains(":log-group:/aws/lambda/ccit-ci-verify-auth-challenge:"))' "$FAKE_STATE" >/dev/null
}

# The code sink's key, 10 days from its expiry, is extended in place: the same id, so the uploaded files that name it
# stay as they are, and nothing is uploaded. Both runs say the new expiry.
an_api_key_near_its_expiry_is_extended_in_place() {
    local key soon after
    key=$(jq -r '[.apis[] | .keys[]] | .[0].id' "$FAKE_STATE")
    soon=$(( $(date +%s) + 10 * 86400 ))
    jq --argjson e "$soon" '(.apis[] | .keys[]).expires = $e' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    run --scope all --upload
    (( STATUS == 0 )) && only_reads && no_identifiers \
        && [[ "$(sed -nE 's/^  \+ //p' <<<"$OUT")" == "extend the tests' read-only API key to 365 days from now (the same key)" ]] \
        && [[ "$OUT" == *"The code sink's API key expires on $(new_key_date) after this run."* ]] \
        || { echo "$OUT" | sed -nE 's/^  \+ //p'; return 1; }
    run --apply --scope all --upload
    (( STATUS == 0 )) && [[ "$OUT" == *"Done: 1 calls made."* ]] && ! calls | grep -qE 'put-object|create-api-key' \
        && no_identifiers && [[ "$(grep -c 'uploaded already, the same bytes' <<<"$OUT")" == 7 ]] \
        || { echo "$OUT" | tail -8; return 1; }
    jq -e --arg k "$key" --argjson e "$(( $(date +%s) + 300 * 86400 ))" \
        '[.apis[] | .keys[]] | length == 1 and .[0].id == $k and .[0].expires > $e' "$FAKE_STATE" >/dev/null || return 1
    after=$(jq -r '[.apis[] | .keys[]] | .[0].expires' "$FAKE_STATE")
    after=$(date -u -r "$after" +%Y-%m-%d 2>/dev/null || date -u -d "@$after" +%Y-%m-%d)
    [[ "$OUT" == *"The code sink's API key expires on $after after this run."* ]] \
        || { echo "$OUT" | grep 'expires on'; return 1; }
}

# A rerun at the edges of the reuse threshold (dry runs only; the key is put back after): a key that lives
# KEY_REUSE_DAYS (120) more days and 10 minutes is reused, one 10 minutes short of them is extended, so is one an hour
# from its expiry, and so is one that expired a second or 59 days ago, which AppSync still keeps (the dry run says
# what follows if AppSync refuses it); one that AppSync has deleted (60 days after it expired), though still listed,
# is replaced by a new key.
a_rerun_reuses_or_extends_the_key_at_the_threshold() {
    local before now case expires plan
    before=$(jq -c '[.apis[] | .keys[]]' "$FAKE_STATE")
    [[ "$(jq length <<<"$before")" == 1 ]] || { echo "not one key: $before"; return 1; }
    now=$(date +%s)
    # <expiry, from now>:<what the rerun plans>
    for case in $((120 * 86400 + 600)):reuse $((120 * 86400 - 600)):extend 3600:extend -1:expired \
        $((-59 * 86400)):expired $((-61 * 86400)):create; do
        expires=$(( now + ${case%%:*} ))
        jq --argjson e "$expires" '(.apis[] | .keys[]) |= (.expires = $e | .deletes = $e + 60 * 86400)' "$FAKE_STATE" \
            > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
        run --scope all
        plan=$(sed -nE 's/^  \+ //p' <<<"$OUT")
        (( STATUS == 0 )) && only_reads || { echo "$case: $OUT" | tail -5; return 1; }
        case "${case##*:}" in
            extend) [[ "$plan" == "extend the tests' read-only API key to 365 days from now (the same key)" ]] ;;
            reuse) [[ -z "$plan" && "$OUT" == *"= the code sink API key (lives more than 120 more days)"* ]] ;;
            expired)
                [[ "$plan" == "extend the tests' read-only API key, which has expired, to 365 days from now (the same key, if AppSync takes it)" ]] \
                    && [[ "$OUT" == *"If AppSync refuses to extend the expired key, --apply makes a new one instead"* ]] \
                    && [[ "$OUT" != *"but the uploaded"* ]] ;;
            create) [[ "$plan" == "create the tests' read-only API key, for 365 days" ]] ;;
        esac || { echo "$case: $plan"; return 1; }
    done
    jq --argjson k "$before" '(.apis[] | .keys) = $k' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    [[ "$(jq -c '[.apis[] | .keys[]]' "$FAKE_STATE")" == "$before" ]]
}

days_from_now() { python3 -c 'import datetime,sys;print(datetime.datetime.now(datetime.timezone.utc).date() + datetime.timedelta(days=int(sys.argv[1])))' "$1"; }

# The UTC date a key made or extended now expires on: 365 days from now, less the 10-minute clock allowance, rounded
# down to the hour.
new_key_date() { python3 -c 'import datetime,time;e=(int(time.time())+365*86400-600)//3600*3600;print(datetime.datetime.fromtimestamp(e,datetime.timezone.utc).date())'; }

# The key is made and extended for 365 days, AppSync's maximum, to the hour, and within AppSync's bounds (which the
# fake checks, as AppSync does) though AppSync's clock is 5 minutes behind the script's. The script's clock is set
# (through the fake `date`) to 1 minute past an hour, where rounding down alone would leave no room for that. The
# state is put back after.
the_key_lives_365_days_within_appsyncs_bounds() {
    local saved="$WORK/key-bounds-state.json" offset now case expires
    cp "$FAKE_STATE" "$saved"
    for case in extend create; do
        if [[ "$case" == extend ]]; then
            jq --argjson e "$(( $(date +%s) + 10 * 86400 ))" '(.apis[] | .keys[]).expires = $e' "$FAKE_STATE" > "$WORK/s"
        else
            jq '(.apis[] | .keys) = []' "$FAKE_STATE" > "$WORK/s"
        fi
        mv "$WORK/s" "$FAKE_STATE"
        now=$(date +%s)
        # The script's clock: 60 s past the next hour; AppSync's: 300 s behind it.
        offset=$(( 3600 - now % 3600 + 60 ))
        : > "$FAKE_LOG"
        STATUS=0
        OUT=$(FAKE_DATE_OFFSET="$offset" FAKE_APPSYNC_CLOCK_BEHIND=$(( 300 - offset )) "$SCRIPT" --apply --scope all 2>&1) \
            || STATUS=$?
        expires=$(jq '[.apis[] | .keys[]] | sort_by(.expires) | last | .expires' "$FAKE_STATE")
        # Made or extended (a new key's run then refuses at the end, over the uploaded files that name the old one).
        [[ "$OUT" == *"+ "*"read-only API key"*"365 days"* && "$OUT" != *ApiKeyValidityOutOfBounds* ]] \
            && (( expires % 3600 == 0 )) \
            && (( expires > now + offset + 365 * 86400 - 3600 - 600 && expires <= now + offset + 365 * 86400 - 600 )) \
            || { echo "$case: $expires"; echo "$OUT" | tail -5; return 1; }
        if [[ "$case" == extend ]]; then (( STATUS == 0 )) || { echo "$OUT" | tail -5; return 1; }; fi
    done
    # And the fake refuses what AppSync refuses: more than 365 days from its own clock.
    jq '(.apis[] | .keys) = []' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(FAKE_APPSYNC_CLOCK_BEHIND=4500 "$SCRIPT" --apply --scope all 2>&1) || STATUS=$?
    cp "$saved" "$FAKE_STATE"
    (( STATUS == 1 )) && [[ "$OUT" == *ApiKeyValidityOutOfBoundsException* ]] || { echo "$OUT" | tail -5; return 1; }
}

# An expired key that AppSync still keeps is extended in place when AppSync takes it, as its API reference says it
# does: the same key, one call, and the uploaded files that name it stay as they are.
an_expired_key_is_extended_in_place_when_appsync_takes_it() {
    local key saved="$WORK/expired-in-place-state.json"
    cp "$FAKE_STATE" "$saved"
    key=$(jq -r '[.apis[] | .keys[]] | .[0].id' "$FAKE_STATE")
    jq --argjson e "$(( $(date +%s) - 86400 ))" '(.apis[] | .keys[]).expires = $e' "$FAKE_STATE" > "$WORK/s" \
        && mv "$WORK/s" "$FAKE_STATE"
    run --apply --scope all --upload
    cp "$FAKE_STATE" "$WORK/expired-in-place-after.json"
    cp "$saved" "$FAKE_STATE"
    (( STATUS == 0 )) && [[ "$OUT" == *"Done: 1 calls made."* ]] && no_identifiers \
        && [[ "$(sed -nE 's/^  \+ //p' <<<"$OUT")" == "extend the tests' read-only API key, which has expired, to 365 days from now (the same key, if AppSync takes it)" ]] \
        && ! calls | grep -qE 'put-object|create-api-key' && [[ "$(grep -c 'uploaded already, the same bytes' <<<"$OUT")" == 7 ]] \
        && [[ "$OUT" == *"The code sink's API key expires on $(new_key_date) after this run."* && "$OUT" != *"refused"* ]] \
        || { echo "$OUT" | tail -8; return 1; }
    jq -e --arg k "$key" --argjson e "$(( $(date +%s) + 300 * 86400 ))" \
        '[.apis[] | .keys[]] | length == 1 and .[0].id == $k and .[0].expires > $e' "$WORK/expired-in-place-after.json" >/dev/null
}

# An expired key AppSync refuses to extend (FAKE_APPSYNC_EXPIRED_KEYS): --apply tries, then makes a new one, but the
# two uploaded files that name the old key are never overwritten: --apply names them, says how to replace them and
# refuses at the end, its upload refused, all with read calls only to tell. Once both are deleted (by hand, after
# their tag check), a rerun with --upload uploads them with the new key.
an_expired_key_needs_the_uploads_that_name_it_replaced() {
    local prefix="v2/testconfiguration/auth/cognito-client-ci" file newest
    local stale="ccit-ci-default-amplify_outputs.json ccit-ci-email-alias-codes-amplify_outputs.json name another code sink key"
    jq --argjson e "$(( $(date +%s) - 86400 ))" '(.apis[] | .keys[]).expires = $e' "$FAKE_STATE" > "$WORK/s" \
        && mv "$WORK/s" "$FAKE_STATE"
    FAKE_APPSYNC_EXPIRED_KEYS=BadRequestException run --apply --scope all --upload
    (( STATUS == 1 )) && [[ "$OUT" == *"+ extend the tests' read-only API key, which has expired, to 365 days from now"* ]] \
        && [[ "$OUT" == *"AppSync refused to extend the expired key (BadRequestException): a new key instead."* ]] \
        && [[ "$OUT" == *"+ create the tests' read-only API key, for 365 days"* ]] \
        && [[ "$OUT" == *"after this run, but the uploaded auth/cognito-client-ci/ files $stale"* ]] \
        && [[ "$OUT" == *"purpose=amplify-cognito-client-integ"*"--apply --scope all --upload"* ]] \
        && [[ "$OUT" == *"than the one that expires on"*"go on using the other key"* ]] \
        && [[ "$OUT" == *"get-object-tagging), delete them"*"uploads them again with the current key"* ]] \
        && [[ "$OUT" == *"nothing is ever overwritten"* ]] && ! calls | grep -q 'put-object' \
        && no_identifiers || { echo "$OUT" | tail -8; return 1; }
    # Without --upload, the run finishes, then refuses with the steps.
    run --apply --scope all
    (( STATUS == 1 )) && [[ "$OUT" == *"Done: 0 calls made."*"Refusing: the uploaded auth/cognito-client-ci/ files $stale"* ]] \
        || { echo "$OUT" | tail -5; return 1; }
    # Both deleted by hand: the rerun uploads them with the new key.
    jq --arg a "$prefix/ccit-ci-default-amplify_outputs.json" --arg b "$prefix/ccit-ci-email-alias-codes-amplify_outputs.json" \
        'del(.s3[$a], .s3[$b])' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    run --apply --scope all --upload
    (( STATUS == 0 )) && [[ "$(calls | grep -c 's3api put-object')" == 2 ]] && no_identifiers \
        && [[ "$OUT" == *"The code sink's API key expires on "*" after this run."* && "$OUT" != *"but the uploaded"* ]] \
        || { echo "$OUT" | tail -8; return 1; }
    newest=$(jq -r '[.apis[] | .keys[]] | sort_by(.expires) | last | .id' "$FAKE_STATE")
    for file in ccit-ci-default-amplify_outputs.json ccit-ci-email-alias-codes-amplify_outputs.json; do
        [[ "$(jq -r --arg k "$prefix/$file" '.s3[$k].body | fromjson | .data.api_key' "$FAKE_STATE")" == "$newest" ]] \
            || { echo "$file does not name the new key"; return 1; }
    done
}

# An uploaded key with other contents refuses the whole upload. The file is put back after, so later uploads find
# every file the same.
a_key_with_other_contents_refuses_the_upload() {
    local key="v2/testconfiguration/auth/cognito-client-ci/ccit-ci-default-credentials.json" body
    body=$(jq -c --arg k "$key" '.s3[$k].body' "$FAKE_STATE")
    jq --arg k "$key" '.s3[$k].body = "{}"' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    run --apply --scope all --upload
    jq --arg k "$key" --argjson b "$body" '.s3[$k].body = $b' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    (( STATUS == 1 )) && [[ "$OUT" == *"nothing is ever overwritten"* ]] && ! calls | grep -q 'put-object' \
        && only_reads && no_identifiers
}

# What a rerun over phase 2 as first applied (80712afe4) plans: the alias-codes and MFA-required pools and what they
# need, the updates to the script's own resources that name them (the SMS role's trust opened while the MFA-required
# pool is made, then narrowed), the code sink key's weekly extension (its log group, role, function and rule), and
# the three new files. The code sink key that script made (for 364 days) is reused,
# as the live one is: it lives more than KEY_REUSE_DAYS.
RERUN_PLAN="create log group /aws/lambda/ccit-ci-pre-sign-up-confirmable
keep /aws/lambda/ccit-ci-pre-sign-up-confirmable for 7 days
create log group /aws/lambda/ccit-ci-extend-api-key
keep /aws/lambda/ccit-ci-extend-api-key for 7 days
open the key policy of alias/ccit-ci-senders to the account's pools while a ccit-ci- pool is made
set the one inline policy of ccit-ci-trigger-exec
open the trust of ccit-ci-cognito-sms to the account's pools while a ccit-ci- SMS pool is made
store /ccit-ci/custom-challenge-answer again, the same value, encrypted with alias/ccit-ci-senders
store /ccit-ci/new-password-temporary again, the same value, encrypted with alias/ccit-ci-senders
create Lambda ccit-ci-pre-sign-up-confirmable (Node.js 22, no reserved concurrency)
create user pool ccit-ci-email-alias-codes (pools/email-alias.json, self sign-up on, custom senders)
let cognito-idp.amazonaws.com invoke ccit-ci-custom-sender (cognito-email-alias-codes)
let cognito-idp.amazonaws.com invoke ccit-ci-pre-sign-up-confirmable (cognito-email-alias-codes)
create app client ccit-ci-email-alias-codes-client (public, pools/email-alias.json \`client\`)
create user pool ccit-ci-mfa-req-totp-sms (pools/mfa-req-totp-sms.json, self sign-up on, custom senders)
let cognito-idp.amazonaws.com invoke ccit-ci-discard-sender (cognito-mfa-req-totp-sms)
let cognito-idp.amazonaws.com invoke ccit-ci-pre-sign-up (cognito-mfa-req-totp-sms)
set the MFA configuration of ccit-ci-mfa-req-totp-sms
create app client ccit-ci-mfa-req-totp-sms-ci (public, pools/mfa-req-totp-sms.json \`ci\`)
set the key policy of alias/ccit-ci-senders to the ccit-ci- pools
set the one inline policy of ccit-ci-sender-exec
set the trust of ccit-ci-cognito-sms to the ccit-ci- SMS pools
set the one inline policy of ccit-ci-reset-exec
create role ccit-ci-key-exec
set the one inline policy of ccit-ci-key-exec
create Lambda ccit-ci-extend-api-key (Node.js 22, no reserved concurrency)
schedule ccit-ci-extend-api-key every 7 days
let events.amazonaws.com invoke ccit-ci-extend-api-key (events-schedule)
point the schedule at Lambda ccit-ci-extend-api-key
upload auth/cognito-client-ci/ccit-ci-email-alias-codes-amplify_outputs.json (new key only)
upload auth/cognito-client-ci/ccit-ci-capabilities.json (new key only)
upload auth/cognito-client-ci/ccit-ci-mfa-req-totp-sms-amplify_outputs.json (new key only)"

# The script as phase 1 and phase 2 were applied with, from git; the whole infra/ directory it reads.
FROZEN_COMMIT=80712afe4
frozen_script() {
    local prefix
    prefix=$(git -C "$CI_DIR" rev-parse --show-prefix 2>/dev/null) || return 1
    git -C "$CI_DIR" cat-file -e "$FROZEN_COMMIT^{commit}" 2>/dev/null || return 1
    mkdir -p "$WORK/frozen"
    (cd "$(git -C "$CI_DIR" rev-parse --show-toplevel)" && git archive "$FROZEN_COMMIT" -- "${prefix%ci/}") \
        | tar -x -C "$WORK/frozen" || return 1
    FROZEN_SCRIPT="$WORK/frozen/${prefix}provision-ci.sh"
    [[ -x "$FROZEN_SCRIPT" ]]
}

a_rerun_over_phase_2_as_applied_adds_only_the_alias_codes_pool() {
    local before status out first second
    fresh_state
    # Phase 1, then phase 2, as the CI account has them.
    if ! "$FROZEN_SCRIPT" --apply --upload >/dev/null 2>&1 \
        || ! "$FROZEN_SCRIPT" --apply --scope all --upload >/dev/null 2>&1; then
        echo "the frozen script failed"
        return 1
    fi
    [[ "$(jq '[.s3 | keys[] | select(contains("cognito-client-ci"))] | length' "$FAKE_STATE")" == 4 ]] || return 1
    # As first applied, the parameters are under the AWS-managed key.
    [[ "$(jq -c '[.ssm[] | .key] | unique' "$FAKE_STATE")" == '["alias/aws/ssm"]' ]] || return 1
    rm -rf "$WORK/disc"
    run snapshot
    first=$(find "$WORK/disc" -name 'snapshot-*.json' ! -name '*.docs.json' | sort | tail -1)
    mv "$first" "$WORK/rerun-before.json" && mv "${first%.json}.docs.json" "$WORK/rerun-before.docs.json"
    before=$(jq -S . "$FAKE_STATE")
    run --scope all --upload
    (( STATUS == 0 )) && only_reads && no_identifiers && plus_lines_are_ours \
        && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] \
        && [[ "$(sed -nE 's/^  \+ //p' <<<"$OUT")" == "$RERUN_PLAN" ]] \
        && [[ "$OUT" == *"Planned: 32 calls. Nothing was changed."* ]] \
        && [[ "$OUT" == *"= the code sink API key (lives more than 120 more days)"* ]] \
        || { echo "$OUT" | sed -nE 's/^  \+ //p'; return 1; }
    before=$(plugin_part)
    run --apply --scope all --upload
    (( STATUS == 0 )) && no_identifiers && [[ "$(plugin_part)" == "$before" ]] \
        && [[ "$(sed -nE 's/^  \+ //p' <<<"$OUT")" == "$RERUN_PLAN" ]] \
        && [[ "$(grep -c 'uploaded already, the same bytes' <<<"$OUT")" == 4 ]] \
        && [[ "$(calls | grep -c 's3api put-object')" == 3 ]] || { echo "$OUT" | tail -8; return 1; }
    CONFIG=$(config_dir_of "$OUT")
    alias_codes_files_are_right && alias_codes_pool_is_right && mfa_required_pool_is_right && secrets_use_the_ccit_ci_key \
        || return 1
    # Only the script's own resources changed, every update the plan shows: the custom sender, given the new pool's
    # invoke permission (its revision, and its policy, as a function and as a trigger), the trigger and discard
    # sender likewise for the MFA-required pool, the three role policies, the SMS role's trust, the key policy and the
    # two parameters' key.
    run snapshot
    second=$(find "$WORK/disc" -name 'snapshot-*.json' ! -name '*.docs.json' | sort | tail -1)
    status=0
    out=$("$SCRIPT" verify-unchanged "$WORK/rerun-before.json" "$second" 2>&1) || status=$?
    (( status == 0 )) && [[ "$out" == *"changed  lambda ccit-ci-custom-sender: RevisionId (ccit-ci-, this script's own)"* ]] \
        && [[ "$out" == *"changed  trigger-lambda-policy ccit-ci-custom-sender: Statement (ccit-ci-, this script's own)"* ]] \
        && [[ "$out" == *"changed  iam-role-policies ccit-ci-trigger-exec: inline.ccit-ci-trigger-exec-policy (ccit-ci-, this script's own)"* ]] \
        && [[ "$out" == *"changed  kms-key-policy alias/ccit-ci-senders: Statement (ccit-ci-, this script's own)"* ]] \
        && [[ "$out" == *"changed  ssm-parameter /ccit-ci/new-password-temporary: KeyId (ccit-ci-, this script's own)"* ]] \
        && [[ "$out" == *"added    user-pool ccit-ci-email-alias-codes (ccit-ci-, expected)"* ]] \
        && [[ "$out" == *"added    user-pool ccit-ci-mfa-req-totp-sms (ccit-ci-, expected)"* ]] \
        && [[ "$out" == *"added    lambda ccit-ci-extend-api-key (ccit-ci-, expected)"* ]] \
        && [[ "$out" == *"added    events-rule ccit-ci-extend-api-key (ccit-ci-, expected)"* ]] \
        && [[ "$out" == *"changed  iam-role ccit-ci-cognito-sms: AssumeRolePolicyDocument.Statement (ccit-ci-, this script's own)"* ]] \
        && [[ "$out" == *"changed  lambda ccit-ci-discard-sender: RevisionId (ccit-ci-, this script's own)"* ]] \
        && [[ "$out" == *" 0 changed, 19 ccit-ci- changed, 0 removed"* ]] || { echo "$out"; return 1; }
    run --apply --scope all --upload
    (( STATUS == 0 )) && [[ "$OUT" == *"Done: 0 calls made."* ]]
}

# Foreign resources of the kinds a snapshot reads beyond the lists: an SSM parameter, a log group and a KMS key, and
# a secret on the plugin's app client. Removed again at the end, so teardown finds only its own.
FOREIGN_SECRET=plugin-client-secret-placeholder
add_foreign_resources() {
    jq --arg p "$PLUGIN_POOL" --arg x "$FOREIGN_SECRET" '.ssm["/plugin/param"] = {value: "v", tags: [], key: "alias/aws/ssm"}
        | .log_groups["/aws/lambda/plugin-pre-sign-up"] = {tags: {}, retention: 14}
        | .kms.keys["plugin-key"] = {policy: {Version: "2012-10-17", Statement: [{Sid: "Root", Effect: "Allow",
            Principal: {AWS: "arn:aws:iam::\(.account):root"}, Action: "kms:*", Resource: "*"}]}, tags: [], state: "Enabled"}
        | .pools[$p].clients["pluginclient0000000000000a"].ClientSecret = $x' "$FAKE_STATE" > "$WORK/s" \
        && mv "$WORK/s" "$FAKE_STATE"
}
remove_foreign_resources() {
    jq --arg p "$PLUGIN_POOL" 'del(.ssm["/plugin/param"], .log_groups["/aws/lambda/plugin-pre-sign-up"], .kms.keys["plugin-key"],
        .pools[$p].clients["pluginclient0000000000000a"].ClientSecret)
        | .roles["plugin-role"].inline = {}' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
}

# The documents a snapshot keeps hold no secret: the SMS external id (in the default pool and the SMS role's trust),
# an app client's secret and the Lambdas' environment values are hashed; the comparison still sees them.
snapshot_documents_hold_no_secret() {
    local docs="$1" external answer_hash
    external=$(jq -r '.roles["ccit-ci-cognito-sms"].Role.AssumeRolePolicyDocument.Statement[0].Condition.StringEquals["sts:ExternalId"]' "$FAKE_STATE")
    answer_hash=$(jq -r '.lambdas["ccit-ci-create-auth-challenge"].config.Environment.Variables.CUSTOM_CHALLENGE_ANSWER_SHA256' "$FAKE_STATE")
    [[ -n "$external" && "$external" != null && -n "$answer_hash" && "$answer_hash" != null ]] || return 1
    ! grep -qF -e "$external" -e "$FOREIGN_SECRET" -e "$answer_hash" "$docs" && grep -q '<sha256:' "$docs"
}

snapshot_and_verify() {
    local first second third out status
    add_foreign_resources
    run snapshot
    (( STATUS == 0 )) && only_reads && no_identifiers || return 1
    first=$(find "$WORK/disc" -name 'snapshot-*.json' ! -name '*.docs.json' | sort | tail -1)
    [[ -f "$first" && "$(stat -f '%Lp' "$first")" == 600 && "$(stat -f '%Lp' "${first%.json}.docs.json")" == 600 ]] || return 1
    snapshot_documents_hold_no_secret "${first%.json}.docs.json" || { echo "a secret is in the documents"; return 1; }
    # The key extension's function, rule, role and log group are read like every other.
    jq -e '[.entries[] | select(.label | test("ccit-ci-(extend-api-key|key-exec)$")) | .kind] | sort
        == ["events-rule", "events-rule-targets", "iam-role", "iam-role-policies", "lambda", "lambda-policy", "log-group"]' \
        "$first" >/dev/null || { jq -c '[.entries[] | select(.label | contains("extend") or contains("key-exec"))]' "$first"; return 1; }
    mv "$first" "$WORK/disc/before.json"
    mv "${first%.json}.docs.json" "$WORK/disc/before.docs.json"
    # A user count moving is not a change.
    jq --arg p "$PLUGIN_POOL" '.pools[$p].UserPool.EstimatedNumberOfUsers = 116999' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    run snapshot
    second=$(find "$WORK/disc" -name 'snapshot-*.json' ! -name '*.docs.json' | sort | tail -1)
    run verify-unchanged "$WORK/disc/before.json" "$second"
    (( STATUS == 0 )) && [[ "$OUT" == *"OK: every resource"* ]] || { echo "$OUT"; return 1; }
    rm -f "$second" "${second%.json}.docs.json"
    # A changed plugin pool, a removed plugin object, a ccit-ci- addition and a foreign one; and the kinds the
    # script writes on its own, changed on foreign resources: a role's inline policy, a key policy, a parameter's
    # key, a log group's retention, and the app client's secret.
    jq --arg p "$PLUGIN_POOL" '.pools[$p].UserPool.MfaConfiguration = "OFF"
        | del(.s3["v2/testconfiguration/auth/AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json"])
        | .roles["plugin-role"].inline["plugin-role-policy"] = {Version: "2012-10-17", Statement: []}
        | .kms.keys["plugin-key"].policy.Statement[0].Action = "kms:Decrypt"
        | .ssm["/plugin/param"].key = "alias/other" | .log_groups["/aws/lambda/plugin-pre-sign-up"].retention = 1
        | .pools[$p].clients["pluginclient0000000000000a"].ClientSecret = "another-secret-placeholder"
        | .roles["ccit-ci-extra"] = (.roles["plugin-role"] | .Role.RoleName = "ccit-ci-extra" | .Role.RoleId = "AROAEXTRA")
        | .roles["someone-else"] = (.roles["plugin-role"] | .Role.RoleName = "someone-else" | .Role.RoleId = "AROAELSE")' \
        "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    run snapshot
    third=$(find "$WORK/disc" -name 'snapshot-*.json' ! -name '*.docs.json' | sort | tail -1)
    status=0
    out=$("$SCRIPT" verify-unchanged "$WORK/disc/before.json" "$third" 2>&1) || status=$?
    (( status == 1 )) && [[ "$out" == *"CHANGED  user-pool amplify-plugin-default: MfaConfiguration"* ]] \
        && [[ "$out" == *"REMOVED  s3-object auth/AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json"* ]] \
        && [[ "$out" == *"added    iam-role ccit-ci-extra (ccit-ci-, expected)"* ]] \
        && [[ "$out" == *"ADDED    iam-role someone-else"* ]] \
        && [[ "$out" == *"CHANGED  iam-role-policies plugin-role: inline"* ]] \
        && [[ "$out" == *"CHANGED  kms-key-policy plugin-key: Statement"* ]] \
        && [[ "$out" == *"CHANGED  ssm-parameter /plugin/param: KeyId"* ]] \
        && [[ "$out" == *"CHANGED  log-group /aws/lambda/plugin-pre-sign-up: retentionInDays"* ]] \
        && [[ "$out" == *"CHANGED  user-pool-client amplify-plugin-default/plugin: ClientSecret"* ]] \
        && [[ "$out" != *"$PLUGIN_POOL"* && "$out" != *"$ACCOUNT"* && "$out" != *116854* ]] \
        && [[ "$out" != *"$FOREIGN_SECRET"* && "$out" != *another-secret-placeholder* ]] || { echo "$out"; return 1; }
    # Only the foreign addition, allowed, leaves the change and the removal failing.
    status=0
    out=$("$SCRIPT" verify-unchanged "$WORK/disc/before.json" "$third" --allow-foreign-additions 2>&1) || status=$?
    remove_foreign_resources
    (( status == 1 )) && [[ "$out" == *"someone-else (not ccit-ci-; allowed)"* ]]
}

# The Cognito lists come a page at a time (FAKE_PAGE_SIZE=1: one item per page, so every ccit-ci- pool but at
# most one is on a later page). Over phase 2 and the alias-codes pool, a dry run still finds every pool, client and
# the identity pool, and plans nothing; a snapshot records every pool; teardown would delete every ccit-ci- pool.
lists_are_read_to_their_last_page() {
    local paged
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(FAKE_PAGE_SIZE=1 "$SCRIPT" --scope all 2>&1) || STATUS=$?
    if ! { (( STATUS == 0 )) && [[ "$OUT" == *"Planned: 0 calls."* ]] \
        && [[ "$OUT" == *"= user pool ccit-ci-email-alias-codes"* && "$OUT" == *"= user pool ccit-ci-default"* ]] \
        && [[ "$OUT" == *"= app client ccit-ci-default-rotation"* && "$OUT" == *"= identity pool ccit_ci_default"* ]] \
        && grep -q -- '--next-token' "$FAKE_LOG"; }; then
        echo "$OUT" | tail -5
        return 1
    fi
    rm -rf "$WORK/disc"
    OUT=$(FAKE_PAGE_SIZE=1 "$SCRIPT" snapshot 2>&1) || return 1
    paged=$(find "$WORK/disc" -name 'snapshot-*.json' ! -name '*.docs.json' | sort | tail -1)
    [[ "$(jq '.counts["user-pool"]' "$paged")" == "$(jq '.pools | length' "$FAKE_STATE")" ]] \
        && [[ "$(jq '.counts["identity-pool"]' "$paged")" == "$(jq '.identity_pools | length' "$FAKE_STATE")" ]] \
        && [[ "$(jq '.counts["user-pool-client"]' "$paged")" == "$(jq '[.pools[] | .clients | length] | add' "$FAKE_STATE")" ]] \
        || return 1
    rm -rf "$WORK/disc"
    OUT=$(FAKE_PAGE_SIZE=1 "$SCRIPT" teardown 2>&1) || return 1
    [[ "$(grep -c '+ delete user pool ccit-ci-' <<<"$OUT")" == 4 && "$OUT" == *"+ delete identity pool ccit_ci_default"* ]]
}

# snapshot.py's normalization: the same documents with their unordered lists in another order (trust principals,
# actions, a condition's value as one string or a list, statements, tags, Cognito's auth flows and schema) are no
# change; Layers in another order, or a real change, are. A version-1 snapshot with its documents compares too, and
# an AWS-managed KMS alias that appears is listed and does not fail.
snapshot_normalizes_unordered_lists() {
    local dir="$WORK/norm" out status
    mkdir -p "$dir"
    printf '%s\n' \
        '{"kind": "iam-role", "id": "AROAONE", "name": "plugin-role", "doc": {"AssumeRolePolicyDocument": {"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Principal": {"Service": ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]}, "Action": ["sts:AssumeRole", "sts:TagSession"], "Condition": {"StringEquals": {"aws:SourceAccount": "123456789012"}}}, {"Effect": "Deny", "Principal": "*", "Action": "sts:AssumeRole"}]}, "Tags": [{"Key": "a", "Value": "1"}, {"Key": "b", "Value": "2"}]}}' \
        '{"kind": "user-pool-client", "id": "pool/client", "name": "plugin/client", "doc": {"ExplicitAuthFlows": ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"], "SchemaAttributes": [{"Name": "email"}, {"Name": "name"}]}}' \
        '{"kind": "lambda", "id": "arn:fn", "name": "plugin-fn", "doc": {"Layers": [{"Arn": "layer-1"}, {"Arn": "layer-2"}], "Timeout": 3}}' \
        > "$dir/a.ndjson"
    jq -c 'if .kind == "iam-role" then .doc.AssumeRolePolicyDocument.Statement |= (reverse
            | map(if (.Principal | type) == "object" then .Principal.Service |= reverse | .Action |= reverse
                  | .Condition.StringEquals["aws:SourceAccount"] |= [.] else . end)) | .doc.Tags |= reverse
           elif .kind == "user-pool-client" then .doc.ExplicitAuthFlows |= reverse | .doc.SchemaAttributes |= reverse
           else . end' "$dir/a.ndjson" > "$dir/b.ndjson"
    python3 "$CI_DIR/snapshot.py" build "$dir/a.ndjson" "$dir/a.json" t >/dev/null \
        && python3 "$CI_DIR/snapshot.py" build "$dir/b.ndjson" "$dir/b.json" t >/dev/null || return 1
    [[ "$(jq .version "$dir/a.json")" == 3 ]] && ! cmp -s "$dir/a.ndjson" "$dir/b.ndjson" || return 1
    out=$(python3 "$CI_DIR/snapshot.py" verify "$dir/a.json" "$dir/b.json") || { echo "$out"; return 1; }
    [[ "$out" == *"0 changed, 0 ccit-ci- changed"* ]] || return 1
    # The same, written by version 1 (hashed unnormalized): the documents are hashed again, so still no change.
    jq '.version = 1 | del(.kinds) | .entries |= map_values(.sha256 = "v1")' "$dir/a.json" > "$dir/v1.json"
    cp "$dir/a.docs.json" "$dir/v1.docs.json"
    out=$(python3 "$CI_DIR/snapshot.py" verify "$dir/v1.json" "$dir/b.json") || { echo "$out"; return 1; }
    # Layers reordered, and a real change, are changes; an AWS-managed alias added is listed, not failed.
    jq -c 'if .kind == "lambda" then .doc.Layers |= reverse
           elif .kind == "user-pool-client" then .doc.ExplicitAuthFlows += ["ALLOW_CUSTOM_AUTH"] else . end' \
        "$dir/a.ndjson" > "$dir/c.ndjson"
    echo '{"kind": "kms-alias", "id": "arn:aws:kms:us-east-1:123456789012:alias/aws/ssm", "name": "alias/aws/ssm", "doc": {"AliasName": "alias/aws/ssm"}}' \
        > "$dir/alias.ndjson"
    cat "$dir/alias.ndjson" >> "$dir/c.ndjson"
    python3 "$CI_DIR/snapshot.py" build "$dir/c.ndjson" "$dir/c.json" t >/dev/null || return 1
    status=0
    out=$(python3 "$CI_DIR/snapshot.py" verify "$dir/a.json" "$dir/c.json") || status=$?
    (( status == 1 )) && [[ "$out" == *"CHANGED  lambda plugin-fn: Layers"* ]] \
        && [[ "$out" == *"CHANGED  user-pool-client plugin/client: ExplicitAuthFlows"* ]] \
        && [[ "$out" == *"added    kms-alias alias/aws/ssm (AWS-managed, made by AWS on first use)"* ]] \
        && [[ "$out" == *"2 changed,"*"1 AWS-managed added, 0 other added"* ]] || { echo "$out"; return 1; }
    # The alias alone is no failure.
    cat "$dir/a.ndjson" "$dir/alias.ndjson" > "$dir/e.ndjson"
    python3 "$CI_DIR/snapshot.py" build "$dir/e.ndjson" "$dir/e.json" t >/dev/null || return 1
    python3 "$CI_DIR/snapshot.py" verify "$dir/a.json" "$dir/e.json" >/dev/null
}

# A Lambda's RuntimeVersionConfig, which Lambda moves by itself with the runtime's automatic updates, is no change,
# as a function and as a trigger, and in a "before" snapshot taken while the documents still kept it; a real change
# beside it still is.
snapshot_ignores_the_runtime_version() {
    local dir="$WORK/runtime" out status
    mkdir -p "$dir"
    printf '%s\n' \
        '{"kind": "lambda", "id": "arn:fn", "name": "plugin-fn", "doc": {"Timeout": 3, "RuntimeVersionConfig": {"RuntimeVersionArn": "arn:runtime:v1"}}}' \
        '{"kind": "trigger-lambda", "id": "arn:fn", "name": "plugin-fn", "doc": {"Timeout": 3, "RuntimeVersionConfig": {"RuntimeVersionArn": "arn:runtime:v1"}}}' \
        > "$dir/a.ndjson"
    sed 's/arn:runtime:v1/arn:runtime:v2/' "$dir/a.ndjson" > "$dir/b.ndjson"
    python3 "$CI_DIR/snapshot.py" build "$dir/a.ndjson" "$dir/a.json" t >/dev/null \
        && python3 "$CI_DIR/snapshot.py" build "$dir/b.ndjson" "$dir/b.json" t >/dev/null || return 1
    ! grep -q RuntimeVersionConfig "$dir/a.docs.json" || return 1
    out=$(python3 "$CI_DIR/snapshot.py" verify "$dir/a.json" "$dir/b.json") || { echo "$out"; return 1; }
    [[ "$out" == *" 0 changed, 0 ccit-ci- changed"* ]] || { echo "$out"; return 1; }
    # A "before" whose documents kept the field (as snapshots did): still no change.
    jq 'map_values(. + {RuntimeVersionConfig: {RuntimeVersionArn: "arn:runtime:v0"}})' "$dir/a.docs.json" > "$dir/old.docs.json"
    jq '.entries |= map_values(.sha256 = "old")' "$dir/a.json" > "$dir/old.json"
    out=$(python3 "$CI_DIR/snapshot.py" verify "$dir/old.json" "$dir/b.json") || { echo "$out"; return 1; }
    [[ "$out" == *" 0 changed, 0 ccit-ci- changed"* ]] || { echo "$out"; return 1; }
    sed 's/"Timeout": 3/"Timeout": 30/' "$dir/b.ndjson" > "$dir/c.ndjson"
    python3 "$CI_DIR/snapshot.py" build "$dir/c.ndjson" "$dir/c.json" t >/dev/null || return 1
    status=0
    out=$(python3 "$CI_DIR/snapshot.py" verify "$dir/old.json" "$dir/c.json") || status=$?
    (( status == 1 )) && [[ "$out" == *"CHANGED  lambda plugin-fn: Timeout"* && "$out" == *"CHANGED  trigger-lambda plugin-fn: Timeout"* ]] \
        && [[ "$out" != *RuntimeVersionConfig* ]] || { echo "$out"; return 1; }
}

# replace takes one of the script's pools, by key or name, and nothing else: any other name is refused before any AWS
# call, and so are no pool, two, --upload and --scope.
replace_takes_only_the_scripts_pools() {
    local args
    for args in "replace amplify-plugin-default" "replace ccit-ci-rotation" "replace ccit-ci-default-x"; do
        # shellcheck disable=SC2086 # split on purpose: each case is a list of arguments
        run $args
        (( STATUS == 1 )) && [[ -z "$(calls)" ]] \
            && [[ "$OUT" == *"replace takes one of the script's pools: ccit-ci-email-alias ccit-ci-default ccit-ci-email-alias-codes ccit-ci-mfa-req-totp-sms"* ]] \
            || { echo "$args: $OUT"; return 1; }
    done
    for args in "replace" "replace default email-alias" "replace default --upload" "replace default --scope all"; do
        # shellcheck disable=SC2086
        run $args
        (( STATUS == 2 )) && [[ -z "$(calls)" ]] || { echo "$args: $OUT"; return 1; }
    done
}

# What replace plans for the default pool: its two uploaded files, the identity pool and the reset Lambda, then the
# pool.
REPLACE_DEFAULT_PLAN="delete auth/cognito-client-ci/ccit-ci-default-amplify_outputs.json
delete auth/cognito-client-ci/ccit-ci-rotation-amplify_outputs.json
delete identity pool ccit_ci_default
delete Lambda ccit-ci-new-password-reset
delete user pool ccit-ci-default (its clients and users with it)"

# replace is a dry run by default: read calls only, nothing changed, the deletions planned and the rerun's dry run
# checked. It refuses, before any change, while a CI run that reads the pools is going (a dispatched run, or a
# Cognito client job of integ_test.yml's), but not for other jobs; when gh cannot tell, it warns and goes on.
replace_is_a_dry_run_and_refuses_while_ci_runs() {
    local before
    before=$(jq -S . "$FAKE_STATE")
    run replace default
    (( STATUS == 0 )) && only_reads && no_identifiers && plus_lines_are_ours && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] \
        && [[ "$(sed -nE 's/^  \+ //p' <<<"$OUT")" == "$REPLACE_DEFAULT_PLAN" ]] \
        && [[ "$OUT" == *"The rerun (--apply --scope all --upload), checked with its dry run:"$'\n'"  it refuses nothing."* ]] \
        && [[ "$OUT" == *"Planned: 5 deletions, then the rerun. Nothing was changed."* && "$OUT" != *Warning* ]] \
        || { echo "$OUT"; return 1; }
    FAKE_GH=dispatched run replace default --apply
    (( STATUS == 1 )) && only_reads && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] \
        && [[ "$OUT" == *"Refusing: a CI run of integ_test_auth_client.yml is going, and it reads the ccit-ci- pools"* ]] \
        || { echo "$OUT" | tail -5; return 1; }
    FAKE_GH=called run replace email-alias --apply
    (( STATUS == 1 )) && only_reads && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] \
        && [[ "$OUT" == *"Refusing: a CI run of integ_test.yml's Cognito client jobs is going"* ]] || { echo "$OUT" | tail -5; return 1; }
    FAKE_GH=other run replace default
    (( STATUS == 0 )) && [[ "$OUT" != *Warning* && "$OUT" != *Refusing* ]] || { echo "$OUT" | tail -5; return 1; }
    FAKE_GH=broken run replace default
    (( STATUS == 0 )) && only_reads \
        && [[ "$OUT" == *"Warning: could not tell whether a CI run is going, which the deletions would break"* ]] \
        || { echo "$OUT" | tail -5; return 1; }
}

# replace --apply refuses a pool without the purpose tag before any change.
replace_refuses_an_untagged_pool() {
    local before
    jq '(.pools[] | select(.UserPool.Name == "ccit-ci-email-alias-codes") | .UserPool.UserPoolTags) = {}' "$FAKE_STATE" \
        > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    before=$(jq -S . "$FAKE_STATE")
    run replace ccit-ci-email-alias-codes --apply
    local status=$STATUS out=$OUT after
    after=$(jq -S . "$FAKE_STATE")
    jq '(.pools[] | select(.UserPool.Name == "ccit-ci-email-alias-codes") | .UserPool.UserPoolTags) = {purpose: "amplify-cognito-client-integ"}' \
        "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    OUT=$out
    (( status == 1 )) && only_reads && [[ "$after" == "$before" ]] \
        && [[ "$out" == *"user-pool ccit-ci-email-alias-codes exists without purpose=amplify-cognito-client-integ"* ]] \
        && [[ "$out" == *"the dry run refused"* ]] && no_identifiers || { echo "$out" | tail -5; return 1; }
}

# The uploaded file $1 (under auth/cognito-client-ci/), as the fake holds it.
uploaded() {
    jq -r --arg k "v2/testconfiguration/auth/cognito-client-ci/$1" '.s3[$k].body' "$FAKE_STATE"
}

# replace default --apply: deletes the pool, its two files, the identity pool and the reset Lambda, then the rerun
# makes them again, with the new pool in the reset Lambda, the identity pool, the invoke permissions and the SMS
# role's trust, uploads the two new files, and leaves the other uploaded files and the plugin's resources as they
# were. A second rerun makes no call.
replace_default_makes_it_again() {
    local old_pool old_identity other before new_pool new_identity
    old_pool=$(jq -r '.pools[] | select(.UserPool.Name == "ccit-ci-default") | .UserPool.Id' "$FAKE_STATE")
    old_identity=$(jq -r '.identity_pools[] | select(.IdentityPoolName == "ccit_ci_default") | .IdentityPoolId' "$FAKE_STATE")
    other=$(jq -c '.s3 | with_entries(select(.key | test("ccit-ci-(default|rotation)-amplify") | not))' "$FAKE_STATE")
    before=$(plugin_part)
    run replace default --apply
    (( STATUS == 0 )) && no_identifiers && [[ "$(plugin_part)" == "$before" ]] \
        && [[ "$(sed -nE 's/^  \+ //p' <<<"$OUT" | head -5)" == "$REPLACE_DEFAULT_PLAN" ]] \
        && [[ "$OUT" == *"Deleted: 5 calls made. The rerun, --apply --scope all --upload:"* ]] \
        && [[ "$OUT" == *"+ create user pool ccit-ci-default"* && "$OUT" == *"new-password users: created 12"* ]] \
        && [[ "$(calls | grep -c 's3api put-object')" == 2 ]] || { echo "$OUT" | tail -12; return 1; }
    new_pool=$(jq -r '.pools[] | select(.UserPool.Name == "ccit-ci-default") | .UserPool.Id' "$FAKE_STATE")
    new_identity=$(jq -r '.identity_pools[] | select(.IdentityPoolName == "ccit_ci_default") | .IdentityPoolId' "$FAKE_STATE")
    [[ -n "$new_pool" && "$new_pool" != "$old_pool" && -n "$new_identity" && "$new_identity" != "$old_identity" ]] \
        || { echo "not made again"; return 1; }
    [[ "$(uploaded ccit-ci-default-amplify_outputs.json | jq -r '.auth.user_pool_id + " " + .auth.identity_pool_id')" == "$new_pool $new_identity" ]] \
        && [[ "$(uploaded ccit-ci-rotation-amplify_outputs.json | jq -r .auth.user_pool_id)" == "$new_pool" ]] \
        && [[ "$(jq -c '.s3 | with_entries(select(.key | test("ccit-ci-(default|rotation)-amplify") | not))' "$FAKE_STATE")" == "$other" ]] \
        || { echo "the uploaded files"; return 1; }
    jq -e --arg p "$new_pool" '(.pools[$p].UserPool.Arn) as $a
        | (.lambdas["ccit-ci-new-password-reset"].config.Environment.Variables.POOL_ID == $p)
        and ([.lambdas[] | .policy[] | select(.Sid == "cognito-default") | .Condition.ArnLike["AWS:SourceArn"]]
             | length > 0 and all(. == $a))
        and ([.identity_pools[] | select(.IdentityPoolName == "ccit_ci_default") | .CognitoIdentityProviders[0].ProviderName
              | endswith($p)] == [true])
        and (.roles["ccit-ci-cognito-sms"].Role.AssumeRolePolicyDocument.Statement[0].Condition.ArnEquals["aws:SourceArn"]
             | index($a) != null)' "$FAKE_STATE" >/dev/null || { echo "what names the pool"; return 1; }
    run --apply --scope all --upload
    (( STATUS == 0 )) && [[ "$OUT" == *"Done: 0 calls made."* ]] || { echo "$OUT" | sed -nE 's/^  \+ //p'; return 1; }
}

# replace of the device-alias pool where only phase 1 exists reruns phase 1, so it never adds phase 2. The state is
# put back after.
replace_over_phase_1_reruns_phase_1() {
    local saved="$WORK/replace-phase-1-state.json" old status out made=0
    cp "$FAKE_STATE" "$saved"
    fresh_state
    run --apply --upload
    (( STATUS == 0 )) || { echo "$OUT" | tail -5; cp "$saved" "$FAKE_STATE"; return 1; }
    old=$(jq -r '.pools[] | select(.UserPool.Name == "ccit-ci-email-alias") | .UserPool.Id' "$FAKE_STATE")
    run replace email-alias --apply
    status=$STATUS out=$OUT
    jq -e --arg o "$old" '([.pools[] | .UserPool.Name] | sort == ["amplify-plugin-default", "ccit-ci-email-alias"])
        and ([.pools[] | select(.UserPool.Name == "ccit-ci-email-alias") | .UserPool.Id] != [$o])
        and ((.apis // {}) == {}) and ([.roles | keys[]] | sort == ["ccit-ci-trigger-exec", "plugin-role"])' \
        "$FAKE_STATE" >/dev/null && [[ "$(uploaded ccit-ci-email-alias-amplify_outputs.json | jq -r .auth.user_pool_id)" != "$old" ]] \
        || made=1
    cp "$saved" "$FAKE_STATE"
    (( status == 0 && made == 0 )) && [[ "$out" == *"The rerun, --apply --scope email-alias --upload:"* ]] \
        || { echo "$out" | tail -8; return 1; }
}

# The fake, as Cognito, makes a pool that names the SNS caller role, or sets its SMS MFA, only when the role's trust
# admits that pool, with its external id: a trust narrowed to other pools, or another external id, is refused.
the_fake_checks_the_sms_roles_trust() {
    local pool role="ccit-ci-cognito-sms" external status out id opened="$WORK/opened.json"
    external=$(jq -r --arg r "$role" '.roles[$r].Role.AssumeRolePolicyDocument.Statement[0].Condition.StringEquals["sts:ExternalId"]' "$FAKE_STATE")
    for id in "$external" not-the-external-id; do
        jq -n --arg a "arn:aws:iam::$ACCOUNT:role/$role" --arg x "$id" '{PoolName: "ccit-ci-trust-probe",
            SmsConfiguration: {SnsCallerArn: $a, ExternalId: $x, SnsRegion: "us-east-1"}}' > "$WORK/sms-pool-$id.json"
    done
    # The trust names the default and MFA-required pools only: no new pool is admitted, whatever its external id.
    for id in "$external" not-the-external-id; do
        status=0
        out=$(aws --region us-east-1 --output json cognito-idp create-user-pool --cli-input-json "file://$WORK/sms-pool-$id.json" 2>&1) \
            || status=$?
        (( status == 254 )) && [[ "$out" == *"(InvalidSmsRoleTrustRelationshipException)"* ]] || { echo "create: $out"; return 1; }
    done
    # Its own pools are: their SMS MFA can be set again.
    pool=$(jq -r '.pools[] | select(.UserPool.Name == "ccit-ci-mfa-req-totp-sms") | .UserPool.Id' "$FAKE_STATE")
    jq --arg id "$pool" '.pools[$id].mfa + {UserPoolId: $id}' "$FAKE_STATE" > "$WORK/sms-mfa.json"
    aws --region us-east-1 --output json cognito-idp set-user-pool-mfa-config --cli-input-json "file://$WORK/sms-mfa.json" \
        >/dev/null || { echo "set-user-pool-mfa-config was refused"; return 1; }
    # Opened to the account's pools, as the script opens it while it makes one: a new pool is admitted, with the
    # role's external id only.
    jq --arg r "$role" --arg p "arn:aws:cognito-idp:us-east-1:$ACCOUNT:userpool/*" \
        '.roles[$r].Role.AssumeRolePolicyDocument.Statement[0].Condition |= (del(.ArnEquals) + {ArnLike: {"aws:SourceArn": $p}})' \
        "$FAKE_STATE" > "$opened"
    if FAKE_STATE="$opened" aws --region us-east-1 --output json cognito-idp create-user-pool \
        --cli-input-json "file://$WORK/sms-pool-not-the-external-id.json" >/dev/null 2>&1; then
        echo "another external id was admitted"
        return 1
    fi
    FAKE_STATE="$opened" aws --region us-east-1 --output json cognito-idp create-user-pool \
        --cli-input-json "file://$WORK/sms-pool-$external.json" >/dev/null
}

# The MFA-required pool deleted by hand (as a replace does) while the default pool stays: the rerun opens the SNS
# caller role's trust to the account's pools while it makes the pool again, which the fake (as Cognito) requires,
# then narrows it to the two SMS pools. A run that left the trust narrowed to the default pool would have its create
# refused (retried, then failed). This needs no git history.
a_remade_sms_pool_gets_the_sms_roles_trust() {
    local before arn
    before=$(plugin_part)
    jq 'del(.pools[] | select(.UserPool.Name == "ccit-ci-mfa-req-totp-sms"))
        | del(.s3["v2/testconfiguration/auth/cognito-client-ci/ccit-ci-mfa-req-totp-sms-amplify_outputs.json"])' \
        "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(FAKE_NO_SLEEP=1 "$SCRIPT" --apply --scope all --upload 2>&1) || STATUS=$?
    (( STATUS == 0 )) && [[ "$(plugin_part)" == "$before" ]] && no_identifiers \
        && [[ "$OUT" == *"+ open the trust of ccit-ci-cognito-sms to the account's pools while a ccit-ci- SMS pool is made"*"+ create user pool ccit-ci-mfa-req-totp-sms"*"+ set the trust of ccit-ci-cognito-sms to the ccit-ci- SMS pools"* ]] \
        && [[ "$(calls | grep -c 'cognito-idp create-user-pool$')" == 1 ]] || { echo "$OUT" | tail -8; return 1; }
    CONFIG=$(config_dir_of "$OUT")
    mfa_required_pool_is_right || return 1
    arn=$(jq -c '[.pools[] | select(.UserPool.Name == "ccit-ci-default" or .UserPool.Name == "ccit-ci-mfa-req-totp-sms")
        | .UserPool.Arn] | sort' "$FAKE_STATE")
    jq -e --argjson a "$arn" '.roles["ccit-ci-cognito-sms"].Role.AssumeRolePolicyDocument.Statement[0].Condition
        | (.ArnEquals["aws:SourceArn"] == $a) and (has("ArnLike") | not)' "$FAKE_STATE" >/dev/null
}

teardown_is_a_dry_run_by_default() {
    local before
    before=$(jq -S . "$FAKE_STATE")
    run teardown
    (( STATUS == 0 )) && only_reads && no_identifiers && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] \
        && [[ "$OUT" == *"+ delete user pool ccit-ci-default"* && "$OUT" == *"+ schedule the key's deletion in 7 days"* ]] \
        && [[ "$OUT" == *"+ delete schedule ccit-ci-extend-api-key"* && "$OUT" == *"+ delete Lambda ccit-ci-extend-api-key"* ]] \
        && [[ "$OUT" == *"+ delete role ccit-ci-key-exec"* && "$OUT" == *"+ delete log group /aws/lambda/ccit-ci-extend-api-key"* ]] \
        && [[ "$OUT" != *"amplify-plugin-default"* && "$OUT" != *"plugin-role"* && "$OUT" != *"someone-else"* ]]
}

teardown_deletes_only_ours() { # the roles left after it, as a sorted JSON list
    local before roles="${1:-[\"ccit-ci-extra\", \"plugin-role\", \"someone-else\"]}"
    before=$(plugin_part)
    run teardown --apply
    (( STATUS == 0 )) || { echo "$OUT" | tail -5; return 1; }
    no_identifiers && [[ "$(plugin_part)" == "$before" ]] || return 1
    jq -e '([.pools[] | .UserPool.Name] == ["amplify-plugin-default"])
        and ([.lambdas | keys[]] == ["plugin-pre-sign-up"])
        and ([.roles | keys[]] | sort == $roles)
        and (.ssm == {}) and ([.kms.aliases | keys[] | select(startswith("alias/aws/") | not)] == [])
        and ([.kms.keys[] | .state] | unique == ["PendingDeletion"])
        and ([.identity_pools[] | .IdentityPoolName] == ["plugin_identity"]) and (.apis == {}) and (.tables == {})
        and ([.s3 | keys[] | select(contains("cognito-client-ci"))] == [])
        and ((.rules // {}) == {}) and ([.log_groups | keys[]] == [])' --argjson roles "$roles" "$FAKE_STATE" >/dev/null
}

teardown_refuses_an_untagged_ccit_ci_resource() {
    fresh_state
    jq '.tables["ccit-ci-codes"] = {tags: [], ttl: true}' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    local before
    before=$(jq -S . "$FAKE_STATE")
    run teardown --apply
    (( STATUS == 1 )) && only_reads && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] \
        && [[ "$OUT" == *"table ccit-ci-codes exists without purpose"* ]]
}

# A pool deleted by hand and made again by a rerun gets a new ARN: the invoke permissions that name the old one are
# replaced, so Cognito can invoke the pool's trigger and sender.
a_remade_pool_gets_its_lambdas_invoke_permissions() {
    local arn
    fresh_state
    run --apply
    (( STATUS == 0 )) || { echo "$OUT" | tail -5; return 1; }
    jq 'del(.pools[] | select(.UserPool.Name == "ccit-ci-email-alias"))' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    run
    (( STATUS == 0 )) && only_reads && no_identifiers \
        && [[ "$OUT" == *"+ remove ccit-ci-pre-sign-up's invoke permission cognito-email-alias, which names another source"* ]] \
        && [[ "$OUT" == *"+ remove ccit-ci-discard-sender's invoke permission cognito-email-alias, which names another source"* ]] \
        || { echo "$OUT" | sed -nE 's/^  \+ //p'; return 1; }
    run --apply
    (( STATUS == 0 )) || { echo "$OUT" | tail -5; return 1; }
    arn=$(jq -r '.pools[] | select(.UserPool.Name == "ccit-ci-email-alias") | .UserPool.Arn' "$FAKE_STATE")
    jq -e --arg a "$arn" '[.lambdas["ccit-ci-pre-sign-up", "ccit-ci-discard-sender"].policy[]
        | .Condition.ArnLike["AWS:SourceArn"]] == [$a, $a]' "$FAKE_STATE" >/dev/null || return 1
    run --apply
    [[ "$OUT" == *"Done: 0 calls made."* ]]
}

# Once the ccit-ci- resources exist in one region, a run in another (whose global roles it would re-point, or
# delete) is refused before any change, provision and teardown alike; and lambda-drift, which there would find no
# function (the fake's Lambdas are regional), pass, and with --record --accept-deployed record an empty baseline, is
# refused before it reads a function, the baseline left as it was.
another_region_is_refused() {
    local baseline args
    fresh_state
    rm -f "$CCIT_CI_LAMBDA_BASELINE"
    # Phase 2, so that the record below has every CI Lambda to record.
    run --apply --scope all
    (( STATUS == 0 )) || { echo "$OUT" | tail -5; return 1; }
    CCIT_CI_REGION=us-west-2 run --apply
    (( STATUS == 1 )) && only_reads && [[ "$OUT" == *"ccit-ci- resources are in us-east-1, not CCIT_CI_REGION's us-west-2"* ]] \
        || { echo "$OUT" | tail -5; return 1; }
    CCIT_CI_REGION=us-west-2 run teardown --apply
    (( STATUS == 1 )) && only_reads && [[ "$OUT" == *"Set CCIT_CI_REGION to theirs."* ]] || { echo "$OUT" | tail -5; return 1; }
    run lambda-drift --record --accept-deployed
    (( STATUS == 0 )) && [[ "$OUT" == *"Recorded the deployed files of 9 functions"* ]] || { echo "$OUT" | tail -5; return 1; }
    baseline=$(cat "$CCIT_CI_LAMBDA_BASELINE")
    for args in "" "--record --accept-deployed"; do
        # shellcheck disable=SC2086
        CCIT_CI_REGION=us-west-2 run lambda-drift $args
        (( STATUS == 1 )) && only_reads && ! calls | grep -q '^lambda get-function$' \
            && [[ "$OUT" == *"ccit-ci- resources are in us-east-1, not CCIT_CI_REGION's us-west-2"* ]] \
            && [[ "$(cat "$CCIT_CI_LAMBDA_BASELINE")" == "$baseline" ]] || { echo "$OUT" | tail -5; return 1; }
    done
    rm -f "$CCIT_CI_LAMBDA_BASELINE"
}

# A teardown whose key deletion fails (denied, or throttled) keeps the alias, so a rerun finds the key and finishes;
# and a key already pending deletion (a teardown that failed at the alias) is not scheduled again.
a_failed_key_deletion_keeps_the_alias_for_a_rerun() {
    fresh_state
    run --apply
    (( STATUS == 0 )) || { echo "$OUT" | tail -5; return 1; }
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(FAKE_FAIL_ONCE="kms schedule-key-deletion KMSInternalException" "$SCRIPT" teardown --apply 2>&1) || STATUS=$?
    (( STATUS == 1 )) && [[ "$OUT" == *"schedule the key's deletion in 7 days failed (KMSInternalException)"* ]] \
        || { echo "$OUT" | tail -5; return 1; }
    jq -e '(.kms.aliases | has("alias/ccit-ci-senders")) and ([.kms.keys[] | .state] == ["Enabled"])' \
        "$FAKE_STATE" >/dev/null || return 1
    run teardown --apply
    (( STATUS == 0 )) && [[ "$(calls | grep -c 'kms schedule-key-deletion')" == 1 ]] || { echo "$OUT" | tail -5; return 1; }
    jq -e '(.kms.aliases == {}) and ([.kms.keys[] | .state] == ["PendingDeletion"])' "$FAKE_STATE" >/dev/null || return 1
    # Pending deletion, the alias put back as a failed delete-alias would have left it: only the alias goes.
    jq '.kms.aliases["alias/ccit-ci-senders"] = (.kms.keys | keys[0])' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    run teardown --apply
    (( STATUS == 0 )) && ! calls | grep -q 'kms schedule-key-deletion' && [[ "$(calls | grep -c 'kms delete-alias')" == 1 ]] \
        && jq -e '.kms.aliases == {}' "$FAKE_STATE" >/dev/null
}

# The first Lambda's create meets IAM propagation once: it is retried, so the two functions take three calls.
a_propagation_error_is_retried() {
    fresh_state
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(FAKE_FAIL_ONCE="lambda create-function InvalidParameterValueException" "$SCRIPT" --apply --scope email-alias 2>&1) || STATUS=$?
    (( STATUS == 0 )) && [[ "$(calls | grep -c 'lambda create-function')" == 3 ]] && no_identifiers
}

another_error_stops_the_apply_and_a_rerun_finishes_it() {
    fresh_state
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(FAKE_FAIL_ONCE="cognito-idp create-user-pool ServiceUnavailableException" "$SCRIPT" --apply --scope email-alias 2>&1) \
        || STATUS=$?
    (( STATUS == 1 )) && [[ "$OUT" == *"create user pool ccit-ci-email-alias"*"failed (ServiceUnavailableException)"* ]] \
        && [[ "$(calls | grep -c 'create-user-pool')" == 1 ]] && no_identifiers || return 1
    jq -e '[.pools[] | .UserPool.Name] == ["amplify-plugin-default"]' "$FAKE_STATE" >/dev/null || return 1
    run --apply --scope email-alias
    (( STATUS == 0 )) && [[ "$OUT" == *"= Lambda ccit-ci-pre-sign-up"* && "$OUT" == *"+ create user pool ccit-ci-email-alias"* ]] \
        && jq -e '[.pools[] | .UserPool.Name] | sort == ["amplify-plugin-default", "ccit-ci-email-alias"]' "$FAKE_STATE" >/dev/null
}

# The custom sender needs npm. With no npm on PATH, a dry run that would create it refuses, and so does --apply,
# before any change; a phase-1 run, which builds no custom sender, does not need it. An `npm ci` that fails stops
# --apply there: the custom sender is never created, and the run does not go on to the pools.
npm_is_checked_by_the_dry_run_and_a_failed_build_stops_the_apply() {
    local nonpm="$WORK/bin-nonpm" path="" dir tool before
    rm -rf "$nonpm"
    mkdir -p "$nonpm"
    ln -s "$BIN/aws" "$nonpm/aws"
    for tool in jq python3 shasum zip openssl git; do
        ln -s "$(command -v "$tool")" "$nonpm/$tool"
    done
    # Every PATH directory without an npm, after the fakes' own.
    local IFS=:
    for dir in $PATH; do
        [[ "$dir" == "$BIN" || -x "$dir/npm" ]] || path+=":$dir"
    done
    unset IFS
    fresh_state
    before=$(jq -S . "$FAKE_STATE")
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(PATH="$nonpm$path" "$SCRIPT" --scope all 2>&1) || STATUS=$?
    (( STATUS == 1 )) && [[ "$OUT" == *"npm is not on PATH"* ]] && only_reads \
        && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] || { echo "$OUT" | tail -5; return 1; }
    STATUS=0
    OUT=$(PATH="$nonpm$path" "$SCRIPT" --apply --scope all 2>&1) || STATUS=$?
    (( STATUS == 1 )) && [[ "$OUT" == *"npm is not on PATH"* && "$OUT" == *"the dry run refused"* ]] && only_reads \
        && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] || { echo "$OUT" | tail -5; return 1; }
    STATUS=0
    OUT=$(PATH="$nonpm$path" "$SCRIPT" --scope email-alias 2>&1) || STATUS=$?
    (( STATUS == 0 )) || { echo "$OUT" | tail -5; return 1; }
    # npm is there, but its `npm ci` fails.
    mkdir -p "$WORK/bin-failing-npm"
    printf '#!/usr/bin/env bash\nexit 1\n' > "$WORK/bin-failing-npm/npm"
    chmod +x "$WORK/bin-failing-npm/npm"
    STATUS=0
    OUT=$(PATH="$WORK/bin-failing-npm:$PATH" "$SCRIPT" --apply --scope all 2>&1) || STATUS=$?
    (( STATUS == 1 )) && [[ "$OUT" == *"npm ci for the custom sender failed"* && "$OUT" != *"Done:"* ]] \
        && [[ "$OUT" != *"create Lambda ccit-ci-custom-sender"* && "$OUT" != *"User pools:"* ]] \
        && jq -e '(.lambdas | has("ccit-ci-custom-sender") | not)
            and ([.pools[] | .UserPool.Name] == ["amplify-plugin-default"])' "$FAKE_STATE" >/dev/null \
        || { echo "$OUT" | tail -5; return 1; }
}

# Redeploys function $1 in the fake by hand: "rezipped" puts the same files in another zip (stored, not deflated,
# and dated 2024, as an older `zip -X` build made them), so its CodeSha256 changes and its files do not; "edited"
# also changes triggers.mjs and adds a file. The fake's CodeSha256 follows the new zip, as Lambda's does.
hand_deploy() {
    python3 - "$FAKE_STATE" "$1" "$2" <<'PY'
import base64, hashlib, io, json, sys, zipfile
state_path, name, how = sys.argv[1:]
with open(state_path) as f:
    state = json.load(f)
function = state["lambdas"][name]
with zipfile.ZipFile(function["code"]) as z:
    files = {n: z.read(n) for n in z.namelist()}
if how == "edited":
    files["triggers.mjs"] += b"\n// edited by hand\n"
    files["notes.txt"] = b"not from the checkout\n"
buffer = io.BytesIO()
with zipfile.ZipFile(buffer, "w", zipfile.ZIP_STORED) as z:
    for n, data in sorted(files.items()):
        z.writestr(zipfile.ZipInfo(n, date_time=(2024, 5, 6, 7, 8, 10)), data)
with open(function["code"], "wb") as f:
    f.write(buffer.getvalue())
function["config"]["CodeSha256"] = base64.b64encode(hashlib.sha256(buffer.getvalue()).digest()).decode()
with open(state_path, "w") as f:
    json.dump(state, f, indent=1, sort_keys=True)
PY
}

# lambda-drift, with read calls only (GetFunction and the tag check, each function): it downloads every deployed zip
# (the fake's Code.Location, a file:// URL to the zip create-function was given) and compares its files with the
# checkout's zip's. Every Lambda --apply made is in sync, CodeSha256 the same; the same files in another zip are in
# sync too, CodeSha256 only noted as different; a function edited by hand is DRIFT, by name, with which files differ
# and how to redeploy it after its tag check, and exit 1, never a URL or a hash printed. --record shows the same and
# records nothing without --accept-deployed; with it, the deployed files are the baseline, and the function is then
# the accepted deployment. A changed runtime version is not compared, and an untagged ccit-ci- function is refused.
# deployed.json is the owner's only (lambda_code.py refuses it otherwise), and no download directory is left behind.
lambda_drift_compares_the_deployed_files() {
    local summary
    fresh_state
    rm -f "$CCIT_CI_LAMBDA_BASELINE"
    run --apply --scope all
    (( STATUS == 0 )) || { echo "$OUT" | tail -5; return 1; }
    jq '.lambdas["ccit-ci-pre-sign-up"].config.RuntimeVersionConfig = {RuntimeVersionArn: "arn:placeholder:runtime:v2"}' \
        "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    run lambda-drift
    (( STATUS == 0 )) && only_reads && no_identifiers \
        && [[ "$(grep -c "the deployed files are this checkout's" <<<"$OUT")" == 9 ]] \
        && [[ "$(grep -c "CodeSha256, a note only: the same as this checkout's zip's" <<<"$OUT")" == 9 ]] \
        && [[ "$(calls | grep -c '^lambda get-function$')" == 9 && "$(calls | grep -c '^lambda list-tags$')" == 9 ]] \
        && [[ -z "$(find "$TMPDIR" -name 'ccit-ci-lambda-code.*')" ]] || { echo "$OUT"; return 1; }
    hand_deploy ccit-ci-discard-sender rezipped
    run lambda-drift
    (( STATUS == 0 )) && [[ "$(grep -c "the deployed files are this checkout's" <<<"$OUT")" == 9 ]] \
        && [[ "$(grep -A1 '= ccit-ci-discard-sender' <<<"$OUT")" == *"not this checkout's zip's (the files decide)"* ]] \
        || { echo "$OUT"; return 1; }
    hand_deploy ccit-ci-pre-sign-up edited
    run lambda-drift
    summary="      changed (1): triggers.mjs
      only deployed (1): notes.txt"
    (( STATUS == 1 )) && only_reads && no_identifiers \
        && [[ "$OUT" == *"DRIFT ccit-ci-pre-sign-up: the deployed files are neither this checkout's"*"$summary"* ]] \
        && [[ "$OUT" == *"check that the function carries purpose=amplify-cognito-client-integ"* ]] \
        && [[ "$(grep -c DRIFT <<<"$OUT")" == 1 && "$OUT" != *file:* && "$OUT" != *"$FAKE_STATE"* ]] \
        || { echo "$OUT"; return 1; }
    run lambda-drift --record
    (( STATUS == 1 )) && only_reads && [[ "$OUT" == *"$summary"*"Nothing recorded."*"--accept-deployed"* ]] \
        && [[ ! -e "$CCIT_CI_LAMBDA_BASELINE" ]] || { echo "$OUT"; return 1; }
    run lambda-drift --accept-deployed
    (( STATUS == 2 )) || return 1
    run lambda-drift --record --accept-deployed
    (( STATUS == 0 )) && only_reads && [[ "$OUT" == *"$summary"*"Recorded the deployed files of 9 functions"* ]] \
        && jq -e '.functions | length == 9 and (.["pre-sign-up"].files | keys == ["notes.txt", "triggers.mjs"])
            and all(.[]; (.sources | test("^[0-9a-f]{64}$")) and (.files | all(.[]; test("^[0-9a-f]{64}$"))))' \
            "$CCIT_CI_LAMBDA_BASELINE" >/dev/null || { echo "$OUT"; return 1; }
    run lambda-drift
    (( STATUS == 0 )) && [[ "$OUT" == *"= ccit-ci-pre-sign-up: the deployed files are the ones the baseline accepted"*"$summary"* ]] \
        || { echo "$OUT"; return 1; }
    jq '.lambdas["ccit-ci-discard-sender"].tags = {}' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    run lambda-drift
    (( STATUS == 1 )) && only_reads && [[ "$OUT" == *"exists without purpose=amplify-cognito-client-integ"* ]] \
        || { echo "$OUT"; return 1; }
    rm -f "$CCIT_CI_LAMBDA_BASELINE"
}

# Foreign AppSync APIs, $1 of them, as other teams' backends in the CI account.
add_foreign_apis() {
    jq --argjson n "$1" 'reduce range($n) as $i (.; .apis["foreignapi\($i)"] = {api: {apiId: "foreignapi\($i)",
        name: "plugin-api-\($i)", arn: "arn:aws:appsync:us-east-1:\(.account):apis/foreignapi\($i)",
        uris: {GRAPHQL: "https://foreignapi\($i).appsync-api.us-east-1.amazonaws.com/graphql"}}, tags: {}, keys: []})' \
        "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
}

# The AppSync headroom is checked only by a run that creates the code sink's API: with 23 APIs in the account (22
# foreign and the sink's), a rerun that only extends the key goes on; a first phase 2 there is refused, before any
# change, unless CCIT_CI_APPSYNC_API_QUOTA gives a raised quota; and phase 1, which creates no API, goes on whatever
# the count.
appsync_headroom_is_checked_only_when_the_api_is_created() {
    fresh_state
    run --apply --scope all
    (( STATUS == 0 )) || { echo "$OUT" | tail -5; return 1; }
    add_foreign_apis 22
    jq --argjson e "$(( $(date +%s) + 10 * 86400 ))" '(.apis[] | .keys[]).expires = $e' "$FAKE_STATE" > "$WORK/s" \
        && mv "$WORK/s" "$FAKE_STATE"
    run --apply --scope all
    (( STATUS == 0 )) && [[ "$OUT" == *"AppSync APIs 23 of 25"* && "$OUT" == *"Done: 1 calls made."* ]] \
        && [[ "$(sed -nE 's/^  \+ //p' <<<"$OUT")" == "extend the tests' read-only API key to 365 days from now (the same key)" ]] \
        || { echo "$OUT" | tail -8; return 1; }
    fresh_state
    add_foreign_apis 23
    local before
    before=$(jq -S . "$FAKE_STATE")
    run --apply --scope all
    (( STATUS == 1 )) && only_reads && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] \
        && [[ "$OUT" == *"23 AppSync APIs exist, this run creates one, and the quota is 25"*"CCIT_CI_APPSYNC_API_QUOTA"* ]] \
        || { echo "$OUT" | tail -5; return 1; }
    CCIT_CI_APPSYNC_API_QUOTA=30 run --scope all
    (( STATUS == 0 )) && [[ "$OUT" == *"AppSync APIs 23 of 30"* && "$OUT" == *"+ create AppSync API ccit-ci-codes"* ]] \
        || { echo "$OUT" | tail -5; return 1; }
    CCIT_CI_APPSYNC_API_QUOTA=lots run --scope all
    (( STATUS == 1 )) && [[ "$OUT" == *"CCIT_CI_APPSYNC_API_QUOTA must be a whole number"* ]] || return 1
    add_foreign_apis 30
    run --apply
    (( STATUS == 0 )) && [[ "$OUT" == *"+ create user pool ccit-ci-email-alias"* ]] || { echo "$OUT" | tail -5; return 1; }
}

library_guards() {
    local out status=0
    out=$(bash -c '
        set -euo pipefail
        source "$1/../lib.sh"; source "$1/lib-ci.sh"
        CI_WORK=$(mktemp -d); CI_REGION=us-east-1; CI_MODE=apply
        mutate plugin-role "delete it" -- iam delete-role --role-name plugin-role' _ "$CI_DIR" 2>&1) || status=$?
    (( status == 1 )) && [[ "$out" == *"is not a ccit-ci- resource"* ]] && ! calls | grep -q delete-role || return 1
    status=0
    out=$(bash -c '
        set -euo pipefail
        source "$1/../lib.sh"; source "$1/lib-ci.sh"
        CI_WORK=$(mktemp -d); CI_REGION=us-east-1; CI_MODE=plan
        aws_into x iam create-role --role-name ccit-ci-x' _ "$CI_DIR" 2>&1) || status=$?
    (( status == 1 )) && [[ "$out" == *"makes read calls only"* ]]
}

check "bad usage is refused" usage_is_refused
check "snapshot and lambda-drift refuse --apply, before any AWS call" read_only_commands_refuse_apply
check "a missing config URL is refused before any AWS call" a_missing_config_url_is_refused
check "a config URL without a path is refused, unprinted" a_config_url_without_a_path_is_refused
check "the default dry run (phase 1) plans exactly the device-alias pool and what it needs" \
    the_default_dry_run_plans_exactly_phase_1
check "a dry run of both phases plans every resource, reads only, and prints no identifier" \
    a_dry_run_of_both_phases_plans_everything
check "a dry run refuses a ccit-ci- name without the tag" untagged_name_is_refused
check "--apply refuses a ccit-ci- name without the tag before any change" untagged_name_is_refused --apply
check "phase 1 --apply --upload makes only the Lite device-alias pool, its trigger and discard sender, and one file" \
    phase_1_creates_only_the_device_alias_pool
check "phase 2 adds the default, alias-codes and MFA-required pools, narrowed, keeps phase 1, and uploads only the six new files" \
    phase_2_adds_the_default_pool_and_keeps_phase_1
check "a second --apply --upload makes no call and uploads nothing" a_second_apply_makes_no_call_and_uploads_nothing
check "a phase-1 --apply after phase 2 is refused, naming --scope all; its dry run plans nothing" \
    a_phase_1_apply_after_phase_2_is_refused
check "the code sink's API key near its expiry is extended in place, and the uploaded files stay valid" \
    an_api_key_near_its_expiry_is_extended_in_place
check "a rerun reuses the key beyond the reuse threshold, extends it within it and once expired, and replaces a deleted one" \
    a_rerun_reuses_or_extends_the_key_at_the_threshold
check "the key is made and extended for 365 days, to the hour, within AppSync's bounds with its clock behind" \
    the_key_lives_365_days_within_appsyncs_bounds
check "an expired key is extended in place when AppSync takes it, and the uploaded files stay valid" \
    an_expired_key_is_extended_in_place_when_appsync_takes_it
check "an expired key AppSync refuses is replaced, and --apply refuses until the uploaded files that name it are replaced" \
    an_expired_key_needs_the_uploads_that_name_it_replaced
check "a key with other contents refuses the whole upload" a_key_with_other_contents_refuses_the_upload
check "snapshot and verify-unchanged: a user count is no change; a change, a removal, a foreign addition fail" \
    snapshot_and_verify
check "snapshot: unordered lists in another order are no change; Layers reordered or a real change are" \
    snapshot_normalizes_unordered_lists
check "snapshot: a Lambda's RuntimeVersionConfig, which Lambda moves by itself, is no change" \
    snapshot_ignores_the_runtime_version
check "the Cognito lists are read to their last page: a ccit-ci- pool on page 2 is found, snapshotted, torn down" \
    lists_are_read_to_their_last_page
check "the fake makes an SMS pool, or sets its SMS MFA, only when the SNS caller role's trust admits it" \
    the_fake_checks_the_sms_roles_trust
check "an SMS pool made again opens the SNS caller role's trust while it is made, then narrows it (no git history)" \
    a_remade_sms_pool_gets_the_sms_roles_trust
check "replace takes only the script's pools, refusing any other name before any AWS call" \
    replace_takes_only_the_scripts_pools
check "replace is a dry run by default, and refuses while a CI run that reads the pools is going" \
    replace_is_a_dry_run_and_refuses_while_ci_runs
check "replace --apply refuses a pool without the tag, before any change" replace_refuses_an_untagged_pool
check "replace default --apply deletes the pool and what names it, then the rerun makes them again" \
    replace_default_makes_it_again
check "replace of the device-alias pool over phase 1 alone reruns phase 1, adding nothing of phase 2" \
    replace_over_phase_1_reruns_phase_1
check "teardown is a dry run by default and names only ccit-ci- resources" teardown_is_a_dry_run_by_default
check "teardown --apply deletes only the ccit-ci- resources it made" teardown_deletes_only_ours
if frozen_script; then
    check "a rerun over phase 2 as applied ($FROZEN_COMMIT) adds only the alias-codes and MFA-required pools, the key's extension and three new files" \
        a_rerun_over_phase_2_as_applied_adds_only_the_alias_codes_pool
    check "teardown --apply then deletes every ccit-ci- resource, the alias-codes pool's too" \
        teardown_deletes_only_ours '["plugin-role"]'
else
    # A clone without that history (a public one: the commit predates the squash merges) cannot run it. The
    # migration it guards was applied to the CI account once, so its absence is reported, never failed.
    echo "skip - the script at $FROZEN_COMMIT is not in this clone's git history, so the rerun over it was not checked"
    skipped=$((skipped + 1))
fi
check "teardown refuses a ccit-ci- resource without the tag, before any change" teardown_refuses_an_untagged_ccit_ci_resource
check "teardown schedules the key's deletion before removing its alias, so a failed schedule can be rerun" \
    a_failed_key_deletion_keeps_the_alias_for_a_rerun
check "a run in another region than the ccit-ci- resources' is refused before any change" another_region_is_refused
check "a pool made again under a new ARN gets its Lambdas' invoke permissions replaced" \
    a_remade_pool_gets_its_lambdas_invoke_permissions
check "a role-propagation error is retried" a_propagation_error_is_retried
check "any other error stops --apply, and a second --apply makes only what is missing" \
    another_error_stops_the_apply_and_a_rerun_finishes_it
check "a dry run refuses a custom sender without npm, and a failed npm ci stops --apply before the sender" \
    npm_is_checked_by_the_dry_run_and_a_failed_build_stops_the_apply
check "lambda-drift compares the deployed files, not the zips' hashes, and records them only with --accept-deployed" \
    lambda_drift_compares_the_deployed_files
check "the AppSync headroom is checked only by a run that creates the API, against CCIT_CI_APPSYNC_API_QUOTA" \
    appsync_headroom_is_checked_only_when_the_api_is_created
check "the library refuses a name that is not ccit-ci-, and a mutating call in a dry run" library_guards

if (( failures > 0 )); then
    echo "$failures failed"
    exit 1
fi
if (( skipped > 0 )); then
    echo "All passed ($skipped skipped)"
else
    echo "All passed"
fi
