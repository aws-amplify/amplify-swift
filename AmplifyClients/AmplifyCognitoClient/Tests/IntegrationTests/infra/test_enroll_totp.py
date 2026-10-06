#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""Self-tests for enroll_totp.py's output hygiene: the sign-in's refresh token is revoked, exactly once, whether
enrollment succeeds or a step after the sign-in fails; no pool identifier is printed; and AWS CLI errors go
through parity.py's redaction.

    python3 infra/test_enroll_totp.py

No AWS call is made: enroll_totp.aws (or, for the error test, subprocess.run) is replaced by a fake, and
USERS_FILE is a temporary file (placeholder values only).
"""

import importlib.util
import io
import json
import os
import shutil
import subprocess
import tempfile
import unittest
from unittest import mock

INFRA = os.path.dirname(os.path.abspath(__file__))
POOL = "us-west-2_placeholder"
REFRESH_TOKEN = "placeholder-refresh-token"


class EnrollTOTPTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.mkdtemp()
        self.users_file = os.path.join(self.directory, "users.json")
        with open(self.users_file, "w") as f:
            json.dump({"carol": "placeholder-password"}, f)
        self.saved_environment = dict(os.environ)
        os.environ.update({"REGION": "us-west-2", "USER_POOL_ID": POOL, "CLIENT_ID": "placeholder-client",
                           "USERS_FILE": self.users_file, "TAG_KEY": "purpose", "TAG_VALUE": "placeholder-tag"})
        spec = importlib.util.spec_from_file_location("enroll_totp", os.path.join(INFRA, "enroll_totp.py"))
        self.enroll = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.enroll)
        self.calls = []
        self.tagged = True
        self.verify_status = "SUCCESS"
        self.failing = set()
        self.raising = set()
        self.real_aws = self.enroll.aws
        self.enroll.aws = self.fake_aws

    def tearDown(self):
        shutil.rmtree(self.directory)
        os.environ.clear()
        os.environ.update(self.saved_environment)

    def fake_aws(self, *args, stdin=None):
        operation = args[1]
        self.calls.append((operation, stdin))
        if operation in self.failing:
            raise SystemExit(f"aws cognito-idp {operation} failed: placeholder")
        if operation in self.raising:
            raise ValueError(f"{operation} output could not be read: {REFRESH_TOKEN}")
        if operation == "describe-user-pool":
            return {"UserPool": {"UserPoolTags": {"purpose": "placeholder-tag"} if self.tagged else {}}}
        if operation == "admin-get-user":
            return {}
        if operation == "initiate-auth":
            return {"AuthenticationResult": {"AccessToken": "placeholder-access-token", "RefreshToken": REFRESH_TOKEN}}
        if operation == "associate-software-token":
            return {"SecretCode": "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"}
        if operation == "verify-software-token":
            return {"Status": self.verify_status}
        return {}

    def revocations(self):
        return [stdin["Token"] for operation, stdin in self.calls if operation == "revoke-token"]

    def test_a_successful_enrollment_revokes_once(self):
        """Given: every call succeeds. When: main runs. Then: the refresh token is revoked once, last."""
        self.enroll.main()
        self.assertEqual(self.revocations(), [REFRESH_TOKEN])
        self.assertEqual(self.calls[-1][0], "revoke-token")

    def test_a_failed_step_still_revokes_once_and_exits_with_its_own_failure(self):
        """Given: VerifySoftwareToken does not succeed, or AssociateSoftwareToken fails. When: main runs.
        Then: it exits with the step's failure, and the refresh token is still revoked, exactly once."""
        for fail in ("verify", "associate-software-token", "admin-set-user-mfa-preference"):
            with self.subTest(fail):
                self.calls = []
                self.failing = set() if fail == "verify" else {fail}
                self.verify_status = "ERROR" if fail == "verify" else "SUCCESS"
                with self.assertRaises(SystemExit) as exit:
                    self.enroll.main()
                self.assertIn("VerifySoftwareToken" if fail == "verify" else fail, str(exit.exception.code))
                self.assertEqual(self.revocations(), [REFRESH_TOKEN])

    def test_a_failed_revocation_after_a_failed_step_keeps_the_steps_failure(self):
        """Given: VerifySoftwareToken does not succeed, and RevokeToken fails too. When: main runs.
        Then: it exits with the verification's failure, not the revocation's."""
        self.verify_status = "ERROR"
        self.failing = {"revoke-token"}
        with self.assertRaises(SystemExit) as exit:
            self.enroll.main()
        self.assertIn("VerifySoftwareToken", str(exit.exception.code))

    def test_any_exception_from_the_revocation_after_a_failed_step_keeps_the_steps_failure(self):
        """Given: VerifySoftwareToken does not succeed, and the revocation raises an exception other than an
        exit, whose text holds the token. When: main runs. Then: it exits with the verification's failure,
        and the report names only the exception's type."""
        self.verify_status = "ERROR"
        self.raising = {"revoke-token"}
        with mock.patch("sys.stderr", new_callable=io.StringIO) as stderr, self.assertRaises(SystemExit) as exit:
            self.enroll.main()
        self.assertIn("VerifySoftwareToken", str(exit.exception.code))
        self.assertIn("ValueError", stderr.getvalue())
        self.assertNotIn(REFRESH_TOKEN, stderr.getvalue())

    def test_a_failed_revocation_after_enrollment_fails_the_run(self):
        """Given: enrollment succeeds, and RevokeToken fails. When: main runs. Then: it exits with the failure."""
        self.failing = {"revoke-token"}
        with self.assertRaises(SystemExit) as exit:
            self.enroll.main()
        self.assertIn("revoke-token", str(exit.exception.code))

    def test_an_untagged_pool_is_refused_without_naming_it(self):
        """Given: the pool lacks the purpose tag. When: the tag is checked. Then: the refusal names no pool."""
        self.tagged = False
        with self.assertRaises(SystemExit) as exit:
            self.enroll.require_pool_tag()
        self.assertIn("Refusing", str(exit.exception.code))
        self.assertNotIn(POOL, str(exit.exception.code))

    def test_cli_errors_are_redacted(self):
        """Given: the CLI fails with an error naming the pool, an account and an email address.
        When: a call runs. Then: the exit message holds none of them."""
        stderr = f"An error occurred (NotAuthorizedException): {POOL} in 000000000000 for user@example.com"
        failed = subprocess.CompletedProcess([], 255, "", stderr)
        with mock.patch("subprocess.run", return_value=failed), self.assertRaises(SystemExit) as exit:
            self.real_aws("cognito-idp", "admin-get-user", "--user-pool-id", POOL)
        message = str(exit.exception.code)
        for value in (POOL, "000000000000", "user@example.com"):
            self.assertNotIn(value, message)
        self.assertIn("NotAuthorizedException", message)


if __name__ == "__main__":
    unittest.main()
