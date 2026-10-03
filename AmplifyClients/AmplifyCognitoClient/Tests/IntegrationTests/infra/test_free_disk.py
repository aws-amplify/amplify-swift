#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""Self-tests for lib.sh's free-disk preflight: provision.sh, prepare-run.sh and `self-sign-up.sh on`
refuse to start, before any AWS call, when the volume holding the state directory has less free space than
COGNITO_CLIENT_INTEG_MIN_FREE_GIB; 0 skips the check, and `self-sign-up.sh off` (the recovery) never makes it.

    python3 infra/test_free_disk.py

No AWS call is made: a fake `aws` on PATH logs each call and refuses it, COGNITO_CLIENT_INTEG_DIR points at a
temporary directory, and the AWS CLI's config and credential files are /dev/null. A minimum no disk can meet stands in
for a full one, so the tests never depend on the machine's free space.
"""

import json
import os
import shutil
import subprocess
import tempfile
import unittest

INFRA = os.path.dirname(os.path.abspath(__file__))
# More than any volume has, so the check always refuses.
UNMEETABLE = "999999"
FAKE_AWS = """#!/usr/bin/env bash
echo "$*" >>"$FAKE_LOG"
[[ "$1 $2 $3" == "configure get cli_history" ]] && exit 1
echo "An error occurred (AccessDeniedException) when calling the operation: placeholder" >&2
exit 254
"""


class FreeDiskPreflightTests(unittest.TestCase):
    def setUp(self):
        self.work = tempfile.mkdtemp()
        self.state = os.path.join(self.work, "state")
        self.bin = os.path.join(self.work, "bin")
        self.log = os.path.join(self.work, "calls.log")
        os.makedirs(self.state)
        os.makedirs(self.bin)
        fake = os.path.join(self.bin, "aws")
        with open(fake, "w") as f:
            f.write(FAKE_AWS)
        os.chmod(fake, 0o755)
        with open(os.path.join(self.state, "state.json"), "w") as f:
            json.dump({"account": "000000000000", "region": "xx-test-1", "userPoolId": "placeholder-base",
                       "parity": {"pools": {"default": {"userPoolId": "placeholder-default"}}}}, f)
        with open(os.path.join(self.state, "users.json"), "w") as f:
            json.dump({}, f)

    def tearDown(self):
        shutil.rmtree(self.work)

    def run_script(self, script, *args, minimum, state=None):
        """bash infra/<script> <args…> with COGNITO_CLIENT_INTEG_MIN_FREE_GIB=`minimum` (unset when None)."""
        environment = {name: value for name, value in os.environ.items()
                       if not name.startswith(("AWS_", "COGNITO_CLIENT_INTEG_")) and name not in ("CI", "GITHUB_ACTIONS")}
        environment.update(PATH=self.bin + os.pathsep + os.environ["PATH"], FAKE_LOG=self.log,
                           COGNITO_CLIENT_INTEG_DIR=state or self.state, AWS_CONFIG_FILE=os.devnull,
                           AWS_SHARED_CREDENTIALS_FILE=os.devnull)
        if minimum is not None:
            environment["COGNITO_CLIENT_INTEG_MIN_FREE_GIB"] = minimum
        return subprocess.run(["bash", os.path.join(INFRA, script), *args], env=environment, cwd=self.work,
                              stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=60)

    def calls(self):
        if not os.path.exists(self.log):
            return []
        with open(self.log) as f:
            return f.read().splitlines()

    SCRIPTS = (("provision.sh", "xx-test-1"), ("prepare-run.sh",), ("self-sign-up.sh", "on", "--", "touch", "ran"))

    def test_each_script_refuses_below_the_minimum_before_any_aws_call(self):
        """Test that each script refuses to start when the free disk is under the minimum

        - Given: a minimum no volume can meet
        - When:
           - provision.sh, prepare-run.sh and `self-sign-up.sh on -- touch ran` each run
        - Then:
           - each exits 1 with one line naming the free space, the minimum and the variable that overrides it
           - none makes an AWS call, and `on` does not run its command
        """
        for script in self.SCRIPTS:
            with self.subTest(script=script[0]):
                result = self.run_script(*script, minimum=UNMEETABLE)
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertRegex(result.stderr, r"^Refusing: only \d+ MiB free on the volume holding .*, under the "
                                                rf"{UNMEETABLE} GiB minimum\. ")
                self.assertIn("COGNITO_CLIENT_INTEG_MIN_FREE_GIB", result.stderr)
                self.assertEqual(len(result.stderr.splitlines()), 1, result.stderr)
                self.assertEqual(self.calls(), [])
                self.assertFalse(os.path.exists(os.path.join(self.work, "ran")))

    def test_zero_skips_the_check(self):
        """Test that COGNITO_CLIENT_INTEG_MIN_FREE_GIB=0 overrides the check

        - Given: the minimum set to 0
        - When:
           - provision.sh, prepare-run.sh and `self-sign-up.sh on -- touch ran` each run
        - Then:
           - none refuses for disk space: each goes on to its first AWS call (which the fake refuses)
        """
        for script in self.SCRIPTS:
            with self.subTest(script=script[0]):
                if os.path.exists(self.log):
                    os.unlink(self.log)
                result = self.run_script(*script, minimum="0")
                self.assertNotIn("free on the volume", result.stderr)
                self.assertNotEqual(self.calls(), [], result.stderr)

    def test_a_low_minimum_passes_on_this_machine(self):
        """Test that a minimum the disk meets lets the script go on

        - Given: a minimum of 1 GiB, which the test skips if this machine's volume does not meet it
        - When:
           - prepare-run.sh runs
        - Then:
           - it does not refuse for disk space, and goes on to its first AWS call
        """
        if shutil.disk_usage(self.state).free < 2 * 1024 ** 3:
            self.skipTest("under 2 GiB free here")
        result = self.run_script("prepare-run.sh", minimum="1")
        self.assertNotIn("free on the volume", result.stderr)
        self.assertNotEqual(self.calls(), [], result.stderr)

    def test_a_state_directory_not_yet_created_is_checked_on_its_parent_volume(self):
        """Test that the check reads the nearest existing parent of a state directory that does not exist yet

        - Given: COGNITO_CLIENT_INTEG_DIR naming a directory two levels below an existing one, and an unmeetable
          minimum
        - When:
           - prepare-run.sh runs
        - Then:
           - it refuses for disk space (not with an error reading it), with no AWS call
        """
        result = self.run_script("prepare-run.sh", minimum=UNMEETABLE,
                                 state=os.path.join(self.work, "not", "yet"))
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertRegex(result.stderr, r"^Refusing: only \d+ MiB free on the volume holding ")
        self.assertEqual(self.calls(), [])

    def test_a_minimum_that_is_not_a_whole_number_is_refused(self):
        """Test that a malformed minimum is refused rather than ignored

        - Given: COGNITO_CLIENT_INTEG_MIN_FREE_GIB set to "two", "-1", "1.5" and "1234567" (an empty value is the
          default, as unset)
        - When:
           - prepare-run.sh runs
        - Then:
           - it exits 1, saying the minimum must be a whole number of GiB, with no AWS call
        """
        for minimum in ("two", "-1", "1.5", "1234567"):
            with self.subTest(minimum=minimum):
                result = self.run_script("prepare-run.sh", minimum=minimum)
                self.assertEqual(result.returncode, 1, result.stderr)
                self.assertIn("must be a whole number of GiB", result.stderr)
                self.assertEqual(self.calls(), [])

    def test_off_never_checks(self):
        """Test that `self-sign-up.sh off`, the recovery, runs whatever the free disk

        - Given: an unmeetable minimum
        - When:
           - `self-sign-up.sh off` runs
        - Then:
           - it does not refuse for disk space, and goes on to its AWS calls
        """
        result = self.run_script("self-sign-up.sh", "off", minimum=UNMEETABLE)
        self.assertNotIn("free on the volume", result.stderr)
        self.assertNotEqual(self.calls(), [], result.stderr)


if __name__ == "__main__":
    unittest.main()
