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
passes), plus the Cognito client's source and unit-test targets at their real paths. The `--check-bundled` cases read
this checkout's Xcode projects, or a scratch git checkout holding one small project or none.
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

    def run_selector(self, groups, changed, renames=None, repo_root=None):
        """The selector's completed process for these changed files and (old, new) rename pairs."""
        command = [sys.executable, SCRIPT, "--package", self.package,
                   "--changed", self.write_list("changed.txt", changed), "--groups", groups]
        if renames is not None:
            command += ["--renames", self.write_list("renames.txt", ["\t".join(pair) for pair in renames])]
        if repo_root is not None:
            command += ["--repo-root", repo_root]
        return subprocess.run(command, capture_output=True, text=True, check=True)

    def selected(self, groups, *changed, renames=None):
        """The `selected=` array the selector prints for these changed files."""
        return selection(self.run_selector(groups, changed, renames))

    def run_check(self, repo_root=REPO, cwd=None):
        """The completed process of `--check-bundled` over `repo_root` (`None` passes no `--repo-root`), run from
        `cwd`."""
        command = [sys.executable, SCRIPT, "--check-bundled"]
        if repo_root is not None:
            command += ["--repo-root", repo_root]
        return subprocess.run(command, capture_output=True, text=True, cwd=cwd)

    def use_package(self, package):
        with open(self.package, "w") as f:
            json.dump(package, f)

    def scratch_checkout(self, pbxproj, files=(), git=True):
        """A scratch checkout holding `GEO_PROJECT` with this `project.pbxproj` text and these other files (paths
        relative to the root, each with a line of text), a git repository unless `git` is false; returns its root."""
        root = os.path.join(self.work.name, "checkout")
        os.makedirs(os.path.join(root, GEO_PROJECT))
        with open(os.path.join(root, GEO_PROJECT, "project.pbxproj"), "w") as f:
            f.write(pbxproj)
        for path in files:
            os.makedirs(os.path.dirname(os.path.join(root, path)), exist_ok=True)
            with open(os.path.join(root, path), "w") as f:
                f.write("x\n")
        if git:
            subprocess.run(["git", "init", "-q", root], check=True)
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

    def test_a_readme_a_host_app_bundles_selects_no_group(self):
        """A README that a host app's test target copies as a bundle resource selects nothing when it changes.

        - Given: this checkout's Xcode projects, where the Auth, Storage and Push host apps list these READMEs in a
          test target's Copy Bundle Resources phase, and the real group files (with the unit groups, AWSPluginsCore's
          `paths` hold `AmplifyPlugins/`, which covers every plugin host app)
        - When:
           - the only changed file is one of those READMEs, with `--repo-root` an empty directory
        - Then:
           - no group is selected, with the integration or the unit groups: an edit changes nothing a build or test
             checks, and a deletion or rename is left to `--check-bundled`
           - nothing is printed on stderr: the selection reads no Xcode project
        """
        empty = os.path.join(self.work.name, "empty")
        os.makedirs(empty)
        for readme in ("AmplifyPlugins/Auth/Tests/AuthHostApp/AuthIntegrationTests/README.md",
                       "AmplifyPlugins/Storage/Tests/StorageHostApp/StorageStressTests/README.md",
                       "AmplifyPlugins/Notifications/Push/Tests/PushNotificationHostApp/"
                       "PushNotificationHostAppUITests/README.md"):
            for groups in (INTEG_GROUPS, UNIT_GROUPS):
                with self.subTest(readme=readme, groups=os.path.basename(groups)):
                    result = self.run_selector(groups, [readme], repo_root=empty)
                    self.assertEqual(selection(result), [])
                    self.assertEqual(result.stderr, "")

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

        - Given: the real group files, and a package dump where AmplifyRecordCache's sources are at their real path
        - When:
           - a file moves out of the Cognito client's sources into AmplifyRecordCache's: the changed list names only
             its new path, and `--renames` the pair
           - or a README the Auth host app bundles is renamed within its directory, or to a `.txt` file under
             `scripts/`
        - Then:
           - the moved file selects the groups of the target it left as well as the one it joined
           - the README's rename selects nothing, with the integration or the unit groups, as its edit does: its old
             path is documentation, and `--check-bundled` catches the project still listing it
        """
        self.use_package(stub_package({"AmplifyRecordCache": RECORD_CACHE + "Sources"}))
        moved = (CLIENT + "Sources/Moved.swift", RECORD_CACHE + "Sources/Moved.swift")
        self.assertEqual(self.selected(UNIT_GROUPS, moved[1], renames=[moved]),
                         ["AWSCognitoAuthPlugin", "AmplifyCognitoClient", "AmplifyRecordCache"])

        old = "AmplifyPlugins/Auth/Tests/AuthHostApp/AuthIntegrationTests/README.md"
        for new in ("AmplifyPlugins/Auth/Tests/AuthHostApp/AuthIntegrationTests/Docs/README.md",
                    "scripts/AuthIntegrationTests-README.txt"):
            for groups in (INTEG_GROUPS, UNIT_GROUPS):
                with self.subTest(new=new, groups=os.path.basename(groups)):
                    self.assertEqual(self.selected(groups, new, renames=[(old, new)]), [])

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

    def test_the_check_passes_on_this_checkout(self):
        """Every file this checkout's Xcode projects copy into a bundle is present, other than the ones git ignores.

        - Given: this checkout, where the Predictions and Storage host apps and a canary app bundle integration-test
          configuration files that git ignores and a fresh checkout lacks
        - When:
           - `--check-bundled` runs over it
        - Then:
           - it exits 0 and prints no `::error`
        """
        result = self.run_check()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("::error", result.stdout)

    def test_the_check_fails_on_a_missing_bundled_file(self):
        """A bundled file missing from the checkout fails the check, naming the project; an unlisted or ignored one
        does not.

        - Given: a scratch checkout whose one project bundles `GeoStressTests/README.md` (through a group with a
          `path` inside a group with only a `name`) and `GeoStressTests/amplifyconfiguration.json`, which a
          `.gitignore` ignores, and lists `GeoStressTests/Notes/README.md` outside any bundle; none of the three is
          in the checkout
        - When:
           - `--check-bundled` runs over it, then again with the README restored, then again with the `.gitignore`
             removed
        - Then:
           - the first run exits 1 with an `::error` on the project file naming the README, and names neither the
             unlisted README nor the ignored configuration
           - the second passes
           - the third fails, naming the configuration
        """
        root = self.scratch_checkout(GEO_PBXPROJ, files=[GEO_HOST_APP + ".gitignore"])
        with open(os.path.join(root, GEO_HOST_APP + ".gitignore"), "w") as f:
            f.write("amplifyconfiguration.json\n")
        readme = GEO_HOST_APP + "GeoStressTests/README.md"
        result = self.run_check(root)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        errors = [line for line in result.stdout.splitlines() if line.startswith("::error")]
        self.assertEqual(len(errors), 1, result.stdout)
        self.assertTrue(errors[0].startswith("::error file=" + GEO_PROJECT + "/project.pbxproj::"), errors[0])
        self.assertIn(readme, errors[0])

        os.makedirs(os.path.dirname(os.path.join(root, readme)))
        with open(os.path.join(root, readme), "w") as f:
            f.write("x\n")
        result = self.run_check(root)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

        os.remove(os.path.join(root, GEO_HOST_APP + ".gitignore"))
        result = self.run_check(root)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn(GEO_HOST_APP + "GeoStressTests/amplifyconfiguration.json", result.stdout)

    def test_the_check_fails_on_a_project_it_cannot_read(self):
        """A project the parser can't read fails the check, naming it, rather than passing unchecked.

        - Given: a scratch checkout whose one project file is truncated
        - When:
           - `--check-bundled` runs over it
        - Then:
           - it exits 1 with an `::error` on that project's file
        """
        root = self.scratch_checkout(GEO_PBXPROJ[:len(GEO_PBXPROJ) // 2])
        result = self.run_check(root)
        self.assertEqual(result.returncode, 1)
        self.assertIn("::error file=" + GEO_PROJECT + "/project.pbxproj::could not read", result.stdout)

    def test_the_check_fails_when_git_cannot_say_what_it_ignores(self):
        """Outside a git checkout, a missing bundled file fails the check rather than being taken as ignored.

        - Given: a scratch directory that is not a git repository, whose one project bundles a README it lacks
        - When:
           - `--check-bundled` runs over it
        - Then:
           - it exits 1 and says it could not ask git
        """
        root = self.scratch_checkout(GEO_PBXPROJ, git=False)
        result = self.run_check(root)
        self.assertEqual(result.returncode, 1)
        self.assertIn("could not ask git", result.stdout)

    def test_the_default_repo_root_is_the_checkout_holding_the_selector(self):
        """Run from another directory without `--repo-root`, the check still reads this checkout's projects.

        - Given: a working directory outside the checkout, and no `--repo-root`
        - When:
           - `--check-bundled` runs
        - Then:
           - it passes, as when run from the checkout's root, with no "found no Xcode project" error
        """
        result = self.run_check(repo_root=None, cwd=self.work.name)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("found no Xcode project", result.stdout)

    def test_a_root_with_no_project_fails_the_check(self):
        """A `--repo-root` holding no Xcode project fails the check rather than passing with nothing checked.

        - Given: an empty directory as `--repo-root`
        - When:
           - `--check-bundled` runs
        - Then:
           - it exits 1 with an `::error` saying it found no project
        """
        root = os.path.join(self.work.name, "empty")
        os.makedirs(root)
        result = self.run_check(root)
        self.assertEqual(result.returncode, 1)
        self.assertIn("::error::found no Xcode project", result.stdout)

    def test_the_selection_needs_its_inputs_without_the_check(self):
        """Without `--check-bundled`, a missing `--package`, `--changed` or `--groups` is a usage error.

        - Given: no package dump argument
        - When:
           - the selector runs with only `--changed` and `--groups`
        - Then:
           - it exits 2 and names the required options
        """
        result = subprocess.run([sys.executable, SCRIPT, "--changed", self.write_list("changed.txt", ["x"]),
                                 "--groups", INTEG_GROUPS], capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn("--package, --changed and --groups are required", result.stderr)

def selection(result):
    """The `selected=` array in a selector run's output."""
    line = next(line for line in result.stdout.splitlines() if line.startswith("selected="))
    return json.loads(line[len("selected="):])


RECORD_CACHE = "AmplifyClients/AmplifyRecordCache/"
GEO_HOST_APP = "AmplifyPlugins/Geo/Tests/GeoHostApp/"
GEO_PROJECT = GEO_HOST_APP + "GeoHostApp.xcodeproj"

# A minimal project: the main group holds a name-only group, which holds the `GeoStressTests` path group, which
# holds README.md, Notes/README.md and amplifyconfiguration.json. The first and the last are in the Copy Bundle
# Resources phase.
GEO_PBXPROJ = """// !$*UTF8*$!
{
	archiveVersion = 1;
	objects = {
		B1 /* README.md in Resources */ = {isa = PBXBuildFile; fileRef = F1 /* README.md */; };
		B3 /* amplifyconfiguration.json in Resources */ = {isa = PBXBuildFile; fileRef = F3 /* amplifyconfiguration.json */; };
		F1 /* README.md */ = {isa = PBXFileReference; lastKnownFileType = net.daringfireball.markdown; path = README.md; sourceTree = "<group>"; };
		F2 /* README.md */ = {isa = PBXFileReference; lastKnownFileType = net.daringfireball.markdown; path = Notes/README.md; sourceTree = "<group>"; };
		F3 /* amplifyconfiguration.json */ = {isa = PBXFileReference; lastKnownFileType = text.json; path = amplifyconfiguration.json; sourceTree = "<group>"; };
		G0 = {isa = PBXGroup; children = (G1 /* Tests */, ); sourceTree = "<group>"; };
		G1 /* Tests */ = {isa = PBXGroup; children = (G2 /* GeoStressTests */, ); name = Tests; sourceTree = "<group>"; };
		G2 /* GeoStressTests */ = {isa = PBXGroup; children = (F1 /* README.md */, F2 /* README.md */, F3 /* amplifyconfiguration.json */, ); path = GeoStressTests; sourceTree = "<group>"; };
		P1 /* Project object */ = {isa = PBXProject; mainGroup = G0; projectDirPath = ""; targets = (); };
		R1 /* Resources */ = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (B1 /* README.md in Resources */, B3 /* amplifyconfiguration.json in Resources */, ); runOnlyForDeploymentPostprocessing = 0; };
	};
	rootObject = P1 /* Project object */;
}
"""

if __name__ == "__main__":
    unittest.main()
