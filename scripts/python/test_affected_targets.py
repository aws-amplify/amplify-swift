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
this checkout's Xcode projects, or a scratch checkout holding one small project or none.
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


def stub_package(moved=None):
    """The stub package dump; `moved` maps a target name to the path it has instead (a test target is added)."""
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
    for name, path in (moved or {}).items():
        targets = [t for t in targets if t["name"] != name]
        targets.append({"name": name, "path": path, "type": "test" if name.endswith("Tests") else "regular",
                        "dependencies": []})
    return {"targets": targets}


class AffectedTargetsTests(unittest.TestCase):

    def setUp(self):
        self.work = tempfile.TemporaryDirectory()
        self.addCleanup(self.work.cleanup)
        self.package = os.path.join(self.work.name, "package.json")
        with open(self.package, "w") as f:
            json.dump(stub_package(), f)

    def write_list(self, name, paths):
        path = os.path.join(self.work.name, name)
        with open(path, "w") as f:
            f.write("\n".join(paths) + "\n")
        return path

    def run_selector(self, groups, changed, repo_root=REPO, renames=None, cwd=None):
        """The selector's completed process for these changed files and (old, new) rename pairs, read against
        `repo_root`'s Xcode projects (`None` passes no `--repo-root`), run from `cwd`."""
        command = [sys.executable, SCRIPT, "--package", self.package,
                   "--changed", self.write_list("changed.txt", changed), "--groups", groups]
        if renames is not None:
            command += ["--renames", self.write_list("renames.txt", ["\t".join(pair) for pair in renames])]
        if repo_root is not None:
            command += ["--repo-root", repo_root]
        return subprocess.run(command, capture_output=True, text=True, check=True, cwd=cwd)

    def selected(self, groups, *changed, repo_root=REPO, renames=None, cwd=None):
        """The `selected=` array the selector prints for these changed files."""
        result = self.run_selector(groups, changed, repo_root, renames, cwd)
        return selection(result)

    def use_package(self, package):
        with open(self.package, "w") as f:
            json.dump(package, f)

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
           - the group whose path covers the host app is selected, and nothing else (selection only: the Storage
             README is copied by StorageStressTests, which no PR job builds, so its group's jobs can't see the break)
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
           - AWSPluginsCore alone is selected, as any other file under a plugin's host app selects there: unit_test.yml
             runs AWSPluginsCore's unit tests, and the three build workflows, which only check that something is
             selected, build the whole package (accepted: none of them builds a host app, so none sees the break)
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
        self.assertEqual(selection(result), ["geo"])
        self.assertIn(GEO_PROJECT, result.stderr)
        self.assertEqual(self.selected(INTEG_GROUPS, "AmplifyPlugins/Auth/README.md", repo_root=root), [])

    def test_a_move_that_changes_a_target_directory_selects_only_what_the_new_paths_select(self):
        """Moving a target's files to a new directory selects the target's group, not every group.

        - Given: a package dump where AmplifyRecordCacheTests now lives at `Tests/UnitTests`, so no target owns its
          old directory, and the real group files
        - When:
           - the changed list names the new paths and Package.swift (as `git diff --name-only -M` does), and the
             renames come through `--renames`
           - or the old paths are in the changed list itself, as plain deletions
        - Then:
           - the unit groups select AmplifyRecordCache alone and the integration groups select nothing
           - a plain deletion of an unattributable path still selects every group (fail closed)
        """
        self.use_package(stub_package({"AmplifyRecordCacheTests": RECORD_CACHE + "Tests/UnitTests"}))
        names = ("AutoFlushSchedulerTests.swift", "RecordCacheTests.swift")
        new = [RECORD_CACHE + "Tests/UnitTests/" + n for n in names] + ["Package.swift"]
        old = [RECORD_CACHE + "Tests/" + n for n in names]
        renames = list(zip(old, new))
        self.assertEqual(self.selected(UNIT_GROUPS, *new, renames=renames), ["AmplifyRecordCache"])
        self.assertEqual(self.selected(INTEG_GROUPS, *new, renames=renames), [])
        with open(UNIT_GROUPS) as f:
            every_group = sorted(json.load(f))
        self.assertEqual(self.selected(UNIT_GROUPS, *(new + old)), every_group)

    def test_a_rename_source_is_attributed_like_a_changed_file(self):
        """A rename's old path still selects what it would select as a changed file.

        - Given: this checkout's Xcode projects, where the Auth host app bundles `AuthIntegrationTests/README.md`,
          and the real group files
        - When:
           - that README is renamed: the changed list names only its new path, which no project bundles, and the
             rename comes through `--renames`
           - or a file moves out of the Cognito client's sources into AmplifyRecordCache's
        - Then:
           - the README's old path selects `auth` with the integration groups and AWSPluginsCore with the unit
             groups, as its deletion does; without `--renames` the rename selects nothing
           - the moved file selects the groups of the target it left as well as the one it joined
        """
        old = "AmplifyPlugins/Auth/Tests/AuthHostApp/AuthIntegrationTests/README.md"
        new = "AmplifyPlugins/Auth/Tests/AuthHostApp/AuthIntegrationTests/Docs/README.md"
        self.assertEqual(self.selected(INTEG_GROUPS, new, renames=[(old, new)]), ["auth"])
        self.assertEqual(self.selected(UNIT_GROUPS, new, renames=[(old, new)]), ["AWSPluginsCore"])
        self.assertEqual(self.selected(INTEG_GROUPS, new), [])

        self.use_package(stub_package({"AmplifyRecordCache": RECORD_CACHE + "Sources"}))
        moved = (CLIENT + "Sources/Moved.swift", RECORD_CACHE + "Sources/Moved.swift")
        self.assertEqual(self.selected(UNIT_GROUPS, moved[1], renames=[moved]),
                         ["AWSCognitoAuthPlugin", "AmplifyCognitoClient", "AmplifyRecordCache"])

    def test_an_unknown_file_moved_where_nothing_attributes_it_selects_every_group(self):
        """A file nothing owns or covers, moved to an ignored path, fails closed as its deletion does.

        - Given: the real group files, where no target owns and no group path covers the package workspace's data
          file or `AmplifyFoundationBridge/AmplifyFoundationBridge.xctestplan`
        - When:
           - one of them is renamed into `.github/` or `scripts/`, or to a `.md` name, all ignored: the changed list
             names only the new path, and `--renames` the pair
        - Then:
           - every group is selected, with the integration and the unit groups
        """
        for old, new in ((".swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata",
                          ".github/contents.xcworkspacedata"),
                         ("AmplifyFoundationBridge/AmplifyFoundationBridge.xctestplan",
                          "scripts/AmplifyFoundationBridge.xctestplan"),
                         ("AmplifyFoundationBridge/AmplifyFoundationBridge.xctestplan",
                          "AmplifyFoundationBridge/AmplifyFoundationBridge.md")):
            for groups in (INTEG_GROUPS, UNIT_GROUPS):
                with self.subTest(new=new, groups=os.path.basename(groups)):
                    with open(groups) as f:
                        every_group = sorted(json.load(f))
                    self.assertEqual(self.selected(groups, new, renames=[(old, new)]), every_group)

    def test_an_unknown_file_moved_where_something_attributes_it_selects_what_the_new_path_selects(self):
        """A file nothing owns or covers, moved to an attributed path, selects only what that new path selects.

        - Given: the real group files, where no target owns and no group path covers
          `AmplifyFoundationBridge/AmplifyFoundationBridge.xctestplan`
        - When:
           - it is renamed under the Geo plugin's directory, a group path in both group files, or into the Cognito
             client's sources, which a target owns
           - or a file under the ignored `scripts/` is renamed within `scripts/`
        - Then:
           - the move into the Geo plugin selects `geo` with the integration groups and AWSPluginsCore with the unit
             groups, the move into the client's sources selects what a change to them selects, and nothing
             fails closed
           - the move within `scripts/` selects nothing
        """
        old = "AmplifyFoundationBridge/AmplifyFoundationBridge.xctestplan"
        for new, integ, unit in (("AmplifyPlugins/Geo/Tests/AmplifyFoundationBridge.xctestplan", ["geo"],
                                  ["AWSPluginsCore"]),
                                 (CLIENT + "Sources/AmplifyFoundationBridge.xctestplan",
                                  ["auth_client", "auth_client_interop"],
                                  ["AWSCognitoAuthPlugin", "AmplifyCognitoClient"])):
            with self.subTest(new=new):
                self.assertEqual(self.selected(INTEG_GROUPS, new, renames=[(old, new)]), integ)
                self.assertEqual(self.selected(UNIT_GROUPS, new, renames=[(old, new)]), unit)
        moved = ("scripts/old_name.sh", "scripts/new_name.sh")
        for groups in (INTEG_GROUPS, UNIT_GROUPS):
            with self.subTest(moved=moved, groups=os.path.basename(groups)):
                self.assertEqual(self.selected(groups, moved[1], renames=[moved]), [])

    def test_a_malformed_rename_list_fails(self):
        """A `--renames` line without exactly two tab-separated paths stops the selector rather than being guessed at.

        - Given: the real integration group file
        - When:
           - the rename list holds only an old path, as the source column alone would
        - Then:
           - the selector exits non-zero and names the line on stderr
        """
        with self.assertRaises(subprocess.CalledProcessError) as raised:
            self.run_selector(INTEG_GROUPS, ["scripts/new_name.sh"], renames=[("scripts/old_name.sh",)])
        self.assertIn("scripts/old_name.sh", raised.exception.stderr)

    def test_the_default_repo_root_is_the_checkout_holding_the_selector(self):
        """Run from another directory without `--repo-root`, the selector still reads this checkout's projects.

        - Given: a working directory outside the checkout, and no `--repo-root`
        - When:
           - the only changed file is a README the Auth host app bundles
        - Then:
           - `auth` is selected, as when run from the checkout's root
           - stderr has no "found no Xcode project" note: the projects were read, so the selection does not come from
             the fallback that treats an unread root's docs as bundled (which selects `auth` too)
        """
        readme = "AmplifyPlugins/Auth/Tests/AuthHostApp/AuthIntegrationTests/README.md"
        result = self.run_selector(INTEG_GROUPS, [readme], repo_root=None, cwd=self.work.name)
        self.assertEqual(selection(result), ["auth"])
        self.assertNotIn("found no Xcode project", result.stderr)

    def test_a_bundled_readme_renamed_away_from_md_is_read_through_its_old_path(self):
        """A bundled README renamed to a name that isn't `.md` still makes the selector read the projects.

        - Given: this checkout's Xcode projects, where the Auth host app bundles `AuthIntegrationTests/README.md`,
          and the real group files
        - When:
           - that README is renamed to a `.txt` file under the ignored `scripts/`, so the only `.md` path in the change
             is the rename's old path
        - Then:
           - the old path selects `auth` with the integration groups and AWSPluginsCore with the unit groups, as its
             deletion does: the projects are read for a `.md` on the old side of a rename too
        """
        old = "AmplifyPlugins/Auth/Tests/AuthHostApp/AuthIntegrationTests/README.md"
        new = "scripts/AuthIntegrationTests-README.txt"
        self.assertEqual(self.selected(INTEG_GROUPS, new, renames=[(old, new)]), ["auth"])
        self.assertEqual(self.selected(UNIT_GROUPS, new, renames=[(old, new)]), ["AWSPluginsCore"])

    def test_a_root_with_no_project_is_unread(self):
        """A `--repo-root` holding no Xcode project makes every doc count as bundled, not none of them.

        - Given: an empty directory as `--repo-root`
        - When:
           - the only changed file is the Auth plugin's README, under the `auth` group's path
        - Then:
           - `auth` is selected, and the selector says on stderr that it found no project
        """
        root = os.path.join(self.work.name, "empty")
        os.makedirs(root)
        result = self.run_selector(INTEG_GROUPS, ["AmplifyPlugins/Auth/README.md"], root)
        self.assertEqual(selection(result), ["auth"])
        self.assertIn("found no Xcode project", result.stderr)


def selection(result):
    """The `selected=` array in a selector run's output."""
    line = next(line for line in result.stdout.splitlines() if line.startswith("selected="))
    return json.loads(line[len("selected="):])


RECORD_CACHE = "AmplifyClients/AmplifyRecordCache/"
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
