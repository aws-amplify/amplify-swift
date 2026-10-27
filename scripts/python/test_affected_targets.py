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
passes), plus the Cognito client's source and unit-test targets at their real paths. The host-app README cases read
this checkout's Xcode projects, or a scratch checkout holding one small project.
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
REPO = os.path.dirname(os.path.dirname(HERE))

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

    def run_selector(self, groups, changed, repo_root=REPO):
        """The selector's completed process for these changed files, read against `repo_root`'s Xcode projects."""
        changed_file = os.path.join(self.work.name, "changed.txt")
        with open(changed_file, "w") as f:
            f.write("\n".join(changed) + "\n")
        return subprocess.run(
            [sys.executable, SCRIPT, "--package", self.package, "--changed", changed_file, "--groups", groups,
             "--repo-root", repo_root],
            capture_output=True, text=True, check=True)

    def selected(self, groups, *changed, repo_root=REPO):
        """The `selected=` array the selector prints for these changed files."""
        result = self.run_selector(groups, changed, repo_root)
        line = next(line for line in result.stdout.splitlines() if line.startswith("selected="))
        return json.loads(line[len("selected="):])

    def scratch_checkout(self, pbxproj):
        """A scratch checkout holding only `GEO_PROJECT` with this `project.pbxproj` text; returns its root."""
        root = os.path.join(self.work.name, "checkout")
        os.makedirs(os.path.join(root, GEO_PROJECT))
        with open(os.path.join(root, GEO_PROJECT, "project.pbxproj"), "w") as f:
            f.write(pbxproj)
        return root

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

    def test_a_readme_a_host_app_bundles_selects_its_group(self):
        """A README that a host app's test target copies as a bundle resource selects that host app's group.

        - Given: this checkout's Xcode projects, where the Auth, Storage and Push host apps list these READMEs in a
          test target's Copy Bundle Resources phase, and the real integration group file
        - When:
           - the only changed file is one of those READMEs (an edit or a deletion: either way the project still
             lists it, and a deletion breaks the host app's build)
        - Then:
           - the group whose path covers the host app is selected, and nothing else
        """
        for readme, group in (("AmplifyPlugins/Auth/Tests/AuthHostApp/AuthIntegrationTests/README.md", "auth"),
                              ("AmplifyPlugins/Storage/Tests/StorageHostApp/StorageStressTests/README.md", "storage"),
                              ("AmplifyPlugins/Notifications/Push/Tests/PushNotificationHostApp/"
                               "PushNotificationHostAppUITests/README.md", "push_notifications")):
            with self.subTest(readme=readme):
                self.assertEqual(self.selected(INTEG_GROUPS, readme), [group])

    def test_a_readme_a_host_app_bundles_selects_the_plugins_core_unit_group(self):
        """With the unit groups, a README a host app bundles selects AWSPluginsCore, as any host-app file does.

        - Given: this checkout's Xcode projects, where the Auth, Storage and Push host apps list these READMEs in a
          test target's Copy Bundle Resources phase, and the real unit group file, whose AWSPluginsCore group's
          `paths` hold `AmplifyPlugins/`
        - When:
           - the only changed file is one of those READMEs
        - Then:
           - AWSPluginsCore alone is selected, which the unit and build workflows then run (accepted: it is what
             any other file under a plugin's host app selects there)
        """
        for readme in ("AmplifyPlugins/Auth/Tests/AuthHostApp/AuthIntegrationTests/README.md",
                       "AmplifyPlugins/Storage/Tests/StorageHostApp/StorageStressTests/README.md",
                       "AmplifyPlugins/Notifications/Push/Tests/PushNotificationHostApp/"
                       "PushNotificationHostAppUITests/README.md"):
            with self.subTest(readme=readme):
                self.assertEqual(self.selected(UNIT_GROUPS, readme), ["AWSPluginsCore"])

    def test_a_host_app_readme_no_project_bundles_selects_no_group(self):
        """A README inside a host app that no Xcode project copies into a bundle still selects nothing.

        - Given: this checkout's Xcode projects, where these READMEs sit inside host apps but in no Copy Bundle
          Resources phase, and the real integration group file
        - When:
           - the only changed file is one of those READMEs
        - Then:
           - no group is selected: the docs skip still holds for documentation that is not a bundle resource
        """
        for readme in ("AmplifyPlugins/Auth/Tests/AuthHostApp/AuthIntegrationTests/PasswordlessTests/README.md",
                       "AmplifyPlugins/API/Tests/APIHostApp/AWSAPIPluginFunctionalTests/README.md",
                       "AmplifyPlugins/DataStore/Tests/DataStoreHostApp/AWSDataStorePluginIntegrationTests/README.md"):
            with self.subTest(readme=readme):
                self.assertEqual(self.selected(INTEG_GROUPS, readme), [])

    def test_a_bundle_resource_resolves_through_the_project_groups(self):
        """A bundled README is found through name-only and path groups, and only the listed file is bundled.

        - Given: a scratch checkout whose one project bundles `GeoStressTests/README.md` through a group with a
          `path` inside a group with only a `name`, and the README file itself deleted
        - When:
           - the only changed file is that README, or a README beside it that the project does not list
        - Then:
           - the bundled README selects `geo`, and the other README selects nothing
        """
        root = self.scratch_checkout(GEO_PBXPROJ)
        self.assertEqual(self.selected(INTEG_GROUPS, GEO_HOST_APP + "GeoStressTests/README.md", repo_root=root),
                         ["geo"])
        self.assertEqual(self.selected(INTEG_GROUPS, GEO_HOST_APP + "GeoStressTests/Notes/README.md",
                                       repo_root=root), [])

    def test_a_project_that_cannot_be_read_makes_its_docs_select_their_group(self):
        """When a project can't be parsed, the docs under its directory are treated as bundled.

        - Given: a scratch checkout whose one project file is truncated
        - When:
           - the only changed file is a README under that project's directory, or a README elsewhere
        - Then:
           - the README under the project selects `geo`, and the selector says on stderr which project it couldn't
             read
           - the README elsewhere still selects nothing
        """
        root = self.scratch_checkout(GEO_PBXPROJ[:len(GEO_PBXPROJ) // 2])
        result = self.run_selector(INTEG_GROUPS, [GEO_HOST_APP + "GeoStressTests/Notes/README.md"], root)
        self.assertIn("selected=[\"geo\"]", result.stdout.splitlines())
        self.assertIn(GEO_PROJECT, result.stderr)
        self.assertEqual(self.selected(INTEG_GROUPS, "AmplifyPlugins/Auth/README.md", repo_root=root), [])


GEO_HOST_APP = "AmplifyPlugins/Geo/Tests/GeoHostApp/"
GEO_PROJECT = GEO_HOST_APP + "GeoHostApp.xcodeproj"

# A minimal project: the main group holds a name-only group, which holds the `GeoStressTests` path group, which
# holds README.md and Notes/README.md. Only the first is in the Copy Bundle Resources phase.
GEO_PBXPROJ = """// !$*UTF8*$!
{
	archiveVersion = 1;
	objects = {
		B1 /* README.md in Resources */ = {isa = PBXBuildFile; fileRef = F1 /* README.md */; };
		F1 /* README.md */ = {isa = PBXFileReference; lastKnownFileType = net.daringfireball.markdown; path = README.md; sourceTree = "<group>"; };
		F2 /* README.md */ = {isa = PBXFileReference; lastKnownFileType = net.daringfireball.markdown; path = Notes/README.md; sourceTree = "<group>"; };
		G0 = {isa = PBXGroup; children = (G1 /* Tests */, ); sourceTree = "<group>"; };
		G1 /* Tests */ = {isa = PBXGroup; children = (G2 /* GeoStressTests */, ); name = Tests; sourceTree = "<group>"; };
		G2 /* GeoStressTests */ = {isa = PBXGroup; children = (F1 /* README.md */, F2 /* README.md */, ); path = GeoStressTests; sourceTree = "<group>"; };
		P1 /* Project object */ = {isa = PBXProject; mainGroup = G0; projectDirPath = ""; targets = (); };
		R1 /* Resources */ = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (B1 /* README.md in Resources */, ); runOnlyForDeploymentPostprocessing = 0; };
	};
	rootObject = P1 /* Project object */;
}
"""


if __name__ == "__main__":
    unittest.main()
