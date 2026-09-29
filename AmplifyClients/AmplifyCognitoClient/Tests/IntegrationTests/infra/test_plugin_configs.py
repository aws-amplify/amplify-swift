#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""Self-tests for plugin-configs.py: the backup and --remove rules that keep a developer's own files safe.

    python3 infra/test_plugin_configs.py

Everything runs in temporary directories (COGNITO_CLIENT_INTEG_DIR and AWS_AMPLIFY_TESTCONFIGURATION_DIR
point there); the real state and testconfiguration directories are never read or written, and no AWS
call is made. The sandbox state is fake: placeholder ids only.
"""

import importlib.util
import json
import os
import shutil
import tempfile
import unittest

INFRA = os.path.dirname(os.path.abspath(__file__))
OWNER_FILE = "AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json"
WEBAUTHN_FILE = "AWSCognitoPluginWebAuthnIntegrationTests-amplify_outputs.json"
POOLS = ["default", "mfa-req-totp-sms", "passwordless", "mfa-req-email", "mfa-req-all", "email-alias", "hosted-ui",
         "webauthn"]


class Crash(Exception):
    pass


def fake_outputs(name):
    auth = {"aws_region": "xx-test-1", "user_pool_id": f"xx-test-1_{name}", "user_pool_client_id": f"client-{name}",
            "mfa_configuration": "OPTIONAL", "mfa_methods": ["TOTP"], "username_attributes": [],
            "user_verification_types": ["email"],
            "password_policy": {"min_length": 10, "require_lowercase": False, "require_uppercase": True,
                                "require_numbers": True, "require_symbols": True},
            "unauthenticated_identities_enabled": False}
    if name == "hosted-ui":
        auth["oauth"] = {"domain": "example.invalid", "scopes": ["openid"], "identity_providers": [],
                         "redirect_sign_in_uri": ["x://"], "redirect_sign_out_uri": ["x://"], "response_type": "code"}
    return {"version": "1.4", "auth": auth}


class PluginConfigsTests(unittest.TestCase):

    def setUp(self):
        self.root = tempfile.mkdtemp(prefix="plugin-configs-test.")
        self.state = os.path.join(self.root, "state")
        self.target = os.path.join(self.root, "testconfiguration")
        os.makedirs(self.state)
        os.makedirs(self.target)
        with open(os.path.join(self.state, "state.json"), "w") as f:
            json.dump({"region": "xx-test-1", "parity": {
                "codeSinkUrl": "https://example.invalid/graphql", "pluginIdentityPoolId": "xx-test-1:identity",
                "pools": {"default": {"clients": {"plugin": "client-plugin", "hostedui-plugin": "client-hosted"}}}}}, f)
        with open(os.path.join(self.state, "users.json"), "w") as f:
            json.dump({"codeSinkApiKey": "key-1", "pluginDeviceAliasPassword": "password", "customChallengeAnswer": "answer", "pluginNewPasswordTemporary": "temporary"}, f)
        for name in POOLS:
            with open(os.path.join(self.state, f"{name}-amplify_outputs.json"), "w") as f:
                json.dump(fake_outputs(name), f)
        with open(os.path.join(self.state, "identity-only-amplify_outputs.json"), "w") as f:
            json.dump({"version": "1.4", "auth": {"aws_region": "xx-test-1", "identity_pool_id": "xx-test-1:guest-only",
                                                  "unauthenticated_identities_enabled": True}}, f)
        os.environ["COGNITO_CLIENT_INTEG_DIR"] = self.state
        os.environ["AWS_AMPLIFY_TESTCONFIGURATION_DIR"] = self.target
        spec = importlib.util.spec_from_file_location("plugin_configs", os.path.join(INFRA, "plugin-configs.py"))
        self.pc = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.pc)

    def tearDown(self):
        del os.environ["COGNITO_CLIENT_INTEG_DIR"]
        del os.environ["AWS_AMPLIFY_TESTCONFIGURATION_DIR"]
        shutil.rmtree(self.root)

    # Helpers

    def put(self, name, content):
        with open(os.path.join(self.target, name), "w") as f:
            f.write(content)

    def read(self, name):
        with open(os.path.join(self.target, name)) as f:
            return f.read()

    def manifest(self):
        with open(os.path.join(self.state, "plugin-configs-manifest.json")) as f:
            return json.load(f)

    def quiet(self, function):
        import contextlib
        import io
        with contextlib.redirect_stdout(io.StringIO()) as out:
            function()
        return out.getvalue()

    def crash_on_write(self, name):
        """Makes the write of `name` into the target directory raise, as a crash at that point would."""
        original = self.pc.write_private

        def write_private(path, data):
            if path == os.path.join(self.target, name):
                raise Crash()
            original(path, data)
        self.pc.write_private = write_private
        return original

    # Tests

    def test_owner_file_is_backed_up_and_restored(self):
        self.put(OWNER_FILE, "owner April file")
        self.quiet(self.pc.write_all)
        self.assertNotEqual(self.read(OWNER_FILE), "owner April file")
        self.quiet(self.pc.remove_all)
        self.assertEqual(self.read(OWNER_FILE), "owner April file")
        self.assertEqual(os.listdir(self.target), [OWNER_FILE])

    def test_remove_restores_the_owner_file_mode_and_times(self):
        self.put(OWNER_FILE, "owner April file")
        path = os.path.join(self.target, OWNER_FILE)
        os.chmod(path, 0o644)
        os.utime(path, (1_700_000_000, 1_700_000_000))
        self.quiet(self.pc.write_all)
        self.quiet(self.pc.remove_all)
        self.assertEqual(os.stat(path).st_mode & 0o777, 0o644)
        self.assertEqual(int(os.stat(path).st_mtime), 1_700_000_000)

    def test_webauthn_name_is_backed_up_like_any_other(self):
        self.put(WEBAUTHN_FILE, "a real WebAuthn backend")
        self.quiet(self.pc.write_all)
        self.quiet(self.pc.remove_all)
        self.assertEqual(self.read(WEBAUTHN_FILE), "a real WebAuthn backend")

    def test_crash_before_the_owner_file_is_replaced_keeps_one_backup_of_it(self):
        self.put(OWNER_FILE, "owner April file")
        original = self.crash_on_write(OWNER_FILE)
        with self.assertRaises(Crash):
            self.quiet(self.pc.write_all)
        self.assertEqual(self.read(OWNER_FILE), "owner April file")
        self.pc.write_private = original
        self.quiet(self.pc.write_all)
        backups = self.manifest()["backups"][OWNER_FILE]
        self.assertEqual(len(backups), 1)
        with open(backups[0]["path"]) as f:
            self.assertEqual(f.read(), "owner April file")
        self.quiet(self.pc.remove_all)
        self.assertEqual(self.read(OWNER_FILE), "owner April file")

    def test_crash_after_the_owner_file_is_replaced_does_not_back_up_the_sandbox_copy(self):
        self.put(OWNER_FILE, "owner April file")
        original = self.crash_on_write("AWSCognitoAuthPluginHostedUIIntegrationTests-amplify_outputs.json")
        with self.assertRaises(Crash):
            self.quiet(self.pc.write_all)
        self.pc.write_private = original
        self.quiet(self.pc.write_all)
        self.assertEqual(len(self.manifest()["backups"][OWNER_FILE]), 1)
        self.quiet(self.pc.remove_all)
        self.assertEqual(self.read(OWNER_FILE), "owner April file")
        self.assertEqual(os.listdir(self.target), [OWNER_FILE])

    def test_backups_go_to_unique_folders(self):
        self.put(OWNER_FILE, "one")
        self.quiet(self.pc.write_all)
        self.quiet(self.pc.remove_all)
        self.quiet(self.pc.write_all)
        folders = os.listdir(os.path.join(self.state, "plugin-configs-backup"))
        self.assertEqual(len(folders), 2)
        self.assertEqual(len(set(folders)), 2)

    def test_an_owner_file_dropped_in_later_is_backed_up_again(self):
        self.put(OWNER_FILE, "owner April file")
        self.quiet(self.pc.write_all)
        self.put(OWNER_FILE, "owner September file")
        self.quiet(self.pc.write_all)
        backups = self.manifest()["backups"][OWNER_FILE]
        self.assertEqual(len(backups), 2)
        self.assertNotEqual(os.path.dirname(backups[0]["path"]), os.path.dirname(backups[1]["path"]))
        self.quiet(self.pc.remove_all)
        self.assertEqual(self.read(OWNER_FILE), "owner September file")
        with open(backups[0]["path"]) as f:
            self.assertEqual(f.read(), "owner April file")

    def test_remove_leaves_a_file_edited_since_it_was_written(self):
        self.put(OWNER_FILE, "owner April file")
        self.quiet(self.pc.write_all)
        self.put(OWNER_FILE, "owner edit")
        with self.assertRaises(SystemExit):
            self.quiet(self.pc.remove_all)
        self.assertEqual(self.read(OWNER_FILE), "owner edit")
        self.assertIn(OWNER_FILE, self.manifest()["written"])
        self.assertIn(OWNER_FILE, self.manifest()["backups"])
        # Everything else was removed.
        self.assertEqual(os.listdir(self.target), [OWNER_FILE])

    def test_remove_right_after_a_crash_keeps_the_untouched_owner_file(self):
        self.put(OWNER_FILE, "owner April file")
        self.crash_on_write(OWNER_FILE)
        with self.assertRaises(Crash):
            self.quiet(self.pc.write_all)
        self.quiet(self.pc.remove_all)
        self.assertEqual(self.read(OWNER_FILE), "owner April file")
        self.assertEqual(self.manifest(), {"written": {}, "backups": {}})

    def test_remove_without_a_manifest_changes_nothing(self):
        self.put(OWNER_FILE, "owner April file")
        self.quiet(self.pc.remove_all)
        self.assertEqual(self.read(OWNER_FILE), "owner April file")

    def test_second_run_writes_the_same_files(self):
        self.quiet(self.pc.write_all)
        first = {n: self.read(n) for n in os.listdir(self.target)}
        self.quiet(self.pc.write_all)
        self.assertEqual({n: self.read(n) for n in os.listdir(self.target)}, first)

    def test_refresh_picks_up_a_rotated_api_key(self):
        self.quiet(self.pc.write_all)
        with open(os.path.join(self.state, "users.json"), "w") as f:
            json.dump({"codeSinkApiKey": "key-2", "pluginDeviceAliasPassword": "password", "customChallengeAnswer": "answer", "pluginNewPasswordTemporary": "temporary"}, f)
        self.quiet(lambda: self.pc.write_all(refresh=True))
        data = json.loads(self.read("AWSCognitoPluginPasswordlessIntegrationTests-amplify_outputs.json"))["data"]
        self.assertEqual(data["api_key"], "key-2")
        # The manifest follows, so --remove still removes it.
        self.quiet(self.pc.remove_all)
        self.assertEqual(os.listdir(self.target), [])

    def test_refresh_leaves_files_it_did_not_write_or_that_changed(self):
        self.quiet(self.pc.write_all)
        self.put(OWNER_FILE, "owner file dropped in after the first run")
        with open(os.path.join(self.state, "users.json"), "w") as f:
            json.dump({"codeSinkApiKey": "key-2", "pluginDeviceAliasPassword": "password", "customChallengeAnswer": "answer", "pluginNewPasswordTemporary": "temporary"}, f)
        self.quiet(lambda: self.pc.write_all(refresh=True))
        self.assertEqual(self.read(OWNER_FILE), "owner file dropped in after the first run")

    def test_refresh_without_a_manifest_writes_nothing(self):
        self.quiet(lambda: self.pc.write_all(refresh=True))
        self.assertEqual(os.listdir(self.target), [])

    def test_an_owner_file_put_back_after_another_is_the_one_restored(self):
        self.put(OWNER_FILE, "X")
        self.quiet(self.pc.write_all)
        self.put(OWNER_FILE, "Y")
        self.quiet(self.pc.write_all)
        self.put(OWNER_FILE, "X")
        self.quiet(self.pc.write_all)
        self.assertEqual(len(self.manifest()["backups"][OWNER_FILE]), 3)
        self.quiet(self.pc.remove_all)
        self.assertEqual(self.read(OWNER_FILE), "X")

    def test_forget_keeps_an_edited_file_and_lets_remove_finish(self):
        self.put(OWNER_FILE, "owner April file")
        self.quiet(self.pc.write_all)
        self.put(OWNER_FILE, "owner edit")
        with self.assertRaises(SystemExit):
            self.quiet(self.pc.remove_all)
        self.quiet(lambda: self.pc.forget(OWNER_FILE))
        self.quiet(self.pc.remove_all)
        self.assertEqual(self.read(OWNER_FILE), "owner edit")
        self.assertEqual(self.manifest(), {"written": {}, "backups": {}})

    def test_remove_keeps_our_file_when_its_backup_is_missing(self):
        self.put(OWNER_FILE, "owner April file")
        self.quiet(self.pc.write_all)
        os.unlink(self.manifest()["backups"][OWNER_FILE][-1]["path"])
        with self.assertRaises(SystemExit):
            self.quiet(self.pc.remove_all)
        self.assertTrue(os.path.exists(os.path.join(self.target, OWNER_FILE)))
        self.assertIn(OWNER_FILE, self.manifest()["backups"])

    def test_an_old_manifest_with_a_missing_backup_loads(self):
        with open(os.path.join(self.state, "plugin-configs-manifest.json"), "w") as f:
            json.dump({"written": {OWNER_FILE: "0" * 64}, "backups": {OWNER_FILE: "/nonexistent/backup.json"}}, f)
        self.put(OWNER_FILE, "ours, as far as the old manifest knew")
        with self.assertRaises(SystemExit):
            self.quiet(self.pc.remove_all)
        self.assertTrue(os.path.exists(os.path.join(self.target, OWNER_FILE)))

    def test_a_failed_write_leaves_no_tmp_file(self):
        original = os.replace

        def failing_replace(src, dst):
            raise OSError("disk full")
        os.replace = failing_replace
        try:
            with self.assertRaises(OSError):
                self.quiet(self.pc.write_all)
        finally:
            os.replace = original
        self.assertEqual([n for n in os.listdir(self.target) if n.endswith(".tmp")], [])

    def test_a_second_run_waits_for_the_lock(self):
        import fcntl
        os.makedirs(self.state, exist_ok=True)
        with open(os.path.join(self.state, "plugin-configs.lock"), "w") as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            with self.assertRaises(SystemExit):
                with self.pc.exclusive():
                    pass

    def test_dir_writes_every_file_there_and_nothing_else(self):
        other = os.path.join(self.root, "client-harness")
        self.quiet(lambda: self.pc.write_into(other))
        written = sorted(os.listdir(other))
        self.assertEqual(written, sorted(self.pc.build()))
        for name in written:
            self.assertEqual(os.stat(os.path.join(other, name)).st_mode & 0o777, 0o600, name)
        # No manifest, no backups, and the default directory untouched.
        self.assertFalse(os.path.exists(os.path.join(self.state, "plugin-configs-manifest.json")))
        self.assertFalse(os.path.exists(os.path.join(self.state, "plugin-configs-backup")))
        self.assertEqual(os.listdir(self.target), [])
        self.assertEqual(os.stat(other).st_mode & 0o777, 0o700)

    def test_dir_overwrites_only_its_own_names(self):
        other = os.path.join(self.root, "client-harness")
        os.makedirs(other)
        with open(os.path.join(other, "unrelated.json"), "w") as f:
            f.write("kept")
        self.quiet(lambda: self.pc.write_into(other))
        self.quiet(lambda: self.pc.write_into(other))
        with open(os.path.join(other, "unrelated.json")) as f:
            self.assertEqual(f.read(), "kept")
        self.assertEqual(len(os.listdir(other)), len(self.pc.build()) + 1)

    def test_dir_naming_the_default_directory_keeps_the_manifest_and_backups(self):
        self.put(OWNER_FILE, "owner April file")
        self.quiet(lambda: self.pc.write_into(self.target))
        self.assertIn(OWNER_FILE, self.manifest()["backups"])
        self.quiet(self.pc.remove_all)
        self.assertEqual(self.read(OWNER_FILE), "owner April file")

    def test_dir_inside_the_default_directory_is_refused(self):
        with self.assertRaises(SystemExit):
            self.quiet(lambda: self.pc.write_into(os.path.join(self.target, "nested")))
        self.assertEqual(os.listdir(self.target), [])

    def test_every_outputs_file_has_the_code_sink_and_the_credentials_name_a_second_identity_pool(self):
        other = os.path.join(self.root, "client-harness")
        self.quiet(lambda: self.pc.write_into(other))
        outputs = [n for n in os.listdir(other) if n.endswith("-amplify_outputs.json")]
        self.assertEqual(len(outputs), 8)
        for name in outputs:
            with open(os.path.join(other, name)) as f:
                data = json.load(f)["data"]
            self.assertEqual((data["url"], data["api_key"]), ("https://example.invalid/graphql", "key-1"), name)
        with open(os.path.join(other, "AWSCognitoAuthPluginIntegrationTests-credentials.json")) as f:
            credentials = json.load(f)
        self.assertEqual(credentials["second_identity_pool_id"], "xx-test-1:guest-only")
        with open(os.path.join(other, "AWSCognitoAuthPluginIntegrationTests-amplify_outputs.json")) as f:
            self.assertNotEqual(json.load(f)["auth"]["identity_pool_id"], credentials["second_identity_pool_id"])

    def test_dir_refuses_the_owner_directory_whatever_the_configured_one(self):
        # The configured directory is this test's temporary one, yet the developer's own directory, by its
        # literal path, and any directory inside it are refused before anything is read or written.
        owner = os.path.expanduser("~/.aws-amplify/amplify-ios/testconfiguration")
        nested = os.path.join(owner, "ccit-test-never-created")
        for directory in (owner, nested, owner + "/"):
            with self.assertRaises(SystemExit):
                self.quiet(lambda: self.pc.write_into(directory))
            with self.assertRaises(SystemExit):
                self.quiet(lambda: self.pc.write_into(directory, ci=True))
        self.assertFalse(os.path.exists(nested))
        self.assertEqual(os.listdir(self.target), [])

    def test_ci_shape_is_refused_for_the_configured_directory(self):
        with self.assertRaises(SystemExit):
            self.quiet(lambda: self.pc.write_into(self.target, ci=True))
        self.assertEqual(os.listdir(self.target), [])

    def test_ci_shape_has_data_only_on_the_code_capturing_backends(self):
        other = os.path.join(self.root, "ci-shape")
        self.quiet(lambda: self.pc.write_into(other, ci=True))
        self.assertEqual(sorted(os.listdir(other)), sorted(self.pc.build()))
        with_data = set()
        for name in os.listdir(other):
            if name.endswith("-amplify_outputs.json"):
                with open(os.path.join(other, name)) as f:
                    if "data" in json.load(f):
                        with_data.add(name)
        self.assertEqual(with_data, set(self.pc.CI_CODE_CAPTURING))
        self.assertEqual(with_data, {"AWSCognitoPluginPasswordlessIntegrationTests-amplify_outputs.json",
                                     "AWSCognitoEmailMFARequiredTests-amplify_outputs.json",
                                     "AWSCognitoAuthEmailMFAWithAllMFATypesRequired-amplify_outputs.json"})

    def test_ci_shape_credentials_carry_only_the_keys_ci_has(self):
        other = os.path.join(self.root, "ci-shape")
        self.quiet(lambda: self.pc.write_into(other, ci=True))
        for name in [n for n in os.listdir(other) if n.endswith("-credentials.json")]:
            with open(os.path.join(other, name)) as f:
                keys = set(json.load(f))
            self.assertTrue(keys <= {"test_email_1", "password"}, f"{name}: {sorted(keys)}")
        with open(os.path.join(other, "AWSCognitoAuthPluginIntegrationTests-credentials.json")) as f:
            self.assertEqual(set(json.load(f)), {"test_email_1"})

    def test_full_shape_keeps_the_sandbox_extras(self):
        other = os.path.join(self.root, "full-shape")
        self.quiet(lambda: self.pc.write_into(other))
        with open(os.path.join(other, "AWSCognitoAuthPluginIntegrationTests-credentials.json")) as f:
            keys = set(json.load(f))
        self.assertEqual(keys, {"test_email_1", "custom_challenge_answer", "new_password_required_usernames",
                                "new_password_required_temporary_password", "second_identity_pool_id"})

    def test_refresh_says_to_rebuild_only_when_it_rewrote(self):
        self.quiet(self.pc.write_all)
        self.assertNotIn("rebuild", self.quiet(lambda: self.pc.write_all(refresh=True)))
        with open(os.path.join(self.state, "users.json"), "w") as f:
            json.dump({"codeSinkApiKey": "key-2", "pluginDeviceAliasPassword": "password",
                       "customChallengeAnswer": "answer", "pluginNewPasswordTemporary": "temporary"}, f)
        self.assertIn("rebuild", self.quiet(lambda: self.pc.write_all(refresh=True)))


if __name__ == "__main__":
    unittest.main(verbosity=2)
