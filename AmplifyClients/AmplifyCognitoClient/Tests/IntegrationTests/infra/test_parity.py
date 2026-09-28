#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""Self-tests for parity.py's self sign-up rules: preflight and verify refuse a missing pool or one whose
self sign-up differs from its template, and provision never re-enables it without the explicit opt-in; and
the reset of the plugin's new-password users tolerates an overlapping run; and the WebAuthn harness's committed
relying party and app ID are found, and provision never switches a live WebAuthn pool off.

    python3 infra/test_parity.py

No AWS call is made: parity.aws and parity.aws_or_none are replaced by fakes, and COGNITO_CLIENT_INTEG_DIR
points at a temporary directory with a fake state.json (placeholder ids only).
"""

import importlib.util
import json
import os
import re
import shutil
import tempfile
import unittest

INFRA = os.path.dirname(os.path.abspath(__file__))
REENABLE = "COGNITO_CLIENT_INTEG_REENABLE_SELF_SIGN_UP"


def described(admin_only):
    return {"AdminCreateUserConfig": {"AllowAdminCreateUserOnly": admin_only}}


class ParitySelfSignUpTests(unittest.TestCase):
    def setUp(self):
        os.environ.pop(REENABLE, None)
        self.state = tempfile.mkdtemp()
        os.environ["COGNITO_CLIENT_INTEG_DIR"] = self.state
        spec = importlib.util.spec_from_file_location("parity", os.path.join(INFRA, "parity.py"))
        self.parity = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.parity)
        self.pools = {key: f"placeholder-{key}" for key in self.parity.POOLS}
        self.write_state(self.pools)
        self.admin_only = {key: False for key in self.pools}
        self.gone = set()
        self.said = []
        self.parity.say = self.said.append
        self.real_aws_or_none = self.parity.aws_or_none
        self.parity.aws_or_none = self.fake_describe
        self.parity.aws = self.fail_on_call

    def tearDown(self):
        shutil.rmtree(self.state)
        del os.environ["COGNITO_CLIENT_INTEG_DIR"]
        os.environ.pop(REENABLE, None)

    def write_state(self, pools):
        with open(os.path.join(self.state, "state.json"), "w") as f:
            json.dump({"account": "000000000000", "region": "us-west-2",
                       "parity": {"pools": {k: {"userPoolId": v} for k, v in pools.items()}}}, f)

    def fake_describe(self, *args, **kwargs):
        self.assertEqual(args[:2], ("cognito-idp", "describe-user-pool"))
        key = next(k for k, v in self.pools.items() if v == args[-1])
        if key in self.gone:
            return None
        return {"UserPool": dict(described(self.admin_only[key]), Name=key)}

    def fail_on_call(self, *args, **kwargs):
        self.fail(f"unexpected AWS call {args[:2]}")

    def gaps(self):
        return self.parity.live_self_sign_up_gaps(self.parity.load_state())

    # --- the check -----------------------------------------------------------------------------------

    def test_every_template_states_and_allows_self_sign_up(self):
        """Given: pools/*.json. Then: every parity template states the flag and allows self sign-up."""
        for key in self.pools:
            config = self.parity.load_template(key)["userPool"]["AdminCreateUserConfig"]
            self.assertIs(config["AllowAdminCreateUserOnly"], False, key)
            self.assertTrue(self.parity.template_self_sign_up(self.parity.load_template(key)), key)

    def test_template_without_the_flag_is_refused(self):
        """Given: a template whose AdminCreateUserConfig does not state the flag. Then: it is refused."""
        with self.assertRaises(SystemExit):
            self.parity.template_self_sign_up({"userPool": {"AdminCreateUserConfig": {}}})

    def test_no_gap_when_every_pool_matches(self):
        """Given: every live pool allows self sign-up. Then: no gap."""
        self.assertEqual(self.gaps(), [])

    def test_gap_for_each_pool_switched_off(self):
        """Given: five pools switched to admin-only, as the 2026-09-26 mitigation did.
        Then: exactly those five are DRIFT, sorted, and default and mfa-req-all are not reported."""
        off = ["passwordless", "email-alias", "mfa-req-email", "mfa-req-totp-sms", "webauthn"]
        for key in off:
            self.admin_only[key] = True
        gaps = self.gaps()
        self.assertEqual([(kind, gap.split(":")[0]) for kind, gap in gaps], [("DRIFT", k) for k in sorted(off)])
        self.assertTrue(all("self sign-up is off" in gap for _, gap in gaps))

    def test_missing_from_state_and_gone_pools_are_reported(self):
        """Given: one POOLS key not in state.json and one recorded pool that no longer exists.
        Then: both are MISSING."""
        recorded = dict(self.pools)
        del recorded["webauthn"]
        self.write_state(recorded)
        self.gone.add("email-alias")
        self.assertEqual(sorted(self.gaps()), [
            ("MISSING", "email-alias: the recorded pool no longer exists; run infra/provision.sh"),
            ("MISSING", "webauthn: no pool recorded in state.json; run infra/provision.sh")])

    def test_unstated_live_flag_is_a_gap(self):
        """Given: a live pool whose AdminCreateUserConfig does not state the flag. Then: it is DRIFT, not allowed."""
        gaps = self.parity.self_sign_up_gaps({"a": True}, {"a"}, {"a": {"AdminCreateUserConfig": {}}})
        self.assertEqual(gaps, [("DRIFT", "a: the pool does not state whether self sign-up is allowed")])

    def test_unexpected_self_sign_up_is_a_gap(self):
        """Given: a template forbidding self sign-up and a live pool allowing it. Then: it is DRIFT."""
        gaps = self.parity.self_sign_up_gaps({"b": False}, {"b"}, {"b": described(False)})
        self.assertEqual(gaps, [("DRIFT", "b: self sign-up is on, but pools/b.json does not allow it")])

    def test_access_denied_stops_the_check_and_preflight(self):
        """Given: DescribeUserPool fails with AccessDenied (not "not found").
        When: the check, then preflight, runs through the real aws_or_none.
        Then: both raise instead of treating the pool as fine or gone; a NotFound, by contrast, is MISSING."""
        self.parity.aws_or_none = self.real_aws_or_none
        self.parity.aws = self.raising("AccessDeniedException")
        with self.assertRaises(self.parity.AwsError) as raised:
            self.gaps()
        self.assertEqual(raised.exception.code, "AccessDeniedException")

        self.stub_preflight_prerequisites()
        self.parity.aws = self.raising("AccessDeniedException")
        with self.assertRaises(self.parity.AwsError):
            self.parity.preflight()

        self.parity.aws = self.raising("ResourceNotFoundException")
        self.assertEqual({kind for kind, _ in self.gaps()}, {"MISSING"})

    def raising(self, code):
        def call(*args, **kwargs):
            if args[:1] == ("sns",):
                return {"IsInSandbox": True}
            raise self.parity.AwsError(code, "placeholder")
        return call

    # --- exits ---------------------------------------------------------------------------------------

    def test_exit_on_gaps_for_verify_and_preflight(self):
        """Given: DRIFT only, UNSAFE only, or nothing. When: exit_on_gaps runs for verify and preflight.
        Then: DRIFT alone and UNSAFE alone exit non-zero for both, the DRIFT message names the opt-in, and
        no gap returns normally."""
        drift = [("DRIFT", "webauthn: self sign-up is off")]
        for command in ("verify", "preflight"):
            with self.assertRaises(SystemExit) as refused:
                self.parity.exit_on_gaps(command, [], drift)
            self.assertTrue(refused.exception.code, command)
            self.assertIn(REENABLE, str(refused.exception.code))
            with self.assertRaises(SystemExit) as refused:
                self.parity.exit_on_gaps(command, ["x: DEVELOPER email"], [])
            self.assertTrue(refused.exception.code, command)
            self.assertIsNone(self.parity.exit_on_gaps(command, [], []))
        self.assertIn("DRIFT webauthn: self sign-up is off", self.said)

    def test_verify_uses_the_shared_exit(self):
        """Given: parity.py. Then: verify and preflight both end their checks with exit_on_gaps and the live
        self sign-up gaps (so the tested exit is the one they take)."""
        with open(os.path.join(INFRA, "parity.py")) as f:
            source = f.read()
        self.assertIn('exit_on_gaps("verify", gaps, live_self_sign_up_gaps(state))', source)
        self.assertIn('exit_on_gaps("preflight", gaps, live_self_sign_up_gaps(state))', source)

    def stub_preflight_prerequisites(self):
        for name in ("require_cli_history_off", "require_recorded_account"):
            setattr(self.parity, name, lambda *args: None)
        for name in ("live_sender_gaps", "ses_gaps", "wildcard_gaps"):
            setattr(self.parity, name, lambda *args: [])
        self.parity.aws = lambda *args, **kwargs: {"IsInSandbox": True}

    def test_preflight_refuses_on_drift(self):
        """Given: no unsafe setting, but one pool with self sign-up off.
        When: preflight runs. Then: it exits non-zero naming the opt-in; with no drift it passes."""
        self.stub_preflight_prerequisites()
        self.admin_only["webauthn"] = True
        with self.assertRaises(SystemExit) as refused:
            self.parity.preflight()
        self.assertIn(REENABLE, str(refused.exception.code))
        self.admin_only["webauthn"] = False
        self.parity.preflight()

    # --- provision -----------------------------------------------------------------------------------

    def test_config_to_send(self):
        """Given: a template allowing self sign-up, with another AdminCreateUserConfig field.
        When: the config to send is computed for a pool that is off, unstated, or on, with and without the opt-in.
        Then: it stays off (keeping the other field) unless the pool is on or the opt-in is set."""
        wanted = {"AdminCreateUserConfig": {"AllowAdminCreateUserOnly": False, "InviteMessageTemplate": {"x": 1}}}
        send = self.parity.admin_create_user_config_to_send
        kept = {"AllowAdminCreateUserOnly": True, "InviteMessageTemplate": {"x": 1}}
        self.assertEqual(send(wanted, described(True), False), (kept, True))
        self.assertEqual(send(wanted, {"AdminCreateUserConfig": {}}, False), (kept, True))
        self.assertEqual(send(wanted, described(True), True), (wanted["AdminCreateUserConfig"], False))
        self.assertEqual(send(wanted, described(False), False), (wanted["AdminCreateUserConfig"], False))
        admin_only = {"AdminCreateUserConfig": {"AllowAdminCreateUserOnly": True}}
        self.assertEqual(send(admin_only, described(False), False), (admin_only["AdminCreateUserConfig"], False))

    def run_ensure_user_pool(self, current_admin_only, reenable, other_drift=True):
        template = self.parity.load_template("passwordless")
        # The live pool matches the template except for self sign-up (and, if asked, a stale trigger).
        current = dict(template["userPool"], **described(current_admin_only),
                       UserPoolTags={"purpose": self.parity.TAG_VALUE})
        if other_drift:
            current["LambdaConfig"] = {}
        calls = []
        self.parity.find_user_pool = lambda *args: "placeholder-passwordless"
        self.parity.require_user_pool_tag = lambda *args: current
        self.parity.aws = lambda *args, stdin=None, **kwargs: calls.append((args, stdin))
        if reenable:
            os.environ[REENABLE] = "1"
        self.parity.ensure_user_pool("passwordless", template, {})
        return template, [stdin for args, stdin in calls if args[:2] == ("cognito-idp", "update-user-pool")]

    def test_provision_does_not_undo_a_mitigation(self):
        """Given: a pool whose self sign-up was turned off, and another field drifted.
        When: ensure_user_pool updates it without the opt-in.
        Then: the one update equals the template's updatable fields except that the flag stays true."""
        template, updates = self.run_ensure_user_pool(current_admin_only=True, reenable=False)
        self.assertEqual(len(updates), 1)
        expected = {k: v for k, v in template["userPool"].items() if k in self.parity.UPDATE_KEYS}
        expected["AdminCreateUserConfig"] = dict(expected["AdminCreateUserConfig"], AllowAdminCreateUserOnly=True)
        body = {k: v for k, v in updates[0].items() if k not in ("UserPoolId", "PoolName", "UserPoolTags")}
        self.assertEqual(body, expected)

    def test_kept_off_with_nothing_else_drifted_makes_no_update(self):
        """Given: a pool whose only difference from the template is self sign-up off.
        When: ensure_user_pool runs without the opt-in. Then: no update is made."""
        _, updates = self.run_ensure_user_pool(current_admin_only=True, reenable=False, other_drift=False)
        self.assertEqual(updates, [])

    def test_provision_reenables_with_opt_in(self):
        """Given: the same pool. When: ensure_user_pool runs with the opt-in.
        Then: the update restores the template's self sign-up."""
        _, updates = self.run_ensure_user_pool(current_admin_only=True, reenable=True, other_drift=False)
        self.assertEqual(len(updates), 1)
        self.assertIs(updates[0]["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"], False)


class NewPasswordUserResetTests(unittest.TestCase):
    """reset_new_password_user (P-14's testNewPasswordRequired users) and delete_user_if_present, over a
    scripted Cognito: every call is recorded, and each mutating call must follow a tag check."""

    POOL = "placeholder-default"
    USER = "ccit-plugin-new-password-1"

    def setUp(self):
        self.state = tempfile.mkdtemp()
        os.environ["COGNITO_CLIENT_INTEG_DIR"] = self.state
        spec = importlib.util.spec_from_file_location("parity", os.path.join(INFRA, "parity.py"))
        self.parity = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.parity)
        self.calls = []
        self.existing = None
        self.create_errors = []
        self.set_errors = []
        self.delete_error = None
        self.gets = []
        self.pool_tagged = True
        self.parity.aws = self.fake_aws
        self.real_require_user_pool_tag = self.parity.require_user_pool_tag
        self.parity.require_user_pool_tag = self.fake_tag_check

    def tearDown(self):
        shutil.rmtree(self.state)
        del os.environ["COGNITO_CLIENT_INTEG_DIR"]

    def fake_tag_check(self, pool_id, label):
        self.calls.append(("tag-check", pool_id))
        self.real_require_user_pool_tag(pool_id, label)

    def fake_aws(self, *args, stdin=None, **kwargs):
        operation = args[1]
        if operation == "describe-user-pool":
            tags = {self.parity.TAG_KEY: self.parity.TAG_VALUE} if self.pool_tagged else {}
            return {"UserPool": {"UserPoolTags": tags}}
        self.calls.append((operation, stdin))
        if operation == "admin-get-user":
            existing = self.gets.pop(0) if self.gets else self.existing
            if existing is None:
                raise self.parity.AwsError("UserNotFoundException", "User does not exist.")
            return existing
        if operation == "admin-delete-user" and self.delete_error:
            raise self.parity.AwsError(self.delete_error, "scripted")
        if operation == "admin-create-user" and self.create_errors:
            raise self.parity.AwsError(self.create_errors.pop(0), "scripted")
        if operation == "admin-set-user-password" and self.set_errors:
            raise self.parity.AwsError(self.set_errors.pop(0), "scripted")
        return {}

    def reset(self):
        self.parity.reset_new_password_user(self.POOL, "default", self.USER, "Tt1!temporary")

    def operations(self):
        return [name for name, _ in self.calls]

    def assert_every_mutation_is_tag_checked(self):
        for index, name in enumerate(self.operations()):
            if name in ("admin-delete-user", "admin-create-user", "admin-set-user-password"):
                self.assertEqual(self.operations()[index - 1], "tag-check", f"{name} without a tag check first")

    def test_missing_user_is_created(self):
        """Given: no such user. When: reset. Then: it is created with the temporary password, nothing else."""
        self.reset()
        self.assertEqual(self.operations(), ["admin-get-user", "tag-check", "admin-create-user"])
        create = self.calls[-1][1]
        self.assertEqual((create["Username"], create["TemporaryPassword"], create["MessageAction"]),
                         (self.USER, "Tt1!temporary", "SUPPRESS"))

    def test_existing_usable_user_is_only_reset(self):
        """Given: the user exists with no email or phone (any status). When: reset.
        Then: only its password is set back to the temporary one, not permanent; no delete, no create."""
        self.existing = {"UserStatus": "CONFIRMED", "UserAttributes": [{"Name": "sub", "Value": "placeholder"}]}
        self.reset()
        self.assertEqual(self.operations(), ["admin-get-user", "tag-check", "admin-set-user-password"])
        reset = self.calls[-1][1]
        self.assertEqual((reset["Password"], reset["Permanent"]), ("Tt1!temporary", False))

    def test_user_left_with_an_email_is_recreated(self):
        """Given: the user exists with the email the plugin test added. When: reset.
        Then: it is deleted and created again, each after a tag check."""
        self.existing = {"UserStatus": "CONFIRMED", "UserAttributes": [{"Name": "email", "Value": "x@example.com"}]}
        self.reset()
        self.assertEqual(self.operations(),
                         ["admin-get-user", "tag-check", "admin-delete-user", "tag-check", "admin-create-user"])
        self.assert_every_mutation_is_tag_checked()

    def test_user_another_run_created_first_is_reset(self):
        """Given: no user at the lookup, but another run creates it first (UsernameExistsException).
        When: reset. Then: it looks again, finds the user, and resets its password; nothing raises."""
        self.create_errors = ["UsernameExistsException"]
        self.gets = [None, {"UserStatus": "FORCE_CHANGE_PASSWORD", "UserAttributes": []}]
        self.reset()
        self.assertEqual(self.operations(), ["admin-get-user", "tag-check", "admin-create-user",
                                             "admin-get-user", "tag-check", "admin-set-user-password"])
        self.assert_every_mutation_is_tag_checked()

    def test_user_another_run_deleted_before_the_reset_is_created(self):
        """Given: a usable user at the lookup, which another run deletes before the reset
        (UserNotFoundException from AdminSetUserPassword). When: reset.
        Then: it looks again, finds none, and creates the user, each change tag-checked."""
        self.gets = [{"UserStatus": "CONFIRMED", "UserAttributes": []}, None]
        self.set_errors = ["UserNotFoundException"]
        self.reset()
        self.assertEqual(self.operations(), ["admin-get-user", "tag-check", "admin-set-user-password",
                                             "admin-get-user", "tag-check", "admin-create-user"])
        self.assert_every_mutation_is_tag_checked()

    def test_a_user_that_keeps_changing_stops_the_run(self):
        """Given: another run creating the user before every create. When: reset.
        Then: after the bounded attempts it refuses (SystemExit) rather than loop."""
        self.create_errors = ["UsernameExistsException"] * 5
        with self.assertRaises(SystemExit):
            self.reset()
        self.assertEqual(self.operations().count("admin-create-user"), self.parity.NEW_PASSWORD_RESET_ATTEMPTS)

    def test_a_user_deleted_before_every_reset_stops_the_run(self):
        """Given: a usable user at every lookup, which another run deletes before every reset
        (UserNotFoundException from AdminSetUserPassword each time). When: reset.
        Then: after the bounded attempts it refuses (SystemExit) rather than loop, and never creates."""
        self.existing = {"UserStatus": "CONFIRMED", "UserAttributes": []}
        self.set_errors = ["UserNotFoundException"] * 5
        with self.assertRaises(SystemExit):
            self.reset()
        self.assertEqual(self.operations().count("admin-set-user-password"), self.parity.NEW_PASSWORD_RESET_ATTEMPTS)
        self.assertNotIn("admin-create-user", self.operations())

    def test_an_untagged_pool_is_never_changed(self):
        """Given: the pool does not carry the purpose tag, for each state of the user.
        When: reset. Then: it refuses (SystemExit) before any create, reset or delete."""
        self.pool_tagged = False
        for existing in (None, {"UserStatus": "CONFIRMED", "UserAttributes": []},
                         {"UserStatus": "CONFIRMED", "UserAttributes": [{"Name": "email", "Value": "x@example.com"}]}):
            self.calls = []
            self.existing = existing
            with self.assertRaises(SystemExit):
                self.reset()
            mutations = [name for name in self.operations()
                         if name in ("admin-delete-user", "admin-create-user", "admin-set-user-password")]
            self.assertEqual(mutations, [], f"a mutation on an untagged pool ({existing})")

    def test_user_another_run_deleted_first_is_created(self):
        """Given: a user to recreate that another run deletes first (UserNotFoundException on delete).
        When: reset. Then: delete_user_if_present reports it gone, and the user is created."""
        self.existing = {"UserStatus": "CONFIRMED", "UserAttributes": [{"Name": "phone_number", "Value": "+15550000000"}]}
        self.delete_error = "UserNotFoundException"
        self.reset()
        self.assertEqual(self.operations(),
                         ["admin-get-user", "tag-check", "admin-delete-user", "tag-check", "admin-create-user"])
        self.assert_every_mutation_is_tag_checked()

    def test_other_create_errors_are_raised(self):
        """Given: AdminCreateUser fails for another reason. When: reset. Then: the error is raised."""
        self.create_errors = ["InvalidPasswordException"]
        with self.assertRaises(self.parity.AwsError):
            self.reset()

    def test_delete_user_if_present_reports_a_missing_user(self):
        """delete_user_if_present: True when it deleted, False for UserNotFoundException, raises otherwise."""
        self.assertTrue(self.parity.delete_user_if_present(self.POOL, self.USER))
        self.delete_error = "UserNotFoundException"
        self.assertFalse(self.parity.delete_user_if_present(self.POOL, self.USER))
        self.delete_error = "AccessDeniedException"
        with self.assertRaises(self.parity.AwsError):
            self.parity.delete_user_if_present(self.POOL, self.USER)



class WebAuthnHarnessIdentityTests(unittest.TestCase):
    """The harness's relying party and app ID come from committed files, and a live WebAuthn pool is never
    switched off. No identifier is printed: the checks compare, they do not show."""

    def setUp(self):
        self.state = tempfile.mkdtemp()
        os.environ["COGNITO_CLIENT_INTEG_DIR"] = self.state
        spec = importlib.util.spec_from_file_location("parity", os.path.join(INFRA, "parity.py"))
        self.parity = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.parity)
        self.parity.say = lambda *_: None
        self.parity.aws = self.fail_on_call
        self.parity.aws_or_none = self.fail_on_call
        # The guards before it read the machine and the account; the refusal must come before any change.
        self.parity.require_sources = lambda: None
        self.parity.require_cli_history_off = lambda: None
        self.parity.require_recorded_account = lambda state: None

    def tearDown(self):
        shutil.rmtree(self.state)
        del os.environ["COGNITO_CLIENT_INTEG_DIR"]

    def fail_on_call(self, *args, **kwargs):
        self.fail(f"unexpected AWS call {args[:2]}")

    def write_state(self, webauthn_record):
        with open(os.path.join(self.state, "state.json"), "w") as f:
            json.dump({"account": "000000000000", "region": "us-west-2",
                       "parity": {"pools": {"webauthn": webauthn_record}}}, f)

    def entitlements_without_a_domain(self):
        path = os.path.join(self.state, "CognitoClientWebAuthnApp.entitlements")
        with open(path, "wb") as f:
            import plistlib
            plistlib.dump({"com.apple.developer.associated-domains": []}, f)
        return path

    def test_the_committed_files_give_the_plugins_relying_party_and_an_app_id(self):
        """With no local file anywhere, the harness's identity resolves offline: the plugin's domain and
        `<team>.<bundle id>` from the project."""
        domain, app_id, gap = self.parity.webauthn_harness_identity()
        self.assertIsNone(gap)
        # Booleans, so a failure does not print the values.
        self.assertTrue([domain] == self.parity.webcredentials_domains(self.parity.PLUGIN_WEBAUTHN_ENTITLEMENTS),
                        "the domain is not the plugin's")
        self.assertTrue(re.fullmatch(r"[A-Z0-9]{10}\.[A-Za-z0-9.-]+", app_id or "") is not None,
                        "the app ID is not <team>.<bundle id>")

    def test_provision_refuses_before_any_change_when_a_live_pools_harness_cannot_be_read(self):
        """Given a live WebAuthn pool and harness entitlements naming no domain, provision exits, no AWS call."""
        self.write_state({"userPoolId": "placeholder-webauthn", "pending": []})
        self.parity.WEBAUTHN_ENTITLEMENTS = self.entitlements_without_a_domain()
        with self.assertRaises(SystemExit) as refused:
            self.parity.provision()
        self.assertIn("Nothing was changed", str(refused.exception.code))
        self.assertFalse(os.path.exists(os.path.join(self.state, "build")))

    def test_a_domain_other_than_the_plugins_is_a_gap(self):
        path = os.path.join(self.state, "CognitoClientWebAuthnApp.entitlements")
        with open(path, "wb") as f:
            import plistlib
            plistlib.dump({"com.apple.developer.associated-domains": ["webcredentials:other.example.invalid"]}, f)
        self.parity.WEBAUTHN_ENTITLEMENTS = path
        self.assertIsNotNone(self.parity.webauthn_harness_identity()[2])

    def test_a_pool_not_yet_live_may_stay_pending(self):
        """With the harness unreadable, a pool with WebAuthn pending, or none recorded, is not refused."""
        self.parity.WEBAUTHN_ENTITLEMENTS = self.entitlements_without_a_domain()
        for record in ({"userPoolId": "placeholder-webauthn", "pending": ["webauthn-relying-party", "web-authn"]},
                       {}):
            self.write_state(record)
            self.parity.require_webauthn_harness_identity(self.parity.load_state()["parity"])

    # --- the app ID from the project's signing settings ------------------------------------------------

    @staticmethod
    def configuration(team="ABCDE12345", bundle="com.example.harness", extra=""):
        """One XCBuildConfiguration that signs with the harness entitlements, in project.pbxproj's layout."""
        return ("\t\tCC0000000000000000000001 /* Debug */ = {\n\t\t\tisa = XCBuildConfiguration;\n"
                "\t\t\tbuildSettings = {\n"
                "\t\t\t\tCODE_SIGN_ENTITLEMENTS = CognitoClientWebAuthnApp.entitlements;\n"
                f"\t\t\t\tDEVELOPMENT_TEAM = {team};\n{extra}"
                f"\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = {bundle};\n"
                "\t\t\t};\n\t\t\tname = Debug;\n\t\t};\n")

    def use_project(self, *configurations):
        path = os.path.join(self.state, "project.pbxproj")
        with open(path, "w") as f:
            f.write("// !$*UTF8*$!\n{\n" + "".join(configurations) + "}\n")
        self.parity.WEBAUTHN_PROJECT = path

    def test_configurations_that_agree_give_the_app_id(self):
        self.use_project(self.configuration(), self.configuration())
        self.assertEqual(self.parity.webauthn_harness_app_id(), ("ABCDE12345.com.example.harness", None))

    def test_every_unresolvable_project_is_a_gap(self):
        """Disagreeing teams or bundle ids, a `$(inherited)` value, a per-SDK override, or no configuration at
        all: each is a gap with no app ID, never one of the candidates."""
        cases = {
            "teams disagree": [self.configuration(), self.configuration(team="ZYXWV98765")],
            "bundle ids disagree": [self.configuration(), self.configuration(bundle="com.example.other")],
            "inherited team": [self.configuration(team="\"$(inherited)\"")],
            "inherited bundle id": [self.configuration(), self.configuration(bundle="\"$(inherited)\"")],
            "per-SDK override": [self.configuration(
                extra="\t\t\t\t\"DEVELOPMENT_TEAM[sdk=iphoneos*]\" = ZYXWV98765;\n")],
            "no configuration": [],
        }
        for name, configurations in cases.items():
            with self.subTest(name):
                self.use_project(*configurations)
                app_id, gap = self.parity.webauthn_harness_app_id()
                self.assertIsNone(app_id)
                self.assertIsNotNone(gap)
                self.assertIsNotNone(self.parity.webauthn_harness_identity()[2])

    def test_provision_refuses_a_live_pool_whose_project_disagrees(self):
        self.write_state({"userPoolId": "placeholder-webauthn", "pending": []})
        self.use_project(self.configuration(), self.configuration(team="ZYXWV98765"))
        with self.assertRaises(SystemExit) as refused:
            self.parity.provision()
        self.assertIn("disagree", str(refused.exception.code))
        self.assertIn("Nothing was changed", str(refused.exception.code))

    def test_a_live_pool_is_never_degraded_at_p10(self):
        """A relying-party gap on a live pool stops the run instead of taking WEB_AUTHN off; a pending pool
        gets the gap back."""
        self.parity.webauthn_relying_party = lambda: (None, "the gap")
        with self.assertRaises(SystemExit) as refused:
            self.parity.webauthn_relying_party_or_refuse({"pools": {"webauthn": {"userPoolId": "p", "pending": []}}})
        self.assertIn("the gap", str(refused.exception.code))
        pending = {"pools": {"webauthn": {"userPoolId": "p", "pending": ["web-authn"]}}}
        self.assertEqual(self.parity.webauthn_relying_party_or_refuse(pending), (None, "the gap"))


if __name__ == "__main__":
    unittest.main()
