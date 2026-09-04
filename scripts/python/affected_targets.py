#!/usr/bin/env python3
"""
Select which build groups are affected by a change set, using the SwiftPM dependency graph.

A "group" is a unit-test scheme or an integration-test category. Groups are defined in a JSON
config mapping each group name to the targets and/or path prefixes that make it up:

    {
      "geo": { "targets": ["AWSLocationGeoPlugin"], "paths": ["AmplifyPlugins/Geo/"] },
      ...
    }

A group is affected ONLY by changes to its own target — never by changes to something it merely
depends on. Concretely, a group is affected when a changed file:
  * belongs to its `targets` (the group's source target); or
  * belongs to that target's test target (matched by name, e.g. FooTests -> Foo, or by the
    group-source it directly depends on); or
  * lives under one of its `paths` prefixes (covers dirs that are not SwiftPM targets, e.g.
    integration-test folders or host apps).

This deliberately does NOT fan out to dependents: editing a shared module (e.g. AWSPluginsCore)
runs that module's own group, not every plugin that depends on it. Cross-cutting coverage of
dependents is left to the full run (push to main / nightly).

A change owned by a target that has no group of its own (a shared util / core module like
AWSPluginsCore, or a C dependency) selects NOTHING — consistent with "own group only", we never run
dependents, and there is no own group to run. Its impact on dependents is covered by the full run
(push to main / nightly).

Fail-closed: a changed file that matches no TARGET at all (and no group path / ignore rule) selects
ALL groups — genuinely-unattributable changes are never silently skipped. Package.swift and
Package.resolved are NOT among these: manifest/lockfile edits are always-ignored (see
ALWAYS_IGNORE_NAMES), on the basis that the source changes using a new/changed target trigger their
own groups.

It also validates the group config: if any group references a target that is absent from the
SwiftPM graph (a rename, a typo, or a not-yet-wired target), it exits non-zero rather than
silently never selecting that group.

Usage:
    python3 scripts/python/affected_targets.py \
        --package package.json --changed changed.txt --groups scripts/python/<groups>.json

Writes to stdout (append to "$GITHUB_OUTPUT"):
    selected=<json array of affected group names>
    <group>=true|false        # one line per group, for use in job-level `if:`
"""
import argparse
import json
import sys

# Paths that can never affect tests. Kept deliberately small — anything not listed here and not
# owned by a target falls through to the fail-closed "run everything" branch.
# Repo/editor metadata and documentation that is inert wherever it lives — never affects a build or
# test, so it is ignored even inside a target directory (checked before target ownership). `.md` is
# here rather than in the unowned-only list below because a README/AGENTS doc inside a target dir is
# still just prose: it is never compiled and never consumed as a test resource, so editing it should
# not trigger that target's 5-platform matrix. (`.yml`/`.yaml` are deliberately NOT promoted — an
# in-target YAML fixture is real test input and must stay owned; see the unowned-only list.)
ALWAYS_IGNORE_SUFFIXES = (".gitignore", ".gitattributes", ".swiftformat", ".editorconfig", ".md")
ALWAYS_IGNORE_NAMES = ("LICENSE", "NOTICE", ".git-blame-ignore-revs", ".gitallowed",
                       # Xcode file-header template macros: an IDE authoring convenience only
                       # (defines the //___FILEHEADER___ text). Never compiled or tested.
                       "IDETemplateMacros.plist",
                       # Package.swift / Package.resolved: a manifest or dependency-pin edit is not
                       # itself change-gated. The source changes that use a new/changed target
                       # trigger their own groups; a pure manifest/lockfile change runs nothing here
                       # (the full main/nightly run covers it).
                       "Package.swift", "Package.resolved")

# Files safe to ignore only when they aren't owned by an SPM target — none of which affect unit or
# integration test outcomes: CI/lint/tooling config (.yml/.yaml — an in-target YAML fixture is still
# owned and runs), images, repo metadata under .github/, the separately-tested canary apps, API-dump
# baselines/fixtures, fastlane config, the standalone AmplifyTools CLI, and repo scripts under
# scripts/ (the detect job runs the selector regardless, so a broken selector or group config still
# fails detect rather than being silently skipped). Documentation (.md) is instead always-ignored
# above, since it is inert even inside a target dir.
# Gemfile/Gemfile.lock pin the Ruby tooling (fastlane, jazzy, xcpretty) used for docs and release
# automation; the gated unit/integration jobs run xcodebuild directly and never `bundle exec`, so a
# gem bump cannot change a test outcome. (Package.swift and Package.resolved are always-ignored
# above — manifest/lockfile edits are not change-gated.)
IGNORE_SUFFIXES = (".yml", ".yaml")
IGNORE_NAMES = ("Gemfile", "Gemfile.lock")
IGNORE_PREFIXES = (
    "readme-images/",
    ".github/",
    "canaries/",
    "api-dump/",
    "api-dump-test/",
    "fastlane/",
    "AmplifyTools/",
    "scripts/",
)

# Shared Xcode schemes live here, one <SchemeName>.xcscheme per scheme. A scheme configures exactly
# how one scheme's build/tests run (which test targets, test plan, arguments), so an edit to it can
# only affect that scheme — not the whole matrix. For every per-target scheme the filename equals a
# SwiftPM target, so we attribute the change to that target (below) and let the dependency logic pick
# the affected group(s). Umbrella schemes (Amplify-Package, Amplify-Build) name no single target and
# fall through to fail closed, as do other .swiftpm files (e.g. the workspace's package references in
# contents.xcworkspacedata, which can affect every scheme's resolution).
XCSCHEME_DIR = ".swiftpm/xcode/xcshareddata/xcschemes/"
XCSCHEME_SUFFIX = ".xcscheme"


def build_graph(pkg):
    """Return (path_of, deps_of, is_test) from a `swift package dump-package` document."""
    names = {t["name"] for t in pkg["targets"]}
    path_of, deps_of, is_test = {}, {}, {}
    for t in pkg["targets"]:
        name = t["name"]
        path_of[name] = t["path"].rstrip("/") + "/"
        is_test[name] = t.get("type") == "test"
        deps = set()
        for dep in t.get("dependencies", []):
            # Internal target edges serialize as {"target": [...]} or {"byName": [...]};
            # external package products as {"product": [...]}. We only want local targets.
            for key in ("target", "byName"):
                if dep.get(key) and dep[key][0]:
                    deps.add(dep[key][0])
        deps_of[name] = deps
    for name in deps_of:
        deps_of[name] &= names  # drop edges to external products
    return path_of, deps_of, is_test


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--package", required=True, help="swift package dump-package JSON")
    ap.add_argument("--changed", required=True, help="file with one changed path per line")
    ap.add_argument("--groups", required=True, help="group definition JSON")
    args = ap.parse_args()

    pkg = json.load(open(args.package))
    groups = json.load(open(args.groups))
    changed = [line.strip() for line in open(args.changed) if line.strip()]

    path_of, deps_of, is_test = build_graph(pkg)

    # Guard: every target a group references must exist in the SwiftPM graph. Otherwise a group
    # naming a renamed, mistyped, or not-yet-wired target would silently never be selected and its
    # tests would silently stop running. Fail loudly instead.
    missing = sorted(
        {t for group in groups.values() for t in group.get("targets", [])} - set(path_of)
    )
    if missing:
        sys.stderr.write(
            "group targets absent from Package.swift (%s): %s\n" % (args.groups, ", ".join(missing))
        )
        sys.exit(1)

    group_paths = [p for g in groups.values() for p in g.get("paths", [])]

    def emit(selected):
        selected = sorted(selected)
        out = ["selected=" + json.dumps(selected)]
        out += [f"{name}=" + ("true" if name in selected else "false") for name in groups]
        print("\n".join(out))
        sys.exit(0)

    # Map each changed file to its owning target (longest matching path wins). A file owned by no
    # target, matching no group path, and not ignorable is unknown -> fail closed to all groups.
    changed_targets = set()
    for f in changed:
        if f.endswith(ALWAYS_IGNORE_SUFFIXES) or f.rsplit("/", 1)[-1] in ALWAYS_IGNORE_NAMES:
            continue
        owner = max((n for n, p in path_of.items() if f.startswith(p)),
                    key=lambda n: len(path_of[n]), default=None)
        if owner:
            changed_targets.add(owner)
        elif f.startswith(XCSCHEME_DIR) and f.endswith(XCSCHEME_SUFFIX):
            # A per-target scheme -> attribute to that target and let dependency logic narrow it.
            # An umbrella/aggregate scheme names no target -> fail closed (whole-package impact).
            scheme = f[len(XCSCHEME_DIR):-len(XCSCHEME_SUFFIX)]
            if scheme in path_of:
                changed_targets.add(scheme)
            else:
                emit(groups.keys())
        elif any(f.startswith(p) for p in group_paths):
            continue  # attributed to a group by its path rule below
        elif (f.endswith(IGNORE_SUFFIXES) or f.startswith(IGNORE_PREFIXES)
              or f.rsplit("/", 1)[-1] in IGNORE_NAMES):
            continue
        else:
            emit(groups.keys())

    # Each group's source target(s) -> group name.
    source_to_group = {t: name for name, g in groups.items() for t in g.get("targets", [])}

    def strip_test_suffix(n):
        for suf in ("UnitTests", "IntegrationTests", "Tests"):
            if n.endswith(suf) and len(n) > len(suf):
                return n[:-len(suf)]
        return n

    # A changed target selects ONLY its own group — never groups that merely depend on it. So a
    # change to a shared module (e.g. AWSPluginsCore) runs that module's own group, not every plugin
    # that depends on it. Mapping:
    #   * a group's source target                      -> that group
    #   * a group's test target (name-matched, or the  -> that group
    #     group-source it directly depends on)
    #   * a target owned by no group (a shared util / core module / C dependency) -> nothing. Per
    #     "own group only" we never fan out to dependents, and such a target has no group of its own,
    #     so its change selects no group here. (A change to a genuinely unknown PATH, owned by no
    #     target at all, still fails closed in the file loop above.)
    selected = set()
    for x in changed_targets:
        if x in source_to_group:
            selected.add(source_to_group[x])
        elif is_test[x]:
            cands = set()
            base = strip_test_suffix(x)
            if base in source_to_group:
                cands.add(source_to_group[base])
            cands |= {source_to_group[d] for d in deps_of.get(x, ()) if d in source_to_group}
            # A test target for a module that has no group here selects nothing.
            selected |= cands
        # else: owned by a non-group source target -> selects nothing (see comment above).

    # Groups selected by a path rule (dirs that are not SwiftPM targets).
    for name, group in groups.items():
        if any(f.startswith(p) for p in group.get("paths", []) for f in changed):
            selected.add(name)
    emit(selected)


if __name__ == "__main__":
    main()
