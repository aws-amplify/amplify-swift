#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""The plugin-parity sandbox resources (P-5 … P-14, listed below).

    parity.py provision   create or reuse every resource below (run by provision.sh)
    parity.py cleanup     delete test-created users older than 24 h (run by prepare-run.sh, P-12)
    parity.py rotate-key  renew the code sink's 7-day API key when under 4 days remain (prepare-run.sh)
    parity.py preflight   read-only: refuse a test run if a live pool could deliver a real message (prepare-run.sh)
    parity.py plugin-users  reset the plugin suites' pre-created user (prepare-run.sh, P-14)
    parity.py verify      read-only: describe every resource, print names and settings, no identifiers
    parity.py teardown    delete every resource below (run by teardown.sh)

Resources, all tagged purpose=amplify-cognito-client-integ and recorded under "parity" in state.json:
    P-5a  KMS key alias/amplify-cognito-client-integ-senders, which Cognito encrypts codes with
    P-5b  Lambdas …-pre-sign-up, …-define-auth-challenge, …-create-auth-challenge, …-verify-auth-challenge
    P-5c  the code sink, as the plugin's backends build it: Lambda …-custom-sender (the custom email and
          SMS sender; it decrypts each code and publishes it with the `createMfaInfo` mutation), the
          AppSync API …-codes (the mutation is AWS_IAM only; a 7-day API key can only read) and its
          DynamoDB table …-codes (TTL `expirationTime`).
          Tests read a code over HTTPS with the `listMfaInfo(username:)` query.
    P-5d  IAM roles …-trigger-exec, …-sender-exec, …-appsync-codes, each with exactly one inline policy
          (checked by require_role_policy_exact), and a CloudWatch log group per Lambda (7-day retention)
    P-6   the user pools from infra/pools/*.json (every POOLS key), each with its app client(s), plus P-10's
    P-6'  identity pool …_identity_only (guest only) and its two permissionless roles
    P-7   the hosted-UI domain and app client on the default pool
    P-8   DEVELOPER email for the pools with email factors, from a domain identity the account already
          verified, in an SES-sandbox region Cognito accepts. It is NOT tagged and not this sandbox's: it is
          used read-only (never tagged, changed or deleted), by explicit choice, and preflight
          re-checks it before every run. COGNITO_CLIENT_INTEG_SES_EMAIL instead creates a tagged address
          identity, which needs a human to click the link SES mails
    P-9   the SNS caller role …-cognito-sms (the plugin's Gen2 `sms: true` role, narrowed): trusted by
          cognito-idp with the external id, this account and every parity pool; sns:Publish on * limited to
          the sandbox region. Only for pools whose SMS goes through the custom sender, and only while the
          account's SNS is in the SMS sandbox
    P-13  identity pool …_plugin (guest on) and its two permissionless roles, federating the default
          pool's `plugin` and `hostedui-plugin` clients: the plugin's default backend has an identity
          pool (AuthIntegrationTests, AuthStressTests), which the base sandbox's R-IP is not. It also
          federates the passwordless pool's `client`, and passwordless-amplify_outputs.json names it, as
          the plugin's Gen2 passwordless backend names its own (PasswordlessTests/README.md, defineAuth):
          the client suites' CS-2 and CS-3 need a pool that tracks no devices, with a guest identity
          pool that federates it. And that pool's `ci` client, which the CI-shaped file names
    CI    a `ci` app client on each pool in CI_SHAPE_CLIENT_POOLS (pools/*.json): the pool's `client` as the
          plugin's CI backend has it, which plugin-configs.py --ci-shape names instead (no USER_PASSWORD_AUTH
          where CI's has none; sign-ups through it left unconfirmed where CI's backend confirms none)
    P-14  the plugin's DeviceAliasTokenRefreshIntegrationTests user on email-alias (pre-created, as its
          doc comment asks), with the password users.json keeps as pluginDeviceAliasPassword; and the
          single-use FORCE_CHANGE_PASSWORD users of AuthSRPSignInTests.testNewPasswordRequired on default,
          admin-created (no message) and reset to users.json pluginNewPasswordTemporary each run
    P-10  WebAuthn on a pool of its own (pools/webauthn.json, U-WA): WEB_AUTHN as a first factor and a WebAuthnConfiguration whose
          relying party is the plugin's (the domain in the client harness's `webcredentials:` entitlement,
          CognitoClientWebAuthnApp.entitlements, committed as the plugin's). The domain is not this sandbox's and is used read-only: an
          HTTPS GET of its apple-app-site-association checks that it lists the harness app ID, and nothing
          on it is ever changed. Nothing is created for P-10

Rules, as in lib.sh: every mutating call is preceded by a check that the target carries the purpose
tag (new resources are created with it); nothing is changed without the tag, and the only untagged
resources used are the P-8 SES identity and the P-10 relying-party domain, both read-only; the caller
must be in the account state.json records and have CLI history off; secrets (the read-only API key and
the custom-challenge answer, both in users.json, and the SMS role's external id, in state.json) reach
the CLI only through --cli-input-json from a mode-600 file that is deleted straight after the call;
and nothing prints an account, pool, client or key identifier, the SES domain, or a secret. AWS CLI
errors are printed with identifiers redacted.
"""

import base64
import datetime
import hashlib
import io
import json
import os
import re
import secrets
import shutil
import string
import subprocess
import sys
import tempfile
import time
import zipfile

INFRA = os.path.dirname(os.path.abspath(__file__))
NAME = "amplify-cognito-client-integ"
TAG_KEY = "purpose"
TAG_VALUE = NAME
STATE_DIR = os.environ.get("COGNITO_CLIENT_INTEG_DIR") or os.path.expanduser("~/.amplify-cognito-client-integ")
STATE_FILE = os.path.join(STATE_DIR, "state.json")
USERS_FILE = os.path.join(STATE_DIR, "users.json")
BUILD_DIR = os.path.join(STATE_DIR, "build")

# Pool key (infra/pools/<key>.json, and the outputs file of its main client) -> pool name.
POOLS = {
    "default": f"{NAME}-default",
    "passwordless": f"{NAME}-passwordless",
    "mfa-req-totp-sms": f"{NAME}-mfa-req-totp-sms",
    "mfa-req-email": f"{NAME}-mfa-req-email",
    "mfa-req-all": f"{NAME}-mfa-req-all",
    "email-alias": f"{NAME}-email-alias",
    "webauthn": f"{NAME}-webauthn",
}
TEST_USER_PREFIXES = ("ccit-", "confirm-")
# The plugin suites' user shapes, which the pre-sign-up trigger also accepts (triggers.mjs, PLUGIN_USER).
PLUGIN_TEST_USER = re.compile(r"^((integtest|hostedui-)[0-9a-f]{8}-|test-[0-9a-f]{8}-[0-9a-f-]{27}@)", re.I)
PLUGIN_BARE_UUID = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", re.I)
# Pools whose plugin suites expect sign-up to stop at the confirm step (no auto-confirm for their users).
PLUGIN_CONFIRM_POOLS = ("passwordless",)
# Pools where a bare UUID username is a plugin test user (EmailMFAWithAllMFATypesRequiredTests).
PLUGIN_UUID_USERNAME_POOLS = ("mfa-req-all",)
# The pools with a `ci` app client (pools/*.json), which the CI-shaped file set names instead of `client`
# (plugin-configs.py --ci-shape, CI_APP_CLIENTS): shaped as the plugin's CI backend's client, so a local run
# on the CI shape meets what CI's does. No USER_PASSWORD_AUTH on the MFA-required, email-MFA and device-alias
# ones (CI's client-suite run: "USER_PASSWORD_AUTH flow not enabled for this client").
CI_SHAPE_CLIENT_POOLS = ("passwordless", "mfa-req-totp-sms", "mfa-req-email", "mfa-req-all", "email-alias")
# Of those, the pools whose plugin CI backend confirms no sign-up (the passwordless README deploys no
# pre-sign-up trigger; CI's device-alias backend left a fresh sign-up unconfirmed): the pre-sign-up trigger
# leaves every sign-up through their `ci` client unconfirmed (triggers.mjs, CI_SHAPE_UNCONFIRMED_CLIENT_IDS).
CI_SHAPE_UNCONFIRMED_POOLS = ("passwordless", "email-alias")
PLUGIN_IDENTITY_POOL = f"{NAME.replace('-', '_')}_plugin"
# P-13's providers: (pool key, app client key). The passwordless `ci` client too, which the CI shape's
# passwordless file names with P-13.
PLUGIN_IDENTITY_CLIENTS = (("default", "plugin"), ("default", "hostedui-plugin"), ("passwordless", "client"),
                           ("passwordless", "ci"))
# The outputs files that name P-13 (the default pool's are the plugin-configs.py files, which add it there).
PLUGIN_IDENTITY_OUTPUTS = ("passwordless",)
PLUGIN_DEVICE_ALIAS_EMAIL = "ccit-plugin-device-alias@example.com"
# Single-use FORCE_CHANGE_PASSWORD users on default, reset by every prepare-run.sh. Every run that reaches one
# uses one up: the plugin's AuthSRPSignInTests.testNewPasswordRequired, in its Gen1 and its Gen2 suite (one more
# per retry iteration: CI runs with -test-iterations 3), and the client suites' CH-1. Three were used up by one
# round of the three; eight leave room for overlapping rounds and retries between two resets.
PLUGIN_NEW_PASSWORD_USER_COUNT = 8
PLUGIN_NEW_PASSWORD_USERS = tuple(f"ccit-plugin-new-password-{i}" for i in range(1, PLUGIN_NEW_PASSWORD_USER_COUNT + 1))
LAMBDA_RUNTIME = "nodejs22.x"
FUNCTIONS = {
    # name suffix: (handler, role suffix, source, environment keys)
    "pre-sign-up": ("triggers.preSignUp", "trigger-exec", "triggers",
                    ["PLUGIN_CONFIRM_POOL_IDS", "PLUGIN_UUID_USERNAME_POOL_IDS", "CI_SHAPE_UNCONFIRMED_CLIENT_IDS"]),
    "define-auth-challenge": ("triggers.defineAuthChallenge", "trigger-exec", "triggers", []),
    "create-auth-challenge": ("triggers.createAuthChallenge", "trigger-exec", "triggers", ["CUSTOM_CHALLENGE_ANSWER_SHA256"]),
    "verify-auth-challenge": ("triggers.verifyAuthChallenge", "trigger-exec", "triggers", []),
    "custom-sender": ("index.handler", "sender-exec", "custom-sender",
                      ["KMS_KEY_ARN", "GRAPHQL_API_ENDPOINT"]),
}
PLACEHOLDER_FUNCTIONS = {
    "PRE_SIGN_UP_ARN": "pre-sign-up",
    "DEFINE_AUTH_CHALLENGE_ARN": "define-auth-challenge",
    "CREATE_AUTH_CHALLENGE_ARN": "create-auth-challenge",
    "VERIFY_AUTH_CHALLENGE_ARN": "verify-auth-challenge",
    "CUSTOM_SENDER_ARN": "custom-sender",
}
KMS_ALIAS = f"alias/{NAME}-senders"
TABLE = f"{NAME}-codes"
APPSYNC_NAME = f"{NAME}-codes"
APPSYNC_DATA_SOURCE = "MfaInfoTable"
IDENTITY_ONLY_POOL = f"{NAME.replace('-', '_')}_identity_only"
LOG_RETENTION_DAYS = 7
API_KEY_LIFETIME_DAYS = 7
API_KEY_RENEW_DAYS = 4


# --- Output hygiene --------------------------------------------------------------------------------

_REDACTIONS = [
    # SES identity ARNs and names (identity/<domain or address>), and hosted-UI domains.
    (re.compile(r"\bidentity/[^\s\"',]+"), "identity/<name>"),
    (re.compile(r"\b[a-z0-9-]+\.auth\.[a-z0-9-]+\.amazoncognito\.com\b"), "<hosted-ui-domain>"),
    # IAM principals in AccessDenied messages: the role name and the session name (often a user alias).
    (re.compile(r"\b(assumed-role|role|user|federated-user)/[\w+=,.@-]+(?:/[\w+=,.@-]+)?"), r"\1/<name>"),
    (re.compile(r"\b[a-z]{2}(?:-gov)?-[a-z]+-\d:[0-9a-f-]{36}\b"), "<identity-pool>"),
    (re.compile(r"\b[a-z]{2}(?:-gov)?-[a-z]+-\d_[A-Za-z0-9]{6,}\b"), "<user-pool>"),
    (re.compile(r"\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b"), "<id>"),
    (re.compile(r"\bda2-[a-z0-9]{20,}\b"), "<api-key>"),
    (re.compile(r"\b[a-z0-9]{26}\b"), "<id>"),
    (re.compile(r"\b\d{12}\b"), "<account>"),
    (re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"), "<email>"),
]


# Literal values to mask wherever they appear, such as the borrowed SES domain; filled by load_state().
_LITERALS = set()


def redact(text):
    for literal in sorted(_LITERALS, key=len, reverse=True):
        text = text.replace(literal, "<domain>")
    for pattern, replacement in _REDACTIONS:
        text = pattern.sub(replacement, text)
    return text


def say(message):
    print(redact(message), flush=True)


def fail(message):
    sys.exit("Refusing: " + redact(message))


class AwsError(Exception):
    def __init__(self, code, message):
        super().__init__(message)
        self.code = code
        self.message = message


# --- AWS CLI ----------------------------------------------------------------------------------------

REGION = None
ACCOUNT = None


def aws(*args, stdin=None, region=True):
    """Runs one AWS CLI call and returns its JSON output. `region` is True for the sandbox's region,
    False for none (IAM), or another region's name. `stdin`, when given, is sent through
    --cli-input-json from a mode-600 file in STATE_DIR that is removed afterwards. Raises AwsError with
    the service's error code and a redacted message."""
    command = ["aws", "--output", "json"]
    if region:
        command += ["--region", REGION if region is True else region]
    command += list(args)
    path = None
    try:
        if stdin is not None:
            fd, path = tempfile.mkstemp(dir=STATE_DIR, prefix=".cli-input.", suffix=".json")
            with os.fdopen(fd, "w") as f:
                json.dump(stdin, f)
            command += ["--cli-input-json", f"file://{path}"]
        result = subprocess.run(command, capture_output=True, text=True)
    finally:
        if path:
            os.unlink(path)
    if result.returncode != 0:
        stderr = result.stderr.strip()
        match = re.search(r"\(([A-Za-z.]+)\)", stderr)
        code = match.group(1) if match else "Unknown"
        lines = stderr.splitlines()
        raise AwsError(code, redact(lines[-1] if lines else str(result.returncode)))
    return json.loads(result.stdout) if result.stdout.strip() else {}


def aws_or_none(*args, missing=("ResourceNotFoundException", "NotFoundException", "NoSuchEntity",
                                "NotFoundException", "ResourceNotFound"), **kwargs):
    """Like aws(), but returns None when the resource does not exist."""
    try:
        return aws(*args, **kwargs)
    except AwsError as error:
        if error.code in missing or error.code.endswith("NotFoundException") or error.code == "NoSuchEntity":
            return None
        raise


def run_step(description, function, *args, **kwargs):
    try:
        return function(*args, **kwargs)
    except AwsError as error:
        sys.exit(f"{description} failed ({error.code}): {error.message}")


# --- State ------------------------------------------------------------------------------------------

def load_json(path, default=None):
    if not os.path.exists(path):
        return {} if default is None else default
    with open(path) as f:
        return json.load(f)


def save_json(path, value, mode=0o600):
    tmp = path + ".tmp"
    with os.fdopen(os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, mode), "w") as f:
        json.dump(value, f, sort_keys=True, indent=1)
        f.write("\n")
    os.replace(tmp, path)
    os.chmod(path, mode)


def load_state():
    state = load_json(STATE_FILE)
    domain = state.get("parity", {}).get("sesDomain")
    if domain:
        _LITERALS.add(domain)
    if not state.get("account") or not state.get("region"):
        sys.exit(f"No usable {STATE_FILE}; run infra/provision.sh first.")
    return state


def save_parity(parity):
    state = load_json(STATE_FILE)
    state["parity"] = parity
    save_json(STATE_FILE, state, mode=0o600)


def users():
    return load_json(USERS_FILE)


def set_user_secret(key, value):
    data = users()
    data[key] = value
    save_json(USERS_FILE, data)


def ensure_user_secret(key, length=24):
    data = users()
    if not data.get(key):
        alphabet = string.ascii_letters + string.digits
        set_user_secret(key, "".join(secrets.choice(alphabet) for _ in range(length)))
        say(f"Generated {key} in users.json")
    return users()[key]


# --- Guards -----------------------------------------------------------------------------------------

def require_cli_history_off():
    history = subprocess.run(["aws", "configure", "get", "cli_history"], capture_output=True, text=True).stdout
    if history.strip() == "enabled":
        sys.exit("Refusing: AWS CLI history is enabled (cli_history = enabled), and it would record the "
                 "secrets these scripts send. Turn it off for this profile first.")


def require_recorded_account(state):
    global ACCOUNT, REGION
    REGION = state["region"]
    ACCOUNT = aws("sts", "get-caller-identity")["Account"]
    if ACCOUNT != state["account"]:
        sys.exit("Refusing: the caller's account is not the one state.json records.")


def tagged(tags):
    return (tags or {}).get(TAG_KEY) == TAG_VALUE


def tag_list(tags):
    return {t["Key"]: t["Value"] for t in tags or []}


def require_user_pool_tag(pool_id, label):
    pool = aws("cognito-idp", "describe-user-pool", "--user-pool-id", pool_id)["UserPool"]
    if not tagged(pool.get("UserPoolTags")):
        fail(f"user pool {label} is not tagged {TAG_KEY}={TAG_VALUE}.")
    return pool


def require_identity_pool_tag(pool_id, label):
    arn = f"arn:aws:cognito-identity:{REGION}:{ACCOUNT}:identitypool/{pool_id}"
    if not tagged(aws("cognito-identity", "list-tags-for-resource", "--resource-arn", arn).get("Tags")):
        fail(f"identity pool {label} is not tagged {TAG_KEY}={TAG_VALUE}.")


def require_role_tag(role):
    tags = tag_list(aws("iam", "list-role-tags", "--role-name", role, region=False).get("Tags"))
    if not tagged(tags):
        fail(f"role {role} is not tagged {TAG_KEY}={TAG_VALUE}.")


def require_role_without_policies(role):
    attached = aws("iam", "list-attached-role-policies", "--role-name", role, region=False)["AttachedPolicies"]
    inline = aws("iam", "list-role-policies", "--role-name", role, region=False)["PolicyNames"]
    if attached or inline:
        fail(f"role {role} has {len(attached)} attached and {len(inline)} inline policies; it must have none.")


def normalized(document):
    return json.dumps(document, sort_keys=True)


def require_role_policy_exact(role, policy_name, document):
    """The tag, no attached policy, and exactly one inline policy, `policy_name`, equal to `document`."""
    require_role_tag(role)
    attached = aws("iam", "list-attached-role-policies", "--role-name", role, region=False)["AttachedPolicies"]
    inline = aws("iam", "list-role-policies", "--role-name", role, region=False)["PolicyNames"]
    if attached or inline != [policy_name]:
        fail(f"role {role} must have exactly the inline policy {policy_name} and nothing attached.")
    current = aws("iam", "get-role-policy", "--role-name", role, "--policy-name", policy_name,
                  region=False)["PolicyDocument"]
    if normalized(current) != normalized(document):
        fail(f"role {role}'s inline policy {policy_name} differs from the script's document.")


def require_lambda_tag(function_arn, label):
    if not tagged(aws("lambda", "list-tags", "--resource", function_arn).get("Tags")):
        fail(f"Lambda {label} is not tagged {TAG_KEY}={TAG_VALUE}.")


def require_kms_tag(key_id):
    tags = {t["TagKey"]: t["TagValue"] for t in aws("kms", "list-resource-tags", "--key-id", key_id)["Tags"]}
    if not tagged(tags):
        fail(f"KMS key {KMS_ALIAS} is not tagged {TAG_KEY}={TAG_VALUE}.")


def require_table_tag(table_arn):
    if not tagged(tag_list(aws("dynamodb", "list-tags-of-resource", "--resource-arn", table_arn).get("Tags"))):
        fail(f"table {TABLE} is not tagged {TAG_KEY}={TAG_VALUE}.")


def require_appsync_tag(api_arn):
    if not tagged(aws("appsync", "list-tags-for-resource", "--resource-arn", api_arn).get("tags")):
        fail(f"AppSync API {APPSYNC_NAME} is not tagged {TAG_KEY}={TAG_VALUE}.")


def log_group_arn(name):
    return f"arn:aws:logs:{REGION}:{ACCOUNT}:log-group:{name}"


def require_log_group_tag(name):
    if not tagged(aws("logs", "list-tags-for-resource", "--resource-arn", log_group_arn(name)).get("tags")):
        fail(f"log group {name} is not tagged {TAG_KEY}={TAG_VALUE}.")


def require_ses_identity_tag(identity_arn):
    if not tagged(tag_list(aws("sesv2", "list-tags-for-resource", "--resource-arn", identity_arn).get("Tags"))):
        fail(f"the SES identity is not tagged {TAG_KEY}={TAG_VALUE}.")


# --- Names and ARNs ---------------------------------------------------------------------------------

def function_name(suffix):
    return f"{NAME}-{suffix}"


def function_arn(suffix):
    return f"arn:aws:lambda:{REGION}:{ACCOUNT}:function:{function_name(suffix)}"


def role_name(suffix):
    return f"{NAME}-{suffix}"


def role_arn(suffix):
    return f"arn:aws:iam::{ACCOUNT}:role/{role_name(suffix)}"


def user_pool_arn(pool_id):
    return f"arn:aws:cognito-idp:{REGION}:{ACCOUNT}:userpool/{pool_id}"


def table_arn():
    return f"arn:aws:dynamodb:{REGION}:{ACCOUNT}:table/{TABLE}"


def lambda_log_group(suffix):
    return f"/aws/lambda/{function_name(suffix)}"


# --- P-5d: log groups and roles --------------------------------------------------------------------

def ensure_log_group(name):
    found = aws("logs", "describe-log-groups", "--log-group-name-prefix", name)["logGroups"]
    group = next((g for g in found if g["logGroupName"] == name), None)
    if group is None:
        aws("logs", "create-log-group", "--log-group-name", name, "--tags", f"{TAG_KEY}={TAG_VALUE}")
        say(f"Created log group {name}")
    else:
        require_log_group_tag(name)
    if (group or {}).get("retentionInDays") != LOG_RETENTION_DAYS:
        require_log_group_tag(name)
        aws("logs", "put-retention-policy", "--log-group-name", name,
            "--retention-in-days", str(LOG_RETENTION_DAYS))


def lambda_trust():
    return {"Version": "2012-10-17", "Statement": [{
        "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole",
        "Condition": {"StringEquals": {"aws:SourceAccount": ACCOUNT}}}]}


def appsync_trust(api_arn):
    return {"Version": "2012-10-17", "Statement": [{
        "Effect": "Allow", "Principal": {"Service": "appsync.amazonaws.com"}, "Action": "sts:AssumeRole",
        "Condition": {"StringEquals": {"aws:SourceAccount": ACCOUNT}, "ArnEquals": {"aws:SourceArn": api_arn}}}]}


def logs_statement(suffixes):
    return {"Sid": "WriteOwnLogs", "Effect": "Allow", "Action": ["logs:CreateLogStream", "logs:PutLogEvents"],
            "Resource": [log_group_arn(lambda_log_group(s)) + ":*" for s in suffixes]}


def role_policies(kms_key_arn, api_arn, pool_ids):
    triggers = [s for s, spec in FUNCTIONS.items() if spec[1] == "trigger-exec"]
    return {
        "trigger-exec": (lambda_trust(), {"Version": "2012-10-17", "Statement": [logs_statement(triggers)]}),
        "sender-exec": (lambda_trust(), {"Version": "2012-10-17", "Statement": [
            logs_statement(["custom-sender"]),
            # Only codes Cognito encrypted for a parity pool (Cognito sets the userpool-id encryption
            # context). Before every pool exists, any pool id in the region.
            {"Sid": "DecryptCodes", "Effect": "Allow", "Action": "kms:Decrypt", "Resource": kms_key_arn,
             "Condition": ({"StringEquals": {"kms:EncryptionContext:userpool-id": sorted(pool_ids)}} if pool_ids
                           else {"StringLike": {"kms:EncryptionContext:userpool-id": f"{REGION}_*"}})},
            {"Sid": "PublishCodes", "Effect": "Allow", "Action": "appsync:GraphQL",
             "Resource": f"{api_arn}/types/Mutation/fields/createMfaInfo"}]}),
        "appsync-codes": (appsync_trust(api_arn), {"Version": "2012-10-17", "Statement": [{
            "Sid": "CodesTable", "Effect": "Allow", "Action": ["dynamodb:PutItem", "dynamodb:Query"],
            "Resource": table_arn()}]}),
    }


def create_role(role, trust):
    """Trust and policy documents reach IAM through --cli-input-json (a mode-600 file), not argv: the
    SMS role's trust carries its external id, which `ps` would otherwise show."""
    aws("iam", "create-role", region=False, stdin={
        "RoleName": role, "AssumeRolePolicyDocument": json.dumps(trust),
        "Tags": [{"Key": TAG_KEY, "Value": TAG_VALUE}]})


def update_trust(role, trust):
    aws("iam", "update-assume-role-policy", region=False,
        stdin={"RoleName": role, "PolicyDocument": json.dumps(trust)})


def ensure_role_with_policy(suffix, trust, policy):
    role = role_name(suffix)
    policy_name = f"{role}-policy"
    existing = aws_or_none("iam", "get-role", "--role-name", role, region=False)
    if existing is None:
        create_role(role, trust)
        say(f"Created role {role}")
    else:
        require_role_tag(role)
        attached = aws("iam", "list-attached-role-policies", "--role-name", role, region=False)["AttachedPolicies"]
        inline = aws("iam", "list-role-policies", "--role-name", role, region=False)["PolicyNames"]
        if attached or any(name != policy_name for name in inline):
            fail(f"role {role} carries a policy the script did not put there.")
        if normalized(existing["Role"]["AssumeRolePolicyDocument"]) != normalized(trust):
            require_role_tag(role)
            update_trust(role, trust)
    require_role_tag(role)
    aws("iam", "put-role-policy", region=False,
        stdin={"RoleName": role, "PolicyName": policy_name, "PolicyDocument": json.dumps(policy)})
    require_role_policy_exact(role, policy_name, policy)
    return role_arn(suffix)


def identity_trust(identity_pool_id, amr):
    return {"Version": "2012-10-17", "Statement": [{
        "Effect": "Allow", "Principal": {"Federated": "cognito-identity.amazonaws.com"},
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {"StringEquals": {"cognito-identity.amazonaws.com:aud": identity_pool_id},
                      "ForAnyValue:StringLike": {"cognito-identity.amazonaws.com:amr": amr}}}]}


def ensure_permissionless_role(suffix, trust):
    """As provision.sh's ensure_role: tagged, no policy of any kind, trust re-applied."""
    role = role_name(suffix)
    if aws_or_none("iam", "get-role", "--role-name", role, region=False) is None:
        create_role(role, trust)
        say(f"Created role {role}")
    else:
        require_role_tag(role)
        require_role_without_policies(role)
        require_role_tag(role)
        update_trust(role, trust)
    return role_arn(suffix)


# --- P-5a: KMS key ----------------------------------------------------------------------------------

def kms_key_policy(pool_ids):
    """Cognito may encrypt with the key only for the parity pools. Before every pool exists (the first
    run), any pool in the account; provision() narrows it once they all do."""
    if pool_ids:
        source = {"ArnEquals": {"aws:SourceArn": sorted(user_pool_arn(i) for i in pool_ids)}}
    else:
        source = {"ArnLike": {"aws:SourceArn": f"arn:aws:cognito-idp:{REGION}:{ACCOUNT}:userpool/*"}}
    return {"Version": "2012-10-17", "Id": f"{NAME}-senders", "Statement": [
        {"Sid": "AccountAdministration", "Effect": "Allow", "Principal": {"AWS": f"arn:aws:iam::{ACCOUNT}:root"},
         "Action": "kms:*", "Resource": "*"},
        {"Sid": "CognitoEncryptsCodes", "Effect": "Allow", "Principal": {"Service": "cognito-idp.amazonaws.com"},
         "Action": ["kms:CreateGrant", "kms:Encrypt"], "Resource": "*",
         "Condition": dict({"StringEquals": {"aws:SourceAccount": ACCOUNT}}, **source)}]}


def recorded_pool_ids(parity):
    """Every parity pool's id (all POOLS keys, webauthn included), or None unless every one is recorded."""
    ids = [parity.get("pools", {}).get(key, {}).get("userPoolId") for key in POOLS]
    return ids if all(ids) else None


def live_pool_ids(parity):
    """Every parity pool's id when every one is recorded and still exists, else None. Policies scoped
    to pools (the KMS key's encrypt, the sender's decrypt, the SMS role's trust) use the wildcard only
    while some pool is about to be created, so a pool deleted by hand and re-created is not locked out
    by a trust naming its old ARN. Read-only."""
    ids = recorded_pool_ids(parity)
    if ids and all(aws_or_none("cognito-idp", "describe-user-pool", "--user-pool-id", i) for i in ids):
        return ids
    return None


def ensure_kms_key(pool_ids):
    aliases = aws("kms", "list-aliases")["Aliases"]
    alias = next((a for a in aliases if a["AliasName"] == KMS_ALIAS), None)
    policy = kms_key_policy(pool_ids)
    if alias is None or not alias.get("TargetKeyId"):
        key = aws("kms", "create-key", "--description", f"{NAME}: Cognito custom sender codes",
                  "--policy", json.dumps(policy), "--tags", f"TagKey={TAG_KEY},TagValue={TAG_VALUE}")["KeyMetadata"]
        key_id = key["KeyId"]
        require_kms_tag(key_id)
        aws("kms", "create-alias", "--alias-name", KMS_ALIAS, "--target-key-id", key_id)
        say(f"Created KMS key {KMS_ALIAS}")
    else:
        key_id = alias["TargetKeyId"]
        require_kms_tag(key_id)
        metadata = aws("kms", "describe-key", "--key-id", key_id)["KeyMetadata"]
        if metadata["KeyState"] != "Enabled":
            fail(f"KMS key {KMS_ALIAS} is {metadata['KeyState']}; cancel its deletion or remove the alias.")
        current = json.loads(aws("kms", "get-key-policy", "--key-id", key_id, "--policy-name", "default")["Policy"])
        if normalized(current) != normalized(policy):
            require_kms_tag(key_id)
            aws("kms", "put-key-policy", "--key-id", key_id, "--policy-name", "default", "--policy", json.dumps(policy))
            say(f"Re-applied the key policy of {KMS_ALIAS}")
    return key_id, aws("kms", "describe-key", "--key-id", key_id)["KeyMetadata"]["Arn"]


# --- P-5c: DynamoDB table and AppSync API ----------------------------------------------------------

def ensure_table():
    table = aws_or_none("dynamodb", "describe-table", "--table-name", TABLE)
    if table is None:
        aws("dynamodb", "create-table", "--table-name", TABLE, "--billing-mode", "PAY_PER_REQUEST",
            "--attribute-definitions", "AttributeName=username,AttributeType=S", "AttributeName=code,AttributeType=S",
            "--key-schema", "AttributeName=username,KeyType=HASH", "AttributeName=code,KeyType=RANGE",
            "--tags", f"Key={TAG_KEY},Value={TAG_VALUE}")
        aws("dynamodb", "wait", "table-exists", "--table-name", TABLE)
        say(f"Created table {TABLE}")
    require_table_tag(table_arn())
    ttl = aws("dynamodb", "describe-time-to-live", "--table-name", TABLE)["TimeToLiveDescription"]
    if ttl.get("TimeToLiveStatus") not in ("ENABLED", "ENABLING"):
        require_table_tag(table_arn())
        aws("dynamodb", "update-time-to-live", "--table-name", TABLE,
            "--time-to-live-specification", "Enabled=true,AttributeName=expirationTime")


def read(path):
    with open(os.path.join(INFRA, path)) as f:
        return f.read()


def ensure_api(parity):
    """The code sink's AppSync API: API key by default (the tests' reads), AWS_IAM as an additional mode
    (the custom sender's `createMfaInfo`, which the key cannot call). Returns (api id, api ARN)."""
    api = None
    if parity.get("codeSinkApiId"):
        api = (aws_or_none("appsync", "get-graphql-api", "--api-id", parity["codeSinkApiId"]) or {}).get("graphqlApi")
    if api is None:
        apis = aws("appsync", "list-graphql-apis")["graphqlApis"]
        api = next((a for a in apis if a["name"] == APPSYNC_NAME), None)
    created = api is None
    if created:
        api = aws("appsync", "create-graphql-api", "--name", APPSYNC_NAME, "--authentication-type", "API_KEY",
                  "--additional-authentication-providers", "authenticationType=AWS_IAM",
                  "--tags", f"{TAG_KEY}={TAG_VALUE}")["graphqlApi"]
        say(f"Created AppSync API {APPSYNC_NAME}")
    api_id, api_arn = api["apiId"], api["arn"]
    require_appsync_tag(api_arn)
    parity["codeSinkApiId"] = api_id
    parity["codeSinkUrl"] = api["uris"]["GRAPHQL"]
    modes = [p.get("authenticationType") for p in api.get("additionalAuthenticationProviders") or []]
    if api.get("authenticationType") != "API_KEY" or modes != ["AWS_IAM"]:
        # UpdateGraphqlApi resets what it is not given; the API has no other settings.
        require_appsync_tag(api_arn)
        aws("appsync", "update-graphql-api", "--api-id", api_id, "--name", APPSYNC_NAME,
            "--authentication-type", "API_KEY", "--additional-authentication-providers", "authenticationType=AWS_IAM")
        say(f"Updated the auth modes of AppSync API {APPSYNC_NAME}")

    schema = read("codesink/schema.graphql")
    schema_sha = hashlib.sha256(schema.encode()).hexdigest()
    if created or parity.get("codeSinkSchemaSha256") != schema_sha:
        require_appsync_tag(api_arn)
        aws("appsync", "start-schema-creation", "--api-id", api_id,
            "--definition", "fileb://" + os.path.join(INFRA, "codesink", "schema.graphql"))
        for _ in range(60):
            status = aws("appsync", "get-schema-creation-status", "--api-id", api_id)
            if status["status"] in ("SUCCESS", "ACTIVE"):
                break
            if status["status"] == "FAILED":
                sys.exit(f"AppSync schema creation failed: {redact(status.get('details', ''))}")
            time.sleep(2)
        parity["codeSinkSchemaSha256"] = schema_sha
        say("Applied the code sink schema")
    return api_id, api_arn


def ensure_api_resolvers(api_id, api_arn, data_source_role_arn):
    config = {"tableName": TABLE, "awsRegion": REGION}
    source = aws_or_none("appsync", "get-data-source", "--api-id", api_id, "--name", APPSYNC_DATA_SOURCE)
    desired_source = {"apiId": api_id, "name": APPSYNC_DATA_SOURCE, "type": "AMAZON_DYNAMODB",
                      "serviceRoleArn": data_source_role_arn, "dynamodbConfig": config}
    if source is None:
        require_appsync_tag(api_arn)
        run_with_iam_retry(lambda: aws("appsync", "create-data-source", stdin=desired_source))
    else:
        current = source["dataSource"]
        if (current.get("serviceRoleArn") != data_source_role_arn
                or current.get("dynamodbConfig", {}).get("tableName") != TABLE):
            require_appsync_tag(api_arn)
            aws("appsync", "update-data-source", stdin=desired_source)

    for type_name, field, request, response in [
        ("Mutation", "createMfaInfo", "codesink/createMfaInfo.request.vtl", "codesink/item.response.vtl"),
        ("Query", "listMfaInfo", "codesink/listMfaInfo.request.vtl", "codesink/items.response.vtl"),
    ]:
        desired = {"apiId": api_id, "typeName": type_name, "fieldName": field, "kind": "UNIT",
                   "dataSourceName": APPSYNC_DATA_SOURCE, "requestMappingTemplate": read(request),
                   "responseMappingTemplate": read(response)}
        current = aws_or_none("appsync", "get-resolver", "--api-id", api_id, "--type-name", type_name,
                              "--field-name", field)
        if current is None:
            require_appsync_tag(api_arn)
            aws("appsync", "create-resolver", stdin=desired)
        else:
            resolver = current["resolver"]
            if any(resolver.get(k) != desired[k] for k in
                   ("dataSourceName", "requestMappingTemplate", "responseMappingTemplate")):
                require_appsync_tag(api_arn)
                aws("appsync", "update-resolver", stdin=desired)


def rotate_api_key(api_id, api_arn):
    """The read-only API key: a secret, kept only in users.json. It lives 7 days; a new one is made
    when the recorded one has under 4 days left (so a bundle built from it keeps working for at least
    3 more days), and keys that have already expired are deleted."""
    keys = {k["id"]: k for k in aws("appsync", "list-api-keys", "--api-id", api_id)["apiKeys"]}
    recorded = users().get("codeSinkApiKey")
    now = time.time()
    longest = now + (API_KEY_LIFETIME_DAYS + 1) * 86400
    current = keys.get(recorded) if recorded else None
    if current is None or current["expires"] < now + API_KEY_RENEW_DAYS * 86400 or current["expires"] > longest:
        require_appsync_tag(api_arn)
        expires = int(now + API_KEY_LIFETIME_DAYS * 86400)
        recorded = aws("appsync", "create-api-key", "--api-id", api_id, "--description", f"{NAME} tests",
                       "--expires", str(expires))["apiKey"]["id"]
        set_user_secret("codeSinkApiKey", recorded)
        say("Created a code sink API key (in users.json); rebuild the tests to pick it up")
    # Expired keys go, and so does any key that outlives the 7-day policy (one made before it).
    for key_id, key in keys.items():
        if key_id != recorded and (key["expires"] < now or key["expires"] > longest):
            require_appsync_tag(api_arn)
            aws("appsync", "delete-api-key", "--api-id", api_id, "--id", key_id)
            say("Deleted an expired or over-long code sink API key")


def run_with_iam_retry(call, attempts=15):
    """A role created seconds ago may not be assumable yet: retry while the service says so."""
    for attempt in range(attempts):
        try:
            return call()
        except AwsError as error:
            retryable = error.code in ("InvalidParameterValueException", "AccessDeniedException",
                                       "BadRequestException") and (
                "assume" in error.message.lower() or "role" in error.message.lower())
            if not retryable or attempt == attempts - 1:
                raise
            time.sleep(4)


# --- P-5b, P-5c: Lambdas ----------------------------------------------------------------------------

def deterministic_zip(root, files):
    """A zip whose bytes depend only on the files' paths and contents, so its SHA-256 matches the
    function's CodeSha256 exactly when the code is unchanged."""
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as archive:
        for relative in sorted(files):
            info = zipfile.ZipInfo(relative, date_time=(1980, 1, 1, 0, 0, 0))
            info.external_attr = 0o644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            with open(os.path.join(root, relative), "rb") as f:
                archive.writestr(info, f.read())
    return buffer.getvalue()


def build_triggers():
    root = os.path.join(INFRA, "lambda", "triggers")
    return deterministic_zip(root, ["triggers.mjs"])


def build_custom_sender():
    source = os.path.join(INFRA, "lambda", "custom-sender")
    inputs = hashlib.sha256()
    for name in ("index.mjs", "package.json", "package-lock.json"):
        with open(os.path.join(source, name), "rb") as f:
            inputs.update(name.encode() + b"\0" + f.read())
    root = os.path.join(BUILD_DIR, "custom-sender-" + inputs.hexdigest()[:16])
    if not os.path.isdir(os.path.join(root, "node_modules")):
        shutil.rmtree(root, ignore_errors=True)
        os.makedirs(root)
        for name in ("index.mjs", "package.json", "package-lock.json"):
            shutil.copy(os.path.join(source, name), root)
        result = subprocess.run(["npm", "ci", "--omit=dev", "--ignore-scripts", "--no-audit", "--no-fund"],
                                cwd=root, capture_output=True, text=True)
        if result.returncode != 0:
            shutil.rmtree(root, ignore_errors=True)
            sys.exit("npm ci for the custom sender failed: " + redact(result.stderr.strip()[-400:]))
        say("Built the custom sender (npm ci)")
    files = []
    for directory, _, names in os.walk(root):
        for name in names:
            path = os.path.join(directory, name)
            if not os.path.islink(path) and name != ".package-lock.json":
                files.append(os.path.relpath(path, root))
    return deterministic_zip(root, files)


def ensure_function(suffix, code, role, environment):
    handler, _, _, _ = FUNCTIONS[suffix]
    name = function_name(suffix)
    code_sha = base64.b64encode(hashlib.sha256(code).digest()).decode()
    desired = {"FunctionName": name, "Role": role, "Handler": handler, "Runtime": LAMBDA_RUNTIME,
               "Timeout": 10, "MemorySize": 256 if suffix == "custom-sender" else 128,
               "Environment": {"Variables": environment}}
    zip_fd, zip_path = tempfile.mkstemp(dir=STATE_DIR, prefix=".lambda.", suffix=".zip")
    try:
        with os.fdopen(zip_fd, "wb") as f:
            f.write(code)
        current = aws_or_none("lambda", "get-function-configuration", "--function-name", name)
        if current is None:
            create = dict(desired, Architectures=["arm64"], Tags={TAG_KEY: TAG_VALUE},
                          Description=f"{NAME}: {suffix}")
            run_with_iam_retry(lambda: aws("lambda", "create-function", "--zip-file", f"fileb://{zip_path}",
                                           stdin=create))
            aws("lambda", "wait", "function-active-v2", "--function-name", name)
            say(f"Created Lambda {name}")
            return
        require_lambda_tag(current["FunctionArn"], name)
        if current.get("CodeSha256") != code_sha:
            require_lambda_tag(current["FunctionArn"], name)
            aws("lambda", "update-function-code", "--function-name", name, "--zip-file", f"fileb://{zip_path}",
                "--architectures", "arm64")
            aws("lambda", "wait", "function-updated-v2", "--function-name", name)
            say(f"Updated the code of Lambda {name}")
        current_env = (current.get("Environment") or {}).get("Variables") or {}
        drift = any(current.get(k) != desired[k] for k in ("Role", "Handler", "Runtime", "Timeout", "MemorySize"))
        if drift or current_env != environment:
            require_lambda_tag(current["FunctionArn"], name)
            run_with_iam_retry(lambda: aws("lambda", "update-function-configuration", stdin=desired))
            aws("lambda", "wait", "function-updated-v2", "--function-name", name)
            say(f"Updated the configuration of Lambda {name}")
    finally:
        os.unlink(zip_path)


def ensure_invoke_permission(suffix, pool_key, pool_id):
    """Lets Cognito invoke function `suffix` for pool `pool_key` only (statement cognito-<key>)."""
    name = function_name(suffix)
    sid = f"cognito-{pool_key}"
    source_arn = user_pool_arn(pool_id)
    policy = aws_or_none("lambda", "get-policy", "--function-name", name)
    statements = json.loads(policy["Policy"])["Statement"] if policy else []
    statement = next((s for s in statements if s.get("Sid") == sid), None)
    if statement is not None:
        condition = statement.get("Condition", {}).get("ArnLike", {}).get("AWS:SourceArn")
        if condition == source_arn:
            return
        require_lambda_tag(function_arn(suffix), name)
        aws("lambda", "remove-permission", "--function-name", name, "--statement-id", sid)
    require_lambda_tag(function_arn(suffix), name)
    aws("lambda", "add-permission", "--function-name", name, "--statement-id", sid,
        "--action", "lambda:InvokeFunction", "--principal", "cognito-idp.amazonaws.com",
        "--source-arn", source_arn, "--source-account", ACCOUNT)


# --- P-8: SES identity ------------------------------------------------------------------------------

# SES regions a user pool in us-west-2 may send DEVELOPER email through.
SES_REGIONS = ("us-west-2", "us-east-1", "eu-west-1")


def ensure_ses(parity):
    """Returns (identity ARN, From address) for the pools' DEVELOPER email, or (None, None).

    Email MFA and EMAIL_OTP need EmailConfiguration DEVELOPER with a *verified* SES identity: Cognito
    refuses email MFA with COGNITO_DEFAULT, and refuses an unverified identity (both checked on this
    sandbox). The plugin's backends use a verified `fromEmail`. An address identity needs a human to
    click the link SES mails to it, so by default this uses a domain identity the account has already
    verified (account_domain_identity); COGNITO_CLIENT_INTEG_SES_EMAIL selects the address path instead."""
    address = os.environ.get("COGNITO_CLIENT_INTEG_SES_EMAIL") or parity.get("sesEmail")
    if not address:
        return account_domain_identity(parity)
    parity["sesEmail"] = address
    identity_arn = f"arn:aws:ses:{REGION}:{ACCOUNT}:identity/{address}"
    identity = aws_or_none("sesv2", "get-email-identity", "--email-identity", address)
    if identity is None:
        aws("sesv2", "create-email-identity", "--email-identity", address,
            "--tags", f"Key={TAG_KEY},Value={TAG_VALUE}")
        say("Created the SES email identity; SES has mailed a verification link to the address (manual step)")
        identity = aws("sesv2", "get-email-identity", "--email-identity", address)
    require_ses_identity_tag(identity_arn)
    parity["sesIdentityArn"] = identity_arn
    if not identity.get("VerifiedForSendingStatus"):
        say("SES identity: created, not yet verified (click the link SES mailed, then re-run provision.sh); "
            "email MFA and EMAIL_OTP stay pending")
        return None, None
    # Cognito sends as this identity in DEVELOPER mode. The custom email sender replaces every
    # delivery, and in the SES sandbox the identity can only reach verified addresses anyway.
    policy = {"Version": "2012-10-17", "Statement": [{
        "Sid": "CognitoSendsAsThisIdentity", "Effect": "Allow", "Principal": {"Service": "cognito-idp.amazonaws.com"},
        "Action": ["ses:SendEmail", "ses:SendRawEmail"], "Resource": identity_arn,
        "Condition": {"StringEquals": {"aws:SourceAccount": ACCOUNT}}}]}
    current = (identity.get("Policies") or {}).get("cognito")
    if current is None or normalized(json.loads(current)) != normalized(policy):
        require_ses_identity_tag(identity_arn)
        if current is None:
            aws("sesv2", "create-email-identity-policy", "--email-identity", address, "--policy-name", "cognito",
                "--policy", json.dumps(policy))
        else:
            aws("sesv2", "update-email-identity-policy", "--email-identity", address, "--policy-name", "cognito",
                "--policy", json.dumps(policy))
    say("SES identity: verified")
    return identity_arn, address


def account_domain_identity(parity):
    """A domain identity the account already verified, used read-only: nothing here tags, changes or
    deletes it (it is not this sandbox's, and teardown leaves it alone). Cognito sends through its email
    service-linked role, so no identity policy is needed; the custom email sender replaces every
    delivery, so nothing is sent. Only an identity in an SES region still in the SES sandbox (no
    production access) qualifies, so even a pool without its custom sender could reach only verified
    recipients. COGNITO_CLIENT_INTEG_SES_DOMAIN picks one domain; otherwise the recorded one, else the
    first in name order. The domain is never printed."""
    wanted = os.environ.get("COGNITO_CLIENT_INTEG_SES_DOMAIN") or parity.get("sesDomain")
    for region in SES_REGIONS:
        domains = sorted(i["IdentityName"] for i in aws("sesv2", "list-email-identities", region=region)["EmailIdentities"]
                         if i["IdentityType"] == "DOMAIN" and i.get("VerificationStatus") == "SUCCESS")
        domains = [d for d in domains if d == wanted] if wanted else domains
        if not domains:
            continue
        if aws("sesv2", "get-account", region=region).get("ProductionAccessEnabled"):
            say(f"SES identity: skipped {region}, whose SES account has production access")
            continue
        for domain in domains:
            if aws("sesv2", "get-email-identity", "--email-identity", domain, region=region).get("VerifiedForSendingStatus"):
                _LITERALS.add(domain)
                parity.update(sesDomain=domain, sesIdentityArn=f"arn:aws:ses:{region}:{ACCOUNT}:identity/{domain}",
                              sesRegion=region)
                say(f"SES identity: a verified domain identity the account owns, in {region} (used read-only)")
                return parity["sesIdentityArn"], f"{NAME}@{domain}"
    say("SES identity: no verified domain identity in an SES-sandbox region; email MFA and EMAIL_OTP stay "
        "pending. Set COGNITO_CLIENT_INTEG_SES_EMAIL to an address you can read to use one instead (SES "
        "mails it a verification link to click).")
    return None, None


# --- P-9: the SNS caller role for SMS ----------------------------------------------------------------

SMS_ROLE = "cognito-sms"


def sms_role_documents(parity, pool_ids):
    """The plugin's Gen2 backends' SMS role: Cognito may assume it (with the external id, for this
    account's parity pools only) and it may publish SMS (`sns:Publish` on `*`: direct-to-phone publishing
    has no resource ARN, and Cognito refuses anything narrower, checked on this sandbox). It never sends:
    every SMS-enabled pool has the custom SMS sender, which receives each code instead (require_custom_sms_sender).
    `aws:RequestedRegion` is limited to the sandbox region unless Cognito refused that condition."""
    if pool_ids:
        source = {"ArnEquals": {"aws:SourceArn": sorted(user_pool_arn(i) for i in pool_ids)}}
    else:
        source = {"ArnLike": {"aws:SourceArn": f"arn:aws:cognito-idp:{REGION}:{ACCOUNT}:userpool/*"}}
    trust = {"Version": "2012-10-17", "Statement": [{
        "Effect": "Allow", "Principal": {"Service": "cognito-idp.amazonaws.com"}, "Action": "sts:AssumeRole",
        "Condition": dict({"StringEquals": {"sts:ExternalId": parity["smsExternalId"], "aws:SourceAccount": ACCOUNT}},
                          **source)}]}
    statement = {"Sid": "CognitoSendsSms", "Effect": "Allow", "Action": "sns:Publish", "Resource": "*"}
    if parity.get("smsRegionCondition") is not False:
        statement["Condition"] = {"StringEquals": {"aws:RequestedRegion": REGION}}
    return trust, {"Version": "2012-10-17", "Statement": [statement]}


def require_sms_sandbox():
    """Read-only. The account's SNS must still be in the SMS sandbox (only verified numbers can
    receive), the backstop behind the custom SMS sender."""
    if not aws("sns", "get-sms-sandbox-account-status").get("IsInSandbox"):
        fail("the account's SNS is out of the SMS sandbox; SMS is not enabled on the parity pools.")


def ensure_sms_role(parity, pool_ids):
    if not parity.get("smsExternalId"):
        parity["smsExternalId"] = secrets.token_hex(16)
    trust, policy = sms_role_documents(parity, pool_ids)
    return ensure_role_with_policy(SMS_ROLE, trust, policy)


def with_sms_role(label, call, parity, pool_ids):
    """Runs a Cognito call that validates the SMS role, waiting out IAM propagation. Only while the region
    condition is untested (smsRegionCondition is None) does a persistent policy refusal drop it (the
    plugin's backends have none) and retry. Once Cognito has accepted the condition (True), a refusal is
    a failure: propagation delay must never widen sns:Publish to every region."""
    refusals = 0
    for _ in range(30):
        try:
            result = call()
            if parity.get("smsRegionCondition") is None and parity.get("smsRoleUsed"):
                parity["smsRegionCondition"] = True
            return result
        except AwsError as error:
            if error.code == "InvalidSmsRoleTrustRelationshipException":
                time.sleep(10)
                continue
            if error.code == "InvalidSmsRoleAccessPolicyException":
                refusals += 1
                if refusals <= 9:
                    time.sleep(10)
                    continue
                if parity.get("smsRegionCondition") is None:
                    say("Cognito refused the SMS role's aws:RequestedRegion condition; using the plugin's "
                        "unconditioned policy")
                    parity["smsRegionCondition"] = False
                    ensure_sms_role(parity, pool_ids)
                    refusals = 0
                    continue
            sys.exit(f"{label} failed ({error.code}): {error.message}")
    sys.exit(f"{label}: Cognito never accepted the SMS role")


def uses_sms(template):
    factors = template["userPool"].get("Policies", {}).get("SignInPolicy", {}).get("AllowedFirstAuthFactors") or []
    return ("SmsConfiguration" in template["userPool"] or "SmsMfaConfiguration" in template["mfa"]
            or "SMS_OTP" in factors)


def require_custom_sms_sender(key, template):
    """Refuses to enable SMS on a pool whose template does not route every SMS through the custom
    sender: with the SNS role in place, such a pool would send real text messages."""
    lambdas = template["userPool"].get("LambdaConfig", {})
    sender = (lambdas.get("CustomSMSSender") or {}).get("LambdaArn")
    if uses_sms(template) and (sender != function_arn("custom-sender") or not lambdas.get("KMSKeyID")):
        fail(f"pool {key} enables SMS without the custom SMS sender; it would send real messages.")


def require_custom_email_sender(key, template):
    """Refuses DEVELOPER email on a pool whose template does not route every email through the custom
    sender: such a pool would send real mail through the SES identity (in the SES sandbox, still to any
    verified recipient, including every address at the domain)."""
    lambdas = template["userPool"].get("LambdaConfig", {})
    sender = (lambdas.get("CustomEmailSender") or {}).get("LambdaArn")
    developer = template["userPool"].get("EmailConfiguration", {}).get("EmailSendingAccount") == "DEVELOPER"
    if developer and (sender != function_arn("custom-sender") or not lambdas.get("KMSKeyID")):
        fail(f"pool {key} uses DEVELOPER email without the custom email sender; it would send real mail.")


def live_sender_gaps(state):
    """Read-only. For every live parity pool, the ways it could deliver a real message: DEVELOPER email
    or an SMS configuration without our custom sender for that channel and the KMS key."""
    gaps = []
    ours = function_arn("custom-sender")
    for key, pool_id in pool_ids(state).items():
        described = aws_or_none("cognito-idp", "describe-user-pool", "--user-pool-id", pool_id)
        if described is None:
            continue
        pool = described["UserPool"]
        lambdas = pool.get("LambdaConfig") or {}
        has_key = bool(lambdas.get("KMSKeyID"))
        if pool.get("EmailConfiguration", {}).get("EmailSendingAccount") == "DEVELOPER":
            if (lambdas.get("CustomEmailSender") or {}).get("LambdaArn") != ours or not has_key:
                gaps.append(f"{key}: DEVELOPER email without the custom email sender")
        if pool.get("SmsConfiguration"):
            if (lambdas.get("CustomSMSSender") or {}).get("LambdaArn") != ours or not has_key:
                gaps.append(f"{key}: SMS configured without the custom SMS sender")
    return gaps


def ses_gaps(parity):
    """Read-only. The borrowed SES domain must still be verified, and its region's SES account must
    still be in the SES sandbox (no production access), as when it was chosen."""
    gaps = []
    domain, region = parity.get("sesDomain"), parity.get("sesRegion")
    if parity.get("sesEmail") or not domain or not region:
        return gaps
    if aws("sesv2", "get-account", region=region).get("ProductionAccessEnabled"):
        gaps.append(f"the SES account in {region} now has production access")
    identity = aws_or_none("sesv2", "get-email-identity", "--email-identity", domain, region=region)
    if not identity or not identity.get("VerifiedForSendingStatus"):
        gaps.append("the borrowed SES domain identity is no longer verified")
    return gaps


def wildcard_gaps():
    """Read-only. The pool-scoped policies a first provisioning run widens to "any pool in the account"
    and narrows once every pool exists: a run that stopped in between leaves them wide."""
    gaps = []
    key = aws("kms", "describe-key", "--key-id", KMS_ALIAS)["KeyMetadata"]
    key_policy = json.loads(aws("kms", "get-key-policy", "--key-id", key["KeyId"], "--policy-name", "default")["Policy"])
    encrypt = next((st for st in key_policy["Statement"] if st.get("Sid") == "CognitoEncryptsCodes"), {})
    if not (encrypt.get("Condition", {}).get("ArnEquals") or {}).get("aws:SourceArn"):
        gaps.append("the KMS key policy still lets Cognito encrypt for any pool")
    sender = aws("iam", "get-role-policy", "--role-name", role_name("sender-exec"),
                 "--policy-name", f"{role_name('sender-exec')}-policy", region=False)["PolicyDocument"]
    decrypt = next((st for st in sender["Statement"] if st.get("Sid") == "DecryptCodes"), {})
    if "StringLike" in (decrypt.get("Condition") or {}):
        gaps.append("the sender role still decrypts codes for any pool")
    role = (aws_or_none("iam", "get-role", "--role-name", role_name(SMS_ROLE), region=False) or {}).get("Role")
    if role is not None:
        trust = role["AssumeRolePolicyDocument"]["Statement"][0]["Condition"]
        if not trust.get("ArnEquals", {}).get("aws:SourceArn"):
            gaps.append("the SMS role still trusts any pool in the account")
    return gaps


# Self sign-up (AdminCreateUserConfig.AllowAdminCreateUserOnly = false) is what the templates ask for, and
# what the sign-up tests need. The account's security tooling may flag such a pool, and an automated
# mitigation may then turn self sign-up off with its own UpdateUserPool call. provision re-enables it only
# when this is set, so a re-run never silently undoes a mitigation: a person decides first (an exception
# for the finding, or a recorded choice to re-enable without one).
REENABLE_SELF_SIGN_UP = "COGNITO_CLIENT_INTEG_REENABLE_SELF_SIGN_UP"
SELF_SIGN_UP_OFF = "self sign-up is off, but pools/{key}.json allows it (an automated mitigation, or a change by hand)"


def admin_only(config):
    """AllowAdminCreateUserOnly of an AdminCreateUserConfig: True, False, or None when it is not stated
    (callers treat None as "not known to allow self sign-up", never as allowed)."""
    value = (config or {}).get("AllowAdminCreateUserOnly")
    return value if isinstance(value, bool) else None


def template_self_sign_up(template):
    value = admin_only(template["userPool"].get("AdminCreateUserConfig"))
    if value is None:
        sys.exit("Refusing: a pool template does not state AdminCreateUserConfig.AllowAdminCreateUserOnly.")
    return not value


def self_sign_up_gaps(expected, recorded, described):
    """Pure. `expected` maps every pool key to whether its template allows self sign-up, `recorded` is the set
    of keys state.json has a pool for, and `described` maps a recorded key to its DescribeUserPool `UserPool`
    (None when the pool is gone). Returns (kind, message) pairs, kind "MISSING" or "DRIFT"."""
    gaps = []
    for key in sorted(expected):
        if key not in recorded:
            gaps.append(("MISSING", f"{key}: no pool recorded in state.json; run infra/provision.sh"))
            continue
        pool = described.get(key)
        if pool is None:
            gaps.append(("MISSING", f"{key}: the recorded pool no longer exists; run infra/provision.sh"))
            continue
        live = admin_only(pool.get("AdminCreateUserConfig"))
        if live is None:
            gaps.append(("DRIFT", f"{key}: the pool does not state whether self sign-up is allowed"))
        elif (not live) != expected[key]:
            gaps.append(("DRIFT", f"{key}: " + (SELF_SIGN_UP_OFF.format(key=key) if expected[key] else
                                               f"self sign-up is on, but pools/{key}.json does not allow it")))
    return gaps


def live_self_sign_up_gaps(state):
    """Read-only. self_sign_up_gaps for every POOLS key. An AWS error other than "not found" propagates."""
    ids = pool_ids(state)
    expected = {key: template_self_sign_up(load_template(key)) for key in POOLS}
    described = {}
    for key, pool_id in ids.items():
        pool = aws_or_none("cognito-idp", "describe-user-pool", "--user-pool-id", pool_id)
        described[key] = (pool or {}).get("UserPool")
    return self_sign_up_gaps(expected, set(ids), described)


def exit_on_gaps(command, unsafe, sign_up):
    """Prints every gap, then exits non-zero if there is any: `unsafe` (strings) first, then `sign_up`
    ((kind, message) pairs from self_sign_up_gaps). Shared by preflight and verify."""
    for gap in unsafe:
        say(f"UNSAFE {gap}")
    for kind, gap in sign_up:
        say(f"{kind} {gap}")
    if unsafe:
        if command == "preflight":
            sys.exit("Refusing: a parity pool could deliver real messages, the SES identity it uses changed, or "
                     "a pool-scoped policy is still open to any pool; re-run infra/provision.sh, which fixes or "
                     "re-checks all three.")
        sys.exit(f"{command}: {len(unsafe)} unsafe setting(s); re-run infra/provision.sh")
    if sign_up:
        sys.exit(f"{'Refusing' if command == 'preflight' else command}: {len(sign_up)} parity pool(s) missing, "
                 f"or whose self sign-up differs from its template, so the tests that sign up a user there "
                 f"would fail. For a DRIFT, check the account's security findings first: re-enabling undoes a "
                 f"security mitigation and needs the owner's decision (an exception, or a recorded choice to "
                 f"re-enable without one). Then run {REENABLE_SELF_SIGN_UP}=1 infra/provision.sh.")


def admin_create_user_config_to_send(desired, current, reenable):
    """Pure. The AdminCreateUserConfig an UpdateUserPool call sends: the template's, except that when the
    template allows self sign-up and the pool does not explicitly allow it (off, or not stated), it stays
    off unless `reenable`. The template's other AdminCreateUserConfig fields are kept either way.
    Returns (config, kept_off)."""
    wanted = desired.get("AdminCreateUserConfig")
    if wanted is None or admin_only(wanted) is not False or reenable:
        return wanted, False
    if admin_only(current.get("AdminCreateUserConfig")) is False:
        return wanted, False
    return dict(wanted, AllowAdminCreateUserOnly=True), True


def preflight():
    """Read-only checks run by prepare-run.sh before every test run: exits non-zero if any live pool
    could deliver a real message, or a parity pool is missing or its self sign-up differs from its template."""
    state = load_state()
    require_cli_history_off()
    require_recorded_account(state)
    gaps = live_sender_gaps(state) + ses_gaps(state.get("parity", {})) + wildcard_gaps()
    if not aws("sns", "get-sms-sandbox-account-status").get("IsInSandbox"):
        gaps.append("the account's SNS is out of the SMS sandbox")
    exit_on_gaps("preflight", gaps, live_self_sign_up_gaps(state))
    say("Preflight: every email- or SMS-enabled parity pool routes through the custom senders, the SES "
        "identity is still verified in an SES-sandbox region, the KMS encrypt, sender decrypt and SMS "
        "role trust are scoped to the parity pools, and each parity pool's self sign-up matched its "
        "template when read (a later mitigation can still change it)")


# --- P-10: the WebAuthn relying party ----------------------------------------------------------------

# The client's WebAuthn UI-test app (CognitoClientHostApp.xcodeproj, target CognitoClientWebAuthnApp). It
# signs as the plugin's AuthWebAuthnApp does, with the same team and bundle identifier, because the relying
# party's apple-app-site-association lists that app ID and no other the harness could use. Its entitlements name
# the plugin's relying party, committed, as AuthWebAuthnApp.entitlements does.
WEBAUTHN_ENTITLEMENTS = os.path.join(os.path.dirname(INFRA), "CognitoClientHostApp",
                                     "CognitoClientWebAuthnApp.entitlements")
WEBAUTHN_PROJECT = os.path.join(os.path.dirname(INFRA), "CognitoClientHostApp", "CognitoClientHostApp.xcodeproj",
                                "project.pbxproj")
PLUGIN_WEBAUTHN_ENTITLEMENTS = os.path.join(os.path.dirname(INFRA), *[os.pardir] * 4, "AmplifyPlugins", "Auth", "Tests",
                                            "AuthWebAuthnApp", "AuthWebAuthnApp", "AuthWebAuthnApp.entitlements")


def webcredentials_domains(path):
    import plistlib
    with open(path, "rb") as f:
        domains = plistlib.load(f).get("com.apple.developer.associated-domains", [])
    return [d.split(":", 1)[1].split("?", 1)[0] for d in domains if d.startswith("webcredentials:")]


def webauthn_harness_app_id():
    """`<team>.<bundle id>` the harness app signs as, from the DEVELOPMENT_TEAM and PRODUCT_BUNDLE_IDENTIFIER of
    the build configurations that sign with its entitlements; or None and the reason. Every such configuration
    must name both literally (not `$(inherited)` or another setting), without a per-SDK override
    (`"DEVELOPMENT_TEAM[sdk=…]"`), and they must all agree. The reasons name no value."""
    with open(WEBAUTHN_PROJECT) as f:
        project = f.read()
    ids = set()
    for block in re.findall(r"buildSettings = \{(.*?)\n\t\t\t\};", project, re.S):
        if "CODE_SIGN_ENTITLEMENTS = CognitoClientWebAuthnApp.entitlements;" not in block:
            continue
        if re.search(r"\b(DEVELOPMENT_TEAM|PRODUCT_BUNDLE_IDENTIFIER)\[", block):
            return None, "a CognitoClientWebAuthnApp build configuration overrides its team or bundle id per SDK"
        team = re.search(r"\bDEVELOPMENT_TEAM = ([A-Z0-9]+);", block)
        bundle = re.search(r"\bPRODUCT_BUNDLE_IDENTIFIER = ([A-Za-z0-9.-]+);", block)
        if not (team and bundle):
            return None, ("a CognitoClientWebAuthnApp build configuration does not name a literal DEVELOPMENT_TEAM "
                          "and PRODUCT_BUNDLE_IDENTIFIER")
        ids.add(f"{team.group(1)}.{bundle.group(1)}")
    if not ids:
        return None, "no build configuration signs with CognitoClientWebAuthnApp.entitlements"
    if len(ids) > 1:
        return None, "the CognitoClientWebAuthnApp build configurations disagree on the team or bundle id"
    return ids.pop(), None


def webauthn_harness_identity():
    """Offline: the relying party and the app ID the harness app is built with, or None, None and the reason."""
    web = webcredentials_domains(WEBAUTHN_ENTITLEMENTS)
    if len(web) != 1:
        return None, None, f"the harness entitlements name {len(web)} webcredentials domains, not 1"
    if web != webcredentials_domains(PLUGIN_WEBAUTHN_ENTITLEMENTS):
        return None, None, "the harness entitlements' webcredentials domain is not the plugin AuthWebAuthnApp's"
    app_id, gap = webauthn_harness_app_id()
    if gap:
        return None, None, gap
    return web[0], app_id, None


def webauthn_pool_is_live(parity):
    """Whether state.json records the WebAuthn pool with WEB_AUTHN on (created, and `web-authn` not pending)."""
    record = parity.get("pools", {}).get("webauthn") or {}
    return bool(record.get("userPoolId")) and "web-authn" not in record.get("pending", [])


def require_webauthn_harness_identity(parity):
    """Before any change: a live WebAuthn pool is never switched off because the harness's committed settings
    cannot be read. A pool not yet live stays pending instead."""
    _, _, gap = webauthn_harness_identity()
    if gap and webauthn_pool_is_live(parity):
        fail(f"the WebAuthn pool is live, and {gap}. Provisioning would switch WEB_AUTHN off for every run on this "
             "sandbox. Nothing was changed.")


def webauthn_relying_party_or_refuse(parity):
    """P-10: the relying party, or None with the reason if the pool is not live yet. A live pool is never degraded:
    a gap (the harness's settings, or the relying party's apple-app-site-association) stops the run instead."""
    rp_id, rp_gap = run_step("WebAuthn relying party", webauthn_relying_party)
    if rp_gap and webauthn_pool_is_live(parity):
        fail(f"the WebAuthn pool is live, and its relying party is not usable: {rp_gap}. Provisioning would switch "
             "WEB_AUTHN off for every run on this sandbox; the pools were not changed.")
    return rp_id, rp_gap


def webauthn_relying_party():
    """Returns the relying party ID for the pools' WebAuthnConfiguration, or None with the reason.

    The ID is the domain in the harness app's `webcredentials:` entitlement, so the pool and the app
    cannot disagree. The domain is the plugin's WebAuthn relying party, and it is not this sandbox's: it
    is used read-only. The only call made to it is an HTTPS GET of its apple-app-site-association, to
    check that it still lists the harness's app ID; nothing on it is ever changed. Cognito itself does
    not read the file, the simulator does; without it the passkey sheet never appears, so a pool
    advertising WEB_AUTHN would only produce failing tests."""
    import urllib.request
    domain, app_id, gap = webauthn_harness_identity()
    if gap:
        return None, gap
    _LITERALS.add(domain)
    try:
        request = urllib.request.Request(f"https://{domain}/.well-known/apple-app-site-association",
                                         headers={"Accept": "application/json"})
        with urllib.request.urlopen(request, timeout=15) as response:
            association = json.load(response)
    except Exception as error:  # noqa: BLE001 - any failure means "not usable", with the reason
        return None, f"the relying party's apple-app-site-association could not be read ({type(error).__name__})"
    apps = (association.get("webcredentials") or {}).get("apps") or []
    if app_id not in apps:
        return None, "the relying party's apple-app-site-association does not list the harness app ID"
    return domain, None


# --- P-6, P-7: user pools ---------------------------------------------------------------------------

UPDATE_KEYS = {"AccountRecoverySetting", "AdminCreateUserConfig", "AutoVerifiedAttributes", "DeletionProtection",
               "DeviceConfiguration", "EmailConfiguration", "EmailVerificationMessage", "EmailVerificationSubject",
               "LambdaConfig", "Policies", "SmsAuthenticationMessage", "SmsConfiguration", "SmsVerificationMessage",
               "UserAttributeUpdateSettings", "UserPoolAddOns", "UserPoolTier", "VerificationMessageTemplate"}
CREATE_ONLY_KEYS = {"UsernameAttributes", "UsernameConfiguration", "AliasAttributes", "Schema"}


def substitute(value, variables):
    if isinstance(value, dict):
        return {k: substitute(v, variables) for k, v in value.items()}
    if isinstance(value, list):
        return [substitute(v, variables) for v in value]
    if isinstance(value, str):
        return re.sub(r"\$\{([A-Z_]+)\}", lambda m: variables[m.group(1)], value)
    return value


def degrade(template, ses_ready, sms_ready, webauthn_ready=True):
    """Removes what a pending prerequisite does not allow yet, and says what was removed."""
    pending = []
    pool, mfa = template["userPool"], template["mfa"]
    factors = pool.get("Policies", {}).get("SignInPolicy", {}).get("AllowedFirstAuthFactors")
    if not webauthn_ready:
        if mfa.pop("WebAuthnConfiguration", None) is not None:
            pending.append("webauthn-relying-party")
        if factors and "WEB_AUTHN" in factors:
            factors.remove("WEB_AUTHN")
            pending.append("web-authn")
    if not ses_ready:
        if pool.pop("EmailConfiguration", None) is not None:
            pending.append("ses-email-configuration")
        if mfa.pop("EmailMfaConfiguration", None) is not None:
            pending.append("email-mfa")
        if factors and "EMAIL_OTP" in factors:
            factors.remove("EMAIL_OTP")
            pending.append("email-otp")
    if not sms_ready:
        pool.pop("SmsConfiguration", None)
        if mfa.pop("SmsMfaConfiguration", None) is not None:
            pending.append("sms-mfa")
        if factors and "SMS_OTP" in factors:
            factors.remove("SMS_OTP")
            pending.append("sms-otp")
    has_factor = (mfa.get("SoftwareTokenMfaConfiguration", {}).get("Enabled")
                  or "SmsMfaConfiguration" in mfa or "EmailMfaConfiguration" in mfa)
    if mfa["MfaConfiguration"] != "OFF" and not has_factor:
        pending.append(f"mfa-{mfa['MfaConfiguration'].lower()}")
        mfa["MfaConfiguration"] = "OFF"
    return pending


def empty(value):
    if isinstance(value, dict):
        return all(empty(v) for v in value.values())
    return value in ([], None, "")


def same(desired, current):
    """Whether every field of `desired` is in `current` with the same value (lists compared
    ignoring order). A field Cognito omits matches an empty desired value."""
    if current is None:
        return empty(desired)
    if isinstance(desired, dict):
        return isinstance(current, dict) and all(same(v, current.get(k)) for k, v in desired.items())
    if isinstance(desired, list):
        if not isinstance(current, list):
            return False
        return sorted(normalized(v) for v in desired) == sorted(normalized(v) for v in current)
    return desired == current


def find_user_pool(recorded_id, pool_name):
    if recorded_id and aws_or_none("cognito-idp", "describe-user-pool", "--user-pool-id", recorded_id):
        return recorded_id
    pools = aws("cognito-idp", "list-user-pools", "--max-results", "60")["UserPools"]
    matches = [p["Id"] for p in pools if p["Name"] == pool_name]
    if len(matches) > 1:
        fail(f"{len(matches)} user pools are named {pool_name}; remove the extras by hand.")
    return matches[0] if matches else None


def ensure_user_pool(key, template, recorded):
    pool_name = POOLS[key]
    desired = template["userPool"]
    pool_id = find_user_pool(recorded.get("userPoolId"), pool_name)
    if pool_id is None:
        create = dict(desired, PoolName=pool_name, UserPoolTags={TAG_KEY: TAG_VALUE})
        pool_id = aws("cognito-idp", "create-user-pool", stdin=create)["UserPool"]["Id"]
        say(f"Created user pool {pool_name}")
        return pool_id
    current = require_user_pool_tag(pool_id, pool_name)
    for field in CREATE_ONLY_KEYS & set(desired):
        if not same(desired[field], current.get(field)):
            fail(f"user pool {pool_name} differs in {field}, which only creation sets. Delete the pool "
                 f"(teardown.sh) and re-run.")
    updatable = {k: v for k, v in desired.items() if k in UPDATE_KEYS}
    reenable = os.environ.get(REENABLE_SELF_SIGN_UP) == "1"
    config, kept_off = admin_create_user_config_to_send(updatable, current, reenable)
    if kept_off:
        updatable["AdminCreateUserConfig"] = config
        say(f"Keeping self sign-up off on {pool_name}: it is not on, though the template allows it (check the "
            f"account's security findings). Once the owner has decided, set {REENABLE_SELF_SIGN_UP}=1 to "
            f"re-enable it; preflight refuses until then.")
    drift = sorted(k for k, v in updatable.items() if not same(v, current.get(k)))
    # A field the template leaves out must be absent too (EmailConfiguration after a degrade, say).
    if "EmailConfiguration" not in desired and current.get("EmailConfiguration", {}).get("EmailSendingAccount") == "DEVELOPER":
        drift.append("EmailConfiguration")
    if drift:
        # UpdateUserPool resets every field it is not given: always the whole template.
        require_user_pool_tag(pool_id, pool_name)
        aws("cognito-idp", "update-user-pool",
            stdin=dict(updatable, UserPoolId=pool_id, PoolName=pool_name, UserPoolTags={TAG_KEY: TAG_VALUE}))
        say(f"Updated user pool {pool_name} ({', '.join(drift)})")
    else:
        say(f"Reusing user pool {pool_name}")
    return pool_id


def set_mfa(pool_id, pool_name, mfa):
    require_user_pool_tag(pool_id, pool_name)
    aws("cognito-idp", "set-user-pool-mfa-config", stdin=dict(mfa, UserPoolId=pool_id))


def ensure_client(pool_id, pool_name, client_key, desired):
    client_name = f"{pool_name}-{client_key}"
    clients = aws("cognito-idp", "list-user-pool-clients", "--user-pool-id", pool_id,
                  "--max-results", "60")["UserPoolClients"]
    client_id = next((c["ClientId"] for c in clients if c["ClientName"] == client_name), None)
    full = dict(desired, ClientName=client_name, UserPoolId=pool_id)
    if client_id is None:
        require_user_pool_tag(pool_id, pool_name)
        client_id = aws("cognito-idp", "create-user-pool-client",
                        stdin=dict(full, GenerateSecret=False))["UserPoolClient"]["ClientId"]
        say(f"Created app client {client_name}")
        return client_id
    current = aws("cognito-idp", "describe-user-pool-client", "--user-pool-id", pool_id,
                  "--client-id", client_id)["UserPoolClient"]
    if current.get("ClientSecret"):
        fail(f"app client {client_name} has a secret; the tests need a public client.")
    if not same(desired, current):
        require_user_pool_tag(pool_id, pool_name)
        aws("cognito-idp", "update-user-pool-client", stdin=dict(full, ClientId=client_id))
        say(f"Updated app client {client_name}")
    return client_id


def ensure_domain(pool_id, pool_name, parity, managed_login_version):
    # Domain prefixes are global and may not contain "aws", "amazon" or "cognito": a random suffix,
    # generated once and recorded, instead of anything account-derived.
    prefix = parity.get("domainPrefix") or f"amplify-client-integ-{secrets.token_hex(4)}"
    parity["domainPrefix"] = prefix
    domain = aws("cognito-idp", "describe-user-pool-domain", "--domain", prefix)["DomainDescription"]
    if not domain.get("UserPoolId"):
        require_user_pool_tag(pool_id, pool_name)
        aws("cognito-idp", "create-user-pool-domain", "--domain", prefix, "--user-pool-id", pool_id,
            "--managed-login-version", str(managed_login_version))
        say(f"Created the hosted-UI domain on {pool_name}")
    elif domain["UserPoolId"] != pool_id:
        fail(f"the recorded hosted-UI domain prefix belongs to another user pool.")
    return f"{prefix}.auth.{REGION}.amazoncognito.com"


def outputs_document(pool_id, client_id, template, oauth_domain=None, client=None):
    mfa = template["mfa"]
    methods = [m for m, k in (("SMS", "SmsMfaConfiguration"), ("TOTP", "SoftwareTokenMfaConfiguration"),
                              ("EMAIL", "EmailMfaConfiguration")) if k in mfa
               and (k != "SoftwareTokenMfaConfiguration" or mfa[k].get("Enabled"))]
    policy = template["userPool"]["Policies"]["PasswordPolicy"]
    auth = {
        "aws_region": REGION,
        "user_pool_id": pool_id,
        "user_pool_client_id": client_id,
        "username_attributes": template["userPool"].get("UsernameAttributes", []),
        "user_verification_types": template["userPool"].get("AutoVerifiedAttributes", []),
        "mfa_configuration": {"OFF": "NONE", "OPTIONAL": "OPTIONAL", "ON": "REQUIRED"}[mfa["MfaConfiguration"]],
        "mfa_methods": methods,
        "password_policy": {
            "min_length": policy["MinimumLength"], "require_lowercase": policy["RequireLowercase"],
            "require_uppercase": policy["RequireUppercase"], "require_numbers": policy["RequireNumbers"],
            "require_symbols": policy["RequireSymbols"]},
        "unauthenticated_identities_enabled": False,
    }
    if oauth_domain:
        auth["oauth"] = {"identity_providers": [], "domain": oauth_domain, "scopes": client["AllowedOAuthScopes"],
                         "redirect_sign_in_uri": client["CallbackURLs"],
                         "redirect_sign_out_uri": client["LogoutURLs"], "response_type": "code"}
    return {"version": "1.4", "auth": auth}


def outputs_path(name):
    """`<name>-amplify_outputs.json`, the plugin's naming (…/testconfiguration/XYZ-amplify_outputs.json).
    The client's AuthClientConfiguration(from:) rejects a resource name with a dot in it."""
    return os.path.join(STATE_DIR, f"{name}-amplify_outputs.json")


def write_outputs(name, document):
    save_json(outputs_path(name), document, mode=0o600)


# --- P-6': identity-only pool -----------------------------------------------------------------------

def ensure_identity_only_pool(parity):
    pool_id = parity.get("identityOnlyPoolId")
    if pool_id and aws_or_none("cognito-identity", "describe-identity-pool", "--identity-pool-id", pool_id) is None:
        pool_id = None
    if not pool_id:
        pools = aws("cognito-identity", "list-identity-pools", "--max-results", "60")["IdentityPools"]
        pool_id = next((p["IdentityPoolId"] for p in pools if p["IdentityPoolName"] == IDENTITY_ONLY_POOL), None)
    if not pool_id:
        pool_id = aws("cognito-identity", "create-identity-pool", "--identity-pool-name", IDENTITY_ONLY_POOL,
                      "--allow-unauthenticated-identities",
                      "--identity-pool-tags", f"{TAG_KEY}={TAG_VALUE}")["IdentityPoolId"]
        say(f"Created identity pool {IDENTITY_ONLY_POOL}")
    else:
        require_identity_pool_tag(pool_id, IDENTITY_ONLY_POOL)
        current = aws("cognito-identity", "describe-identity-pool", "--identity-pool-id", pool_id)
        if not current.get("AllowUnauthenticatedIdentities") or current.get("CognitoIdentityProviders"):
            require_identity_pool_tag(pool_id, IDENTITY_ONLY_POOL)
            aws("cognito-identity", "update-identity-pool", "--identity-pool-id", pool_id,
                "--identity-pool-name", IDENTITY_ONLY_POOL, "--allow-unauthenticated-identities",
                "--identity-pool-tags", f"{TAG_KEY}={TAG_VALUE}")
            say(f"Updated identity pool {IDENTITY_ONLY_POOL}")
        else:
            say(f"Reusing identity pool {IDENTITY_ONLY_POOL}")
    parity["identityOnlyPoolId"] = pool_id
    auth_role = ensure_permissionless_role("identity-only-authenticated", identity_trust(pool_id, "authenticated"))
    unauth_role = ensure_permissionless_role("identity-only-unauthenticated", identity_trust(pool_id, "unauthenticated"))
    require_identity_pool_tag(pool_id, IDENTITY_ONLY_POOL)
    run_with_iam_retry(lambda: aws("cognito-identity", "set-identity-pool-roles", "--identity-pool-id", pool_id,
                                   "--roles", f"authenticated={auth_role},unauthenticated={unauth_role}"))
    write_outputs("identity-only", {"version": "1.4", "auth": {
        "aws_region": REGION, "identity_pool_id": pool_id, "unauthenticated_identities_enabled": True}})


# --- P-13: the plugin suites' identity pool --------------------------------------------------------

def plugin_pool_ids(parity, keys):
    pools = parity.get("pools", {})
    return ",".join(sorted(pools[k]["userPoolId"] for k in keys
                           if pools.get(k, {}).get("userPoolId")))


def ci_shape_client_ids(parity, keys):
    """The `ci` app clients of the pools `keys` that have one yet, comma-separated (CI_SHAPE_CLIENT_POOLS)."""
    pools = parity.get("pools", {})
    return ",".join(sorted(pools[k]["clients"]["ci"] for k in keys
                           if pools.get(k, {}).get("clients", {}).get("ci")))


def plugin_identity_providers(parity):
    providers = []
    for pool_key, client_key in PLUGIN_IDENTITY_CLIENTS:
        record = parity["pools"][pool_key]
        providers.append({"ProviderName": f"cognito-idp.{REGION}.amazonaws.com/{record['userPoolId']}",
                          "ClientId": record["clients"][client_key], "ServerSideTokenCheck": False})
    return providers


def name_plugin_identity_pool_in_outputs(parity):
    """Adds P-13, with guest access, to the outputs of the pools it federates besides the default one
    (PLUGIN_IDENTITY_OUTPUTS). The pool loop rewrites those files without it, so this runs after it."""
    for name in PLUGIN_IDENTITY_OUTPUTS:
        with open(outputs_path(name)) as f:
            document = json.load(f)
        document["auth"]["identity_pool_id"] = parity["pluginIdentityPoolId"]
        document["auth"]["unauthenticated_identities_enabled"] = True
        write_outputs(name, document)
    say(f"Named the plugin identity pool in {', '.join(PLUGIN_IDENTITY_OUTPUTS)}-amplify_outputs.json")


def ensure_plugin_identity_pool(parity):
    """The plugin's default backend federates its user pool into an identity pool with guest access
    (AuthIntegrationTests/README.md, AuthStressTests/README.md). Tagged, guest on, the default pool's
    `plugin` and `hostedui-plugin` clients and the passwordless pool's `client` and `ci` as providers, and roles
    that grant nothing."""
    desired = plugin_identity_providers(parity)
    pool_id = parity.get("pluginIdentityPoolId")
    if pool_id and aws_or_none("cognito-identity", "describe-identity-pool", "--identity-pool-id", pool_id) is None:
        pool_id = None
    if not pool_id:
        pools = aws("cognito-identity", "list-identity-pools", "--max-results", "60")["IdentityPools"]
        pool_id = next((p["IdentityPoolId"] for p in pools if p["IdentityPoolName"] == PLUGIN_IDENTITY_POOL), None)
    update = {"IdentityPoolName": PLUGIN_IDENTITY_POOL, "AllowUnauthenticatedIdentities": True,
              "CognitoIdentityProviders": desired, "IdentityPoolTags": {TAG_KEY: TAG_VALUE}}
    if not pool_id:
        pool_id = aws("cognito-identity", "create-identity-pool", stdin=update)["IdentityPoolId"]
        say(f"Created identity pool {PLUGIN_IDENTITY_POOL}")
    else:
        require_identity_pool_tag(pool_id, PLUGIN_IDENTITY_POOL)
        current = aws("cognito-identity", "describe-identity-pool", "--identity-pool-id", pool_id)
        key = lambda p: (p["ProviderName"], p["ClientId"], bool(p.get("ServerSideTokenCheck")))
        if (not current.get("AllowUnauthenticatedIdentities")
                or sorted(map(key, current.get("CognitoIdentityProviders") or [])) != sorted(map(key, desired))):
            require_identity_pool_tag(pool_id, PLUGIN_IDENTITY_POOL)
            aws("cognito-identity", "update-identity-pool", stdin=dict(update, IdentityPoolId=pool_id))
            say(f"Updated identity pool {PLUGIN_IDENTITY_POOL}")
        else:
            say(f"Reusing identity pool {PLUGIN_IDENTITY_POOL}")
    parity["pluginIdentityPoolId"] = pool_id
    auth_role = ensure_permissionless_role("plugin-authenticated", identity_trust(pool_id, "authenticated"))
    unauth_role = ensure_permissionless_role("plugin-unauthenticated", identity_trust(pool_id, "unauthenticated"))
    require_identity_pool_tag(pool_id, PLUGIN_IDENTITY_POOL)
    run_with_iam_retry(lambda: aws("cognito-identity", "set-identity-pool-roles", "--identity-pool-id", pool_id,
                                   "--roles", f"authenticated={auth_role},unauthenticated={unauth_role}"))


# --- Commands ---------------------------------------------------------------------------------------

def load_template(key):
    with open(os.path.join(INFRA, "pools", f"{key}.json")) as f:
        return json.load(f)


def require_sources():
    """Fails before any AWS call if a checked-in input is missing (on a fresh clone, say)."""
    required = [os.path.join("lambda", "triggers", "triggers.mjs")]
    required += [os.path.join("lambda", "custom-sender", n) for n in ("index.mjs", "package.json", "package-lock.json")]
    required += [os.path.join("codesink", n) for n in ("schema.graphql", "createMfaInfo.request.vtl",
                                                       "listMfaInfo.request.vtl", "item.response.vtl",
                                                       "items.response.vtl")]
    required += [os.path.join("pools", f"{key}.json") for key in POOLS]
    required += [os.path.relpath(p, INFRA) for p in (WEBAUTHN_ENTITLEMENTS, WEBAUTHN_PROJECT,
                                                     PLUGIN_WEBAUTHN_ENTITLEMENTS)]
    missing = [path for path in required if not os.path.isfile(os.path.join(INFRA, path))]
    if missing:
        sys.exit(f"Missing infra inputs, nothing was changed: {', '.join(missing)}")
    if shutil.which("npm") is None:
        sys.exit("npm is not on PATH; the custom sender needs `npm ci`. Nothing was changed.")


def provision():
    require_sources()
    state = load_state()
    require_cli_history_off()
    require_recorded_account(state)
    parity = state.get("parity", {})
    require_webauthn_harness_identity(parity)
    os.makedirs(BUILD_DIR, exist_ok=True)
    challenge_answer = ensure_user_secret("customChallengeAnswer")

    # P-5d, P-5a, P-5c: logs, key, table, roles, API.
    for suffix in FUNCTIONS:
        run_step(f"Log group for {suffix}", ensure_log_group, lambda_log_group(suffix))
    # Scoped to the pools that exist now; the wildcard only while one is about to be created.
    ids_now = live_pool_ids(parity)
    kms_key_id, kms_key_arn = run_step("KMS key", ensure_kms_key, ids_now)
    parity["kmsKeyId"] = kms_key_id
    run_step("Codes table", ensure_table)
    # The API first: the sender's and the data source's roles name its ARN.
    api_id, api_arn = run_step("Code sink API", ensure_api, parity)
    role_arns = {}
    for suffix, (trust, policy) in role_policies(kms_key_arn, api_arn, ids_now).items():
        role_arns[suffix] = run_step(f"Role {suffix}", ensure_role_with_policy, suffix, trust, policy)
    run_step("Code sink resolvers", ensure_api_resolvers, api_id, api_arn, role_arns["appsync-codes"])
    run_step("Code sink API key", rotate_api_key, api_id, api_arn)
    save_parity(parity)

    # P-5b, P-5c: Lambdas.
    # The custom-auth answer never reaches the Lambda's configuration: only its SHA-256 does, which the
    # verify trigger compares against (the answer is 143 random bits, so the hash cannot be reversed).
    answer_sha256 = hashlib.sha256(challenge_answer.encode()).hexdigest()
    secrets_by_key = {"CUSTOM_CHALLENGE_ANSWER_SHA256": answer_sha256, "KMS_KEY_ARN": kms_key_arn,
                      "GRAPHQL_API_ENDPOINT": parity["codeSinkUrl"],
                      "PLUGIN_CONFIRM_POOL_IDS": plugin_pool_ids(parity, PLUGIN_CONFIRM_POOLS),
                      "PLUGIN_UUID_USERNAME_POOL_IDS": plugin_pool_ids(parity, PLUGIN_UUID_USERNAME_POOLS),
                      "CI_SHAPE_UNCONFIRMED_CLIENT_IDS": ci_shape_client_ids(parity, CI_SHAPE_UNCONFIRMED_POOLS)}
    code = {"triggers": build_triggers(), "custom-sender": build_custom_sender()}
    for suffix, (_, role_suffix, source, env_keys) in FUNCTIONS.items():
        run_step(f"Lambda {suffix}", ensure_function, suffix, code[source], role_arns[role_suffix],
                 {k: secrets_by_key[k] for k in env_keys})

    # P-8.
    ses_arn, ses_email = run_step("SES identity", ensure_ses, parity)
    save_parity(parity)

    # P-6, P-7.
    variables = {k: function_arn(v) for k, v in PLACEHOLDER_FUNCTIONS.items()}
    variables.update({"KMS_KEY_ARN": kms_key_arn, "SES_IDENTITY_ARN": ses_arn or "", "SES_FROM_EMAIL": ses_email or ""})
    # P-9, before the pools that name it. Its trust is narrowed to the pools once they all exist.
    parity.pop("smsMfaWithoutSns", None)
    require_sms_sandbox()
    sms_role_arn = run_step("Role cognito-sms", ensure_sms_role, parity, ids_now)
    save_parity(parity)
    variables.update({"SMS_ROLE_ARN": sms_role_arn, "SMS_EXTERNAL_ID": parity["smsExternalId"], "SMS_REGION": REGION})
    sms_ready = True
    # P-10: read-only; the relying party is the plugin's, named by the harness's entitlement.
    rp_id, rp_gap = webauthn_relying_party_or_refuse(parity)
    if rp_gap:
        say(f"WebAuthn: pending, {rp_gap}")
    variables["WEBAUTHN_RP_ID"] = rp_id or ""
    pools = parity.setdefault("pools", {})
    for key, pool_name in POOLS.items():
        template = substitute(load_template(key), variables)
        pending = degrade(template, ses_arn is not None, sms_ready, rp_id is not None)
        require_custom_sms_sender(key, template)
        require_custom_email_sender(key, template)
        record = pools.setdefault(key, {})
        if uses_sms(template):
            parity["smsRoleUsed"] = True
        record["userPoolId"] = with_sms_role(f"User pool {key}", lambda: ensure_user_pool(key, template, record),
                                             parity, ids_now)
        save_parity(parity)
        pool_id = record["userPoolId"]
        for suffix in sorted(set(PLACEHOLDER_FUNCTIONS.values())):
            if function_arn(suffix) in json.dumps(template["userPool"].get("LambdaConfig", {})):
                run_step(f"Invoke permission {suffix} for {key}", ensure_invoke_permission, suffix, key, pool_id)
        with_sms_role(f"MFA of {key}", lambda: set_mfa(pool_id, pool_name, template["mfa"]), parity,
                      ids_now)
        record["pending"] = pending
        clients = record.setdefault("clients", {})
        for client_key, client in template["appClients"].items():
            clients[client_key] = run_step(f"App client {key}-{client_key}", ensure_client, pool_id, pool_name,
                                           client_key, client)
        domain = None
        if "domain" in template:
            domain = run_step(f"Domain of {key}", ensure_domain, pool_id, pool_name, parity,
                              template["domain"]["ManagedLoginVersion"])
        for output_name, spec in template["outputs"].items():
            client = template["appClients"][spec["client"]]
            write_outputs(output_name, outputs_document(pool_id, clients[spec["client"]], template,
                                                        domain if spec.get("oauth") else None, client))
        say(f"  {key}: pending {', '.join(pending) if pending else 'nothing'}")
        save_parity(parity)

    # Now that every pool exists, only they may encrypt, and the sender decrypts only for them.
    pool_ids = recorded_pool_ids(parity)
    run_step("KMS key policy", ensure_kms_key, pool_ids)
    trust, policy = role_policies(kms_key_arn, api_arn, pool_ids)["sender-exec"]
    run_step("Role sender-exec", ensure_role_with_policy, "sender-exec", trust, policy)
    run_step("Role cognito-sms", ensure_sms_role, parity, pool_ids)
    save_parity(parity)
    # The pre-sign-up trigger learns the plugin pools' ids and the CI-shaped clients (a no-op unless one is new).
    secrets_by_key["PLUGIN_CONFIRM_POOL_IDS"] = plugin_pool_ids(parity, PLUGIN_CONFIRM_POOLS)
    secrets_by_key["PLUGIN_UUID_USERNAME_POOL_IDS"] = plugin_pool_ids(parity, PLUGIN_UUID_USERNAME_POOLS)
    secrets_by_key["CI_SHAPE_UNCONFIRMED_CLIENT_IDS"] = ci_shape_client_ids(parity, CI_SHAPE_UNCONFIRMED_POOLS)
    _, role_suffix, source, env_keys = FUNCTIONS["pre-sign-up"]
    run_step("Lambda pre-sign-up", ensure_function, "pre-sign-up", code[source], role_arns[role_suffix],
             {k: secrets_by_key[k] for k in env_keys})

    # P-6'.
    run_step("Identity-only pool", ensure_identity_only_pool, parity)
    save_parity(parity)

    # P-13.
    run_step("Plugin identity pool", ensure_plugin_identity_pool, parity)
    save_parity(parity)
    run_step("Plugin identity pool in the outputs", name_plugin_identity_pool_in_outputs, parity)
    say("Parity resources done")


def pool_ids(state):
    return {key: record["userPoolId"] for key, record in state.get("parity", {}).get("pools", {}).items()
            if record.get("userPoolId")}


GENERATED_USERNAME = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")


def is_test_user(user, key):
    """Exactly the users the pre-sign-up trigger admits (triggers.mjs preSignUp): a ccit-/confirm- or
    plugin-shaped username, a bare UUID username on PLUGIN_UUID_USERNAME_POOLS, or, where Cognito generated
    the username (a lower-case UUID, as on email-alias), an email of those shapes."""
    def admitted(name):
        return (name.lower().startswith(TEST_USER_PREFIXES) or bool(PLUGIN_TEST_USER.match(name))
                or (key in PLUGIN_UUID_USERNAME_POOLS and bool(PLUGIN_BARE_UUID.match(name))))
    attributes = {a["Name"]: a["Value"] for a in user.get("Attributes") or []}
    username = user["Username"]
    return admitted(username) or (bool(GENERATED_USERNAME.match(username)) and admitted(attributes.get("email", "")))


def cleanup():
    """P-12: deletes users the tests created (ccit-/confirm- usernames, or emails on the email-alias
    pool, and the plugin suites' user shapes) more than 24 h ago, in the parity pools only."""
    state = load_state()
    require_cli_history_off()
    require_recorded_account(state)
    cutoff = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(hours=24)
    for key, pool_id in pool_ids(state).items():
        pool_name = POOLS[key]
        if aws_or_none("cognito-idp", "describe-user-pool", "--user-pool-id", pool_id) is None:
            continue
        require_user_pool_tag(pool_id, pool_name)
        deleted = 0
        gone = 0
        # Every user, matched here: the plugin's shapes (a bare UUID among them) have no common prefix.
        for user in aws("cognito-idp", "list-users", "--user-pool-id", pool_id)["Users"]:
            if is_test_user(user, key):
                created = datetime.datetime.fromisoformat(str(user["UserCreateDate"]).replace("Z", "+00:00"))
                if created.tzinfo is None:
                    created = created.replace(tzinfo=datetime.timezone.utc)
                if created < cutoff:
                    require_user_pool_tag(pool_id, pool_name)
                    # Another runner's cleanup (or a test's own teardown) may delete the same user between
                    # the listing and this call: that user is already gone, which is the goal.
                    if delete_user_if_present(pool_id, user["Username"]):
                        deleted += 1
                    else:
                        gone += 1
        already = f" ({gone} already deleted by another run)" if gone else ""
        say(f"{key}: deleted {deleted} test users older than 24 h{already}")


def delete_user_if_present(pool_id, username):
    """Deletes one user. Returns False, rather than raising, when the user no longer exists
    (UserNotFoundException); every other error is raised."""
    try:
        aws("cognito-idp", "admin-delete-user", "--user-pool-id", pool_id, "--username", username)
    except AwsError as error:
        if error.code == "UserNotFoundException":
            return False
        raise
    return True


def plugin_users():
    """P-14: the plugin's DeviceAliasTokenRefreshIntegrationTests signs in as a pre-created user on a
    pool with email as the username. Creates it on email-alias when missing (no message is sent) and
    sets its permanent password to users.json pluginDeviceAliasPassword, and forgets its devices. Runs after cleanup, which
    deletes it once it is a day old (its email starts ccit-), so a run always finds it."""
    state = load_state()
    require_cli_history_off()
    require_recorded_account(state)
    pool_id = pool_ids(state).get("email-alias")
    if not pool_id:
        sys.exit("No email-alias pool recorded; run infra/provision.sh.")
    pool_name = POOLS["email-alias"]
    require_user_pool_tag(pool_id, pool_name)
    if not users().get("pluginDeviceAliasPassword"):
        set_user_secret("pluginDeviceAliasPassword", "Aa1!" + secrets.token_urlsafe(18))
        say("Generated pluginDeviceAliasPassword in users.json")
    found = aws("cognito-idp", "list-users", "--user-pool-id", pool_id,
                "--filter", f'email = "{PLUGIN_DEVICE_ALIAS_EMAIL}"')["Users"]
    if not found:
        require_user_pool_tag(pool_id, pool_name)
        aws("cognito-idp", "admin-create-user", stdin={
            "UserPoolId": pool_id, "Username": PLUGIN_DEVICE_ALIAS_EMAIL, "MessageAction": "SUPPRESS",
            "UserAttributes": [{"Name": "email", "Value": PLUGIN_DEVICE_ALIAS_EMAIL},
                               {"Name": "email_verified", "Value": "true"}]})
        say("Created the plugin's device-alias user on email-alias")
    require_user_pool_tag(pool_id, pool_name)
    aws("cognito-idp", "admin-set-user-password", stdin={
        "UserPoolId": pool_id, "Username": PLUGIN_DEVICE_ALIAS_EMAIL,
        "Password": users()["pluginDeviceAliasPassword"], "Permanent": True})
    say("plugin device-alias user: password set (permanent)")
    # Its devices from earlier runs: the suite's forget tests expect none but their own.
    # AdminListDevices returns at most 60 per page and the CLI does not page it: follow PaginationToken.
    devices, token = [], None
    while True:
        page = aws("cognito-idp", "admin-list-devices", "--user-pool-id", pool_id, "--username",
                   PLUGIN_DEVICE_ALIAS_EMAIL, "--limit", "60", *(["--pagination-token", token] if token else []))
        devices += page.get("Devices", [])
        token = page.get("PaginationToken")
        if not token:
            break
    for device in devices:
        require_user_pool_tag(pool_id, pool_name)
        aws("cognito-idp", "admin-forget-device", "--user-pool-id", pool_id, "--username", PLUGIN_DEVICE_ALIAS_EMAIL,
            "--device-key", device["DeviceKey"])
    say(f"plugin device-alias user: forgot {len(devices)} devices")

    # testNewPasswordRequired: each run needs users still in FORCE_CHANGE_PASSWORD, with no email or phone
    # (the test adds the email while setting the new password).
    default_id, default_name = pool_ids(state)["default"], POOLS["default"]
    require_user_pool_tag(default_id, default_name)
    if not users().get("pluginNewPasswordTemporary"):
        set_user_secret("pluginNewPasswordTemporary", "Tt1!" + secrets.token_urlsafe(18))
        say("Generated pluginNewPasswordTemporary in users.json")
    for username in PLUGIN_NEW_PASSWORD_USERS:
        reset_new_password_user(default_id, default_name, username, users()["pluginNewPasswordTemporary"])
    say(f"plugin new-password users: {len(PLUGIN_NEW_PASSWORD_USERS)} reset to FORCE_CHANGE_PASSWORD")


def new_password_user_needs_recreating(user):
    """Whether a new-password user is in a state a password reset cannot undo: the plugin's
    testNewPasswordRequired adds an email while it sets the new password, and the next run needs a user
    with neither an email nor a phone number."""
    names = {attribute["Name"] for attribute in user.get("UserAttributes", [])}
    return bool(names & {"email", "phone_number"})


NEW_PASSWORD_RESET_ATTEMPTS = 3


def reset_new_password_user(pool_id, pool_name, username, temporary):
    """Leaves `username` in FORCE_CHANGE_PASSWORD with the `temporary` password and no email or phone.

    An existing user in a usable state is only reset (AdminSetUserPassword, not permanent); one the test
    left with an email is deleted and created again. Overlapping runs (two prepare-run.sh at once) are
    tolerated: whenever another run deletes the user (UserNotFoundException from the reset) or creates it
    (UsernameExistsException from the create) between this run's lookup and its change, the lookup is made
    again and acted on, at most NEW_PASSWORD_RESET_ATTEMPTS times. Every mutating call is tag-checked
    first, so an untagged pool is never changed."""
    for _ in range(NEW_PASSWORD_RESET_ATTEMPTS):
        user = aws_or_none("cognito-idp", "admin-get-user", "--user-pool-id", pool_id, "--username", username,
                           missing=("UserNotFoundException",))
        if user is not None and not new_password_user_needs_recreating(user):
            require_user_pool_tag(pool_id, pool_name)
            try:
                aws("cognito-idp", "admin-set-user-password", stdin={
                    "UserPoolId": pool_id, "Username": username, "Password": temporary, "Permanent": False})
                return
            except AwsError as error:
                if error.code != "UserNotFoundException":
                    raise
                # Another run deleted it after the lookup: look again, and create it.
                continue
        if user is not None:
            require_user_pool_tag(pool_id, pool_name)
            delete_user_if_present(pool_id, username)
        require_user_pool_tag(pool_id, pool_name)
        try:
            aws("cognito-idp", "admin-create-user", stdin={
                "UserPoolId": pool_id, "Username": username, "MessageAction": "SUPPRESS",
                "TemporaryPassword": temporary})
            return
        except AwsError as error:
            if error.code != "UsernameExistsException":
                raise
            # Another run created it after the lookup: look again, and reset it.
    fail(f"{username} on {pool_name} kept changing under another run; run prepare-run.sh again.")


def rotate_key():
    """Renews the code sink's 7-day API key when it has under 4 days left (run by prepare-run.sh)."""
    state = load_state()
    require_cli_history_off()
    require_recorded_account(state)
    api_id = state.get("parity", {}).get("codeSinkApiId")
    api = api_id and aws_or_none("appsync", "get-graphql-api", "--api-id", api_id)
    if not api:
        sys.exit("No code sink API recorded; run infra/provision.sh.")
    require_appsync_tag(api["graphqlApi"]["arn"])
    rotate_api_key(api_id, api["graphqlApi"]["arn"])


def webauthn_summary(mfa):
    """The pool's WebAuthnConfiguration as booleans: whether it is set, and whether its relying party is
    the harness's (the domain itself is never printed)."""
    config = mfa.get("WebAuthnConfiguration")
    if not config:
        return None
    rp_id, _ = webauthn_relying_party()
    return {"harnessRelyingParty": config.get("RelyingPartyId") == rp_id,
            "userVerification": config.get("UserVerification")}


def verify():
    """Read-only. Prints names, settings and booleans; never an identifier."""
    state = load_state()
    require_recorded_account(state)
    parity = state.get("parity", {})
    for key, pool_id in pool_ids(state).items():
        pool = aws("cognito-idp", "describe-user-pool", "--user-pool-id", pool_id)["UserPool"]
        mfa = aws("cognito-idp", "get-user-pool-mfa-config", "--user-pool-id", pool_id)
        clients = aws("cognito-idp", "list-user-pool-clients", "--user-pool-id", pool_id,
                      "--max-results", "60")["UserPoolClients"]
        lambdas = sorted(k for k, v in (pool.get("LambdaConfig") or {}).items() if v and k != "KMSKeyID")
        factors = pool.get("Policies", {}).get("SignInPolicy", {}).get("AllowedFirstAuthFactors")
        methods = [m for m, k in (("TOTP", "SoftwareTokenMfaConfiguration"), ("SMS", "SmsMfaConfiguration"),
                                  ("EMAIL", "EmailMfaConfiguration"))
                   if k in mfa and (k != "SoftwareTokenMfaConfiguration" or mfa[k].get("Enabled"))]
        say(f"{key}: tagged={tagged(pool.get('UserPoolTags'))} tier={pool.get('UserPoolTier')} "
            f"mfa={mfa.get('MfaConfiguration')}{methods} firstFactors={factors} "
            f"usernameAttributes={pool.get('UsernameAttributes', [])} devices={'DeviceConfiguration' in pool} "
            f"selfSignUp={not pool['AdminCreateUserConfig']['AllowAdminCreateUserOnly']} "
            f"email={pool.get('EmailConfiguration', {}).get('EmailSendingAccount')} "
            f"domain={bool(pool.get('Domain'))} triggers={lambdas} clients={sorted(c['ClientName'] for c in clients)} "
            f"webAuthn={webauthn_summary(mfa)} pending={parity['pools'][key].get('pending')}")
    for suffix in FUNCTIONS:
        config = aws("lambda", "get-function-configuration", "--function-name", function_name(suffix))
        tags = aws("lambda", "list-tags", "--resource", config["FunctionArn"]).get("Tags")
        say(f"lambda {suffix}: tagged={tagged(tags)} state={config.get('State')} runtime={config['Runtime']} "
            f"env={sorted(((config.get('Environment') or {}).get('Variables') or {}).keys())}")
    for suffix in ("trigger-exec", "sender-exec", "appsync-codes"):
        policies = aws("iam", "list-role-policies", "--role-name", role_name(suffix), region=False)["PolicyNames"]
        say(f"role {suffix}: inline={policies}")
    key = aws("kms", "describe-key", "--key-id", KMS_ALIAS)["KeyMetadata"]
    key_policy = json.loads(aws("kms", "get-key-policy", "--key-id", key["KeyId"], "--policy-name", "default")["Policy"])
    encrypt = next((st for st in key_policy["Statement"] if st.get("Sid") == "CognitoEncryptsCodes"), {})
    kms_pools = len((encrypt.get("Condition", {}).get("ArnEquals") or {}).get("aws:SourceArn", []))
    say(f"kms {KMS_ALIAS}: state={key['KeyState']} encryptPools={kms_pools}")
    # A first run that stopped before narrowing leaves "any pool in the account" policies behind.
    wildcards = wildcard_gaps()
    table = aws("dynamodb", "describe-table", "--table-name", TABLE)["Table"]
    ttl = aws("dynamodb", "describe-time-to-live", "--table-name", TABLE)["TimeToLiveDescription"]
    say(f"table {TABLE}: {table['TableStatus']} ttl={ttl.get('TimeToLiveStatus')}")
    api = aws("appsync", "get-graphql-api", "--api-id", parity["codeSinkApiId"])["graphqlApi"]
    say(f"appsync {APPSYNC_NAME}: auth={api['authenticationType']} tagged={tagged(api.get('tags'))}")
    ip = aws("cognito-identity", "describe-identity-pool", "--identity-pool-id", parity["identityOnlyPoolId"])
    say(f"identity pool {IDENTITY_ONLY_POOL}: guest={ip['AllowUnauthenticatedIdentities']} "
        f"providers={len(ip.get('CognitoIdentityProviders') or [])}")
    if parity.get("pluginIdentityPoolId"):
        ip = aws("cognito-identity", "describe-identity-pool", "--identity-pool-id", parity["pluginIdentityPoolId"])
        say(f"identity pool {PLUGIN_IDENTITY_POOL}: guest={ip['AllowUnauthenticatedIdentities']} "
            f"providers={len(ip.get('CognitoIdentityProviders') or [])}")
    role = (aws_or_none("iam", "get-role", "--role-name", role_name(SMS_ROLE), region=False) or {}).get("Role")
    if role is None:
        say("role cognito-sms: missing (SMS is not provisioned)")
    else:
        sms_policy = aws("iam", "get-role-policy", "--role-name", role_name(SMS_ROLE),
                         "--policy-name", f"{role_name(SMS_ROLE)}-policy", region=False)["PolicyDocument"]["Statement"][0]
        trust = role["AssumeRolePolicyDocument"]["Statement"][0]["Condition"]
        sms_pools = len(trust.get("ArnEquals", {}).get("aws:SourceArn", []))
        say(f"role cognito-sms: trust={sorted(k for c in trust.values() for k in c)} "
            f"pools={sms_pools} publish={sms_policy['Action']} regionCondition={'Condition' in sms_policy}")
    for key, pool_id in pool_ids(state).items():
        pool = aws("cognito-idp", "describe-user-pool", "--user-pool-id", pool_id)["UserPool"]
        lambdas = pool.get("LambdaConfig") or {}
        say(f"{key}: email={pool.get('EmailConfiguration', {}).get('EmailSendingAccount')} "
            f"customEmailSender={(lambdas.get('CustomEmailSender') or {}).get('LambdaArn') == function_arn('custom-sender')} "
            f"sms={bool(pool.get('SmsConfiguration'))} "
            f"customSMSSender={(lambdas.get('CustomSMSSender') or {}).get('LambdaArn') == function_arn('custom-sender')} "
            f"kmsKey={bool(lambdas.get('KMSKeyID'))}")
    gaps = live_sender_gaps(state)
    say(f"ses identity: "
        f"{'address (owned)' if parity.get('sesEmail') else 'domain (account-owned, read-only)' if parity.get('sesDomain') else 'not configured'}")
    gaps += wildcards
    exit_on_gaps("verify", gaps, live_self_sign_up_gaps(state))


def teardown():
    """Deletes the parity resources, each only after its tag check. Destructive."""
    state = load_state()
    require_cli_history_off()
    require_recorded_account(state)
    parity = state.get("parity", {})

    failures = []

    def attempt(label, function):
        """Runs one deletion. A failure (an AWS error, or a tag guard refusing) is reported and
        remembered, so the parity state that locates the resource is kept for a later retry."""
        try:
            function()
        except AwsError as error:
            say(f"Failed to delete {label}: {error.code}")
            failures.append(label)
        except SystemExit as refusal:
            say(f"Skipped {label}: {refusal}")
            failures.append(label)

    for key, pool_id in pool_ids(state).items():
        pool_name = POOLS[key]

        def delete_pool(pool_id=pool_id, pool_name=pool_name, key=key):
            pool = aws_or_none("cognito-idp", "describe-user-pool", "--user-pool-id", pool_id)
            if pool is None:
                return
            if not tagged(pool["UserPool"].get("UserPoolTags")):
                say(f"Skipped user pool {pool_name}: tag missing")
                return
            if pool["UserPool"].get("Domain"):
                require_user_pool_tag(pool_id, pool_name)
                aws("cognito-idp", "delete-user-pool-domain", "--domain", pool["UserPool"]["Domain"],
                    "--user-pool-id", pool_id)
            require_user_pool_tag(pool_id, pool_name)
            aws("cognito-idp", "delete-user-pool", "--user-pool-id", pool_id)
            say(f"Deleted user pool {pool_name}")
        attempt(f"user pool {pool_name}", delete_pool)

    def delete_identity_pool():
        pool_id = parity.get("identityOnlyPoolId")
        if pool_id and aws_or_none("cognito-identity", "describe-identity-pool", "--identity-pool-id", pool_id):
            require_identity_pool_tag(pool_id, IDENTITY_ONLY_POOL)
            aws("cognito-identity", "delete-identity-pool", "--identity-pool-id", pool_id)
            say(f"Deleted identity pool {IDENTITY_ONLY_POOL}")
    attempt("identity pool", delete_identity_pool)

    def delete_plugin_identity_pool():
        pool_id = parity.get("pluginIdentityPoolId")
        if pool_id and aws_or_none("cognito-identity", "describe-identity-pool", "--identity-pool-id", pool_id):
            require_identity_pool_tag(pool_id, PLUGIN_IDENTITY_POOL)
            aws("cognito-identity", "delete-identity-pool", "--identity-pool-id", pool_id)
            say(f"Deleted identity pool {PLUGIN_IDENTITY_POOL}")
    attempt("plugin identity pool", delete_plugin_identity_pool)

    for suffix in FUNCTIONS:
        def delete_function(suffix=suffix):
            config = aws_or_none("lambda", "get-function-configuration", "--function-name", function_name(suffix))
            if config is None:
                return
            require_lambda_tag(config["FunctionArn"], function_name(suffix))
            aws("lambda", "delete-function", "--function-name", function_name(suffix))
            say(f"Deleted Lambda {function_name(suffix)}")
        attempt(f"Lambda {suffix}", delete_function)

        def delete_log_group(suffix=suffix):
            name = lambda_log_group(suffix)
            if not any(g["logGroupName"] == name for g in
                       aws("logs", "describe-log-groups", "--log-group-name-prefix", name)["logGroups"]):
                return
            require_log_group_tag(name)
            aws("logs", "delete-log-group", "--log-group-name", name)
            say(f"Deleted log group {name}")
        attempt(f"log group {suffix}", delete_log_group)

    def delete_api():
        api_id = parity.get("codeSinkApiId")
        api = api_id and aws_or_none("appsync", "get-graphql-api", "--api-id", api_id)
        if api:
            require_appsync_tag(api["graphqlApi"]["arn"])
            aws("appsync", "delete-graphql-api", "--api-id", api_id)
            say(f"Deleted AppSync API {APPSYNC_NAME}")
    attempt("AppSync API", delete_api)

    def delete_table():
        if aws_or_none("dynamodb", "describe-table", "--table-name", TABLE):
            require_table_tag(table_arn())
            aws("dynamodb", "delete-table", "--table-name", TABLE)
            say(f"Deleted table {TABLE}")
    attempt("table", delete_table)

    for suffix in ("trigger-exec", "sender-exec", "appsync-codes", SMS_ROLE,
                   "identity-only-authenticated", "identity-only-unauthenticated",
                   "plugin-authenticated", "plugin-unauthenticated"):
        def delete_role(suffix=suffix):
            role = role_name(suffix)
            if aws_or_none("iam", "get-role", "--role-name", role, region=False) is None:
                return
            require_role_tag(role)
            for policy in aws("iam", "list-role-policies", "--role-name", role, region=False)["PolicyNames"]:
                require_role_tag(role)
                aws("iam", "delete-role-policy", "--role-name", role, "--policy-name", policy, region=False)
            require_role_tag(role)
            aws("iam", "delete-role", "--role-name", role, region=False)
            say(f"Deleted role {role}")
        attempt(f"role {suffix}", delete_role)

    def delete_key():
        key_id = parity.get("kmsKeyId")
        if not key_id:
            return
        metadata = aws_or_none("kms", "describe-key", "--key-id", key_id)
        if metadata is None:
            return
        require_kms_tag(key_id)
        # Deletion is scheduled before the alias goes, so a failure leaves the alias pointing at the
        # key and a re-run of provision.sh or teardown.sh still finds it.
        if metadata["KeyMetadata"]["KeyState"] != "PendingDeletion":
            aws("kms", "schedule-key-deletion", "--key-id", key_id, "--pending-window-in-days", "7")
            say(f"Scheduled KMS key {KMS_ALIAS} for deletion in 7 days")
        if any(a["AliasName"] == KMS_ALIAS for a in aws("kms", "list-aliases", "--key-id", key_id)["Aliases"]):
            require_kms_tag(key_id)
            aws("kms", "delete-alias", "--alias-name", KMS_ALIAS)
    attempt("KMS key", delete_key)

    def delete_ses():
        # Only an address identity this script created (sesEmail). A borrowed domain identity is not
        # this sandbox's and is never touched.
        address, identity_arn = parity.get("sesEmail"), parity.get("sesIdentityArn")
        if address and identity_arn and aws_or_none("sesv2", "get-email-identity", "--email-identity", address):
            require_ses_identity_tag(identity_arn)
            aws("sesv2", "delete-email-identity", "--email-identity", address)
            say("Deleted the SES email identity")
    attempt("SES identity", delete_ses)

    if failures:
        # Every deletion skips what is already gone, so keeping the whole section makes a re-run
        # retry exactly the failures.
        sys.exit(f"Teardown incomplete ({', '.join(failures)}); the parity state is kept. Re-run teardown.sh.")
    for name in list(POOLS) + ["hosted-ui", "identity-only"]:
        path = outputs_path(name)
        if os.path.exists(path):
            os.unlink(path)
    shutil.rmtree(BUILD_DIR, ignore_errors=True)
    state.pop("parity", None)
    save_json(STATE_FILE, state)
    say("Parity resources removed")


if __name__ == "__main__":
    commands = {"provision": provision, "cleanup": cleanup, "rotate-key": rotate_key, "preflight": preflight,
                "plugin-users": plugin_users,
                "verify": verify,
                "teardown": teardown}
    if len(sys.argv) != 2 or sys.argv[1] not in commands:
        sys.exit(f"Usage: {sys.argv[0]} {'|'.join(commands)}")
    commands[sys.argv[1]]()
