#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""Self-tests for parity.py's self sign-up rules: off is the resting state, so preflight and verify refuse
only a missing pool, one left on outside a self-sign-up.sh run, or one on against its template; provision never
turns it on; and `self-sign-up on|off` sends each pool's full configuration back with only the flag changed. And
the reset of the plugin's new-password users tolerates an overlapping run; and the WebAuthn harness's committed
relying party and app ID are found, and provision never switches a live WebAuthn pool off; and the plugin
identity pool (P-13) federates the passwordless pool, and the passwordless outputs name it.

    python3 infra/test_parity.py

No AWS call is made: parity.aws and parity.aws_or_none are replaced by fakes, and COGNITO_CLIENT_INTEG_DIR
points at a temporary directory with a fake state.json (placeholder ids only).
"""

import contextlib
import copy
import importlib.util
import io
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from unittest import mock

INFRA = os.path.dirname(os.path.abspath(__file__))
RUN = "COGNITO_CLIENT_INTEG_SELF_SIGN_UP"
RETIRED_REENABLE = "COGNITO_CLIENT_INTEG_REENABLE_SELF_SIGN_UP"
CI_VARIABLES = ("CI", "GITHUB_ACTIONS")


def described(admin_only):
    return {"AdminCreateUserConfig": {"AllowAdminCreateUserOnly": admin_only}}


# The relying party the fakes stand the harness's for (parity.harness_rp_id is replaced to return it).
RP_ID = "placeholder-rp.example"


def provisioned_mfa(parity, key):
    """Pool `key`'s MFA configuration as provision applies it, ${WEBAUTHN_RP_ID} resolved to RP_ID (the other
    placeholders stay: only the WebAuthn relying party is compared by value)."""
    mfa = copy.deepcopy(parity.load_template(key)["mfa"])
    if "WebAuthnConfiguration" in mfa:
        mfa["WebAuthnConfiguration"]["RelyingPartyId"] = RP_ID
    return mfa


class ParitySelfSignUpTests(unittest.TestCase):
    def setUp(self):
        self.saved_environment = {name: os.environ.pop(name, None)
                                  for name in (RUN, RETIRED_REENABLE) + CI_VARIABLES}
        self.state = tempfile.mkdtemp()
        os.environ["COGNITO_CLIENT_INTEG_DIR"] = self.state
        spec = importlib.util.spec_from_file_location("parity", os.path.join(INFRA, "parity.py"))
        self.parity = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.parity)
        self.pools = {key: f"placeholder-{key}" for key in self.parity.POOLS}
        self.write_state(self.pools)
        # Off, the resting state.
        self.admin_only = {key: True for key in self.pools}
        self.gone = set()
        self.said = []
        self.parity.say = self.said.append
        self.real_aws_or_none = self.parity.aws_or_none
        self.parity.aws_or_none = self.fake_describe
        self.parity.aws = self.fail_on_call
        self.parity.harness_rp_id = lambda: RP_ID

    def tearDown(self):
        shutil.rmtree(self.state)
        del os.environ["COGNITO_CLIENT_INTEG_DIR"]
        for name, value in self.saved_environment.items():
            os.environ.pop(name, None)
            if value is not None:
                os.environ[name] = value

    def write_state(self, pools):
        with open(os.path.join(self.state, "state.json"), "w") as f:
            json.dump({"account": "000000000000", "region": "us-west-2",
                       "parity": {"pools": {k: {"userPoolId": v} for k, v in pools.items()}}}, f)

    def fake_describe(self, *args, **kwargs):
        self.assertIn(args[:2], (("cognito-idp", "describe-user-pool"), ("cognito-idp", "get-user-pool-mfa-config")))
        key = next(k for k, v in self.pools.items() if v == args[-1])
        if key in self.gone:
            return None
        if args[1] == "get-user-pool-mfa-config":
            return self.mfa.get(key) or provisioned_mfa(self.parity, key)
        return {"UserPool": dict(described(self.admin_only[key]), Name=key)}

    mfa = {}

    def fail_on_call(self, *args, **kwargs):
        self.fail(f"unexpected AWS call {args[:2]}")

    def gaps(self):
        return self.parity.live_self_sign_up_gaps(self.parity.load_state())

    def hold_a_live_lease(self):
        """As if a self-sign-up.sh run held a live lease."""
        self.parity.live_leases = lambda: [{"pid": 1, "start": "placeholder"}]

    # --- the check -----------------------------------------------------------------------------------

    def test_every_template_states_and_allows_self_sign_up(self):
        """Given: pools/*.json. Then: every parity template states the flag and allows self sign-up, the shape a
        run needs (the flag is off at rest, but not in the templates)."""
        for key in self.pools:
            config = self.parity.load_template(key)["userPool"]["AdminCreateUserConfig"]
            self.assertIs(config["AllowAdminCreateUserOnly"], False, key)
            self.assertTrue(self.parity.template_self_sign_up(self.parity.load_template(key)), key)

    def test_template_without_the_flag_is_refused(self):
        """Given: a template whose AdminCreateUserConfig does not state the flag. Then: it is refused."""
        with self.assertRaises(SystemExit):
            self.parity.template_self_sign_up({"userPool": {"AdminCreateUserConfig": {}}})

    def test_off_is_the_resting_state(self):
        """Given: every live pool has self sign-up off (admin-only), as provision leaves it.
        When: the check runs with no lease, and with a run's live lease. Then: no gap either way."""
        self.assertEqual(self.gaps(), [])
        self.hold_a_live_lease()
        self.assertEqual(self.gaps(), [])

    def test_on_outside_a_run_is_a_gap(self):
        """Given: two pools left on (a crashed run, say), and no live lease, even with the run's variable set.
        Then: exactly those two are LEFT-ON, sorted, with the recovery command."""
        os.environ[RUN] = "on"
        for key in ("webauthn", "email-alias"):
            self.admin_only[key] = False
        self.assertEqual(self.gaps(), [
            ("LEFT-ON", "email-alias: self sign-up was left on; run infra/self-sign-up.sh off"),
            ("LEFT-ON", "webauthn: self sign-up was left on; run infra/self-sign-up.sh off")])

    def test_on_inside_a_run_is_not_a_gap(self):
        """Given: every pool on. When: a self-sign-up.sh run holds a live lease, and then none does.
        Then: no gap, then every pool is LEFT-ON."""
        self.admin_only = {key: False for key in self.pools}
        real = self.parity.live_leases
        self.hold_a_live_lease()
        self.assertEqual(self.gaps(), [])
        self.parity.live_leases = real
        self.assertEqual({kind for kind, _ in self.gaps()}, {"LEFT-ON"})

    # --- MFA (B1) ------------------------------------------------------------------------------------

    def test_expected_mfa_is_the_template_as_degraded(self):
        """Given: mfa-req-all's template (MFA on, EMAIL, SMS and TOTP). When: its expected MFA is computed with
        nothing pending, then with email pending. Then: all three methods, then SMS and TOTP only."""
        self.assertEqual(self.parity.expected_mfa("mfa-req-all", []), ("ON", ["EMAIL", "SMS", "TOTP"], None))
        self.assertEqual(self.parity.expected_mfa("mfa-req-all", ["email-mfa"]), ("ON", ["SMS", "TOTP"], None))
        self.assertEqual(self.parity.expected_mfa("email-alias", None), ("OFF", [], None))

    def test_an_mfa_reset_is_a_gap(self):
        """Given: one pool whose MFA was reset to OFF (an interrupted toggle, say), the others as provisioned.
        Then: exactly that pool is an MFA gap, naming provision; a gone pool is not reported here."""
        self.mfa = {"mfa-req-totp-sms": {"MfaConfiguration": "OFF"}}
        self.gone.add("webauthn")
        gaps = self.parity.live_mfa_gaps(self.parity.load_state())
        self.assertEqual([(kind, gap.split(":")[0]) for kind, gap in gaps], [("MFA", "mfa-req-totp-sms")])
        self.assertIn("run infra/provision.sh", gaps[0][1])

    def test_preflight_refuses_an_mfa_reset(self):
        """Given: no other gap, and one pool's MFA reset to OFF. When: preflight runs. Then: it refuses, naming
        MFA and provision; with the MFA as provisioned it passes."""
        self.stub_preflight_prerequisites()
        self.mfa = {"default": {"MfaConfiguration": "OFF"}}
        with self.assertRaises(SystemExit) as refused:
            self.parity.preflight()
        self.assertIn("for MFA, re-run infra/provision.sh", str(refused.exception.code))
        self.mfa = {}
        self.parity.preflight()

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
        """Given: a live pool whose AdminCreateUserConfig does not state the flag. Then: it is DRIFT, in a run too."""
        for in_run in (False, True):
            gaps = self.parity.self_sign_up_gaps({"a": True}, {"a"}, {"a": {"AdminCreateUserConfig": {}}}, in_run)
            self.assertEqual(gaps, [("DRIFT", "a: the pool does not state whether self sign-up is allowed")])

    def test_unexpected_self_sign_up_is_a_gap(self):
        """Given: a template forbidding self sign-up and a live pool allowing it.
        Then: it is DRIFT, in a run too; off on that pool is no gap."""
        for in_run in (False, True):
            gaps = self.parity.self_sign_up_gaps({"b": False}, {"b"}, {"b": described(False)}, in_run)
            self.assertEqual(gaps, [("DRIFT", "b: self sign-up is on, but pools/b.json does not allow it")])
        self.assertEqual(self.parity.self_sign_up_gaps({"b": False}, {"b"}, {"b": described(True)}), [])

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
        """Given: LEFT-ON only, DRIFT only, UNSAFE only, or nothing. When: exit_on_gaps runs for verify and
        preflight. Then: each gap exits non-zero for both; LEFT-ON names infra/self-sign-up.sh off, DRIFT names
        provision, neither names the retired opt-in; and no gap returns normally."""
        left_on = [("LEFT-ON", "webauthn: self sign-up was left on; run infra/self-sign-up.sh off")]
        drift = [("DRIFT", "b: self sign-up is on, but pools/b.json does not allow it")]
        for command in ("verify", "preflight"):
            with self.assertRaises(SystemExit) as refused:
                self.parity.exit_on_gaps(command, [], left_on)
            self.assertTrue(refused.exception.code, command)
            self.assertIn("infra/self-sign-up.sh off", str(refused.exception.code))
            self.assertNotIn("provision", str(refused.exception.code))
            with self.assertRaises(SystemExit) as refused:
                self.parity.exit_on_gaps(command, [], drift)
            self.assertIn("infra/provision.sh", str(refused.exception.code))
            self.assertNotIn(RETIRED_REENABLE, str(refused.exception.code))
            with self.assertRaises(SystemExit) as refused:
                self.parity.exit_on_gaps(command, [], [("MFA", "c: MFA is OFF []")])
            self.assertIn("for MFA, re-run infra/provision.sh", str(refused.exception.code))
            self.assertNotIn("self-sign-up.sh", str(refused.exception.code))
            with self.assertRaises(SystemExit) as refused:
                self.parity.exit_on_gaps(command, ["x: DEVELOPER email"], [])
            self.assertTrue(refused.exception.code, command)
            self.assertIsNone(self.parity.exit_on_gaps(command, [], []))
        self.assertIn("LEFT-ON webauthn: self sign-up was left on; run infra/self-sign-up.sh off", self.said)

    def test_verify_uses_the_shared_exit(self):
        """Given: parity.py. Then: verify and preflight both end their checks with exit_on_gaps and the live
        self sign-up gaps (so the tested exit is the one they take), and the retired opt-in is gone."""
        with open(os.path.join(INFRA, "parity.py")) as f:
            source = f.read()
        self.assertIn('exit_on_gaps("verify", gaps, live_self_sign_up_gaps(state) + live_mfa_gaps(state))', source)
        self.assertIn('exit_on_gaps("preflight", gaps, live_self_sign_up_gaps(state) + live_mfa_gaps(state))', source)
        self.assertNotIn(RETIRED_REENABLE, source)

    def test_verify_prints_an_absent_flag_without_a_key_error(self):
        """Given: DescribeUserPool `UserPool`s with the flag off, on, unstated, and with no AdminCreateUserConfig.
        When: verify's selfSignUp= summary is made. Then: off, on, unstated, unstated; no KeyError."""
        summary = self.parity.self_sign_up_summary
        self.assertEqual([summary(described(True)), summary(described(False)),
                          summary({"AdminCreateUserConfig": {}}), summary({})],
                         ["off", "on", "unstated", "unstated"])

    def stub_preflight_prerequisites(self):
        for name in ("require_cli_history_off", "require_recorded_account"):
            setattr(self.parity, name, lambda *args: None)
        for name in ("live_sender_gaps", "ses_gaps", "wildcard_gaps"):
            setattr(self.parity, name, lambda *args: [])
        self.parity.aws = lambda *args, **kwargs: {"IsInSandbox": True}

    def test_preflight_refuses_only_left_on(self):
        """Given: no unsafe setting. When: preflight runs with every pool off, then with one pool on outside a
        run, then with it on inside a run. Then: it passes, refuses naming infra/self-sign-up.sh off, and passes."""
        self.stub_preflight_prerequisites()
        self.parity.preflight()
        self.admin_only["webauthn"] = False
        with self.assertRaises(SystemExit) as refused:
            self.parity.preflight()
        self.assertIn("infra/self-sign-up.sh off", str(refused.exception.code))
        self.hold_a_live_lease()
        self.parity.preflight()

    # --- provision -----------------------------------------------------------------------------------

    def test_config_to_send(self):
        """Given: a template allowing self sign-up, with another AdminCreateUserConfig field.
        When: the config to send is computed, by default and with `on`.
        Then: off by default and on only with `on`, keeping the other field; None without the block."""
        wanted = {"AdminCreateUserConfig": {"AllowAdminCreateUserOnly": False, "InviteMessageTemplate": {"x": 1}}}
        send = self.parity.admin_create_user_config_to_send
        self.assertEqual(send(wanted), {"AllowAdminCreateUserOnly": True, "InviteMessageTemplate": {"x": 1}})
        self.assertEqual(send(wanted, on=True), {"AllowAdminCreateUserOnly": False, "InviteMessageTemplate": {"x": 1}})
        self.assertEqual(send({"AdminCreateUserConfig": {"AllowAdminCreateUserOnly": True}}),
                         {"AllowAdminCreateUserOnly": True})
        self.assertIsNone(send({}))
        self.assertIs(wanted["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"], False, "the template is not changed")

    def run_ensure_user_pool(self, current_admin_only, other_drift=True, exists=True, extra_tags=None):
        template = self.parity.load_template("passwordless")
        # The live pool matches the template except for self sign-up (and, if asked, a stale trigger).
        current = dict(template["userPool"], **described(current_admin_only),
                       UserPoolTags=dict(extra_tags or {}, purpose=self.parity.TAG_VALUE))
        if other_drift:
            current["LambdaConfig"] = {}
        calls = []
        self.parity.find_user_pool = lambda *args: "placeholder-passwordless" if exists else None
        self.parity.require_user_pool_tag = lambda *args: current

        def record(*args, stdin=None, **kwargs):
            calls.append((args, stdin))
            return {"UserPool": {"Id": "placeholder-new"}}
        self.parity.aws = record
        self.parity.ensure_user_pool("passwordless", template, {})
        return template, calls

    @staticmethod
    def sent(calls, operation):
        return [stdin for args, stdin in calls if args[:2] == ("cognito-idp", operation)]

    def test_provision_never_turns_it_on(self):
        """Given: a template allowing self sign-up. When: ensure_user_pool updates a pool that is on and drifted
        in another field, updates one that is off, and creates a missing one, each with the retired opt-in set.
        Then: the update is the template's updatable fields with the flag true; the creation is admin-only too."""
        os.environ[RETIRED_REENABLE] = "1"
        template, calls = self.run_ensure_user_pool(current_admin_only=False)
        updates = self.sent(calls, "update-user-pool")
        self.assertEqual(len(updates), 1)
        expected = {k: v for k, v in template["userPool"].items() if k in self.parity.UPDATE_KEYS}
        expected["AdminCreateUserConfig"] = dict(expected["AdminCreateUserConfig"], AllowAdminCreateUserOnly=True)
        body = {k: v for k, v in updates[0].items() if k not in ("UserPoolId", "PoolName", "UserPoolTags")}
        self.assertEqual(body, expected)

        _, calls = self.run_ensure_user_pool(current_admin_only=True)
        self.assertIs(self.sent(calls, "update-user-pool")[0]["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"],
                      True)

        _, calls = self.run_ensure_user_pool(current_admin_only=True, exists=False)
        creates = self.sent(calls, "create-user-pool")
        self.assertEqual(len(creates), 1)
        self.assertIs(creates[0]["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"], True)

    def test_off_with_nothing_else_drifted_makes_no_update(self):
        """Given: a pool whose only difference from the template is self sign-up off.
        When: ensure_user_pool runs. Then: no update is made."""
        _, calls = self.run_ensure_user_pool(current_admin_only=True, other_drift=False)
        self.assertEqual(self.sent(calls, "update-user-pool"), [])

    def test_on_with_nothing_else_drifted_is_turned_off(self):
        """Given: a pool left on, otherwise matching its template. When: ensure_user_pool runs.
        Then: one update turns it off."""
        _, calls = self.run_ensure_user_pool(current_admin_only=False, other_drift=False)
        updates = self.sent(calls, "update-user-pool")
        self.assertEqual(len(updates), 1)
        self.assertIs(updates[0]["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"], True)

    def test_an_update_keeps_the_pools_own_tags(self):
        """Given: a drifted pool with a tag of its own beside the purpose tag. When: ensure_user_pool updates
        it. Then: the update sends the pool's own tags, the purpose tag among them, so none is dropped."""
        _, calls = self.run_ensure_user_pool(current_admin_only=True, extra_tags={"owner": "placeholder"})
        updates = self.sent(calls, "update-user-pool")
        self.assertEqual(updates[0]["UserPoolTags"], {"owner": "placeholder", "purpose": self.parity.TAG_VALUE})


class SelfSignUpCommandTests(unittest.TestCase):
    """`parity.py self-sign-up on|release|off` over a scripted Cognito: every call is recorded, and the pools' live
    configurations and MFA are kept in memory, so a field an update leaves out is lost, as UpdateUserPool loses it.
    The runs that hold leases are real `sleep` processes, so liveness and start times are the real ones."""

    def setUp(self):
        self.saved_environment = {name: os.environ.pop(name, None) for name in (RUN,) + CI_VARIABLES}
        self.saved_signals = {number: signal.getsignal(number)
                              for number in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP)}
        self.state = tempfile.mkdtemp()
        os.environ["COGNITO_CLIENT_INTEG_DIR"] = self.state
        spec = importlib.util.spec_from_file_location("parity", os.path.join(INFRA, "parity.py"))
        self.parity = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.parity)
        self.ids = {key: f"placeholder-{key}" for key in self.parity.POOLS}
        with open(os.path.join(self.state, "state.json"), "w") as f:
            json.dump({"account": "000000000000", "region": "us-west-2",
                       "parity": {"pools": {k: {"userPoolId": v} for k, v in self.ids.items()}}}, f)
        self.live = {pool_id: self.live_pool(key) for key, pool_id in self.ids.items()}
        self.mfa = {pool_id: provisioned_mfa(self.parity, key) for key, pool_id in self.ids.items()}
        self.parity.harness_rp_id = lambda: RP_ID
        self.calls = []
        self.said = []
        self.reset_mfa_on_update = False
        self.parity.say = self.said.append
        self.real_aws = self.parity.aws
        self.parity.aws = self.fake_aws
        self.parity.aws_or_none = self.fake_aws
        self.parity.require_cli_history_off = lambda: None
        self.parity.require_recorded_account = lambda state: None
        self.runs = []

    def tearDown(self):
        for run in self.runs:
            run.kill()
            run.wait()
        for number, handler in self.saved_signals.items():
            signal.signal(number, handler)
        shutil.rmtree(self.state)
        del os.environ["COGNITO_CLIENT_INTEG_DIR"]
        for name, value in self.saved_environment.items():
            os.environ.pop(name, None)
            if value is not None:
                os.environ[name] = value

    def run_pid(self):
        """The PID of a fresh, live process standing in for a self-sign-up.sh run."""
        run = subprocess.Popen(["sleep", "60"])
        self.runs.append(run)
        return run.pid

    def live_pool(self, key):
        """A described pool as provision leaves it: the template's updatable fields, placeholders and all, with
        self sign-up off, plus what DescribeUserPool adds (the deprecated UnusedAccountValidityDays among them)."""
        pool = {k: copy.deepcopy(v) for k, v in self.parity.load_template(key)["userPool"].items()
                if k in self.parity.UPDATE_KEYS | self.parity.CREATE_ONLY_KEYS}
        pool["AdminCreateUserConfig"] = dict(pool["AdminCreateUserConfig"], AllowAdminCreateUserOnly=True,
                                             UnusedAccountValidityDays=7)
        pool.update(Name=self.parity.POOLS[key], UserPoolTags={"purpose": self.parity.TAG_VALUE},
                    MfaConfiguration="OPTIONAL", Arn="placeholder-arn", CreationDate=0)
        return pool

    def fake_aws(self, *args, stdin=None, **kwargs):
        self.calls.append((args[:2], copy.deepcopy(stdin)))
        operation = args[:2]
        pool_id = stdin["UserPoolId"] if stdin else args[args.index("--user-pool-id") + 1]
        if operation == ("cognito-idp", "describe-user-pool"):
            return {"UserPool": copy.deepcopy(self.live[pool_id])}
        if operation == ("cognito-idp", "get-user-pool-mfa-config"):
            return copy.deepcopy(self.mfa[pool_id])
        if operation == ("cognito-idp", "set-user-pool-mfa-config"):
            self.mfa[pool_id] = {k: v for k, v in stdin.items() if k != "UserPoolId"}
            return {}
        if operation == ("cognito-idp", "update-user-pool"):
            if "UnusedAccountValidityDays" in stdin.get("AdminCreateUserConfig", {}):
                raise self.parity.AwsError("InvalidParameterException", "placeholder")
            kept = {k: v for k, v in self.live[pool_id].items() if k not in self.parity.UPDATE_KEYS}
            self.live[pool_id] = dict(kept, **{k: v for k, v in stdin.items() if k in self.parity.UPDATE_KEYS},
                                      UserPoolTags=stdin["UserPoolTags"])
            if self.reset_mfa_on_update:
                self.mfa[pool_id] = {"MfaConfiguration": "OFF"}
            return {}
        self.fail(f"unexpected AWS call {operation}")

    def updates(self):
        return [stdin for operation, stdin in self.calls if operation == ("cognito-idp", "update-user-pool")]

    def flags(self):
        return {pool["Name"]: not pool["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"] for pool in self.live.values()}

    def leases(self):
        return [lease["pid"] for lease in self.parity.load_json(self.parity.SELF_SIGN_UP_LEASES, default=[])]

    # --- on and off --------------------------------------------------------------------------------------------

    def test_self_sign_up_command_sends_the_full_template(self):
        """Given: every pool as provision leaves it (off). When: a run turns self sign-up on, then releases it.
        Then: one update per pool each way, each the pool's full updatable configuration (every UPDATE_KEYS field
        it has) and its own tags, with only the flag changed and the deprecated UnusedAccountValidityDays left out;
        every pool ends as it began, and no other field changed."""
        before = copy.deepcopy(self.live)
        run = self.run_pid()
        self.parity.self_sign_up("on", lease=run)
        self.assertEqual(set(self.flags().values()), {True})
        self.assertEqual(self.leases(), [run])
        updates = self.updates()
        self.assertEqual(len(updates), len(self.ids))
        for update in updates:
            pool = before[update["UserPoolId"]]
            expected = {k: v for k, v in pool.items() if k in self.parity.UPDATE_KEYS}
            expected["AdminCreateUserConfig"] = {k: v for k, v in pool["AdminCreateUserConfig"].items()
                                                 if k != "UnusedAccountValidityDays"}
            expected["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"] = False
            body = {k: v for k, v in update.items() if k not in ("UserPoolId", "PoolName", "UserPoolTags")}
            self.assertEqual(body, expected, pool["Name"])
            self.assertEqual(update["UserPoolTags"], pool["UserPoolTags"])
            self.assertGreater(len(body), 5, "more than the flag is sent")

        self.parity.self_sign_up("release", lease=run)
        self.assertEqual(set(self.flags().values()), {False})
        self.assertEqual(self.leases(), [])
        self.assertEqual(len(self.updates()), 2 * len(self.ids))
        for pool_id, pool in self.live.items():
            expected = dict(before[pool_id])
            expected["AdminCreateUserConfig"] = {k: v for k, v in expected["AdminCreateUserConfig"].items()
                                                 if k != "UnusedAccountValidityDays"}
            self.assertEqual(pool, expected)

    def test_off_is_idempotent(self):
        """Given: every pool already off, no lease. When: `self-sign-up off`. Then: no update, no MFA call; each
        pool says so."""
        self.parity.self_sign_up("off")
        self.assertEqual(self.updates(), [])
        self.assertEqual({operation for operation, _ in self.calls}, {("cognito-idp", "describe-user-pool")})
        self.assertEqual(len([line for line in self.said if "already off" in line]), len(self.ids))

    def test_on_refuses_an_untagged_pool_before_any_change(self):
        """Given: one pool without the purpose tag. When: a run turns self sign-up on.
        Then: it exits non-zero naming it, and no pool is updated."""
        self.live[self.ids["webauthn"]]["UserPoolTags"] = {}
        with self.assertRaises(SystemExit) as refused:
            self.parity.self_sign_up("on", lease=self.run_pid())
        self.assertIn("nothing was changed", str(refused.exception.code))
        self.assertIn("not tagged", str(refused.exception.code))
        self.assertEqual(self.updates(), [])

    def test_on_refuses_a_pool_whose_mfa_is_not_its_templates(self):
        """Given: one pool whose MFA was reset to OFF (an earlier interrupted toggle, say). When: a run turns self
        sign-up on. Then: it exits non-zero naming the MFA gap, and no pool is updated."""
        self.mfa[self.ids["mfa-req-email"]] = {"MfaConfiguration": "OFF"}
        with self.assertRaises(SystemExit) as refused:
            self.parity.self_sign_up("on", lease=self.run_pid())
        self.assertIn("mfa-req-email: MFA is OFF", str(refused.exception.code))
        self.assertEqual(self.updates(), [])

    def test_on_refuses_a_webauthn_pool_whose_relying_party_is_not_the_harnesss(self):
        """Test that `on` refuses a WebAuthn relying party other than the one provision resolves

        - Given: the WebAuthn pool's live WebAuthnConfiguration naming another relying party
        - When:
           - a run turns self sign-up on
        - Then:
           - it exits non-zero naming the WebAuthn gap, without the domain, and no pool is updated
        """
        self.mfa[self.ids["webauthn"]]["WebAuthnConfiguration"]["RelyingPartyId"] = "placeholder-other.example"
        with self.assertRaises(SystemExit) as refused:
            self.parity.self_sign_up("on", lease=self.run_pid())
        self.assertIn("webauthn: MFA is", str(refused.exception.code))
        self.assertIn("WebAuthn with another relying party", str(refused.exception.code))
        self.assertNotIn("placeholder-other.example", str(refused.exception.code))
        self.assertEqual(self.updates(), [])

    def test_off_release_and_status_never_read_the_webauthn_harness(self):
        """Test that off, release and status never depend on the WebAuthn harness's files

        - Given: every pool on under a run's lease, and the harness's files unreadable (each read raising, as a
          missing file does)
        - When:
           - the run releases; then, every pool on again, `off`; then `status`
        - Then:
           - the release and `off` each turn every pool off, with its MFA; status exits 0; none reads the files
        """
        run = self.run_pid()
        self.parity.self_sign_up("on", lease=run)
        self.assertEqual(set(self.flags().values()), {True})

        def unreadable(*_):
            raise FileNotFoundError("placeholder")
        self.parity.webauthn_harness_identity = unreadable
        self.parity.harness_rp_id = lambda: self.fail("harness_rp_id was called")
        self.parity.self_sign_up("release", lease=run)
        self.assertEqual(set(self.flags().values()), {False})
        for pool_id, key in ((v, k) for k, v in self.ids.items()):
            self.assertEqual(self.mfa[pool_id], provisioned_mfa(self.parity, key), key)
        for flag in self.live.values():
            flag["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"] = False
        self.parity.self_sign_up("off")
        self.assertEqual(set(self.flags().values()), {False})
        self.parity.self_sign_up_command(["status"])
        self.assertTrue(any("every parity pool has self sign-up off" in line for line in self.said), self.said)

    def test_off_skips_an_untagged_pool_and_turns_off_the_rest(self):
        """Given: every pool on, one of them without the purpose tag. When: `self-sign-up off`.
        Then: every tagged pool is turned off, the untagged one is never updated, and it exits non-zero."""
        for pool in self.live.values():
            pool["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"] = False
        untagged = self.ids["webauthn"]
        self.live[untagged]["UserPoolTags"] = {}
        with self.assertRaises(SystemExit):
            self.parity.self_sign_up("off")
        self.assertNotIn(untagged, [update["UserPoolId"] for update in self.updates()])
        self.assertEqual(len(self.updates()), len(self.ids) - 1)
        flags = self.flags()
        self.assertTrue(flags.pop(self.parity.POOLS["webauthn"]))
        self.assertEqual(set(flags.values()), {False})

    def test_refuses_on_ci(self):
        """Given: CI or GITHUB_ACTIONS set. When: on, release or off. Then: it exits before any call."""
        for name in CI_VARIABLES:
            for mode in ("on", "release", "off"):
                os.environ[name] = "true"
                with self.assertRaises(SystemExit) as refused:
                    self.parity.self_sign_up(mode, lease=1)
                self.assertIn("never on CI", str(refused.exception.code))
                del os.environ[name]
        self.assertEqual(self.calls, [])

    def test_an_mfa_configuration_reset_by_the_update_is_restored(self):
        """Given: an UpdateUserPool that resets the pool's MFA configuration. When: a run turns self sign-up on.
        Then: each pool's MFA configuration is set back to what it was, and saying so."""
        self.reset_mfa_on_update = True
        before = copy.deepcopy(self.mfa)
        self.parity.self_sign_up("on", lease=self.run_pid())
        self.assertEqual(self.mfa, before)
        reset = [pool_id for pool_id, mfa in before.items() if mfa != {"MfaConfiguration": "OFF"}]
        self.assertGreater(len(reset), 1)
        self.assertEqual(len([line for line in self.said if line.startswith("Restored the MFA configuration")]),
                         len(reset))

    def test_an_error_after_the_update_still_restores_the_mfa_configuration(self):
        """Given: an UpdateUserPool that resets the pool's MFA configuration, and a stdout that breaks right after
        the first update (say raises BrokenPipeError on its "Updated user pool" line, B1).
        When: a run turns self sign-up on.
        Then: the error ends the run, but only after that pool's MFA configuration was set back; no later pool
        was tried."""
        self.reset_mfa_on_update = True
        before = copy.deepcopy(self.mfa)

        def broken(message):
            if message.startswith("Updated user pool"):
                raise BrokenPipeError(32, "Broken pipe")
            self.said.append(message)
        self.parity.say = broken
        with self.assertRaises(BrokenPipeError):
            self.parity.self_sign_up("on", lease=self.run_pid())
        self.assertEqual(len(self.updates()), 1)
        self.assertEqual(self.mfa, before)

    def test_say_survives_a_closed_stdout(self):
        """Given: parity.py with a stdout whose reader has gone (a dead pipe, as a Ctrl-C on `… | xcbeautify`
        leaves it, B1). When: it says two lines, then exits. Then: no error, no traceback and no "Exception
        ignored" at exit; it exits 0."""
        read_end, write_end = os.pipe()
        os.close(read_end)
        child = subprocess.run([sys.executable, "-c", (
            "import importlib.util, sys\n"
            "spec = importlib.util.spec_from_file_location('parity', sys.argv[1])\n"
            "parity = importlib.util.module_from_spec(spec)\n"
            "spec.loader.exec_module(parity)\n"
            "parity.say('one')\n"
            "parity.say('two')\n"
            "sys.stderr.write('done\\n')\n"), os.path.join(INFRA, "parity.py")],
            stdout=write_end, stderr=subprocess.PIPE, text=True)
        os.close(write_end)
        self.assertEqual((child.returncode, child.stderr), (0, "done\n"))

    def test_another_change_at_the_same_time_is_reported(self):
        """Given: a pool whose password policy and tags change while self sign-up is turned on (another writer).
        When: a run turns self sign-up on. Then: it exits non-zero, naming both fields and provision."""
        real = self.fake_aws
        target = self.ids["passwordless"]

        def interfering(*args, stdin=None, **kwargs):
            result = real(*args, stdin=stdin, **kwargs)
            if args[:2] == ("cognito-idp", "update-user-pool") and stdin["UserPoolId"] == target:
                self.live[target]["Policies"] = {"PasswordPolicy": {"MinimumLength": 99}}
                self.live[target]["UserPoolTags"] = {"purpose": self.parity.TAG_VALUE, "other": "placeholder"}
            return result
        self.parity.aws = interfering
        with self.assertRaises(SystemExit) as refused:
            self.parity.self_sign_up("on", lease=self.run_pid())
        self.assertIn("Policies, UserPoolTags changed as well; re-run infra/provision.sh", str(refused.exception.code))

    def test_a_toggle_or_read_failure_keeps_the_cli_tail(self):
        """Test that a failed toggle, and a pool that cannot be read, report the AWS CLI's redacted tail

        - Given: `off` with every pool on, UpdateUserPool on one pool failing, and then DescribeUserPool on one pool
          failing, each with a multi-line stderr whose last line is the launcher's
        - When:
           - `self-sign-up off` runs each time
        - Then:
           - it exits non-zero naming the pool, the code and the message, followed by the tail with the cause
        """
        real = self.fake_aws
        for flag in self.live.values():
            flag["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"] = False
        crash = self.parity.AwsError("Unknown", "[PYI-4242:ERROR] Failed to execute script 'aws'",
                                     "OSError: [Errno 28] No space left on device\n"
                                     "[PYI-4242:ERROR] Failed to execute script 'aws'")
        for operation in ("update-user-pool", "describe-user-pool"):
            with self.subTest(operation=operation):
                failing = self.ids["passwordless"]

                def failing_call(*args, stdin=None, **kwargs):
                    pool_id = stdin["UserPoolId"] if stdin else args[args.index("--user-pool-id") + 1]
                    if args[:2] == ("cognito-idp", operation) and pool_id == failing:
                        raise crash
                    return real(*args, stdin=stdin, **kwargs)
                self.parity.aws = self.parity.aws_or_none = failing_call
                with self.assertRaises(SystemExit) as failed:
                    self.parity.self_sign_up("off")
                report = str(failed.exception.code)
                self.assertIn("passwordless", report)
                self.assertIn("Unknown", report)
                self.assertIn("AWS CLI stderr, last lines (redacted):\n    OSError: [Errno 28] No space left on device",
                              report)

    def test_an_on_that_fails_part_way_stops_and_release_undoes_it(self):
        """Given: an UpdateUserPool that fails on the passwordless pool when turning on.
        When: a run turns self sign-up on, and its trap then releases.
        Then: on exits non-zero; the pools before passwordless (sorted) were turned on, and no pool after it was
        tried; release turns every pool off."""
        real = self.fake_aws
        failing = self.ids["passwordless"]

        def failing_on(*args, stdin=None, **kwargs):
            if (args[:2] == ("cognito-idp", "update-user-pool") and stdin["UserPoolId"] == failing
                    and stdin["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"] is False):
                self.calls.append((args[:2], copy.deepcopy(stdin)))
                raise self.parity.AwsError("InternalErrorException", "placeholder")
            return real(*args, stdin=stdin, **kwargs)
        self.parity.aws = failing_on
        run = self.run_pid()
        with self.assertRaises(SystemExit) as refused:
            self.parity.self_sign_up("on", lease=run)
        self.assertIn("InternalErrorException", str(refused.exception.code))
        order = sorted(self.ids)
        tried = [update["UserPoolId"] for update in self.updates()]
        self.assertEqual(tried, [self.ids[key] for key in order[:order.index("passwordless") + 1]])
        self.assertEqual(self.leases(), [run])

        self.parity.self_sign_up("release", lease=run)
        self.assertEqual(set(self.flags().values()), {False})

    def test_the_tag_is_checked_again_before_each_update(self):
        """Given: a pool whose purpose tag is removed after the first check, before its update.
        When: a run turns self sign-up on. Then: that pool is never updated, and the command exits non-zero."""
        real = self.fake_aws
        target = self.ids["default"]
        described = []

        def untagging(*args, stdin=None, **kwargs):
            if args[:2] == ("cognito-idp", "describe-user-pool") and args[-1] == target:
                described.append(target)
                if len(described) > 1:
                    self.live[target]["UserPoolTags"] = {}
            return real(*args, stdin=stdin, **kwargs)
        self.parity.aws = untagging
        with self.assertRaises(SystemExit) as refused:
            self.parity.self_sign_up("on", lease=self.run_pid())
        self.assertIn("not tagged", str(refused.exception.code))
        self.assertNotIn(target, [update["UserPoolId"] for update in self.updates()])

    def test_live_update_document_leaves_the_described_pool_unchanged(self):
        """Given: a described pool. When: its update document is made. Then: only UPDATE_KEYS fields, without
        UnusedAccountValidityDays, and the described pool itself still has it (a deep copy)."""
        pool = self.live_pool("default")
        document = self.parity.live_update_document(pool)
        self.assertLessEqual(set(document), self.parity.UPDATE_KEYS)
        self.assertNotIn("UnusedAccountValidityDays", document["AdminCreateUserConfig"])
        self.assertIn("UnusedAccountValidityDays", pool["AdminCreateUserConfig"])

    # --- leases ---------------------------------------------------------------------------------------------

    def test_two_overlapping_runs_share_self_sign_up(self):
        """Given: two runs. When: both turn self sign-up on, the second releases, then the first.
        Then: the second release leaves it on (no update), and only the last release turns it off."""
        first, second = self.run_pid(), self.run_pid()
        self.parity.self_sign_up("on", lease=first)
        self.parity.self_sign_up("on", lease=second)
        self.assertEqual(len(self.updates()), len(self.ids), "the second on changes nothing")
        self.assertEqual(sorted(self.leases()), sorted([first, second]))
        self.parity.self_sign_up("release", lease=second)
        self.assertEqual(set(self.flags().values()), {True})
        self.assertEqual(len(self.updates()), len(self.ids))
        self.assertTrue(any("stays on" in line for line in self.said))
        self.parity.self_sign_up("release", lease=first)
        self.assertEqual(set(self.flags().values()), {False})
        self.assertEqual(self.leases(), [])

    def test_a_dead_or_reused_pid_holds_no_lease(self):
        """Given: a lease whose run has exited, and one whose PID is alive but started at another time (a reused
        PID). Then: neither is live, and a run's release with only them left turns self sign-up off."""
        dead = subprocess.Popen(["true"])
        dead.wait()
        reused = self.run_pid()
        self.parity.write_leases([{"pid": dead.pid, "start": "Thu Jan  1 00:00:00 1970", "clock": "C/UTC"},
                                  {"pid": reused, "start": "Thu Jan  1 00:00:00 1970", "clock": "C/UTC"}])
        self.assertEqual(self.parity.live_leases(), [])
        run = self.run_pid()
        self.parity.self_sign_up("on", lease=run)
        self.parity.self_sign_up("release", lease=run)
        self.assertEqual(set(self.flags().values()), {False})
        self.assertEqual(self.leases(), [])

    def set_clock(self, **environment):
        """Sets the locale and time zone variables to `environment` alone, restored after the test."""
        for name in ("LANG", "LC_ALL", "LC_TIME", "TZ"):
            self.addCleanup(lambda name=name, value=os.environ.get(name): (
                os.environ.__setitem__(name, value) if value is not None else os.environ.pop(name, None)))
            os.environ.pop(name, None)
        os.environ.update(environment)

    def test_a_lease_is_live_whatever_the_locale_and_time_zone(self):
        """Given: a live run whose lease was taken under LANG=en_CA.UTF-8 and TZ=America/Toronto (`ps` prints
        its start as "Fri  2 Oct 05:54:37 2026" there). When: it is checked under LC_ALL=C and TZ=Asia/Tokyo,
        and under the first locale again.
        Then: it is live each time, so `off` refuses under the run, and its release turns self sign-up off."""
        run = self.run_pid()
        self.set_clock(LANG="en_CA.UTF-8", TZ="America/Toronto")
        self.parity.self_sign_up("on", lease=run)
        self.set_clock(LC_ALL="C", TZ="Asia/Tokyo")
        self.assertEqual([lease["pid"] for lease in self.parity.live_leases()], [run])
        with self.assertRaises(SystemExit) as refused:
            self.parity.self_sign_up("off")
        self.assertIn(str(run), str(refused.exception.code))
        self.assertEqual(set(self.flags().values()), {True})
        self.set_clock(LANG="en_CA.UTF-8", TZ="America/Toronto")
        self.assertEqual([lease["pid"] for lease in self.parity.live_leases()], [run])
        self.parity.self_sign_up("release", lease=run)
        self.assertEqual(set(self.flags().values()), {False})

    def test_a_lease_without_a_clock_is_dead_even_on_a_live_pid(self):
        """Given: a lease without "clock" (not written by this code: a dead run's, say) whose PID now belongs to an
        unrelated live process, even with that process's start time recorded. When: the leases are read, then
        `off` runs, then a run turns self sign-up on and releases it.
        Then: the lease is never live, so `off` turns self sign-up off, and the run's release turns it off too and
        drops the lease: it fails toward off."""
        unrelated = self.run_pid()
        for pool in self.live.values():
            pool["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"] = False
        self.parity.write_leases([{"pid": unrelated, "start": self.parity.process_start(unrelated)}])
        self.assertEqual(self.parity.live_leases(), [])
        self.parity.self_sign_up("off")
        self.assertEqual(set(self.flags().values()), {False})
        self.parity.write_leases([{"pid": unrelated, "start": self.parity.process_start(unrelated)}])
        run = self.run_pid()
        self.parity.self_sign_up("on", lease=run)
        self.parity.self_sign_up("release", lease=run)
        self.assertEqual(set(self.flags().values()), {False})
        self.assertEqual(self.leases(), [])

    def test_recovery_off_refuses_while_a_live_lease_exists_unless_forced(self):
        """Given: a run holding self sign-up on. When: `off`, then `off --force`.
        Then: off refuses naming the run and changes nothing; forced, it turns every pool off and drops the lease."""
        run = self.run_pid()
        self.parity.self_sign_up("on", lease=run)
        updates = len(self.updates())
        with self.assertRaises(SystemExit) as refused:
            self.parity.self_sign_up("off")
        self.assertIn(str(run), str(refused.exception.code))
        self.assertEqual(len(self.updates()), updates)
        self.parity.self_sign_up("off", force=True)
        self.assertEqual(set(self.flags().values()), {False})
        self.assertEqual(self.leases(), [])

    def test_on_and_release_need_a_lease(self):
        """Given: no run. When: on or release is asked for without a lease. Then: it refuses, before any call."""
        for mode in ("on", "release"):
            with self.assertRaises(SystemExit) as refused:
                self.parity.self_sign_up(mode)
            self.assertIn("only through infra/self-sign-up.sh", str(refused.exception.code))
        self.assertEqual(self.calls, [])

    def test_provision_refuses_while_a_lease_is_held(self):
        """Given: a run holding a live lease. When: provision runs. Then: it refuses naming the run, before any
        call; `self-sign-up require-idle`, which provision.sh runs first, refuses too."""
        run = self.run_pid()
        self.parity.write_leases([{"pid": run, "start": self.parity.process_start(run), "clock": "C/UTC"}])
        with self.assertRaises(SystemExit) as refused:
            self.parity.provision()
        self.assertIn("Refusing to provision", str(refused.exception.code))
        self.assertIn(str(run), str(refused.exception.code))
        with self.assertRaises(SystemExit):
            self.parity.self_sign_up_command(["require-idle"])
        self.assertEqual(self.calls, [])

    def test_a_held_lock_serialises_toggles(self):
        """Given: another process holding the toggle lock. When: a run asks to turn self sign-up on.
        Then: it waits, saying so, and changes nothing until the lock is released."""
        holder = subprocess.Popen([sys.executable, "-c", (
            "import fcntl, os, sys, time\n"
            "fd = os.open(sys.argv[1], os.O_RDWR | os.O_CREAT, 0o600)\n"
            "fcntl.flock(fd, fcntl.LOCK_EX)\n"
            "print('held', flush=True)\n"
            "time.sleep(1)\n"), self.parity.SELF_SIGN_UP_LOCK], stdout=subprocess.PIPE, text=True)
        self.assertEqual(holder.stdout.readline().strip(), "held")
        started = time.monotonic()
        self.parity.self_sign_up("on", lease=self.run_pid())
        self.assertGreater(time.monotonic() - started, 0.5)
        self.assertIn("Waiting for another self sign-up change, or a provision, to finish", self.said)
        holder.wait()
        holder.stdout.close()

    # --- the CLI ------------------------------------------------------------------------------------------------

    def test_the_cli_needs_the_wrappers_token(self):
        """Given: no token, then a token that is not this process's parent. When: `self-sign-up on` and `release`
        are run through the CLI. Then: each refuses before any call."""
        for token in (None, "1"):
            if token:
                os.environ[self.parity.SELF_SIGN_UP_WRAPPER] = token
            for mode in ("on", "release"):
                with self.assertRaises(SystemExit) as refused:
                    self.parity.self_sign_up_command([mode])
                self.assertIn("only through infra/self-sign-up.sh", str(refused.exception.code))
        os.environ.pop(self.parity.SELF_SIGN_UP_WRAPPER, None)
        self.assertEqual(self.calls, [])

    def test_interrupts_are_held_once_the_lock_is_held(self):
        """Given: the toggle itself stubbed. When: `self-sign-up off --force` runs through the CLI.
        Then: INT, TERM and HUP are at their defaults until the lock is held (so a Ctrl-C can stop a run waiting
        for it), and held from then on by a handler that only records them, so a Ctrl-C can never cut a toggle
        between its update and its MFA restore; and the mode and force flag reach the toggle."""
        seen = []
        real_lock = self.parity.self_sign_up_lock

        @contextlib.contextmanager
        def lock():
            seen.append(("waiting", [signal.getsignal(n) for n in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP)]))
            with real_lock():
                yield

        def toggle(state, on):
            seen.append(("toggling", [signal.getsignal(n) for n in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP)]))
        self.parity.self_sign_up_lock = lock
        self.parity.set_self_sign_up = toggle
        self.parity.self_sign_up_command(["off", "--force"])
        self.assertEqual(seen[0], ("waiting", [signal.default_int_handler, signal.SIG_DFL, signal.SIG_DFL]))
        self.assertEqual(seen[1][0], "toggling")
        for handler in seen[1][1]:
            self.assertTrue(callable(handler))
            self.assertNotIn(handler, (signal.default_int_handler, signal.SIG_DFL, signal.SIG_IGN))
        for bad in (["sideways"], ["on", "--force"], ["off", "--now"], ["status", "--force"], []):
            with self.assertRaises(SystemExit):
                self.parity.self_sign_up_command(bad)

    def test_a_signal_held_during_the_toggle_ends_the_command_with_its_status(self):
        """Test that a signal held off during a toggle is not lost: the command finishes, then exits 128 + it

        - Given: a run's `on` whose toggles each receive SIGINT and then SIGTERM part-way (a Ctrl-C, then a kill)
        - When:
           - `self-sign-up on` runs through the CLI
        - Then:
           - every pool is turned on, its MFA restored, as with no signal; the command then exits 130 (the first
             signal's), saying it held SIGINT
           - and a release of that run, with SIGINT again during its toggles, turns every pool off and exits 130
        """
        real = self.fake_aws

        def interrupted(*args, stdin=None, **kwargs):
            if args[:2] == ("cognito-idp", "update-user-pool"):
                os.kill(os.getpid(), signal.SIGINT)
                os.kill(os.getpid(), signal.SIGTERM)
            return real(*args, stdin=stdin, **kwargs)
        self.parity.aws = interrupted
        warned = []
        self.parity.warn = warned.append
        run = self.run_pid()
        # As the wrapper runs it: the run is the parent, and its PID the token.
        with mock.patch.dict(os.environ, {self.parity.SELF_SIGN_UP_WRAPPER: str(run)}), \
                mock.patch.object(self.parity.os, "getppid", lambda: run):
            with self.assertRaises(SystemExit) as on:
                self.parity.self_sign_up_command(["on"])
            self.assertEqual(on.exception.code, 130)
            self.assertEqual(set(self.flags().values()), {True})
            self.assertTrue(any(line.startswith("SIGINT arrived during self-sign-up on") for line in warned), warned)
            for key, pool_id in self.ids.items():
                self.assertEqual(self.mfa[pool_id], provisioned_mfa(self.parity, key), key)
            with self.assertRaises(SystemExit) as release:
                self.parity.self_sign_up_command(["release"])
            self.assertEqual(release.exception.code, 130)
        self.assertEqual(set(self.flags().values()), {False})

    def test_a_signal_ignored_at_start_stays_ignored(self):
        """Test that a signal the command starts with ignored (the wrapper's release ignores INT, TERM and HUP) stays
        ignored, and so does not change its status

        - Given: INT, TERM and HUP ignored, and every pool on
        - When:
           - `self-sign-up off` runs, receiving SIGINT during its toggles
        - Then:
           - every pool is turned off, and the command returns normally
        """
        for number in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
            signal.signal(number, signal.SIG_IGN)
        for flag in self.live.values():
            flag["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"] = False
        real = self.fake_aws

        def interrupted(*args, stdin=None, **kwargs):
            if args[:2] == ("cognito-idp", "update-user-pool"):
                os.kill(os.getpid(), signal.SIGINT)
            return real(*args, stdin=stdin, **kwargs)
        self.parity.aws = interrupted
        self.parity.self_sign_up_command(["off"])
        self.assertEqual(set(self.flags().values()), {False})
        self.assertEqual(signal.getsignal(signal.SIGINT), signal.SIG_IGN)

    def test_the_aws_cli_ignores_the_held_signals(self):
        """Test that the AWS CLI calls made while signals are held start with INT, TERM and HUP ignored

        - Given: a fake `aws` on PATH that reports how it starts with each of the three
        - When:
           - parity.aws runs it before hold_interrupts, then after
        - Then:
           - before, none is ignored; after, all three are, so a Ctrl-C to the run's process group cannot cut a call
        """
        self.parity.aws = self.real_aws
        work = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, work)
        fake = os.path.join(work, "aws")
        with open(fake, "w") as f:
            f.write("#!/usr/bin/env python3\nimport json, signal\nprint(json.dumps([signal.getsignal(n) == "
                    "signal.SIG_IGN for n in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP)]))\n")
        os.chmod(fake, 0o755)
        self.parity.REGION = "xx-test-1"
        with mock.patch.dict(os.environ, {"PATH": work + os.pathsep + os.environ["PATH"]}):
            self.assertEqual(self.parity.aws("sts", "get-caller-identity"), [False, False, False])
            self.parity.hold_interrupts()
            self.assertEqual(self.parity.aws("sts", "get-caller-identity"), [True, True, True])

    def test_a_ctrl_c_while_waiting_for_the_lock_changes_nothing(self):
        """Given: another process holding the toggle lock for 20 s. When: a run's `self-sign-up on` waits for it
        and gets SIGINT after 0.5 s. Then: it exits 130 at once, saying nothing was changed, with no update
        and no lease."""
        holder = subprocess.Popen([sys.executable, "-c", (
            "import fcntl, os, sys, time\n"
            "fd = os.open(sys.argv[1], os.O_RDWR | os.O_CREAT, 0o600)\n"
            "fcntl.flock(fd, fcntl.LOCK_EX)\n"
            "print('held', flush=True)\n"
            "time.sleep(20)\n"), self.parity.SELF_SIGN_UP_LOCK], stdout=subprocess.PIPE, text=True)
        self.addCleanup(lambda: (holder.kill(), holder.wait(), holder.stdout.close()))
        self.assertEqual(holder.stdout.readline().strip(), "held")
        run = self.run_pid()
        os.environ[self.parity.SELF_SIGN_UP_WRAPPER] = str(run)
        self.addCleanup(os.environ.pop, self.parity.SELF_SIGN_UP_WRAPPER, None)
        self.parity.warn = self.said.append
        timer = threading.Timer(0.5, os.kill, (os.getpid(), signal.SIGINT))
        timer.start()
        self.addCleanup(timer.cancel)
        started = time.monotonic()
        with mock.patch.object(self.parity.os, "getppid", return_value=run), \
                self.assertRaises(SystemExit) as interrupted:
            self.parity.self_sign_up_command(["on"])
        self.assertLess(time.monotonic() - started, 10)
        self.assertEqual(interrupted.exception.code, 130)
        self.assertEqual((self.updates(), self.leases()), ([], []))
        self.assertTrue(any("nothing was changed" in line for line in self.said), self.said)

    def test_a_release_by_a_run_without_a_lease_changes_nothing_and_does_not_wait(self):
        """Given: a run whose on never recorded a lease (stopped while it waited for the lock), every pool
        on under another run's lease, and the lock held by another process. When: the first run releases.
        Then: it returns at once, without the lock, and changes nothing."""
        other = self.run_pid()
        self.parity.self_sign_up("on", lease=other)
        updates = len(self.updates())
        holder = subprocess.Popen([sys.executable, "-c", (
            "import fcntl, os, sys, time\n"
            "fd = os.open(sys.argv[1], os.O_RDWR | os.O_CREAT, 0o600)\n"
            "fcntl.flock(fd, fcntl.LOCK_EX)\n"
            "print('held', flush=True)\n"
            "time.sleep(20)\n"), self.parity.SELF_SIGN_UP_LOCK], stdout=subprocess.PIPE, text=True)
        self.addCleanup(lambda: (holder.kill(), holder.wait(), holder.stdout.close()))
        self.assertEqual(holder.stdout.readline().strip(), "held")
        started = time.monotonic()
        self.parity.self_sign_up("release", lease=self.run_pid())
        self.assertLess(time.monotonic() - started, 10)
        self.assertEqual(len(self.updates()), updates)
        self.assertEqual(set(self.flags().values()), {True})
        self.assertEqual(self.leases(), [other])

    def test_status_says_whether_every_pool_is_at_rest(self):
        """Given: every pool off with its MFA; then one pool on; then, off again, one pool's MFA reset. When:
        `self-sign-up status` (read-only; the script runs it after a release that did not finish). Then: it exits
        0, then 3 naming the pool that is on, then 3 naming the MFA gap; it never changes a pool."""
        self.parity.self_sign_up_command(["status"])
        self.assertTrue(any("every parity pool has self sign-up off" in line for line in self.said), self.said)
        self.live[self.ids["passwordless"]]["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"] = False
        with self.assertRaises(SystemExit) as on:
            self.parity.self_sign_up_command(["status"])
        self.assertEqual(on.exception.code, 3)
        self.assertIn(f"Self sign-up is still on: {self.parity.POOLS['passwordless']}", self.said)
        self.live[self.ids["passwordless"]]["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"] = True
        self.mfa[self.ids["mfa-req-email"]] = {"MfaConfiguration": "OFF"}
        with self.assertRaises(SystemExit) as reset:
            self.parity.self_sign_up_command(["status"])
        self.assertEqual(reset.exception.code, 3)
        self.assertTrue(any("mfa-req-email: MFA is OFF" in line for line in self.said), self.said)
        self.assertEqual(self.updates(), [])
        self.assertNotIn(("cognito-idp", "set-user-pool-mfa-config"), [operation for operation, _ in self.calls])

    def test_status_tells_other_runs_leases_from_the_callers_own(self):
        """Given: every pool on, and the calling wrapper's own lease left by a release that did not finish. When:
        `self-sign-up status` runs with the wrapper's token (from a subshell, so not this process's parent),
        alone, then with another live run's lease too.
        Then: alone, it exits 3 (on, and nobody holds it: run off); with the other run, it exits 4 naming that
        run's PID only, since self sign-up is on for it and its end turns it off."""
        for pool in self.live.values():
            pool["AdminCreateUserConfig"]["AllowAdminCreateUserOnly"] = False
        own, other = self.run_pid(), self.run_pid()
        os.environ[self.parity.SELF_SIGN_UP_WRAPPER] = str(own)
        self.addCleanup(os.environ.pop, self.parity.SELF_SIGN_UP_WRAPPER, None)
        clock = self.parity.LEASE_CLOCK
        self.parity.write_leases([{"pid": own, "start": self.parity.process_start(own), "clock": clock}])
        with self.assertRaises(SystemExit) as alone:
            self.parity.self_sign_up_command(["status"])
        self.assertEqual(alone.exception.code, 3)
        self.assertFalse(any("other infra/self-sign-up.sh run" in line for line in self.said), self.said)
        self.parity.write_leases([{"pid": pid, "start": self.parity.process_start(pid), "clock": clock}
                                  for pid in (own, other)])
        with self.assertRaises(SystemExit) as shared:
            self.parity.self_sign_up_command(["status"])
        self.assertEqual(shared.exception.code, 4)
        self.assertIn(f"1 other infra/self-sign-up.sh run(s) hold self sign-up on (PID {other}); the last of them "
                      "to end turns it off", self.said)
        self.assertEqual(self.updates(), [])


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

    def test_there_are_eight_distinct_test_users(self):
        """Given: the users prepare-run.sh resets. Then: eight distinct ccit- test users, 1 to 8 in order: one
        round of the plugin's Gen1 and Gen2 suites and the client's CH-1 takes three, and retries more."""
        users = self.parity.PLUGIN_NEW_PASSWORD_USERS
        self.assertEqual(self.parity.PLUGIN_NEW_PASSWORD_USER_COUNT, 8)
        self.assertEqual(users, tuple(f"ccit-plugin-new-password-{i}" for i in range(1, 9)))
        self.assertEqual(len(set(users)), 8)

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

    def test_the_mfa_checks_relying_party_is_the_one_provision_resolves(self):
        """Test that the MFA check resolves ${WEBAUTHN_RP_ID} as provision does

        - Given: the committed harness files
        - When:
           - harness_rp_id runs, and webauthn_relying_party runs with its apple-app-site-association listing the
             harness's app ID
        - Then:
           - both give the harness's webcredentials domain, and from then on it is masked in everything said
           - with the harness's files unreadable, harness_rp_id gives None
        """
        domain, app_id, _ = self.parity.webauthn_harness_identity()
        rp_id = self.parity.harness_rp_id()
        self.assertTrue(rp_id == domain and bool(rp_id))
        self.assertEqual(self.parity.redact(f"rp {rp_id}"), "rp <domain>")

        class Response(io.BytesIO):
            def __enter__(self):
                return self

            def __exit__(self, *_):
                return False

        association = json.dumps({"webcredentials": {"apps": [app_id]}}).encode()
        with mock.patch("urllib.request.urlopen", lambda *args, **kwargs: Response(association)):
            provisioned, gap = self.parity.webauthn_relying_party()
        self.assertIsNone(gap)
        self.assertTrue(provisioned == rp_id)

        self.parity.webauthn_harness_identity = lambda: (None, None, "the harness entitlements cannot be read")
        self.assertIsNone(self.parity.harness_rp_id())

    def test_missing_or_malformed_harness_files_give_no_relying_party_and_no_exception(self):
        """Test that harness_rp_id returns None, never raising, when a harness file is missing or malformed

        - Given: in turn, a missing harness entitlements file, a missing plugin entitlements file, a missing project,
          an entitlements file that is not a property list, one that is truncated XML, and a project that is not UTF-8
        - When:
           - harness_rp_id runs
        - Then:
           - it returns None each time
        """
        missing = os.path.join(self.state, "missing")
        not_a_plist = os.path.join(self.state, "not-a-plist.entitlements")
        with open(not_a_plist, "w") as f:
            f.write("placeholder, not a property list")
        truncated = os.path.join(self.state, "truncated.entitlements")
        with open(truncated, "w") as f:
            f.write('<?xml version="1.0" encoding="UTF-8"?>\n<plist version="1.0"><dict><key>')
        not_utf8 = os.path.join(self.state, "project.pbxproj")
        with open(not_utf8, "wb") as f:
            f.write(b"\xff\xfe\x00 placeholder")
        for name, path in (("WEBAUTHN_ENTITLEMENTS", missing), ("PLUGIN_WEBAUTHN_ENTITLEMENTS", missing),
                           ("WEBAUTHN_PROJECT", missing), ("WEBAUTHN_ENTITLEMENTS", not_a_plist),
                           ("WEBAUTHN_ENTITLEMENTS", truncated), ("WEBAUTHN_PROJECT", not_utf8)):
            with self.subTest(name=name, path=os.path.basename(path)):
                with mock.patch.object(self.parity, name, path):
                    self.assertIsNone(self.parity.harness_rp_id())

    def test_verify_reports_an_unreadable_harness_as_unknown(self):
        """Test that verify's WebAuthn summary says "unknown", not a traceback, when the harness's files are unreadable

        - Given: a live WebAuthnConfiguration, and the WebAuthn harness's entitlements missing
        - When:
           - webauthn_summary runs, as verify runs it
        - Then:
           - it returns "unknown"; a pool without WebAuthn is still None
        """
        live = {"WebAuthnConfiguration": {"RelyingPartyId": "placeholder-rp.example", "UserVerification": "preferred"}}
        with mock.patch.object(self.parity, "WEBAUTHN_ENTITLEMENTS", os.path.join(self.state, "missing")):
            self.assertEqual(self.parity.webauthn_summary(live), "unknown")
            self.assertIsNone(self.parity.webauthn_summary({"MfaConfiguration": "OFF"}))

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


class PluginIdentityPoolTests(unittest.TestCase):
    """P-13: its providers (the default pool's plugin and hosted-UI clients, and the passwordless pool's
    client and CI-shaped `ci` client), the update that adds a missing one after a tag check, and the passwordless outputs that name
    it. Over a scripted Cognito Identity: no AWS call is made."""

    def setUp(self):
        self.state = tempfile.mkdtemp()
        os.environ["COGNITO_CLIENT_INTEG_DIR"] = self.state
        spec = importlib.util.spec_from_file_location("parity", os.path.join(INFRA, "parity.py"))
        self.parity = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.parity)
        self.parity.REGION = "xx-test-1"
        self.parity.say = lambda message: None
        self.record = {"pools": {
            "default": {"userPoolId": "xx-test-1_default", "clients": {"client": "c-client", "plugin": "c-plugin",
                                                                        "hostedui": "c-hosted",
                                                                        "hostedui-plugin": "c-hosted-plugin"}},
            "passwordless": {"userPoolId": "xx-test-1_passwordless", "clients": {"client": "c-passwordless",
                                                                                  "ci": "c-passwordless-ci"}},
            "webauthn": {"userPoolId": "xx-test-1_webauthn", "clients": {"client": "c-webauthn"}}},
            "pluginIdentityPoolId": "xx-test-1:plugin"}
        self.calls = []
        self.current_providers = []
        self.parity.aws = self.fake_aws
        self.parity.aws_or_none = lambda *args, **kwargs: {}
        self.parity.require_identity_pool_tag = lambda pool_id, label: self.calls.append(("tag-check", pool_id))
        self.parity.ensure_permissionless_role = lambda suffix, trust: f"arn:role/{suffix}"
        self.parity.run_with_iam_retry = lambda function: function()

    def tearDown(self):
        shutil.rmtree(self.state)
        del os.environ["COGNITO_CLIENT_INTEG_DIR"]

    def fake_aws(self, *args, stdin=None, **kwargs):
        operation = args[1]
        self.calls.append((operation, stdin))
        if operation == "describe-identity-pool":
            return {"AllowUnauthenticatedIdentities": True, "CognitoIdentityProviders": self.current_providers}
        return {}

    def operations(self):
        return [name for name, _ in self.calls]

    def test_providers_are_the_default_plugin_clients_and_the_passwordless_client(self):
        providers = self.parity.plugin_identity_providers(self.record)
        self.assertEqual(
            sorted((p["ProviderName"], p["ClientId"]) for p in providers),
            [("cognito-idp.xx-test-1.amazonaws.com/xx-test-1_default", "c-hosted-plugin"),
             ("cognito-idp.xx-test-1.amazonaws.com/xx-test-1_default", "c-plugin"),
             ("cognito-idp.xx-test-1.amazonaws.com/xx-test-1_passwordless", "c-passwordless"),
             ("cognito-idp.xx-test-1.amazonaws.com/xx-test-1_passwordless", "c-passwordless-ci")])
        self.assertTrue(all(p["ServerSideTokenCheck"] is False for p in providers))

    def test_a_pool_without_the_passwordless_provider_is_updated_after_a_tag_check(self):
        self.current_providers = [p for p in self.parity.plugin_identity_providers(self.record)
                                  if "passwordless" not in p["ProviderName"]]
        self.parity.ensure_plugin_identity_pool(self.record)
        update = [stdin for name, stdin in self.calls if name == "update-identity-pool"]
        self.assertEqual(len(update), 1)
        self.assertEqual(update[0]["CognitoIdentityProviders"], self.parity.plugin_identity_providers(self.record))
        index = self.operations().index("update-identity-pool")
        self.assertEqual(self.operations()[index - 1], "tag-check")

    def test_a_pool_with_every_provider_is_not_updated(self):
        self.current_providers = list(reversed(self.parity.plugin_identity_providers(self.record)))
        self.parity.ensure_plugin_identity_pool(self.record)
        self.assertNotIn("update-identity-pool", self.operations())

    def test_the_passwordless_outputs_name_the_plugin_identity_pool_and_keep_the_rest(self):
        document = {"version": "1.4", "auth": {"user_pool_id": "xx-test-1_passwordless",
                                               "unauthenticated_identities_enabled": False}}
        other = {"version": "1.4", "auth": {"user_pool_id": "xx-test-1_default"}}
        self.parity.write_outputs("passwordless", document)
        self.parity.write_outputs("default", other)

        self.parity.name_plugin_identity_pool_in_outputs(self.record)

        with open(self.parity.outputs_path("passwordless")) as f:
            written = json.load(f)
        self.assertEqual(written["auth"], {"user_pool_id": "xx-test-1_passwordless",
                                           "identity_pool_id": "xx-test-1:plugin",
                                           "unauthenticated_identities_enabled": True})
        self.assertEqual(written["version"], "1.4")
        self.assertEqual(os.stat(self.parity.outputs_path("passwordless")).st_mode & 0o777, 0o600)
        with open(self.parity.outputs_path("default")) as f:
            self.assertEqual(json.load(f), other)

    def test_naming_twice_writes_the_same_file(self):
        self.parity.write_outputs("passwordless", {"version": "1.4", "auth": {"user_pool_id": "p"}})
        self.parity.name_plugin_identity_pool_in_outputs(self.record)
        with open(self.parity.outputs_path("passwordless")) as f:
            first = f.read()
        self.parity.name_plugin_identity_pool_in_outputs(self.record)
        with open(self.parity.outputs_path("passwordless")) as f:
            self.assertEqual(f.read(), first)


class CIShapeClientTests(unittest.TestCase):
    """The `ci` app clients plugin-configs.py --ci-shape names, and the pre-sign-up trigger's list of those
    it leaves unconfirmed. Templates and state only: no AWS call is made."""

    def setUp(self):
        spec = importlib.util.spec_from_file_location("parity", os.path.join(INFRA, "parity.py"))
        self.parity = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.parity)

    def test_the_ci_clients_are_the_sandbox_clients_as_ci_has_them(self):
        for key in self.parity.POOLS:
            clients = self.parity.load_template(key)["appClients"]
            self.assertEqual("ci" in clients, key in self.parity.CI_SHAPE_CLIENT_POOLS, key)
            if "ci" not in clients:
                continue
            ci, client = clients["ci"], clients["client"]
            flows = set(client["ExplicitAuthFlows"])
            if key != "passwordless":
                # CI's MFA-required, email-MFA and device-alias clients refuse USER_PASSWORD_AUTH.
                flows.discard("ALLOW_USER_PASSWORD_AUTH")
            self.assertEqual(set(ci["ExplicitAuthFlows"]), flows, key)
            self.assertEqual({k: v for k, v in ci.items() if k != "ExplicitAuthFlows"},
                             {k: v for k, v in client.items() if k != "ExplicitAuthFlows"}, key)

    def test_the_unconfirmed_clients_are_the_recorded_ci_clients_of_those_pools(self):
        self.assertTrue(set(self.parity.CI_SHAPE_UNCONFIRMED_POOLS) <= set(self.parity.CI_SHAPE_CLIENT_POOLS))
        record = {"pools": {"passwordless": {"clients": {"client": "c-1", "ci": "ci-passwordless"}},
                            "email-alias": {"clients": {"client": "c-2"}},
                            "mfa-req-all": {"clients": {"client": "c-3", "ci": "ci-all"}}}}
        self.assertEqual(self.parity.ci_shape_client_ids(record, self.parity.CI_SHAPE_UNCONFIRMED_POOLS),
                         "ci-passwordless")
        record["pools"]["email-alias"]["clients"]["ci"] = "ci-alias"
        self.assertEqual(self.parity.ci_shape_client_ids(record, self.parity.CI_SHAPE_UNCONFIRMED_POOLS),
                         "ci-alias,ci-passwordless")
        self.assertIn("CI_SHAPE_UNCONFIRMED_CLIENT_IDS", self.parity.FUNCTIONS["pre-sign-up"][3])



class WebAuthnMfaDriftTests(unittest.TestCase):
    """Preflight's MFA comparison covers the WebAuthn relying-party settings the templates define, over
    fakes shaped exactly as GetUserPoolMfaConfig answered for the sandbox's seven parity pools on 2026-10-02, values
    replaced by placeholders: WebAuthnConfiguration ({RelyingPartyId, UserVerification}) on the WebAuthn pool only,
    and left out altogether on the others; SmsMfaConfiguration with SmsConfiguration only. No AWS call is made."""

    SMS = {"SmsConfiguration": {"SnsCallerArn": "arn:aws:iam::000000000000:role/placeholder-sms",
                                "ExternalId": "placeholder-external-id", "SnsRegion": "xx-test-1"}}
    TOTP = {"Enabled": True}
    EMAIL = {"Message": "placeholder {####}", "Subject": "placeholder"}
    LIVE = {
        "default": {"SmsMfaConfiguration": SMS, "SoftwareTokenMfaConfiguration": TOTP, "MfaConfiguration": "OPTIONAL"},
        "email-alias": {"MfaConfiguration": "OFF"},
        "mfa-req-all": {"SmsMfaConfiguration": SMS, "SoftwareTokenMfaConfiguration": TOTP,
                        "EmailMfaConfiguration": EMAIL, "MfaConfiguration": "ON"},
        "mfa-req-email": {"SmsMfaConfiguration": SMS, "EmailMfaConfiguration": EMAIL, "MfaConfiguration": "ON"},
        "mfa-req-totp-sms": {"SmsMfaConfiguration": SMS, "SoftwareTokenMfaConfiguration": TOTP,
                             "MfaConfiguration": "ON"},
        "passwordless": {"SmsMfaConfiguration": SMS, "SoftwareTokenMfaConfiguration": TOTP,
                         "MfaConfiguration": "OPTIONAL"},
        "webauthn": {"SmsMfaConfiguration": SMS, "SoftwareTokenMfaConfiguration": TOTP, "MfaConfiguration": "OPTIONAL",
                     "WebAuthnConfiguration": {"RelyingPartyId": RP_ID, "UserVerification": "preferred"}},
    }

    def setUp(self):
        self.state = tempfile.mkdtemp()
        os.environ["COGNITO_CLIENT_INTEG_DIR"] = self.state
        spec = importlib.util.spec_from_file_location("parity", os.path.join(INFRA, "parity.py"))
        self.parity = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.parity)
        self.ids = {key: f"placeholder-{key}" for key in self.parity.POOLS}
        self.write_state({})
        self.live = copy.deepcopy(self.LIVE)
        self.parity.harness_rp_id = lambda: RP_ID
        self.parity.aws_or_none = self.fake_mfa_config
        self.parity.aws = self.fake_mfa_config

    def tearDown(self):
        shutil.rmtree(self.state)
        del os.environ["COGNITO_CLIENT_INTEG_DIR"]

    def write_state(self, pending):
        with open(os.path.join(self.state, "state.json"), "w") as f:
            json.dump({"account": "000000000000", "region": "us-west-2",
                       "parity": {"pools": {k: {"userPoolId": v, "pending": pending.get(k, [])}
                                            for k, v in self.ids.items()}}}, f)

    def fake_mfa_config(self, *args, **kwargs):
        self.assertEqual(args[:2], ("cognito-idp", "get-user-pool-mfa-config"))
        key = next(k for k, v in self.ids.items() if v == args[-1])
        return copy.deepcopy(self.live[key])

    def gaps(self):
        return self.parity.live_mfa_gaps(self.parity.load_state())

    def test_the_fakes_cover_every_parity_pool(self):
        """Test that the live-shaped fakes stand for every parity pool, and only the WebAuthn template has WebAuthn

        - Given: the fakes and pools/*.json
        - When:
           - their keys and WebAuthnConfigurations are compared
        - Then:
           - the fakes name every POOLS key, and WebAuthnConfiguration appears in the WebAuthn template and fake only
        """
        self.assertEqual(set(self.LIVE), set(self.parity.POOLS))
        for key in self.parity.POOLS:
            has_webauthn = "WebAuthnConfiguration" in self.parity.load_template(key)["mfa"]
            self.assertEqual(has_webauthn, key == "webauthn", key)
            self.assertEqual("WebAuthnConfiguration" in self.LIVE[key], key == "webauthn", key)

    def test_pools_as_provisioned_have_no_gap(self):
        """Test that live-shaped MFA configurations as provisioned are no gap

        - Given: every pool's GetUserPoolMfaConfig as the sandbox answered it, the WebAuthn pool naming the
          harness's relying party
        - When:
           - the MFA check runs
        - Then:
           - there is no gap, and the WebAuthn pool's expected and live summaries carry the same WebAuthn settings
        """
        self.assertEqual(self.gaps(), [])
        state = self.parity.load_state()
        expected = self.parity.expected_mfa_summaries(state)["webauthn"]
        self.assertEqual(expected, ("OPTIONAL", ["SMS", "TOTP"], ("the harness's", "preferred")))
        self.assertEqual(self.parity.live_mfa_summaries(state)["webauthn"], expected)

    def test_any_none_shape_is_no_gap_for_a_template_without_webauthn(self):
        """Test that a pool whose template has no WebAuthn accepts whatever Cognito returns for none

        - Given: every pool but the WebAuthn one answering WebAuthnConfiguration left out (as the sandbox does), then
          null, an empty object, one with UserVerification only, and one with an empty RelyingPartyId
        - When:
           - the MFA check runs for each
        - Then:
           - there is no gap for any of them
        """
        for none in (None, {}, {"UserVerification": "preferred"}, {"UserVerification": "required"},
                     {"RelyingPartyId": "", "UserVerification": "preferred"}):
            with self.subTest(none=none):
                for key in self.live:
                    if key != "webauthn":
                        self.live[key]["WebAuthnConfiguration"] = copy.deepcopy(none)
                self.assertEqual(self.gaps(), [])

    def test_relying_party_drift_on_the_webauthn_pool_is_a_gap(self):
        """Test that the WebAuthn pool's relying-party settings are compared with its template's

        - Given: the WebAuthn pool naming another relying party; then user verification "required"; then no
          WebAuthnConfiguration; then one with UserVerification only
        - When:
           - the MFA check runs for each
        - Then:
           - each is one MFA gap on the WebAuthn pool naming what differs, and naming provision, never the domain
        """
        cases = (
            ({"RelyingPartyId": "placeholder-other.example", "UserVerification": "preferred"},
             "WebAuthn with another relying party and user verification preferred"),
            ({"RelyingPartyId": RP_ID, "UserVerification": "required"},
             "WebAuthn with the harness's relying party and user verification required"),
            (None, "no WebAuthn"),
            ({"UserVerification": "preferred"}, "no WebAuthn"),
        )
        for live, described in cases:
            with self.subTest(described=described):
                if live is None:
                    self.live["webauthn"].pop("WebAuthnConfiguration", None)
                else:
                    self.live["webauthn"]["WebAuthnConfiguration"] = copy.deepcopy(live)
                gaps = self.gaps()
                self.assertEqual([kind for kind, _ in gaps], ["MFA"])
                message = gaps[0][1]
                self.assertTrue(message.startswith(f"webauthn: MFA is OPTIONAL ['SMS', 'TOTP'], {described}, but "
                                                   "pools/webauthn.json (as provisioned) has OPTIONAL ['SMS', 'TOTP'], "
                                                   "WebAuthn with the harness's relying party and user verification "
                                                   "preferred; run infra/provision.sh"), message)
                self.assertNotIn(RP_ID, message)
                self.assertNotIn("placeholder-other.example", message)

    def test_a_relying_party_on_a_pool_without_webauthn_is_a_gap(self):
        """Test that WebAuthn on a pool whose template has none is drift

        - Given: the default pool answering a WebAuthnConfiguration that names a relying party
        - When:
           - the MFA check runs
        - Then:
           - it is one MFA gap on that pool, saying its template has no WebAuthn
        """
        self.live["default"]["WebAuthnConfiguration"] = {"RelyingPartyId": RP_ID, "UserVerification": "preferred"}
        gaps = self.gaps()
        self.assertEqual([(kind, gap.split(":")[0]) for kind, gap in gaps], [("MFA", "default")])
        self.assertIn("(as provisioned) has OPTIONAL ['SMS', 'TOTP'], no WebAuthn;", gaps[0][1])

    def test_a_pending_relying_party_expects_no_webauthn(self):
        """Test that a WebAuthn pool provisioned with its relying party pending expects no WebAuthn

        - Given: state.json recording the WebAuthn pool with webauthn-relying-party and web-authn pending, as
          provision degrades it when the relying party is not usable
        - When:
           - the MFA check runs with the pool answering no WebAuthnConfiguration, then the harness's
        - Then:
           - no gap, then one MFA gap on the WebAuthn pool
        """
        self.write_state({"webauthn": ["webauthn-relying-party", "web-authn"]})
        del self.live["webauthn"]["WebAuthnConfiguration"]
        self.assertEqual(self.gaps(), [])
        self.live["webauthn"]["WebAuthnConfiguration"] = copy.deepcopy(self.LIVE["webauthn"]["WebAuthnConfiguration"])
        self.assertEqual([(kind, gap.split(":")[0]) for kind, gap in self.gaps()], [("MFA", "webauthn")])

    def test_an_unresolvable_harness_relying_party_is_a_gap(self):
        """Test that a relying party the check cannot resolve is a gap, not a pass, and says where the fault is

        - Given: the harness's relying party unresolvable (its entitlements unreadable, say), and the WebAuthn pool as
          provisioned
        - When:
           - the MFA check runs, then exit_on_gaps for preflight
        - Then:
           - it is one WEBAUTHN gap on the WebAuthn pool, naming the harness's committed files, not provision, and no
             other pool has a gap
           - preflight refuses with the WEBAUTHN remedy, which restores the harness's files, and no MFA remedy
        """
        self.parity.harness_rp_id = lambda: None
        gaps = self.gaps()
        self.assertEqual([(kind, gap.split(":")[0]) for kind, gap in gaps], [("WEBAUTHN", "webauthn")])
        self.assertIn("the relying party pools/webauthn.json names cannot be resolved", gaps[0][1])
        self.assertIn("committed entitlements or project (CognitoClientHostApp)", gaps[0][1])
        self.assertNotIn("provision", gaps[0][1])
        self.assertNotIn(RP_ID, gaps[0][1])
        self.parity.say = lambda *_: None
        with self.assertRaises(SystemExit) as refused:
            self.parity.exit_on_gaps("preflight", [], gaps)
        self.assertIn("for WEBAUTHN, restore the WebAuthn harness's committed entitlements and project",
                      str(refused.exception.code))
        self.assertNotIn("for MFA", str(refused.exception.code))

    def test_preflight_refuses_relying_party_drift_and_passes_as_provisioned(self):
        """Test that preflight refuses WebAuthn relying-party drift, and passes the pools as provisioned

        - Given: no other gap, and the WebAuthn pool naming another relying party
        - When:
           - preflight runs, then runs again with the pool as provisioned
        - Then:
           - it refuses, naming MFA and provision; then it passes
        """
        for name in ("require_cli_history_off", "require_recorded_account"):
            setattr(self.parity, name, lambda *args: None)
        for name in ("live_sender_gaps", "ses_gaps", "wildcard_gaps", "live_self_sign_up_gaps"):
            setattr(self.parity, name, lambda *args: [])
        said = []
        self.parity.say = said.append
        self.parity.aws = lambda *args, **kwargs: {"IsInSandbox": True}
        self.live["webauthn"]["WebAuthnConfiguration"]["RelyingPartyId"] = "placeholder-other.example"
        with self.assertRaises(SystemExit) as refused:
            self.parity.preflight()
        self.assertIn("for MFA, re-run infra/provision.sh", str(refused.exception.code))
        self.assertTrue(any(line.startswith("MFA webauthn: ") for line in said), said)
        self.live = copy.deepcopy(self.LIVE)
        self.parity.preflight()


class AwsErrorAtTheCommandBoundaryTests(unittest.TestCase):
    """parity.py run as the scripts run it, over a fake `aws` on PATH that refuses one call: an AWS error ends the
    command with one redacted line on stderr and a non-zero exit, never a traceback. No AWS call is
    made: the fake is first on PATH, and the AWS CLI's config and credential files are /dev/null."""

    # The refusal's message carries placeholder identifiers, which the line must not repeat.
    REFUSAL = ("An error occurred ({code}) when calling the {operation} operation: refused for "
               "arn:aws:sts::000000000000:assumed-role/placeholder-role/placeholder-session")
    FAKE_AWS = """#!/usr/bin/env python3
import json, os, sys
args, argv = [], sys.argv[1:]
while argv:
    if argv[0].startswith("--"):
        argv = argv[2:]
    else:
        args, argv = args + [argv[0]], argv[1:]
if args[:3] == ["configure", "get", "cli_history"]:
    sys.exit(1)
if " ".join(args[:2]) == os.environ["FAKE_REFUSE"]:
    sys.stderr.write(os.environ["FAKE_REFUSAL"] + "\\n")
    sys.exit(254)
if args[:2] == ["sts", "get-caller-identity"]:
    print(json.dumps({"Account": "000000000000"}))
    sys.exit(0)
sys.stderr.write(f"fake aws: unexpected call {args}\\n")
sys.exit(2)
"""

    def setUp(self):
        self.work = tempfile.mkdtemp()
        self.state = os.path.join(self.work, "state")
        self.bin = os.path.join(self.work, "bin")
        os.makedirs(self.state)
        os.makedirs(self.bin)
        fake = os.path.join(self.bin, "aws")
        with open(fake, "w") as f:
            f.write(self.FAKE_AWS)
        os.chmod(fake, 0o755)
        with open(os.path.join(self.state, "state.json"), "w") as f:
            json.dump({"account": "000000000000", "region": "xx-test-1",
                       "parity": {"pools": {"passwordless": {"userPoolId": "placeholder-passwordless"}}}}, f)

    def tearDown(self):
        shutil.rmtree(self.work)

    def run_parity(self, *args, refuse, code, refusal=None):
        """parity.py <args…>, with the fake refusing the `refuse` call ("service operation") with `code`, or with
        the stderr `refusal` when given. As infra/self-sign-up.sh runs it: this process, its parent, is the wrapper,
        and holds a lease."""
        with open(os.path.join(self.state, "self-sign-up-leases.json"), "w") as f:
            json.dump([{"pid": os.getpid()}], f)
        operation = "".join(word.capitalize() for word in refuse.split()[1].split("-"))
        environment = {name: value for name, value in os.environ.items()
                       if name not in (RUN,) + CI_VARIABLES and not name.startswith("AWS_")}
        environment.update(PATH=self.bin + os.pathsep + os.environ["PATH"], COGNITO_CLIENT_INTEG_DIR=self.state,
                           AWS_CONFIG_FILE=os.devnull, AWS_SHARED_CREDENTIALS_FILE=os.devnull, FAKE_REFUSE=refuse,
                           FAKE_REFUSAL=refusal or self.REFUSAL.format(code=code, operation=operation),
                           COGNITO_CLIENT_INTEG_SELF_SIGN_UP_WRAPPER=str(os.getpid()))
        return subprocess.run([sys.executable, os.path.join(INFRA, "parity.py"), *args], env=environment,
                              stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=60)

    def assert_one_redacted_line(self, result, starting):
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("Traceback", result.stderr)
        lines = result.stderr.splitlines()
        self.assertEqual(len(lines), 1, result.stderr)
        self.assertTrue(lines[0].startswith(starting), lines[0])
        for identifier in ("000000000000", "placeholder-role", "placeholder-session"):
            self.assertNotIn(identifier, result.stderr + result.stdout)

    def test_sts_refusing_the_self_sign_up_release_prints_one_line(self):
        """Test that an STS refusal during `self-sign-up release` is reported in one line

        - Given: a run that holds a lease, and STS refusing GetCallerIdentity (expired credentials, say)
        - When:
           - the run's trap runs `parity.py self-sign-up release`
        - Then:
           - it exits non-zero, with one redacted line on stderr saying the account could not be confirmed and
             why, and no traceback
        """
        result = self.run_parity("self-sign-up", "release", refuse="sts get-caller-identity", code="ExpiredToken")
        self.assert_one_redacted_line(result, "Could not confirm the AWS account (STS refused): ")
        self.assertIn("ExpiredToken", result.stderr)

    def test_sts_refusing_any_command_prints_one_line(self):
        """Test that an STS refusal is reported in one line by every command that checks the account

        - Given: STS refusing GetCallerIdentity
        - When:
           - each of `self-sign-up on|off|status`, `preflight`, `verify` and `teardown` runs
        - Then:
           - each exits non-zero, with one redacted line on stderr saying the account could not be confirmed, and
             no traceback
        """
        for args in (("self-sign-up", "on"), ("self-sign-up", "off"), ("self-sign-up", "status"), ("preflight",),
                     ("verify",), ("teardown",)):
            with self.subTest(args=args):
                result = self.run_parity(*args, refuse="sts get-caller-identity", code="ExpiredToken")
                self.assert_one_redacted_line(result, "Could not confirm the AWS account (STS refused): ")

    def test_any_other_aws_error_prints_one_line(self):
        """Test that an AWS error no step handles ends the command in one line

        - Given: STS accepting the caller, and Cognito refusing DescribeUserPool
        - When:
           - `parity.py verify` runs
        - Then:
           - it exits non-zero, with one redacted line on stderr naming the command and the error code, and no
             traceback
        """
        result = self.run_parity("verify", refuse="cognito-idp describe-user-pool", code="AccessDeniedException")
        self.assert_one_redacted_line(result, "parity.py verify: an AWS call failed (AccessDeniedException): ")

    # The AWS CLI binary itself crashing (the disk was full): a traceback whose last line is only the
    # PyInstaller launcher's, with placeholder identifiers in the lines before it. Seven non-empty lines, and a
    # blank one.
    CRASH_LINES = [
        "first line, which the tail drops",
        "second line, which the tail drops",
        "Traceback (most recent call last):",
        '  File "awscli/clidriver.py", line 92, in main, for arn:aws:sts::000000000000:assumed-role/'
        "placeholder-role/placeholder-session",
        '  File "botocore/client.py", line 1005, in _make_api_call, client abcdefghijklmnopqrstuvwxyz',
        "OSError: [Errno 28] No space left on device: '/placeholder/cache/xx-test-1_PlaceHold3r/"
        "placeholder@example.com'",
        "",
        "[PYI-4242:ERROR] Failed to execute script 'aws' due to unhandled exception!",
    ]
    CRASH_IDENTIFIERS = ("000000000000", "placeholder-role", "placeholder-session", "abcdefghijklmnopqrstuvwxyz",
                         "xx-test-1_PlaceHold3r", "placeholder@example.com")

    def test_a_crashed_cli_keeps_a_redacted_tail(self):
        """Test that a crash of the AWS CLI binary keeps the cause, redacted, at the command boundary

        - Given: STS accepting the caller, and the CLI crashing on DescribeUserPool with a multi-line traceback whose
          last line is only the PyInstaller launcher's, and whose earlier lines name placeholder identifiers
        - When:
           - `parity.py verify` runs
        - Then:
           - it exits non-zero, without a traceback of its own, with its one line ending in the launcher's line,
             followed by the last five non-empty lines of the CLI's stderr, indented, the cause among them
           - no identifier survives, and the lines before the last five are dropped
        """
        result = self.run_parity("verify", refuse="cognito-idp describe-user-pool", code="unused",
                                 refusal="\n".join(self.CRASH_LINES))
        self.assertNotEqual(result.returncode, 0)
        lines = result.stderr.splitlines()
        self.assertTrue(lines[0].startswith("parity.py verify: an AWS call failed (Unknown): [PYI-4242:ERROR]"),
                        lines[0])
        self.assertEqual(lines[1], "  AWS CLI stderr, last lines (redacted):")
        self.assertEqual(len(lines), 7, result.stderr)
        self.assertTrue(all(line.startswith("    ") for line in lines[2:]), result.stderr)
        self.assertEqual(lines[2], "    Traceback (most recent call last):")
        self.assertTrue(lines[5].startswith("    OSError: [Errno 28] No space left on device"), lines[5])
        self.assertEqual(lines[6], "    [PYI-4242:ERROR] Failed to execute script 'aws' due to unhandled exception!")
        self.assertNotIn("which the tail drops", result.stderr)
        for identifier in self.CRASH_IDENTIFIERS:
            self.assertNotIn(identifier, result.stderr + result.stdout)

    # Identifiers split across lines: an ARN cut after "assumed-role/", an account id cut in two, an email cut after
    # "@"; and a home directory and user name in a traceback's path.
    SPLIT_LINES = [
        "Traceback (most recent call last):",
        '  File "/Users/placeholder-alias/.local/aws/botocore/client.py", line 1005, in _make_api_call',
        "botocore.exceptions.ClientError: refused for arn:aws:sts::000000000000:assumed-role/",
        "placeholder-role/placeholder-session in account 000000",
        "000000 for placeholder@",
        "example.com by placeholder-alias",
        "[PYI-4242:ERROR] Failed to execute script 'aws' due to unhandled exception!",
    ]

    def test_an_identifier_split_across_lines_is_masked_whole(self):
        """Test that the tail masks identifiers split across lines, and the home directory and user name

        - Given: the AWS CLI crashing with a traceback whose ARN is cut after "assumed-role/", whose account id is cut
          in two, whose email is cut after "@", and whose path names the home directory and the user
        - When:
           - parity.aws makes the call
        - Then:
           - no part of any of them survives in the error's message or detail: the cut lines are joined, then
             redacted, and the home directory reads "~" and the user "<user>"
           - the traceback's own lines keep their indentation
        """
        spec = importlib.util.spec_from_file_location("parity", os.path.join(INFRA, "parity.py"))
        parity = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(parity)
        parity.REGION = "xx-test-1"
        environment = dict(PATH=self.bin + os.pathsep + os.environ["PATH"], FAKE_REFUSE="cognito-idp describe-user-pool",
                           FAKE_REFUSAL="\n".join(self.SPLIT_LINES), AWS_CONFIG_FILE=os.devnull,
                           AWS_SHARED_CREDENTIALS_FILE=os.devnull, HOME="/Users/placeholder-alias",
                           USER="placeholder-alias")
        with mock.patch.dict(os.environ, environment):
            with self.assertRaises(parity.AwsError) as crashed:
                parity.aws("cognito-idp", "describe-user-pool", "--user-pool-id", "placeholder")
        text = crashed.exception.message + "\n" + crashed.exception.detail
        for fragment in ("placeholder-role", "placeholder-session", "000000", "placeholder@", "example.com",
                         "placeholder-alias", "/Users/"):
            self.assertNotIn(fragment, text)
        tail = crashed.exception.detail.splitlines()
        self.assertEqual(tail[1], '  File "~/.local/aws/botocore/client.py", line 1005, in _make_api_call')
        self.assertEqual(tail[2], "botocore.exceptions.ClientError: refused for arn:aws:sts::<account>:assumed-role/"
                                  "<name> in account <account> for <email> by <user>")
        self.assertEqual(tail[-1], crashed.exception.message)

    def cli_error(self, stderr):
        """The AwsError parity.aws raises for a CLI that fails with `stderr`, and that parity module."""
        spec = importlib.util.spec_from_file_location("parity", os.path.join(INFRA, "parity.py"))
        parity = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(parity)
        parity.REGION = "xx-test-1"
        environment = dict(PATH=self.bin + os.pathsep + os.environ["PATH"], FAKE_REFUSE="cognito-idp describe-user-pool",
                           FAKE_REFUSAL=stderr, AWS_CONFIG_FILE=os.devnull, AWS_SHARED_CREDENTIALS_FILE=os.devnull,
                           HOME="/Users/placeholder-alias", USER="placeholder-alias")
        with mock.patch.dict(os.environ, environment):
            with self.assertRaises(parity.AwsError) as raised:
                parity.aws("cognito-idp", "describe-user-pool", "--user-pool-id", "placeholder")
        return raised.exception, parity

    def test_the_message_is_the_last_joined_line_redacted(self):
        """Test that the error's message, its main line, masks an identifier its last raw line only ends

        - Given: stderr whose next-to-last line ends at "assumed-role/" and whose last line is the rest of the ARN;
          then lines cut after a pool id's "_", and before an email's "@"
        - When:
           - parity.aws raises for each
        - Then:
           - the message is the joined line, redacted: no part of the role, session, pool id or email survives
        """
        error, _ = self.cli_error("An error occurred (AccessDeniedException) when calling the DescribeUserPool "
                                  "operation: refused for arn:aws:sts::000000000000:assumed-role/\n"
                                  "PlaceholderAdmin/placeholder-alias")
        self.assertEqual(error.code, "AccessDeniedException")
        # The user name is masked first, then the rest of the ARN.
        self.assertTrue(error.message.endswith("refused for arn:aws:sts::<account>:assumed-role/<name>/<user>"),
                        error.message)
        for fragment in ("PlaceholderAdmin", "placeholder-alias", "000000000000"):
            self.assertNotIn(fragment, error.message + error.detail)
        error, _ = self.cli_error("refused for pool xx-test-1_\nPlaceHold3r by placeholder\n@example.com")
        self.assertEqual(error.message, "refused for pool <user-pool> by <email>")
        for fragment in ("PlaceHold3r", "placeholder@", "example.com"):
            self.assertNotIn(fragment, error.message + error.detail)

    def test_iam_retry_still_matches_a_joined_message(self):
        """Test that run_with_iam_retry still recognises IAM's not-yet-assumable refusal

        - Given: the CLI failing with IAM's "role … cannot be assumed" refusal, its operation line ending in a colon
          (so it is joined with the refusal)
        - When:
           - run_with_iam_retry runs a call that raises that error once, then succeeds
        - Then:
           - the message names the role and "assumed", and the call is retried, then returns
        """
        error, parity = self.cli_error("An error occurred (InvalidParameterValueException) when calling the "
                                       "CreateFunction operation:\nThe role defined for the function cannot be "
                                       "assumed by Lambda.")
        self.assertIn("role", error.message)
        self.assertIn("assumed", error.message)
        attempts = []

        def call():
            attempts.append(1)
            if len(attempts) == 1:
                raise error
            return "created"
        with mock.patch.object(parity.time, "sleep", lambda _: None):
            self.assertEqual(parity.run_with_iam_retry(call), "created")
        self.assertEqual(len(attempts), 2)

    def test_a_crashed_cli_raises_its_last_line_as_message_and_the_tail_as_detail(self):
        """Test that AwsError keeps `message` as the CLI's last line, so callers that match on it still work

        - Given: the AWS CLI crashing with the multi-line traceback above, and a CLI refusing in one line
        - When:
           - parity.aws makes each call
        - Then:
           - the crash's AwsError has the launcher's line, redacted, as `message`, and the last five non-empty
             lines, redacted, as `detail`, `message` last; no identifier survives in either
           - the one-line refusal's `detail` is its `message`, and with_detail leaves its line unchanged
        """
        spec = importlib.util.spec_from_file_location("parity", os.path.join(INFRA, "parity.py"))
        parity = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(parity)
        parity.REGION = "xx-test-1"
        environment = dict(PATH=self.bin + os.pathsep + os.environ["PATH"], FAKE_REFUSE="cognito-idp describe-user-pool",
                           FAKE_REFUSAL="\n".join(self.CRASH_LINES), AWS_CONFIG_FILE=os.devnull,
                           AWS_SHARED_CREDENTIALS_FILE=os.devnull)
        with mock.patch.dict(os.environ, environment):
            with self.assertRaises(parity.AwsError) as crashed:
                parity.aws("cognito-idp", "describe-user-pool", "--user-pool-id", "placeholder")
        error = crashed.exception
        self.assertEqual(error.message, self.CRASH_LINES[-1])
        tail = error.detail.splitlines()
        self.assertEqual(len(tail), 5)
        self.assertEqual(tail[0], "Traceback (most recent call last):")
        self.assertEqual(tail[-1], error.message)
        self.assertIn("<account>", error.detail)
        self.assertIn("<user-pool>", error.detail)
        self.assertIn("<email>", error.detail)
        for identifier in self.CRASH_IDENTIFIERS:
            self.assertNotIn(identifier, error.message + error.detail)

        refusal = self.REFUSAL.format(code="AccessDeniedException", operation="DescribeUserPool")
        with mock.patch.dict(os.environ, dict(environment, FAKE_REFUSAL=refusal)):
            with self.assertRaises(parity.AwsError) as refused:
                parity.aws("cognito-idp", "describe-user-pool", "--user-pool-id", "placeholder")
        self.assertEqual(refused.exception.code, "AccessDeniedException")
        self.assertEqual(refused.exception.detail, refused.exception.message)
        self.assertEqual(parity.with_detail("line", refused.exception), "line")


if __name__ == "__main__":
    unittest.main()
