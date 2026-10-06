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
# three pools, the sender's decrypt to the two it sends for and the SMS role to the default pool, and writes the six
# files (mode 600, in a mode-700 directory) with what the client reads; that a second --apply makes no call; that
# --upload puts only new keys under auth/cognito-client-ci/ and refuses, with no upload, once one exists; that a
# rerun over phase 2 as it was first applied (the script at 80712afe4, when git has it) plans and makes only the
# alias-codes pool and what it needs, updates only the script's own resources, and uploads only the two new files,
# finding the four uploaded ones byte for byte the same; that snapshot and verify-unchanged ignore a user count,
# and fail on a changed, removed or foreign added resource, but not on a ccit-ci- addition or change; that teardown
# is a dry run by default, deletes only the ccit-ci- resources with --apply, and refuses an untagged one; and that
# the library's guards refuse a name that is not ccit-ci- and a mutating call in a dry run.
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
unset AWS_PROFILE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN CCIT_CI_REGION
[[ "$(command -v aws)" == "$BIN/aws" ]] || { echo "FAIL: the fake aws is not first on PATH"; exit 1; }
ACCOUNT=123456789012
BUCKET=fake-ci-bucket.example
PLUGIN_POOL=us-east-1_PluginPool01

failures=0
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

# No identifier the fake knows reaches the output: the account, the bucket, a pool, client, key or API id.
no_identifiers() {
    [[ "$OUT" != *"$ACCOUNT"* && "$OUT" != *"$BUCKET"* && "$OUT" != *"$PLUGIN_POOL"* && "$OUT" != *us-east-1_Fake* ]] \
        && ! grep -qE '[0-9a-f]{26}|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|da2-' <<<"$OUT"
}

# Every planned or made call ('+' line) names a ccit-ci- resource.
plus_lines_are_ours() {
    ! grep -E '^  \+ ' <<<"$OUT" | grep -vqE 'ccit-ci-|ccit_ci_|/ccit-ci/|alias/ccit-ci-|cognito-client-ci/|the code sink schema|the tests. read-only API key|the code table|resolver|the KMS key for|expire ccit'
}

usage_is_refused() {
    run --scope bogus
    (( STATUS == 2 )) && [[ ! -s "$FAKE_LOG" ]] || [[ -z "$(calls)" ]]
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
        and ($arns | length == 3)
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
    [[ "$(calls | grep -c 's3api put-object')" == 5 ]] || return 1
    CONFIG=$(config_dir_of "$OUT")
    [[ -d "$CONFIG" && "$(stat -f '%Lp' "$CONFIG")" == 700 ]] || return 1
    modes=$(find "$CONFIG" -type f -exec stat -f '%Lp' {} + | sort -u)
    [[ "$modes" == 600 && "$(find "$CONFIG" -type f | wc -l | tr -d ' ')" == 6 ]] || return 1
    alias_codes_files_are_right && alias_codes_pool_is_right || return 1
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
    jq -e '([.pools[] | select(.UserPool.Name | startswith("ccit-ci-")) | .UserPool.UserPoolTags.purpose] | length == 3 and (unique == ["amplify-cognito-client-integ"]))
        and ([.pools[] | .UserPool.Name] | sort == ["amplify-plugin-default", "ccit-ci-default", "ccit-ci-email-alias", "ccit-ci-email-alias-codes"])
        and ([.pools[] | select(.UserPool.Name == "ccit-ci-default") | .UserPool.UserPoolTier] == ["ESSENTIALS"])
        and ([.roles | keys[] | select(startswith("ccit-ci-"))] | length == 7)
        and ([.roles[] | select(.Role.RoleName | startswith("ccit-ci-")) | .tags[0].Value] | unique == ["amplify-cognito-client-integ"])
        and ([.lambdas[] | select(.config.FunctionName | startswith("ccit-ci-")) | .tags.purpose] | length == 8 and (unique == ["amplify-cognito-client-integ"]))
        and ([.lambdas[] | .config.FunctionName] | all(startswith("ccit-ci-") or . == "plugin-pre-sign-up"))
        and ([.ssm | keys[]] == ["/ccit-ci/custom-challenge-answer", "/ccit-ci/new-password-temporary"])
        and ([.identity_pools[] | .IdentityPoolName] | sort == ["ccit_ci_default", "plugin_identity"])' "$FAKE_STATE" >/dev/null || return 1
    # The SMS role is narrowed to the default pool, the only one that names it (the key and the decrypt: above).
    jq -e '.roles["ccit-ci-cognito-sms"].Role.AssumeRolePolicyDocument.Statement[0].Condition.ArnEquals["aws:SourceArn"] | length == 1' \
        "$FAKE_STATE" >/dev/null || return 1
    secrets_use_the_ccit_ci_key || return 1
    [[ "$OUT" == *"new-password users: created 12"* ]]
}

a_second_apply_makes_no_call_and_uploads_nothing() {
    run --apply --scope all --upload
    (( STATUS == 0 )) && [[ "$OUT" == *"Done: 0 calls made."* ]] && ! calls | grep -q 'put-object' && no_identifiers
}

a_key_with_other_contents_refuses_the_upload() {
    jq '.s3["v2/testconfiguration/auth/cognito-client-ci/ccit-ci-default-credentials.json"].body = "{}"' "$FAKE_STATE" \
        > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    run --apply --scope all --upload
    (( STATUS == 1 )) && [[ "$OUT" == *"nothing is ever overwritten"* ]] && ! calls | grep -q 'put-object' \
        && only_reads && no_identifiers
}

# What a rerun over phase 2 as first applied (80712afe4) plans: the alias-codes pool and what it needs, the updates
# to the script's own resources that name it, and the two new files.
RERUN_PLAN="create log group /aws/lambda/ccit-ci-pre-sign-up-confirmable
keep /aws/lambda/ccit-ci-pre-sign-up-confirmable for 7 days
open the key policy of alias/ccit-ci-senders to the account's pools while a ccit-ci- pool is made
set the one inline policy of ccit-ci-trigger-exec
store /ccit-ci/custom-challenge-answer again, the same value, encrypted with alias/ccit-ci-senders
store /ccit-ci/new-password-temporary again, the same value, encrypted with alias/ccit-ci-senders
create Lambda ccit-ci-pre-sign-up-confirmable (Node.js 22, no reserved concurrency)
create user pool ccit-ci-email-alias-codes (pools/email-alias.json, self sign-up on, custom senders)
let cognito-idp.amazonaws.com invoke ccit-ci-custom-sender (cognito-email-alias-codes)
let cognito-idp.amazonaws.com invoke ccit-ci-pre-sign-up-confirmable (cognito-email-alias-codes)
create app client ccit-ci-email-alias-codes-client (public, pools/email-alias.json \`client\`)
set the key policy of alias/ccit-ci-senders to the ccit-ci- pools
set the one inline policy of ccit-ci-sender-exec
set the one inline policy of ccit-ci-reset-exec
upload auth/cognito-client-ci/ccit-ci-email-alias-codes-amplify_outputs.json (new key only)
upload auth/cognito-client-ci/ccit-ci-capabilities.json (new key only)"

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
        && [[ "$OUT" == *"Planned: 16 calls. Nothing was changed."* ]] \
        || { echo "$OUT" | sed -nE 's/^  \+ //p'; return 1; }
    before=$(plugin_part)
    run --apply --scope all --upload
    (( STATUS == 0 )) && no_identifiers && [[ "$(plugin_part)" == "$before" ]] \
        && [[ "$(sed -nE 's/^  \+ //p' <<<"$OUT")" == "$RERUN_PLAN" ]] \
        && [[ "$(grep -c 'uploaded already, the same bytes' <<<"$OUT")" == 4 ]] \
        && [[ "$(calls | grep -c 's3api put-object')" == 2 ]] || { echo "$OUT" | tail -8; return 1; }
    CONFIG=$(config_dir_of "$OUT")
    alias_codes_files_are_right && alias_codes_pool_is_right && secrets_use_the_ccit_ci_key || return 1
    # Only the script's own resources changed: the custom sender, given the new pool's invoke permission (its
    # revision, and its policy, recorded both as a function and as a trigger).
    run snapshot
    second=$(find "$WORK/disc" -name 'snapshot-*.json' ! -name '*.docs.json' | sort | tail -1)
    status=0
    out=$("$SCRIPT" verify-unchanged "$WORK/rerun-before.json" "$second" 2>&1) || status=$?
    (( status == 0 )) && [[ "$out" == *"changed  lambda ccit-ci-custom-sender: RevisionId (ccit-ci-, this script's own)"* ]] \
        && [[ "$out" == *"changed  trigger-lambda-policy ccit-ci-custom-sender: Statement (ccit-ci-, this script's own)"* ]] \
        && [[ "$out" == *"added    user-pool ccit-ci-email-alias-codes (ccit-ci-, expected)"* ]] \
        && [[ "$out" == *" 0 changed, 3 ccit-ci- changed, 0 removed"* ]] || { echo "$out"; return 1; }
    run --apply --scope all --upload
    (( STATUS == 0 )) && [[ "$OUT" == *"Done: 0 calls made."* ]]
}

snapshot_and_verify() {
    local first second third out status
    run snapshot
    (( STATUS == 0 )) && only_reads && no_identifiers || return 1
    first=$(find "$WORK/disc" -name 'snapshot-*.json' ! -name '*.docs.json' | sort | tail -1)
    [[ -f "$first" && "$(stat -f '%Lp' "$first")" == 600 && "$(stat -f '%Lp' "${first%.json}.docs.json")" == 600 ]] || return 1
    mv "$first" "$WORK/disc/before.json"
    mv "${first%.json}.docs.json" "$WORK/disc/before.docs.json"
    # A user count moving is not a change.
    jq --arg p "$PLUGIN_POOL" '.pools[$p].UserPool.EstimatedNumberOfUsers = 116999' "$FAKE_STATE" > "$WORK/s" && mv "$WORK/s" "$FAKE_STATE"
    run snapshot
    second=$(find "$WORK/disc" -name 'snapshot-*.json' ! -name '*.docs.json' | sort | tail -1)
    run verify-unchanged "$WORK/disc/before.json" "$second"
    (( STATUS == 0 )) && [[ "$OUT" == *"OK: every resource"* ]] || { echo "$OUT"; return 1; }
    rm -f "$second" "${second%.json}.docs.json"
    # A changed plugin pool, a removed plugin object, a ccit-ci- addition and a foreign one.
    jq --arg p "$PLUGIN_POOL" '.pools[$p].UserPool.MfaConfiguration = "OFF"
        | del(.s3["v2/testconfiguration/auth/AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json"])
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
        && [[ "$out" != *"$PLUGIN_POOL"* && "$out" != *"$ACCOUNT"* && "$out" != *116854* ]] || { echo "$out"; return 1; }
    # Only the foreign addition, allowed, leaves the change and the removal failing.
    status=0
    out=$("$SCRIPT" verify-unchanged "$WORK/disc/before.json" "$third" --allow-foreign-additions 2>&1) || status=$?
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
    [[ "$(grep -c '+ delete user pool ccit-ci-' <<<"$OUT")" == 3 && "$OUT" == *"+ delete identity pool ccit_ci_default"* ]]
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
    [[ "$(jq .version "$dir/a.json")" == 2 ]] && ! cmp -s "$dir/a.ndjson" "$dir/b.ndjson" || return 1
    out=$(python3 "$CI_DIR/snapshot.py" verify "$dir/a.json" "$dir/b.json") || { echo "$out"; return 1; }
    [[ "$out" == *"0 changed, 0 ccit-ci- changed"* ]] || return 1
    # The same, written by version 1 (hashed unnormalized): the documents are hashed again, so still no change.
    jq '.version = 1 | .entries |= map_values(.sha256 = "v1")' "$dir/a.json" > "$dir/v1.json"
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
check "phase 2 adds the default and alias-codes pools, narrowed, keeps phase 1, and uploads only the five new files" \
    phase_2_adds_the_default_pool_and_keeps_phase_1
check "a second --apply --upload makes no call and uploads nothing" a_second_apply_makes_no_call_and_uploads_nothing
check "a key with other contents refuses the whole upload" a_key_with_other_contents_refuses_the_upload
check "snapshot and verify-unchanged: a user count is no change; a change, a removal, a foreign addition fail" \
    snapshot_and_verify
check "snapshot: unordered lists in another order are no change; Layers reordered or a real change are" \
    snapshot_normalizes_unordered_lists
check "the Cognito lists are read to their last page: a ccit-ci- pool on page 2 is found, snapshotted, torn down" \
    lists_are_read_to_their_last_page
check "teardown is a dry run by default and names only ccit-ci- resources" teardown_is_a_dry_run_by_default
check "teardown --apply deletes only the ccit-ci- resources it made" teardown_deletes_only_ours
if frozen_script; then
    check "a rerun over phase 2 as applied ($FROZEN_COMMIT) adds only the alias-codes pool and two new files" \
        a_rerun_over_phase_2_as_applied_adds_only_the_alias_codes_pool
    check "teardown --apply then deletes every ccit-ci- resource, the alias-codes pool's too" \
        teardown_deletes_only_ours '["plugin-role"]'
else
    echo "FAIL - the script at $FROZEN_COMMIT is not in this clone's git history, so the rerun over it was not checked"
    failures=$((failures + 1))
fi
check "teardown refuses a ccit-ci- resource without the tag, before any change" teardown_refuses_an_untagged_ccit_ci_resource
check "a role-propagation error is retried" a_propagation_error_is_retried
check "any other error stops --apply, and a second --apply makes only what is missing" \
    another_error_stops_the_apply_and_a_rerun_finishes_it
check "the library refuses a name that is not ccit-ci-, and a mutating call in a dry run" library_guards

if (( failures > 0 )); then
    echo "$failures failed"
    exit 1
fi
echo "All passed"
