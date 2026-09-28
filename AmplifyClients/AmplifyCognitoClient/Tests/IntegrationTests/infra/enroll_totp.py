#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""Enrolls carol in TOTP MFA and makes it her preferred factor (sandbox resource P-2).

Run by provision.sh, which passes REGION, USER_POOL_ID, CLIENT_ID, USERS_FILE, TAG_KEY and
TAG_VALUE in the environment. Skipped when carol is already enrolled and users.json still holds her
secret. If she is enrolled but the secret is lost, TOTP is switched off for her first, so that she
can sign in with her password alone and enroll again.

Steps: USER_PASSWORD_AUTH sign-in, AssociateSoftwareToken, a code computed from the secret,
VerifySoftwareToken, AdminSetUserMFAPreference, then RevokeToken so that no refresh token is left
behind, also when a step after the sign-in fails. Every mutating call is preceded by a check of the
pool's purpose tag. Secrets and tokens reach the AWS CLI through --cli-input-json, from a mode-600
file next to users.json that is deleted straight after the call, never as arguments, and are never
printed. The secret is written only to users.json (mode 600), as carolTotpSecret. No pool
identifier is printed, and AWS CLI errors go through parity.py's redaction.
"""

import base64
import hashlib
import hmac
import json
import os
import struct
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from parity import redact, require_aws_profile  # noqa: E402  (parity.py's redaction and profile guard)

REGION = os.environ["REGION"]
POOL = os.environ["USER_POOL_ID"]
CLIENT = os.environ["CLIENT_ID"]
USERS_FILE = os.environ["USERS_FILE"]
TAG_KEY = os.environ["TAG_KEY"]
TAG_VALUE = os.environ["TAG_VALUE"]
USER = "carol"
SECRET_KEY = "carolTotpSecret"


def aws(*args, stdin=None):
    """Runs one AWS CLI call. Secrets travel in `stdin`, through a mode-600 temporary file (the CLI
    cannot read --cli-input-json from /dev/stdin); the error printed is the CLI's last line, redacted."""
    command = ["aws", "--region", REGION, "--output", "json", *args]
    if stdin is None:
        result = subprocess.run(command, capture_output=True, text=True)
    else:
        with tempfile.NamedTemporaryFile("w", dir=os.path.dirname(USERS_FILE), prefix=".cli-input.",
                                         suffix=".json") as f:
            json.dump(stdin, f)
            f.flush()
            result = subprocess.run(command + ["--cli-input-json", f"file://{f.name}"],
                                    capture_output=True, text=True)
    if result.returncode != 0:
        lines = result.stderr.strip().splitlines()
        sys.exit(f"aws {args[0]} {args[1]} failed: {redact(lines[-1]) if lines else result.returncode}")
    return json.loads(result.stdout) if result.stdout.strip() else {}


def require_pool_tag():
    tags = aws("cognito-idp", "describe-user-pool", "--user-pool-id", POOL)["UserPool"].get("UserPoolTags") or {}
    if tags.get(TAG_KEY) != TAG_VALUE:
        sys.exit(f"Refusing: the user pool is not tagged {TAG_KEY}={TAG_VALUE}.")


def totp(secret, at=None):
    """RFC 6238: HMAC-SHA1, 30-second steps, 6 digits. The same algorithm the tests use."""
    key = base64.b32decode(secret.upper() + "=" * (-len(secret) % 8))
    counter = int((time.time() if at is None else at) // 30)
    digest = hmac.new(key, struct.pack(">Q", counter), hashlib.sha1).digest()
    offset = digest[-1] & 0x0F
    code = (struct.unpack(">I", digest[offset:offset + 4])[0] & 0x7FFFFFFF) % 1_000_000
    return f"{code:06d}"


def load_users():
    with open(USERS_FILE) as f:
        return json.load(f)


def save_users(users):
    tmp = USERS_FILE + ".tmp"
    with os.fdopen(os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "w") as f:
        json.dump(users, f, sort_keys=True)
        f.write("\n")
    os.replace(tmp, USERS_FILE)
    os.chmod(USERS_FILE, 0o600)


def set_totp(enabled):
    require_pool_tag()
    flag = "true" if enabled else "false"
    aws("cognito-idp", "admin-set-user-mfa-preference", "--user-pool-id", POOL, "--username", USER,
        "--software-token-mfa-settings", f"Enabled={flag},PreferredMfa={flag}")


def main():
    users = load_users()
    user = aws("cognito-idp", "admin-get-user", "--user-pool-id", POOL, "--username", USER)
    has_totp = "SOFTWARE_TOKEN_MFA" in (user.get("UserMFASettingList") or [])
    preferred = user.get("PreferredMfaSetting") == "SOFTWARE_TOKEN_MFA"
    if has_totp and preferred and users.get(SECRET_KEY):
        print(f"{USER}: TOTP already enrolled and preferred")
        return
    if has_totp:
        set_totp(False)
        print(f"{USER}: TOTP switched off to re-enroll")

    require_pool_tag()
    auth = aws("cognito-idp", "initiate-auth", stdin={
        "AuthFlow": "USER_PASSWORD_AUTH",
        "ClientId": CLIENT,
        "AuthParameters": {"USERNAME": USER, "PASSWORD": users[USER]},
    })
    tokens = auth.get("AuthenticationResult")
    if not tokens:
        # Nothing to revoke: a challenge issues no tokens.
        sys.exit(f"{USER}: expected tokens from sign-in, got the challenge {auth.get('ChallengeName')}")

    enrolled = False
    try:
        enroll(tokens)
        enrolled = True
    finally:
        # Also after a failed step (every failure here is a sys.exit), so no refresh token is left behind.
        revoke(tokens, reporting_failure_only=not enrolled)
    print(f"{USER}: TOTP enrolled and preferred; secret stored in users.json")


def revoke(tokens, reporting_failure_only=False):
    """Revokes the sign-in's refresh token. After a failed step, any failure to revoke (an exit or any
    other exception) is only reported, so that the step's own failure is the one the script exits with."""
    refresh_token = tokens.get("RefreshToken")
    if not refresh_token:
        return
    try:
        require_pool_tag()
        aws("cognito-idp", "revoke-token", stdin={"Token": refresh_token, "ClientId": CLIENT})
    except (SystemExit, Exception) as failure:
        if not reporting_failure_only:
            raise
        # An exit's message is the script's own (redacted); another exception's text is not, so only its type.
        reason = failure.code if isinstance(failure, SystemExit) else type(failure).__name__
        print(f"{USER}: the refresh token was not revoked: {reason}", file=sys.stderr)


def enroll(tokens):
    """AssociateSoftwareToken, VerifySoftwareToken, then TOTP switched on as carol's preferred factor."""
    require_pool_tag()
    secret = aws("cognito-idp", "associate-software-token", stdin={"AccessToken": tokens["AccessToken"]})["SecretCode"]
    require_pool_tag()
    status = aws("cognito-idp", "verify-software-token", stdin={
        "AccessToken": tokens["AccessToken"],
        "UserCode": totp(secret),
        "FriendlyDeviceName": "amplify-cognito-client-integ",
    }).get("Status")
    if status != "SUCCESS":
        sys.exit(f"{USER}: VerifySoftwareToken returned {status}")
    # Saved before TOTP is switched on, so a failure from here on cannot lose the verified secret.
    users = load_users()
    users[SECRET_KEY] = secret
    save_users(users)
    set_totp(True)


if __name__ == "__main__":
    require_aws_profile()
    main()
