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
# and writes the seven files (mode 600, in a mode-700 directory) with what the client reads; that a second --apply makes no call; that
# --upload puts only new keys under auth/cognito-client-ci/ and refuses, with no upload, once one exists; that a
# rerun over phase 2 as it was first applied (the script at 80712afe4 when git has it, else skipped) plans and makes
# only the alias-codes and MFA-required pools and what they need, updates only the script's own resources, and
# uploads only the three new files, finding the four uploaded ones byte for byte the same; that a phase-1 rerun after phase 2 makes no call, and
# a code sink key near its expiry is extended in place, its expiry recorded for the reminder (and by key-expiry
# --record, read-only; a record that cannot be written is never reported as written), and that an expired one's
# replacement is recorded only once the uploaded files that name the old key are replaced; that the AppSync headroom
# is checked only by a run that
# creates the API, against CCIT_CI_APPSYNC_API_QUOTA; that a dry run refuses a custom sender to build without npm,
# and a failed npm ci stops --apply before the sender; that lambda-drift downloads each deployed zip and tells a
# Lambda whose files are not this checkout's, which --record --accept-deployed alone accepts; that snapshot and
# verify-unchanged ignore a user count, and fail on a changed, removed or foreign added resource (a foreign role's
# inline policy, key policy, parameter or log group included), but not on a ccit-ci- addition or change, nor on a
# Lambda's runtime version, and that the snapshot's documents hold no secret; that snapshot, key-expiry and
# lambda-drift refuse --apply; that teardown is a dry run by default, deletes only the ccit-ci- resources with
# --apply, refuses an untagged one, and schedules the key's deletion before removing its alias; that a run in another
# region is refused (lambda-drift too, which there would find nothing to compare); that a pool made again gets its
# Lambdas' invoke permissions replaced; and that the library's
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
export PATH="$BIN:$PATH" FAKE_STATE="$WORK/state.json" FAKE_LOG="$WORK/calls.log" TMPDIR="$WORK/tmp"
export AWS_CONFIG_FILE=/dev/null AWS_SHARED_CREDENTIALS_FILE=/dev/null CCIT_CI_DISCOVERY_DIR="$WORK/disc"
export COGNITO_CLIENT_INTEG_CI_CONFIG_URL="s3://fake-ci-bucket.example/v2/testconfiguration"
# The code sink key's expiry record, never the committed one.
export CCIT_CI_KEY_RECORD="$WORK/code-sink-key-expiry.json"
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
    run --scope bogus
    (( STATUS == 2 )) && { [[ ! -s "$FAKE_LOG" ]] || [[ -z "$(calls)" ]]; }
}

# snapshot, key-expiry and lambda-drift only read: --apply, which would switch the read-only guard off for them, is a
# usage error, before any AWS call.
read_only_commands_refuse_apply() {
    local command
    for command in snapshot key-expiry lambda-drift; do
        run --apply "$command"
        (( STATUS == 2 )) && [[ "$OUT" == *"$command is read-only: it takes no --apply."* ]] && [[ -z "$(calls)" ]] \
            || { echo "$command: $OUT"; return 1; }
    done
    run key-expiry --record --apply
    (( STATUS == 2 )) && [[ -z "$(calls)" ]] || return 1
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
        and ([.lambdas["ccit-ci-discard-sender", "ccit-ci-pre-sign-up"].policy[].Sid] | index("cognito-mfa-req-totp-sms") != null)' \
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
        and ([.roles | keys[] | select(startswith("ccit-ci-"))] | length == 7)
        and ([.roles[] | select(.Role.RoleName | startswith("ccit-ci-")) | .tags[0].Value] | unique == ["amplify-cognito-client-integ"])
        and ([.lambdas[] | select(.config.FunctionName | startswith("ccit-ci-")) | .tags.purpose] | length == 8 and (unique == ["amplify-cognito-client-integ"]))
        and ([.lambdas[] | .config.FunctionName] | all(startswith("ccit-ci-") or . == "plugin-pre-sign-up"))
        and ([.ssm | keys[]] == ["/ccit-ci/custom-challenge-answer", "/ccit-ci/new-password-temporary"])
        and ([.identity_pools[] | .IdentityPoolName] | sort == ["ccit_ci_default", "plugin_identity"])' "$FAKE_STATE" >/dev/null || return 1
    # The SMS role is narrowed to the default and MFA-required pools, the two that name it (the key and the decrypt:
    # above).
    jq -e '([.pools[] | select(.UserPool.Name == "ccit-ci-default" or .UserPool.Name == "ccit-ci-mfa-req-totp-sms")
            | .UserPool.Arn] | sort) as $sms
        | .roles["ccit-ci-cognito-sms"].Role.AssumeRolePolicyDocument.Statement[0].Condition.ArnEquals["aws:SourceArn"] == $sms' \
        "$FAKE_STATE" >/dev/null || return 1
    secrets_use_the_ccit_ci_key || return 1
    [[ "$OUT" == *"new-password users: created 12"* ]]
}

a_second_apply_makes_no_call_and_uploads_nothing() {
    run --apply --scope all --upload
    (( STATUS == 0 )) && [[ "$OUT" == *"Done: 0 calls made."* ]] && ! calls | grep -q 'put-object' && no_identifiers
}

# The default scope after phase 2 changes nothing: the triggers' role keeps the phase-2 triggers' log groups.
a_phase_1_rerun_after_phase_2_makes_no_call() {
    run --apply --upload
    if ! { (( STATUS == 0 )) && [[ "$OUT" == *"Done: 0 calls made."* ]] && ! calls | grep -q 'put-object'; }; then
        echo "$OUT" | sed -nE 's/^  \+ //p'
        return 1
    fi
    no_identifiers && jq -e '.roles["ccit-ci-trigger-exec"].inline["ccit-ci-trigger-exec-policy"].Statement[0].Resource
        | any(contains(":log-group:/aws/lambda/ccit-ci-verify-auth-challenge:"))' "$FAKE_STATE" >/dev/null
}

# The code sink's key, 10 days from its expiry, is extended in place: the same id, so the uploaded files that name it
# stay as they are, and nothing is uploaded.
an_api_key_near_its_expiry_is_extended_in_place() {
    local key soon
    key=$(jq -r '[.apis[] | .keys[]] | .[0].id' "$FAKE_STATE")
    soon=$(( $(date +%s) + 10 * 86400 ))
    jq --argjson e "$soon" '(.apis[] | .keys[]).expires = $e' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    # As the record would have it then.
    printf '{"expires": "%s"}\n' "$(days_from_now 10)" > "$CCIT_CI_KEY_RECORD"
    run --scope all --upload
    (( STATUS == 0 )) && only_reads && no_identifiers \
        && [[ "$(sed -nE 's/^  \+ //p' <<<"$OUT")" == "extend the tests' read-only API key to 364 days from now (the same key)" ]] \
        && [[ "$OUT" == *"The code sink's API key expires on "*" after this run; --apply records it"* ]] \
        || { echo "$OUT" | sed -nE 's/^  \+ //p'; return 1; }
    run --apply --scope all --upload
    (( STATUS == 0 )) && [[ "$OUT" == *"Done: 1 calls made."* ]] && ! calls | grep -qE 'put-object|create-api-key' \
        && no_identifiers && [[ "$(grep -c 'uploaded already, the same bytes' <<<"$OUT")" == 7 ]] \
        || { echo "$OUT" | tail -8; return 1; }
    jq -e --arg k "$key" --argjson e "$(( $(date +%s) + 300 * 86400 ))" \
        '[.apis[] | .keys[]] | length == 1 and .[0].id == $k and .[0].expires > $e' "$FAKE_STATE" >/dev/null || return 1
    [[ "$OUT" == *"Recorded the code sink's API key's expiry, $(jq -r .expires "$CCIT_CI_KEY_RECORD")"* ]] \
        && [[ "$(jq -r .expires "$CCIT_CI_KEY_RECORD")" > "$(days_from_now 300)" ]]
}

# The expiry is recorded as soon as the key is extended, not at the end of the run: a later step that stops it (here
# the reset Lambda's create, which fails) leaves the new date recorded, so the reminder does not ask to renew a key
# that already was. A rerun then finishes.
the_expiry_is_recorded_when_the_key_is_extended() {
    jq --argjson e "$(( $(date +%s) + 10 * 86400 ))" '(.apis[] | .keys[]).expires = $e
        | del(.lambdas["ccit-ci-new-password-reset"])' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    printf '{"expires": "%s"}\n' "$(days_from_now 10)" > "$CCIT_CI_KEY_RECORD"
    : > "$FAKE_LOG"
    STATUS=0
    OUT=$(FAKE_FAIL_ONCE="lambda create-function ServiceUnavailableException" "$SCRIPT" --apply --scope all 2>&1) \
        || STATUS=$?
    (( STATUS == 1 )) && [[ "$OUT" == *"+ extend the tests' read-only API key"*"Recorded the code sink's API key's expiry"* ]] \
        && [[ "$OUT" == *"Recorded the code sink's API key's expiry"*"New-password users:"*"failed (ServiceUnavailableException)"* ]] \
        && [[ "$(jq -r .expires "$CCIT_CI_KEY_RECORD")" > "$(days_from_now 300)" ]] && no_identifiers \
        || { echo "$OUT" | tail -8; return 1; }
    run --apply --scope all
    (( STATUS == 0 )) && [[ "$OUT" == *"+ create Lambda ccit-ci-new-password-reset"* ]] \
        && jq -e '.lambdas | has("ccit-ci-new-password-reset")' "$FAKE_STATE" >/dev/null || { echo "$OUT" | tail -5; return 1; }
}

days_from_now() { python3 -c 'import datetime,sys;print(datetime.datetime.now(datetime.timezone.utc).date() + datetime.timedelta(days=int(sys.argv[1])))' "$1"; }

# The code sink key's expiry, recorded for the reminder (code_sink_key.py): --apply --scope all records it, and says
# so when it changed; key-expiry reads it with read calls only, and --record writes it; and the record holds the date
# alone. A record that cannot be written (here under a missing directory) is never reported as recorded: key-expiry
# --record exits 1, and --apply says so and goes on.
the_key_expiry_is_recorded() {
    local recorded
    recorded=$(jq -r .expires "$CCIT_CI_KEY_RECORD") || return 1
    [[ "$recorded" == "$(days_from_now 364)" || "$recorded" == "$(days_from_now 363)" ]] \
        && jq -e 'keys == ["expires"]' "$CCIT_CI_KEY_RECORD" >/dev/null || { cat "$CCIT_CI_KEY_RECORD"; return 1; }
    run --apply --scope all
    (( STATUS == 0 )) && [[ "$OUT" == *"The code sink's API key expires on $recorded, as code-sink-key-expiry.json records."* ]] \
        || { echo "$OUT" | tail -3; return 1; }
    rm -f "$CCIT_CI_KEY_RECORD"
    run key-expiry
    (( STATUS == 0 )) && only_reads && no_identifiers && [[ "$OUT" == *"expires on $recorded."* ]] \
        && [[ "$OUT" == *"has no recorded expiry"* && ! -e "$CCIT_CI_KEY_RECORD" ]] || { echo "$OUT"; return 1; }
    run key-expiry --record
    (( STATUS == 0 )) && only_reads && [[ "$(jq -r .expires "$CCIT_CI_KEY_RECORD")" == "$recorded" ]] \
        && [[ "$OUT" == *"Recorded the code sink's API key's expiry, $recorded"* ]] || { echo "$OUT"; return 1; }
    CCIT_CI_KEY_RECORD="$WORK/no-such-dir/code-sink-key-expiry.json" run key-expiry --record
    (( STATUS == 1 )) && only_reads && [[ ! -e "$WORK/no-such-dir" && "$OUT" != *"Recorded the code sink"* ]] \
        && [[ "$OUT" == *"Not recorded: the code sink's API key's expiry, $recorded, could not be written to"* ]] \
        || { echo "$OUT"; return 1; }
    CCIT_CI_KEY_RECORD="$WORK/no-such-dir/code-sink-key-expiry.json" run --apply --scope all
    (( STATUS == 0 )) && [[ "$OUT" == *"Done: 0 calls made."* && "$OUT" != *"Recorded the code sink"* ]] \
        && [[ "$OUT" == *"Not recorded: the code sink's API key's expiry, $recorded, could not be written to"* ]] \
        && [[ ! -e "$WORK/no-such-dir" ]] || { echo "$OUT" | tail -5; return 1; }
    run --record
    (( STATUS == 2 ))
}

# An expired key cannot be extended: --apply makes a new one, but the two uploaded files that name the old key are never
# overwritten, so the new expiry is not recorded (the record keeps the old date, and the reminder keeps failing): the
# dry run says so, --apply says how to replace them and refuses at the end, its upload refused, and key-expiry
# --record refuses too, all with read calls only to tell. Once both are deleted (by hand, after their tag check), a
# rerun with --upload uploads them with the new key and records its expiry, and key-expiry --record then records it.
an_expired_key_is_recorded_only_once_the_uploads_name_the_new_one() {
    local old_record prefix="v2/testconfiguration/auth/cognito-client-ci" file newest
    local stale="ccit-ci-default-amplify_outputs.json ccit-ci-email-alias-codes-amplify_outputs.json name another code sink key"
    jq --argjson e "$(( $(date +%s) - 86400 ))" '(.apis[] | .keys[]).expires = $e' "$FAKE_STATE" > "$WORK/s" \
        && mv "$WORK/s" "$FAKE_STATE"
    printf '{"expires": "%s"}\n' "$(days_from_now -1)" > "$CCIT_CI_KEY_RECORD"
    old_record=$(cat "$CCIT_CI_KEY_RECORD")
    run --scope all
    (( STATUS == 0 )) && only_reads && no_identifiers \
        && [[ "$OUT" == *"--apply would not record the code sink's API key's expiry"*"$stale"* ]] \
        || { echo "$OUT" | tail -8; return 1; }
    run --apply --scope all --upload
    (( STATUS == 1 )) && [[ "$OUT" == *"+ create the tests' read-only API key, for 364 days"* ]] \
        && [[ "$OUT" == *"Not recorded: the uploaded auth/cognito-client-ci/ files $stale"* ]] \
        && [[ "$OUT" == *"purpose=amplify-cognito-client-integ"*"--apply --scope all --upload"* ]] \
        && [[ "$OUT" == *"than the one that expires on"*"and the reminder keeps failing"* ]] \
        && [[ "$OUT" == *"get-object-tagging), delete them"*"uploads them again with the current key"* ]] \
        && [[ "$OUT" == *"nothing is ever overwritten"* ]] && ! calls | grep -q 'put-object' \
        && [[ "$(cat "$CCIT_CI_KEY_RECORD")" == "$old_record" ]] && no_identifiers || { echo "$OUT" | tail -8; return 1; }
    run key-expiry --record
    (( STATUS == 1 )) && only_reads && [[ "$OUT" == *"Not recorded: the uploaded auth/cognito-client-ci/ files $stale"* ]] \
        && [[ "$(cat "$CCIT_CI_KEY_RECORD")" == "$old_record" ]] && no_identifiers || { echo "$OUT"; return 1; }
    run key-expiry
    (( STATUS == 0 )) && only_reads && [[ "$OUT" == *"But the uploaded auth/cognito-client-ci/ files $stale"* ]] \
        || { echo "$OUT"; return 1; }
    # Without --upload, the run finishes, then refuses with the steps.
    run --apply --scope all
    (( STATUS == 1 )) && [[ "$OUT" == *"Done: 0 calls made."*"Refusing: the uploaded auth/cognito-client-ci/ files $stale"* ]] \
        && [[ "$(cat "$CCIT_CI_KEY_RECORD")" == "$old_record" ]] || { echo "$OUT" | tail -5; return 1; }
    # Both deleted by hand: the rerun uploads them with the new key and records its expiry.
    jq --arg a "$prefix/ccit-ci-default-amplify_outputs.json" --arg b "$prefix/ccit-ci-email-alias-codes-amplify_outputs.json" \
        'del(.s3[$a], .s3[$b])' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    run --apply --scope all --upload
    (( STATUS == 0 )) && [[ "$(calls | grep -c 's3api put-object')" == 2 ]] && no_identifiers \
        && [[ "$OUT" == *"Recorded the code sink's API key's expiry, $(jq -r .expires "$CCIT_CI_KEY_RECORD")"* ]] \
        && [[ "$(jq -r .expires "$CCIT_CI_KEY_RECORD")" > "$(days_from_now 300)" ]] || { echo "$OUT" | tail -8; return 1; }
    newest=$(jq -r '[.apis[] | .keys[]] | sort_by(.expires) | last | .id' "$FAKE_STATE")
    for file in ccit-ci-default-amplify_outputs.json ccit-ci-email-alias-codes-amplify_outputs.json; do
        [[ "$(jq -r --arg k "$prefix/$file" '.s3[$k].body | fromjson | .data.api_key' "$FAKE_STATE")" == "$newest" ]] \
            || { echo "$file does not name the new key"; return 1; }
    done
    rm -f "$CCIT_CI_KEY_RECORD"
    run key-expiry --record
    (( STATUS == 0 )) && only_reads && [[ "$(jq -r .expires "$CCIT_CI_KEY_RECORD")" > "$(days_from_now 300)" ]] \
        || { echo "$OUT"; return 1; }
}

a_key_with_other_contents_refuses_the_upload() {
    jq '.s3["v2/testconfiguration/auth/cognito-client-ci/ccit-ci-default-credentials.json"].body = "{}"' "$FAKE_STATE" \
        > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    run --apply --scope all --upload
    (( STATUS == 1 )) && [[ "$OUT" == *"nothing is ever overwritten"* ]] && ! calls | grep -q 'put-object' \
        && only_reads && no_identifiers
}

# What a rerun over phase 2 as first applied (80712afe4) plans: the alias-codes and MFA-required pools and what they
# need, the updates to the script's own resources that name them (the SMS role's trust opened while the MFA-required
# pool is made, then narrowed), and the three new files.
RERUN_PLAN="create log group /aws/lambda/ccit-ci-pre-sign-up-confirmable
keep /aws/lambda/ccit-ci-pre-sign-up-confirmable for 7 days
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
        && [[ "$OUT" == *"Planned: 24 calls. Nothing was changed."* ]] \
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

teardown_is_a_dry_run_by_default() {
    local before
    before=$(jq -S . "$FAKE_STATE")
    run teardown
    (( STATUS == 0 )) && only_reads && no_identifiers && [[ "$(jq -S . "$FAKE_STATE")" == "$before" ]] \
        && [[ "$OUT" == *"+ delete user pool ccit-ci-default"* && "$OUT" == *"+ schedule the key's deletion in 7 days"* ]] \
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
        and ([.log_groups | keys[]] == [])' --argjson roles "$roles" "$FAKE_STATE" >/dev/null
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
    run --apply
    (( STATUS == 0 )) || { echo "$OUT" | tail -5; return 1; }
    CCIT_CI_REGION=us-west-2 run --apply
    (( STATUS == 1 )) && only_reads && [[ "$OUT" == *"ccit-ci- resources are in us-east-1, not CCIT_CI_REGION's us-west-2"* ]] \
        || { echo "$OUT" | tail -5; return 1; }
    CCIT_CI_REGION=us-west-2 run teardown --apply
    (( STATUS == 1 )) && only_reads && [[ "$OUT" == *"Set CCIT_CI_REGION to theirs."* ]] || { echo "$OUT" | tail -5; return 1; }
    run lambda-drift --record --accept-deployed
    (( STATUS == 0 )) && [[ "$OUT" == *"Recorded the deployed files of 2 functions"* ]] || { echo "$OUT" | tail -5; return 1; }
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
        && [[ "$(grep -c "the deployed files are this checkout's" <<<"$OUT")" == 8 ]] \
        && [[ "$(grep -c "CodeSha256, a note only: the same as this checkout's zip's" <<<"$OUT")" == 8 ]] \
        && [[ "$(calls | grep -c '^lambda get-function$')" == 8 && "$(calls | grep -c '^lambda list-tags$')" == 8 ]] \
        && [[ -z "$(find "$TMPDIR" -name 'ccit-ci-lambda-code.*')" ]] || { echo "$OUT"; return 1; }
    hand_deploy ccit-ci-discard-sender rezipped
    run lambda-drift
    (( STATUS == 0 )) && [[ "$(grep -c "the deployed files are this checkout's" <<<"$OUT")" == 8 ]] \
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
    (( STATUS == 0 )) && only_reads && [[ "$OUT" == *"$summary"*"Recorded the deployed files of 8 functions"* ]] \
        && jq -e '.functions | length == 8 and (.["pre-sign-up"].files | keys == ["notes.txt", "triggers.mjs"])
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
        && [[ "$(sed -nE 's/^  \+ //p' <<<"$OUT")" == "extend the tests' read-only API key to 364 days from now (the same key)" ]] \
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
check "snapshot, key-expiry and lambda-drift refuse --apply, before any AWS call" read_only_commands_refuse_apply
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
check "a phase-1 --apply --upload after phase 2 makes no call: the triggers' role keeps every trigger's logs" \
    a_phase_1_rerun_after_phase_2_makes_no_call
check "the code sink's API key near its expiry is extended in place, and the uploaded files stay valid" \
    an_api_key_near_its_expiry_is_extended_in_place
check "the code sink key's expiry is recorded as soon as the key is extended, though a later step stops the run" \
    the_expiry_is_recorded_when_the_key_is_extended
check "the code sink key's expiry is recorded by --apply and by key-expiry --record, with read calls only" \
    the_key_expiry_is_recorded
check "an expired key's replacement is recorded only once the uploaded files that name the old key are replaced" \
    an_expired_key_is_recorded_only_once_the_uploads_name_the_new_one
check "a key with other contents refuses the whole upload" a_key_with_other_contents_refuses_the_upload
check "snapshot and verify-unchanged: a user count is no change; a change, a removal, a foreign addition fail" \
    snapshot_and_verify
check "snapshot: unordered lists in another order are no change; Layers reordered or a real change are" \
    snapshot_normalizes_unordered_lists
check "snapshot: a Lambda's RuntimeVersionConfig, which Lambda moves by itself, is no change" \
    snapshot_ignores_the_runtime_version
check "the Cognito lists are read to their last page: a ccit-ci- pool on page 2 is found, snapshotted, torn down" \
    lists_are_read_to_their_last_page
check "teardown is a dry run by default and names only ccit-ci- resources" teardown_is_a_dry_run_by_default
check "teardown --apply deletes only the ccit-ci- resources it made" teardown_deletes_only_ours
if frozen_script; then
    check "a rerun over phase 2 as applied ($FROZEN_COMMIT) adds only the alias-codes and MFA-required pools and three new files" \
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
