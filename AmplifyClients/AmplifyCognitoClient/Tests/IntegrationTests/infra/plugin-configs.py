#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""Writes the configuration files the AWSCognitoAuthPlugin's own integration suites expect, pointed at
this sandbox's parity backends, from the state provision.sh leaves in ~/.amplify-cognito-client-integ.

    plugin-configs.py            write every file (backing up any file not written by this script)
    plugin-configs.py --dir DIR  write every file into DIR instead (created if missing), with no manifest and
                                 no backups: for a directory of its own, such as the one the client suites'
                                 host app reads through COGNITO_CLIENT_INTEG_DIR. Refuses
                                 ~/.aws-amplify/amplify-ios/testconfiguration and every directory inside it,
                                 whatever AWS_AMPLIFY_TESTCONFIGURATION_DIR says, and every directory inside
                                 the configured one; the configured directory itself, when it is another,
                                 behaves as without --dir
    plugin-configs.py --dir DIR --ci-shape
                                 the file set the plugin's CI downloads (CI_FILES below), from the same
                                 backends: its nine names, Gen1 where CI has Gen1 files, a `data` block only on
                                 the backends that capture codes, no EMAIL in the email-MFA files' mfa_methods,
                                 app clients shaped as CI's (CI_APP_CLIENTS), no sandbox marker, and no
                                 credentials file. Only into a directory of its own
    plugin-configs.py --refresh  rewrite only the files it wrote that are still as written (after a key
                                 rotation, say); does nothing if it has written none (prepare-run.sh)
    plugin-configs.py --forget NAME  drop NAME from the manifest and leave the file there as it is (for a
                                 file --remove left because it was replaced or edited; its backups stay
                                 in the backup folder)
    plugin-configs.py --remove   put back what each written file replaced (or delete it), but only files
                                 still exactly as written; anything replaced or edited since is left

The plugin's host apps (AuthHostApp, AuthHostedUIApp, AuthWebAuthnApp) copy
~/.aws-amplify/amplify-ios/testconfiguration/ into their bundle in a "Copy Configuration folder" build phase (or
the directory COGNITO_CLIENT_INTEG_DIR names, as the client's host app does, so a --dir file set serves them too);
CI downloads prebuilt files into the same directory (run_integration_tests.yml). So the files go there: outside
git, mode 600, never committed.
AWS_AMPLIFY_TESTCONFIGURATION_DIR overrides the directory.

Suite -> file -> sandbox backend:
    AuthIntegrationTests (Gen1), AuthGen2IntegrationTests (Gen2)
        AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration / -amplify_outputs / -credentials
                                                             default (client `plugin`) + the plugin identity pool (P-13)
        AWSCognitoAuthPluginMFARequiredIntegrationTests-*     mfa-req-totp-sms
        AWSCognitoPluginPasswordlessIntegrationTests-amplify_outputs      passwordless + code sink
        AWSCognitoEmailMFARequiredTests-amplify_outputs                   mfa-req-email + code sink
        AWSCognitoAuthEmailMFAWithAllMFATypesRequired-amplify_outputs     mfa-req-all + code sink
        AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs / -credentials
                                                             email-alias + its pre-created user (P-14)
    AuthStressTests
        AWSAmplifyStressTests-amplifyconfiguration / -credentials         default + P-13
    AuthHostedUIApp (Gen1), AuthHostedUIAppGen2UITests (Gen2)
        AWSCognitoAuthPluginHostedUIIntegrationTests-*        default, client hostedui-plugin (myapp://)
    AuthWebAuthnApp
        AWSCognitoPluginWebAuthnIntegrationTests-amplify_outputs          webauthn (P-10)
    the client's interop target only (CognitoClientPluginInteropTests' PluginRotationTests), not the plugin's
        AmplifyCognitoClientRotationIntegrationTests-amplify_outputs     default, client `rotation` (P-15, refresh-token
                                                             rotation on, no grace period); written only once
                                                             provision.sh has made that client, and never in
                                                             the CI shape, so the tests skip without it

The `data` section is the code sink's AppSync API with its read-only API key, which the plugin's
`onCreateMfaInfo` subscription (AWSAuthBaseTest.subscribeToOTPCreation) uses through AWSAPIPlugin. Every
outputs file carries it, since every sandbox pool's custom senders publish there: the plugin's suites
read it only where they add AWSAPIPlugin, and the client suites read each pool's codes through its own
file's block. The default backend's credentials file also names the identity-only pool (P-6')
as `second_identity_pool_id`: a guest identity pool that federates none of the set's user pools, which
the client's CS-3 needs and the plugin's suites never read.
The CI shape (--ci-shape) is the file set the plugin's CI downloads (download_test_configuration,
resource_subfolder: auth), as a CI run listed it: nine files. The default, MFA-required, hosted-UI and stress
backends are Gen1 amplifyconfiguration.json files only, in the shape gen1() writes for the plugin's Gen1
suites (the stress one under CI's name, AWSAuthStressTests-); the other five are Gen2 outputs. Only the
passwordless and the two email-MFA backends deploy custom senders and an MfaInfo API
(PasswordlessTests/README.md, MFATests/EmailMFATests/README.md) and have suites that subscribe to it, so only
their outputs carry a `data` block. There is no credentials file at all: the plugin's AWSAuthBaseTest then
uses a random email and password, and its custom-auth and new-password tests skip. The two email-MFA backends
turn email MFA on outside defineAuth, so their outputs list no EMAIL in mfa_methods (CI_EMAIL_MFA_UNLISTED).
Where CI's backends' app clients or pre-sign-up triggers differ from the sandbox clients the full set names,
the CI shape names each pool's `ci` app client instead (CI_APP_CLIENTS), which parity.py shapes as CI's.
Every Gen2 file of the full set carries a `custom` block that marks it as the sandbox's (SANDBOX_MARKER), so
the client suites' sandbox checks run only there; the CI shape, as CI's files, has none.
Nothing here calls AWS, and nothing printed names an identifier or a secret.
"""

import contextlib
import datetime
import fcntl
import hashlib
import importlib.util
import json
import os
import shutil
import sys
import tempfile

STATE_DIR = os.environ.get("COGNITO_CLIENT_INTEG_DIR") or os.path.expanduser("~/.amplify-cognito-client-integ")
TARGET_DIR = (os.environ.get("AWS_AMPLIFY_TESTCONFIGURATION_DIR")
              or os.path.expanduser("~/.aws-amplify/amplify-ios/testconfiguration"))
MANIFEST = os.path.join(STATE_DIR, "plugin-configs-manifest.json")
LOCK = os.path.join(STATE_DIR, "plugin-configs.lock")
BACKUP_DIR = os.path.join(STATE_DIR, "plugin-configs-backup")
DEVICE_ALIAS_EMAIL = "ccit-plugin-device-alias@example.com"
HOSTED_UI_REDIRECT = "myapp://"


def _parity():
    """parity.py, loaded by its path, from wherever this script is run or loaded. Loading it calls no AWS."""
    spec = importlib.util.spec_from_file_location("parity", os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                                                         "parity.py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


# The single-use FORCE_CHANGE_PASSWORD users prepare-run.sh resets, as parity.py defines them.
NEW_PASSWORD_USERS = _parity().PLUGIN_NEW_PASSWORD_USERS


def load(path):
    with open(path) as f:
        return json.load(f)


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def outputs(name):
    path = os.path.join(STATE_DIR, f"{name}-amplify_outputs.json")
    if not os.path.exists(path):
        sys.exit(f"Missing {os.path.basename(path)} in the state directory; run infra/provision.sh.")
    return load(path)


def gen1(auth, identity_pool_id=None, oauth=None):
    """The Gen1 amplifyconfiguration.json shape the plugin's ConfigurationHelper reads."""
    methods = {"SMS": "SMS", "TOTP": "TOTP", "EMAIL": "EMAIL"}
    policy = auth.get("password_policy", {})
    characters = [name for key, name in (("require_lowercase", "REQUIRES_LOWERCASE"),
                                         ("require_uppercase", "REQUIRES_UPPERCASE"),
                                         ("require_numbers", "REQUIRES_NUMBERS"),
                                         ("require_symbols", "REQUIRES_SYMBOLS")) if policy.get(key)]
    default = {
        "authenticationFlowType": "USER_SRP_AUTH",
        "socialProviders": [],
        "usernameAttributes": [a.upper() for a in auth.get("username_attributes", [])],
        "signupAttributes": [],
        "passwordProtectionSettings": {"passwordPolicyMinLength": policy.get("min_length", 8),
                                       "passwordPolicyCharacters": characters},
        "mfaConfiguration": {"NONE": "OFF", "OPTIONAL": "OPTIONAL", "REQUIRED": "ON"}[auth["mfa_configuration"]],
        "mfaTypes": [methods[m] for m in auth.get("mfa_methods", [])],
        "verificationMechanisms": [v.upper() for v in auth.get("user_verification_types", [])],
    }
    if oauth:
        default["OAuth"] = oauth
    plugin = {
        "UserAgent": "aws-amplify/cli",
        "Version": "0.1.0",
        "IdentityManager": {"Default": {}},
        "CognitoUserPool": {"Default": {"PoolId": auth["user_pool_id"], "AppClientId": auth["user_pool_client_id"],
                                        "Region": auth["aws_region"]}},
        "Auth": {"Default": default},
    }
    if identity_pool_id:
        plugin["CredentialsProvider"] = {"CognitoIdentity": {"Default": {"PoolId": identity_pool_id,
                                                                         "Region": auth["aws_region"]}}}
    return {"UserAgent": "aws-amplify-cli/2.0", "Version": "1.0", "auth": {"plugins": {"awsCognitoAuthPlugin": plugin}}}


def with_identity_pool(document, identity_pool_id):
    document = json.loads(json.dumps(document))
    document["auth"]["identity_pool_id"] = identity_pool_id
    document["auth"]["unauthenticated_identities_enabled"] = True
    return document


def with_data(document, region, url, api_key):
    document = json.loads(json.dumps(document))
    document["data"] = {"aws_region": region, "url": url, "api_key": api_key,
                        "default_authorization_type": "API_KEY", "authorization_types": []}
    return document


def credentials(email, password, **extra):
    return dict({"test_email_1": email, "password": password}, **extra)


# The outputs files whose backends capture codes on CI, so the only ones with a `data` block in the CI shape.
CI_CODE_CAPTURING = (
    "AWSCognitoPluginPasswordlessIntegrationTests-amplify_outputs.json",
    "AWSCognitoEmailMFARequiredTests-amplify_outputs.json",
    "AWSCognitoAuthEmailMFAWithAllMFATypesRequired-amplify_outputs.json",
)
# The plugin's CI file set, by CI's names, each from the file build() writes for the same backend in the same
# format. No credentials file: CI has none.
CI_FILES = {
    "AWSAuthStressTests-amplifyconfiguration.json": "AWSAmplifyStressTests-amplifyconfiguration.json",
    "AWSCognitoAuthEmailMFAWithAllMFATypesRequired-amplify_outputs.json":
        "AWSCognitoAuthEmailMFAWithAllMFATypesRequired-amplify_outputs.json",
    "AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json": "AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json",
    "AWSCognitoAuthPluginHostedUIIntegrationTests-amplifyconfiguration.json":
        "AWSCognitoAuthPluginHostedUIIntegrationTests-amplifyconfiguration.json",
    "AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json":
        "AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json",
    "AWSCognitoAuthPluginMFARequiredIntegrationTests-amplifyconfiguration.json":
        "AWSCognitoAuthPluginMFARequiredIntegrationTests-amplifyconfiguration.json",
    "AWSCognitoEmailMFARequiredTests-amplify_outputs.json": "AWSCognitoEmailMFARequiredTests-amplify_outputs.json",
    "AWSCognitoPluginPasswordlessIntegrationTests-amplify_outputs.json":
        "AWSCognitoPluginPasswordlessIntegrationTests-amplify_outputs.json",
    "AWSCognitoPluginWebAuthnIntegrationTests-amplify_outputs.json": "AWSCognitoPluginWebAuthnIntegrationTests-amplify_outputs.json",
}
# The client harness's own directory must never be the developer's own plugin configuration.
OWNER_TESTCONFIGURATION_DIR = os.path.expanduser("~/.aws-amplify/amplify-ios/testconfiguration")


# The CI files whose backends' app clients differ from the sandbox client the full set names, each with the
# sandbox pool whose `ci` app client (parity.py CI_SHAPE_CLIENT_POOLS, pools/*.json) the CI shape names
# instead. That client is shaped as CI's: no USER_PASSWORD_AUTH on the MFA-required, email-MFA and device-alias
# backends ("USER_PASSWORD_AUTH flow not enabled for this client" in the client suites' CI run), and, through
# it, no confirming pre-sign-up trigger on the passwordless and device-alias backends (the passwordless README
# deploys none; CI's device-alias backend left a fresh sign-up unconfirmed).
CI_APP_CLIENTS = {
    "AWSCognitoAuthPluginMFARequiredIntegrationTests-amplifyconfiguration.json": "mfa-req-totp-sms",
    "AWSCognitoEmailMFARequiredTests-amplify_outputs.json": "mfa-req-email",
    "AWSCognitoAuthEmailMFAWithAllMFATypesRequired-amplify_outputs.json": "mfa-req-all",
    "AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json": "email-alias",
    "AWSCognitoPluginPasswordlessIntegrationTests-amplify_outputs.json": "passwordless",
}
# The CI files whose backends turn email MFA on outside defineAuth (MFATests/EmailMFATests/README.md:
# `multifactor` names `sms`, and `totp` on the all-types one), so whose mfa_methods list no EMAIL.
CI_EMAIL_MFA_UNLISTED = (
    "AWSCognitoEmailMFARequiredTests-amplify_outputs.json",
    "AWSCognitoAuthEmailMFAWithAllMFATypesRequired-amplify_outputs.json",
)
# What the full set's Gen2 files carry to say they are the sandbox's (the client harness's
# IntegrationTestEnvironment.isSandbox): a check of what only the sandbox provisions runs there, and skips on
# any other file set. CI's files have no such block, and the CI shape drops it.
SANDBOX_MARKER = {"amplify_cognito_client_integ": {"sandbox": True}}


def ci_shape(files, ci_clients):
    """The plugin's CI file set (CI_FILES) from `files`, what build() returns: `data` only on
    CI_CODE_CAPTURING, no sandbox marker, no EMAIL in CI_EMAIL_MFA_UNLISTED's mfa_methods, and the `ci` app
    client of CI_APP_CLIENTS' pools (`ci_clients`: pool key to client id)."""
    shaped = {}
    for name, source in CI_FILES.items():
        document = json.loads(json.dumps(files[source]))
        if name.endswith("-amplify_outputs.json"):
            document.pop("custom", None)
            if name not in CI_CODE_CAPTURING:
                document.pop("data", None)
            if name in CI_EMAIL_MFA_UNLISTED:
                document["auth"]["mfa_methods"] = [m for m in document["auth"]["mfa_methods"] if m != "EMAIL"]
        if name in CI_APP_CLIENTS:
            client_id = ci_clients.get(CI_APP_CLIENTS[name]) or sys.exit(
                f"No `ci` app client on {CI_APP_CLIENTS[name]} in state.json; run infra/provision.sh.")
            if name.endswith("-amplify_outputs.json"):
                document["auth"]["user_pool_client_id"] = client_id
            else:
                document["auth"]["plugins"]["awsCognitoAuthPlugin"]["CognitoUserPool"]["Default"]["AppClientId"] = \
                    client_id
        shaped[name] = document
    return shaped


def ci_app_clients():
    """Each pool's `ci` app client in state.json, by pool key."""
    pools = load(os.path.join(STATE_DIR, "state.json")).get("parity", {}).get("pools", {})
    return {key: record["clients"]["ci"] for key, record in pools.items() if record.get("clients", {}).get("ci")}


def build():
    state = load(os.path.join(STATE_DIR, "state.json"))
    users = load(os.path.join(STATE_DIR, "users.json"))
    parity = state.get("parity") or sys.exit("No parity resources in state.json; run infra/provision.sh.")
    region = state["region"]
    identity_pool_id = parity.get("pluginIdentityPoolId") or sys.exit(
        "No plugin identity pool (P-13) in state.json; run infra/provision.sh.")
    for key in ("codeSinkApiKey", "pluginDeviceAliasPassword", "customChallengeAnswer", "pluginNewPasswordTemporary"):
        if not users.get(key):
            sys.exit(f"{key} is missing from users.json; run infra/provision.sh and infra/prepare-run.sh.")
    data = lambda document: with_data(document, region, parity["codeSinkUrl"], users["codeSinkApiKey"])
    identity_only = outputs("identity-only")["auth"].get("identity_pool_id") or sys.exit(
        "identity-only-amplify_outputs.json has no identity pool; run infra/provision.sh.")

    # The default pool's `plugin` client: `client` with user-existence errors on (LEGACY).
    default = with_identity_pool(outputs("default"), identity_pool_id)
    default["auth"]["user_pool_client_id"] = parity["pools"]["default"]["clients"]["plugin"]
    default = data(default)
    mfa_required = outputs("mfa-req-totp-sms")
    # An RFC 2606 address: the suites only store it as the email attribute (no mail is sent, the custom
    # email sender takes every code). Derived, not random, so a rewrite with nothing changed is identical.
    main_email = f"ccit-plugin-{hashlib.sha256(identity_pool_id.encode()).hexdigest()[:8]}@example.com"

    hosted = outputs("hosted-ui")
    hosted["auth"]["user_pool_client_id"] = parity["pools"]["default"]["clients"]["hostedui-plugin"]
    hosted["auth"]["oauth"]["redirect_sign_in_uri"] = [HOSTED_UI_REDIRECT]
    hosted["auth"]["oauth"]["redirect_sign_out_uri"] = [HOSTED_UI_REDIRECT]
    oauth = hosted["auth"]["oauth"]
    hosted_gen1 = gen1(hosted["auth"], oauth={
        "WebDomain": oauth["domain"], "AppClientId": hosted["auth"]["user_pool_client_id"],
        "SignInRedirectURI": HOSTED_UI_REDIRECT, "SignOutRedirectURI": HOSTED_UI_REDIRECT,
        "Scopes": oauth["scopes"]})

    files = {
        "AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json": gen1(default["auth"], identity_pool_id),
        "AWSCognitoAuthPluginIntegrationTests-amplify_outputs.json": default,
        # The default pool's custom-auth answer (AuthCustomSignInTests) and its single-use
        # FORCE_CHANGE_PASSWORD users (AuthSRPSignInTests.testNewPasswordRequired, P-14). The answer signs in
        # any default-pool user without a password: the file stays mode 600, outside git.
        "AWSCognitoAuthPluginIntegrationTests-credentials.json": credentials(
            main_email, "", custom_challenge_answer=users["customChallengeAnswer"],
            new_password_required_usernames=",".join(NEW_PASSWORD_USERS),
            new_password_required_temporary_password=users["pluginNewPasswordTemporary"],
            second_identity_pool_id=identity_only),
        "AWSCognitoAuthPluginMFARequiredIntegrationTests-amplifyconfiguration.json": gen1(mfa_required["auth"]),
        "AWSCognitoAuthPluginMFARequiredIntegrationTests-amplify_outputs.json": data(mfa_required),
        "AWSCognitoPluginPasswordlessIntegrationTests-amplify_outputs.json": data(outputs("passwordless")),
        "AWSCognitoEmailMFARequiredTests-amplify_outputs.json": data(outputs("mfa-req-email")),
        "AWSCognitoAuthEmailMFAWithAllMFATypesRequired-amplify_outputs.json": data(outputs("mfa-req-all")),
        "AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json": data(outputs("email-alias")),
        "AWSCognitoAuthPluginDeviceAliasTests-credentials.json":
            credentials(DEVICE_ALIAS_EMAIL, users["pluginDeviceAliasPassword"]),
        "AWSAmplifyStressTests-amplifyconfiguration.json": gen1(default["auth"], identity_pool_id),
        "AWSAmplifyStressTests-credentials.json": credentials(main_email, ""),
        "AWSCognitoAuthPluginHostedUIIntegrationTests-amplifyconfiguration.json": hosted_gen1,
        "AWSCognitoAuthPluginHostedUIIntegrationTests-amplify_outputs.json": data(hosted),
        "AWSCognitoPluginWebAuthnIntegrationTests-amplify_outputs.json": data(outputs("webauthn")),
    }
    # The default pool's `rotation` client, once provision.sh has made it: an older sandbox has no such file, and
    # the client's rotation tests then skip.
    if os.path.exists(os.path.join(STATE_DIR, "rotation-amplify_outputs.json")):
        files["AmplifyCognitoClientRotationIntegrationTests-amplify_outputs.json"] = data(outputs("rotation"))
    # Gen2 allows any `custom` block; the plugin and the client ignore it.
    return {name: dict(document, custom=SANDBOX_MARKER) if name.endswith("-amplify_outputs.json") else document
            for name, document in files.items()}


def write_private(path, data):
    tmp = path + ".tmp"
    try:
        with os.fdopen(os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "wb") as f:
            f.write(data)
        os.replace(tmp, path)
    finally:
        # A failed write must not leave <name>.tmp behind: the host apps' build phase copies the whole
        # directory.
        if os.path.exists(tmp):
            os.unlink(tmp)
    os.chmod(path, 0o600)


@contextlib.contextmanager
def exclusive():
    """One plugin-configs.py at a time: two runs interleaving their manifest writes could lose a backup."""
    os.makedirs(STATE_DIR, exist_ok=True)
    with os.fdopen(os.open(LOCK, os.O_WRONLY | os.O_CREAT, 0o600), "w") as f:
        try:
            fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            sys.exit("Another plugin-configs.py is running; wait for it to finish.")
        yield


def load_manifest():
    """{"written": {name: sha256 of what this script wrote (or is about to write)},
        "backups": {name: [{"path", "sha256"}, …], oldest first}}. Older manifests kept one path per name."""
    manifest = load(MANIFEST) if os.path.exists(MANIFEST) else {"written": {}, "backups": {}}
    for name, entry in list(manifest["backups"].items()):
        if isinstance(entry, str):
            # A backup that has gone missing keeps its path, with no hash: --remove then warns and keeps
            # the entry instead of deleting the file.
            digest = None
            if os.path.exists(entry):
                with open(entry, "rb") as f:
                    digest = sha256(f.read())
            manifest["backups"][name] = [{"path": entry, "sha256": digest}]
    return manifest


def save_manifest(manifest):
    write_private(MANIFEST, (json.dumps(manifest, indent=1, sort_keys=True) + "\n").encode())


def back_up(path, name):
    """Copies `path` into a new, uniquely named folder under BACKUP_DIR (never over an existing backup)
    and returns the manifest entry."""
    os.makedirs(BACKUP_DIR, mode=0o700, exist_ok=True)
    folder = tempfile.mkdtemp(prefix=datetime.datetime.now().strftime("%Y%m%d-%H%M%S-"), dir=BACKUP_DIR)
    target = os.path.join(folder, name)
    with open(path, "rb") as source:
        data = source.read()
    with os.fdopen(os.open(target, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "wb") as f:
        f.write(data)
    # The original's mode and times, so --remove (copy2) puts the file back exactly as it was. The
    # mkdtemp folder is private (0700) whatever the file's own mode.
    shutil.copystat(path, target)
    return {"path": target, "sha256": sha256(data)}


def serialized(name, document):
    """What a file holds: the credentials files carry only what the suites read (an empty password means
    "not set")."""
    if name.endswith("-credentials.json"):
        document = {k: v for k, v in document.items() if v}
    return (json.dumps(document, indent=2, sort_keys=True) + "\n").encode()


def write_into(directory, ci=False):
    """Writes every file into `directory`, a directory of the caller's own: no manifest and no backups, since
    nothing there is anyone else's. Only the file names this script writes are touched. With `ci`, in the
    shape the plugin's CI files have (`ci_shape`)."""
    target = os.path.realpath(directory)
    default = os.path.realpath(TARGET_DIR)
    owner = os.path.realpath(OWNER_TESTCONFIGURATION_DIR)
    if target == owner or target.startswith(owner + os.sep):
        sys.exit("--dir must not be ~/.aws-amplify/amplify-ios/testconfiguration or inside it; run without "
                 "--dir to write there, with its manifest and backups.")
    if target.startswith(default + os.sep):
        sys.exit("--dir must not be inside the plugin's testconfiguration directory.")
    if target == default:
        if ci:
            sys.exit("--ci-shape writes only into a directory of its own.")
        write_all()
        return
    full = build()
    files = ci_shape(full, ci_app_clients()) if ci else full
    os.makedirs(target, mode=0o700, exist_ok=True)
    for name, document in files.items():
        write_private(os.path.join(target, name), serialized(name, document))
    # The CI shape is exactly CI's file set: a file of the full set left from an earlier write would make it
    # something CI never has. Only names this script writes are removed.
    for name in sorted(set(full) - set(files)) if ci else []:
        path = os.path.join(target, name)
        if os.path.exists(path):
            os.unlink(path)
    print(f"{len(files)} file(s) written; build the client host app with COGNITO_CLIENT_INTEG_DIR set to that "
          f"directory to use them.")


def write_all(refresh=False):
    """Writes every file. With `refresh`, only rewrites the files it wrote before that are still exactly
    as written, and leaves everything else (missing, replaced, edited) alone."""
    manifest = load_manifest()
    if refresh and not manifest["written"]:
        print("No plugin configuration files written; nothing to refresh.")
        return
    files = build()
    os.makedirs(TARGET_DIR, exist_ok=True)
    rewritten = 0
    for name, document in files.items():
        data = serialized(name, document)
        path = os.path.join(TARGET_DIR, name)
        if refresh:
            current = None
            if os.path.exists(path):
                with open(path, "rb") as f:
                    current = sha256(f.read())
            if current is None or current != manifest["written"].get(name):
                print(f"Left {name}: not written by plugin-configs.py, or changed since")
                continue
            if current == sha256(data):
                continue
        if os.path.exists(path):
            with open(path, "rb") as f:
                current = sha256(f.read())
            backups = manifest["backups"].setdefault(name, [])
            if current != manifest["written"].get(name) and (not backups or current != backups[-1]["sha256"]):
                # Not what this script wrote, and not the latest backup: someone else's file (a real
                # backend's, or an edit of ours). It is kept, to put back with --remove; each new one is
                # backed up again under a new folder. Only the latest backup counts as "already kept": an
                # developer who puts an older file back gets it backed up again, so --remove restores it and not
                # the one in between. The manifest is saved before the file is replaced, so a crash cannot
                # lose track of the backup (and the rerun finds it as the latest).
                backups.append(back_up(path, name))
                save_manifest(manifest)
                print(f"Backed up the existing {name}")
            if not backups:
                del manifest["backups"][name]
        # Recorded before the write: a crash in between leaves a hash that matches nothing on disk,
        # which the next run and --remove treat as not ours.
        manifest["written"][name] = sha256(data)
        save_manifest(manifest)
        write_private(path, data)
        rewritten += 1
        print(f"Wrote {name}")
    if rewritten:
        print(f"{rewritten} file(s) written in the plugin's testconfiguration directory; rebuild the host apps "
              f"(build-for-testing) to pick them up.")


def remove_all():
    """Puts back what was there before, for each file this script wrote, but only while the file is still
    exactly what the script wrote: a file someone has since replaced or edited is left alone, with a
    warning, and its manifest entry kept."""
    manifest = load_manifest()
    kept = {"written": {}, "backups": {}}
    for name in sorted(manifest["written"]):
        path = os.path.join(TARGET_DIR, name)
        backups = manifest["backups"].get(name) or []
        current = None
        if os.path.exists(path):
            with open(path, "rb") as f:
                current = sha256(f.read())
        if backups and current == backups[-1]["sha256"]:
            # Never replaced (a crash between recording and writing it): already the original.
            continue
        if current is not None and current != manifest["written"][name]:
            print(f"Left {name}: it is not what plugin-configs.py wrote (replaced or edited since). To keep it as "
                  f"it is: plugin-configs.py --forget {name}. To put back what was there before this script "
                  f"first wrote: copy the backup you want from {BACKUP_DIR}, then --forget {name}.")
            kept["written"][name] = manifest["written"][name]
            if backups:
                kept["backups"][name] = backups
            continue
        if backups and not os.path.exists(backups[-1]["path"]):
            # The file this one replaced is recorded but its backup is gone: deleting ours would lose the
            # only trace that something was there.
            print(f"Left {name}: its recorded backup is missing ({backups[-1]['path']}). Put the original back "
                  f"by hand if you have it, then plugin-configs.py --forget {name}.")
            kept["written"][name] = manifest["written"][name]
            kept["backups"][name] = backups
            continue
        if backups:
            shutil.copy2(backups[-1]["path"], path)
            print(f"Restored {name}")
        elif current is not None:
            os.unlink(path)
            print(f"Removed {name}")
    save_manifest(kept)
    if kept["written"]:
        sys.exit(f"{len(kept['written'])} file(s) left in place; see above (--forget NAME for each).")


def forget(name):
    """Drops `name` from the manifest and leaves the file itself untouched. Its backups stay on disk."""
    manifest = load_manifest()
    if name not in manifest["written"] and name not in manifest["backups"]:
        sys.exit(f"{name} is not in {MANIFEST}.")
    backups = manifest["backups"].pop(name, [])
    manifest["written"].pop(name, None)
    save_manifest(manifest)
    print(f"Forgot {name}; the file is left as it is" + (f", and {len(backups)} backup(s) stay in {BACKUP_DIR}" if backups else ""))


if __name__ == "__main__":
    with exclusive():
        if len(sys.argv) == 3 and sys.argv[1] == "--forget":
            forget(sys.argv[2])
        elif sys.argv[1:] == ["--remove"]:
            remove_all()
        elif sys.argv[1:] == ["--refresh"]:
            write_all(refresh=True)
        elif len(sys.argv) == 3 and sys.argv[1] == "--dir":
            write_into(sys.argv[2])
        elif len(sys.argv) == 4 and sys.argv[1] == "--dir" and sys.argv[3] == "--ci-shape":
            write_into(sys.argv[2], ci=True)
        elif not sys.argv[1:]:
            write_all()
        else:
            sys.exit(f"Usage: {sys.argv[0]} [--dir DIR [--ci-shape] | --refresh | --remove | --forget NAME]")
