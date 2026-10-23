#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""
Self-test for affected_targets.py, run over this directory's real group files and a stub package dump:

    python3 -m unittest discover -s scripts/python -p 'test_*.py'

The stub names every target the group files reference (each under a placeholder path, so the group-target check
passes), plus the Cognito client's source and unit-test targets at their real paths.
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "affected_targets.py")
INTEG_GROUPS = os.path.join(HERE, "integ_test_groups.json")
UNIT_GROUPS = os.path.join(HERE, "unit_test_groups.json")

CLIENT = "AmplifyClients/AmplifyCognitoClient/"


def stub_package():
    names = set()
    for path in (INTEG_GROUPS, UNIT_GROUPS):
        with open(path) as f:
            for group in json.load(f).values():
                names.update(group.get("targets", []))
    real = {"AmplifyCognitoClient": CLIENT + "Sources", "AmplifyCognitoClientTests": CLIENT + "Tests/UnitTests"}
    targets = [{"name": n, "path": f"StubTargets/{n}", "type": "regular", "dependencies": []}
               for n in sorted(names - set(real))]
    targets.append({"name": "AmplifyCognitoClient", "path": real["AmplifyCognitoClient"], "type": "regular",
                    "dependencies": []})
    targets.append({"name": "AmplifyCognitoClientTests", "path": real["AmplifyCognitoClientTests"], "type": "test",
                    "dependencies": [{"byName": ["AmplifyCognitoClient", None]}]})
    return {"targets": targets}


class AffectedTargetsTests(unittest.TestCase):

    def setUp(self):
        self.work = tempfile.TemporaryDirectory()
        self.addCleanup(self.work.cleanup)
        self.package = os.path.join(self.work.name, "package.json")
        with open(self.package, "w") as f:
            json.dump(stub_package(), f)

    def selected(self, groups, *changed):
        """The `selected=` array the selector prints for these changed files."""
        changed_file = os.path.join(self.work.name, "changed.txt")
        with open(changed_file, "w") as f:
            f.write("\n".join(changed) + "\n")
        result = subprocess.run(
            [sys.executable, SCRIPT, "--package", self.package, "--changed", changed_file, "--groups", groups],
            capture_output=True, text=True, check=True)
        line = next(line for line in result.stdout.splitlines() if line.startswith("selected="))
        return json.loads(line[len("selected="):])

    def test_a_readme_under_a_group_path_selects_no_group(self):
        """A README under a group's path prefix selects nothing, in the integration and unit-test group files.

        - Given: the real group files, where the client's module root and its integration-test directory are
          group paths, and so is the plugin's `AmplifyPlugins/Auth/`
        - When:
           - the only changed file is the client's README, the integration runbook, or the plugin's README
        - Then:
           - no group is selected: `.md` is ignored by the path rule too, not only by target ownership
        """
        for readme in (CLIENT + "README.md", CLIENT + "Tests/IntegrationTests/README.md",
                       "AmplifyPlugins/Auth/README.md"):
            for groups in (INTEG_GROUPS, UNIT_GROUPS):
                with self.subTest(readme=readme, groups=os.path.basename(groups)):
                    self.assertEqual(self.selected(groups, readme), [])

    def test_a_swift_file_under_the_client_integration_tests_selects_both_client_groups(self):
        """A source file under the client's integration tests still selects the client's integration groups.

        - Given: the real integration group file
        - When:
           - the only changed file is a `.swift` file under the client's integration-test directory
        - Then:
           - `auth_client` and `auth_client_interop` are selected, and nothing else
        """
        changed = CLIENT + "Tests/IntegrationTests/CognitoClientHostApp/CognitoClientIntegrationTests/SignInTests.swift"
        self.assertEqual(self.selected(INTEG_GROUPS, changed), ["auth_client", "auth_client_interop"])

    def test_a_readme_beside_a_swift_change_keeps_the_swift_selection(self):
        """A README changed with a source file selects what the source file alone selects.

        - Given: the real integration group file
        - When:
           - the changed files are the client's README and a `.swift` file under its integration-test directory
        - Then:
           - `auth_client` and `auth_client_interop` are selected, and nothing else
        """
        changed = CLIENT + "Tests/IntegrationTests/CognitoClientHostApp/CognitoClientIntegrationTests/SignInTests.swift"
        self.assertEqual(self.selected(INTEG_GROUPS, CLIENT + "README.md", changed),
                         ["auth_client", "auth_client_interop"])


if __name__ == "__main__":
    unittest.main()
