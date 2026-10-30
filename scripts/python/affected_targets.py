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
ALL groups — genuinely-unattributable changes are never silently skipped (a rename's old path can be
the exception, see Renames below). Package.swift and
Package.resolved are NOT among these: manifest/lockfile edits are always-ignored (see
ALWAYS_IGNORE_NAMES), on the basis that the source changes using a new/changed target trigger their
own groups. Integration-test host apps and Xcode project bundles (`HostApp/` and `.xcodeproj/`
contents — see IGNORE_PATH_SUBSTRINGS) are likewise not fail-closed: they are integration-only, so
they are attributed to their integ group by its path rule when covered and otherwise ignored, never
SwiftPM/unit inputs.

Renames: `--changed` is a rename-detecting list (`git diff --name-only -M`), which names a rename's new
path only, and `--renames` holds each rename's old and new paths, tab-separated (`git diff --name-status
-M --diff-filter=R | cut -f2-`). An old path is attributed like any changed file, with one difference:
one that nothing owns, covers or ignores is skipped rather than failing closed when its new path is
itself attributed (owned by a target, or under a group's `paths`), since that new path is already in
the changed list and selects its group. So moving a target's files to a new directory selects what the
new paths select, not every group. When the new path is ignored or unknown too (an unknown file moved
into `scripts/` or `.github/`, say), the old path fails closed, as its deletion would. A plain deletion
is in the changed list and still fails closed.

Documentation (`.md`) is ignored everywhere, including a file an Xcode project copies into a bundle (a
host app's README in a test target's Copy Bundle Resources): editing one changes nothing a build or test
checks. Deleting or renaming one breaks the build of the target that copies it, which no selection can
promise to catch (six of the bundled READMEs are copied only by stress-test targets, which no PR job
builds), so the detect steps run `--check-bundled` before selecting: it fails, naming the project, when a
file any Xcode project in the checkout lists in Copy Bundle Resources is missing from the checkout, other
than one git ignores (an integration-test configuration CI writes before building). A project it can't
read, or a root with no project at all, fails the check too. The projects are read from `--repo-root`
(default: the checkout that holds this script, wherever it is run from).

It also validates the group config: if any group references a target that is absent from the
SwiftPM graph (a rename, a typo, or a not-yet-wired target), it exits non-zero rather than
silently never selecting that group.

Usage:
    python3 scripts/python/affected_targets.py \
        --package package.json --changed changed.txt [--renames renames.txt] \
        --groups scripts/python/<groups>.json
    python3 scripts/python/affected_targets.py --check-bundled [--repo-root <checkout>]

The selection writes to stdout (append to "$GITHUB_OUTPUT"):
    selected=<json array of affected group names>
    <group>=true|false        # one line per group, for use in job-level `if:`
The check writes one `::error` workflow command per problem to stdout and exits 1, or a summary and 0.
"""
import argparse
import json
import os
import re
import subprocess
import sys

# Paths that can never affect tests. Kept deliberately small — anything not listed here and not
# owned by a target falls through to the fail-closed "run everything" branch.
# Repo/editor metadata and documentation, ignored even inside a target dir (checked before
# target ownership). `.md` is here rather than in the unowned-only list below because a README/AGENTS
# doc inside a target dir is usually just prose: it is never compiled, so editing it should not
# trigger that target's 5-platform matrix. A README a host app copies into a bundle is ignored too:
# editing it changes no test, and the deletion or rename that would break the copying target's build
# is caught by `--check-bundled` instead (see the module docstring). (`.yml`/`.yaml` are deliberately
# NOT promoted — an in-target YAML fixture is real test input and must stay owned; see the
# unowned-only list.)
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
# Integration-test host apps (`<Something>HostApp/` — the Xcode host app that runs a category's
# integration tests, its `.xcodeproj` bundle, and the integration `.swift` sources inside it) and any
# other stray `.xcodeproj` bundle. None of this is a SwiftPM-compiled source or a unit-test resource,
# so a host-app edit can never change a unit-test outcome — unit runs are gated and host-app changes
# drive integration only. This is checked when unowned and AFTER the group-path rule below, so a host
# app that sits under an integration group's `paths` is still attributed to that integ group (e.g.
# KinesisFirehoseClientHostApp via the path added to `kinesis_firehose`); this rule only keeps a
# host-app edit from fanning out to every group via the fail-closed branch. A host app whose category
# has no integration group at all (e.g. AmplifyConnectClient, which is not slated for integ CI) falls
# through to here and correctly selects nothing.
IGNORE_PATH_SUBSTRINGS = (".xcodeproj/", "HostApp/")
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


def is_always_ignored(path):
    """True for a file that never affects a build or test wherever it lives (ALWAYS_IGNORE_*)."""
    return path.endswith(ALWAYS_IGNORE_SUFFIXES) or path.rsplit("/", 1)[-1] in ALWAYS_IGNORE_NAMES


# Directories read_projects never descends into: VCS metadata and local build output.
SCAN_SKIP_DIRS = {".git", ".build", "DerivedData", "node_modules"}

# One token of an Xcode project file (an old-style ASCII property list): whitespace or a comment
# (skipped), a quoted string (group 1), punctuation (group 2), or an unquoted string (group 3).
_PLIST_TOKEN = re.compile(r'\s+|/\*.*?\*/|//[^\n]*|"((?:[^"\\]|\\.)*)"|([{}()=;,])|([^\s{}()=;,"]+)',
                          re.S)


def _unescape(match):
    """The character a quoted-string escape (`\\n`, `\\t`, `\\"`, `\\\\`) stands for."""
    return {"n": "\n", "t": "\t"}.get(match.group(1), match.group(1))


def parse_pbxproj(text):
    """Parse an Xcode `project.pbxproj` into dicts, lists and strings. Raises ValueError if malformed."""
    tokens, pos = [], 0
    while pos < len(text):
        m = _PLIST_TOKEN.match(text, pos)
        if not m:
            raise ValueError("unexpected character at offset %d" % pos)
        pos = m.end()
        if m.group(1) is not None:
            tokens.append(("str", re.sub(r"\\(.)", _unescape, m.group(1))))
        elif m.group(2):
            tokens.append(("punct", m.group(2)))
        elif m.group(3):
            tokens.append(("str", m.group(3)))

    def token(i):
        if i >= len(tokens):
            raise ValueError("unexpected end of file")
        return tokens[i]

    def expect(i, punct):
        if token(i) != ("punct", punct):
            raise ValueError("expected %r, found %r" % (punct, token(i)[1]))
        return i + 1

    def value(i):
        kind, tok = token(i)
        if kind == "str":
            return tok, i + 1
        if tok == "{":
            obj, i = {}, i + 1
            while token(i) != ("punct", "}"):
                if token(i)[0] != "str":
                    raise ValueError("expected a key, found %r" % token(i)[1])
                key = token(i)[1]
                i = expect(i + 1, "=")
                obj[key], i = value(i)
                i = expect(i, ";")
            return obj, i + 1
        if tok == "(":
            items, i = [], i + 1
            while token(i) != ("punct", ")"):
                item, i = value(i)
                items.append(item)
                if token(i) == ("punct", ","):
                    i += 1
                elif token(i) != ("punct", ")"):
                    raise ValueError("expected ',' or ')', found %r" % token(i)[1])
            return items, i + 1
        raise ValueError("unexpected %r" % tok)

    root, end = value(0)
    if end != len(tokens) or not isinstance(root, dict):
        raise ValueError("trailing content after the top-level dictionary")
    return root


def bundle_resources(project_dir, text):
    """Paths (joined onto `project_dir`) of the files an Xcode project's Copy Bundle Resources phases copy.

    A `<group>`-relative reference resolves through its parent groups' `path`s (a group with only a
    `name` adds nothing); a `SOURCE_ROOT` reference resolves from the project directory. References
    outside the checkout (absolute, SDK, built products) are left out. A folder synchronized with the
    file system has no per-file reference, so a deleted file there simply drops out of the build.
    """
    objects = parse_pbxproj(text)["objects"]
    parent = {child: oid for oid, obj in objects.items() for child in obj.get("children", [])}
    project = next(obj for obj in objects.values() if obj.get("isa") == "PBXProject")
    main_group = project["mainGroup"]
    base = os.path.join(project_dir, project.get("projectDirPath", ""))

    def location(oid):
        obj = objects.get(oid)
        if obj is None:
            return None
        path = obj.get("path", "")
        if oid == main_group:
            return os.path.join(base, path)
        tree = obj.get("sourceTree", "<group>")
        if tree == "SOURCE_ROOT":
            return os.path.join(base, path)
        if tree != "<group>" or oid not in parent:
            return None
        directory = location(parent[oid])
        return None if directory is None else os.path.join(directory, path)

    def files(oid):
        obj = objects.get(oid, {})
        if "children" in obj:  # a variant (localized) group: every variant is copied
            return [p for child in obj["children"] for p in files(child)]
        loc = location(oid)
        return [] if loc is None else [loc]

    copied = set()
    for obj in objects.values():
        if obj.get("isa") == "PBXResourcesBuildPhase":
            for build_file in obj.get("files", []):
                ref = objects.get(build_file, {}).get("fileRef")
                if ref:
                    copied.update(files(ref))
    return copied


def read_projects(root):
    """Return (bundles, unread) for the Xcode projects under the checkout at `root`.

    `bundles` maps each readable project's repo-relative `.xcodeproj` path to the repo-relative paths of the files
    it copies into a bundle. `unread` holds (project, error) for each project this parser could not read.
    """
    def rel(path):
        return os.path.relpath(os.path.normpath(path), root).replace(os.sep, "/")

    bundles, unread = {}, []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(d for d in dirnames if d not in SCAN_SKIP_DIRS)
        if not dirpath.endswith(".xcodeproj"):
            continue
        dirnames[:] = []
        if "project.pbxproj" not in filenames:
            continue
        try:
            with open(os.path.join(dirpath, "project.pbxproj"), encoding="utf-8") as f:
                bundles[rel(dirpath)] = {rel(p) for p in bundle_resources(os.path.dirname(dirpath), f.read())}
        except Exception as error:  # noqa: BLE001 -- any unreadable project fails the check, see check_bundled
            unread.append((rel(dirpath), error))
    return bundles, unread


def _escape(text, prop=False):
    """`text` escaped for a GitHub workflow command's message (or, with `prop`, a property value)."""
    text = text.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    return text.replace(":", "%3A").replace(",", "%2C") if prop else text


def _error(message, project=None):
    """An `::error` workflow command (annotating `project`'s project file, if given) on stdout."""
    where = "" if project is None else " file=" + _escape(project + "/project.pbxproj", prop=True)
    print("::error%s::%s" % (where, _escape(message)))


def git_ignored(root, paths):
    """The subset of the repo-relative `paths` that git ignores in the checkout at `root`. Raises OSError or
    subprocess.CalledProcessError when git can't answer."""
    if not paths:
        return set()
    result = subprocess.run(["git", "-C", root, "check-ignore", "-z", "--stdin"], input="\0".join(paths) + "\0",
                            capture_output=True, text=True)
    if result.returncode not in (0, 1):  # 1: none of them is ignored
        raise subprocess.CalledProcessError(result.returncode, result.args, result.stdout, result.stderr)
    return {p for p in result.stdout.split("\0") if p}


def check_bundled(root):
    """`--check-bundled`: 1 when a file an Xcode project under `root` copies into a bundle is missing from the
    checkout, a project can't be read, or there is no project at all; otherwise 0.

    A missing file git ignores is left out: the integration-test configurations (amplifyconfiguration.json,
    amplify_outputs.json) are written by CI before a build and are absent from a fresh checkout. So is a reference
    that resolves outside the checkout.
    """
    bundles, unread = read_projects(root)
    if not bundles and not unread:
        _error("found no Xcode project under %s, so no bundled file was checked; pass the checkout's root as "
               "--repo-root" % root)
        return 1
    failed = False
    for project, error in unread:
        _error("could not read the bundle resources of %s (%s), so a file it copies into a bundle may be missing "
               "unnoticed" % (project, error), project)
        failed = True
    missing = {project: sorted(f for f in files if not f.startswith("../") and
                               not os.path.exists(os.path.join(root, f)))
               for project, files in bundles.items()}
    try:
        ignored = git_ignored(root, sorted({f for files in missing.values() for f in files}))
    except (OSError, subprocess.CalledProcessError) as error:
        _error("could not ask git which of the missing bundled files it ignores (%s)"
               % (getattr(error, "stderr", None) or error).strip())
        return 1
    for project, files in sorted(missing.items()):
        for f in files:
            if f not in ignored:
                _error("%s copies %s into a bundle (Copy Bundle Resources), but the file is not in the checkout. "
                       "Restore it, or update the project: remove the reference, or point it at the file's new path."
                       % (project, f), project)
                failed = True
    if not failed:
        print("checked the %d files %d Xcode projects copy into bundles: none is missing"
              % (sum(len(files) for files in bundles.values()), len(bundles)))
    return 1 if failed else 0


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


# The checkout that holds this script (scripts/python/affected_targets.py), the default --repo-root.
SCRIPT_CHECKOUT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def read_paths(path):
    """The non-blank lines of a path-list file, stripped."""
    with open(path) as f:
        return [line.strip() for line in f if line.strip()]


def read_renames(path):
    """The (old path, new path) pairs of a rename list: one rename per line, the two paths tab-separated."""
    pairs = []
    for line in read_paths(path):
        fields = line.split("\t")
        if len(fields) != 2 or not all(fields):
            sys.stderr.write("%s: expected an old path, a tab and a new path, found %r\n" % (path, line))
            sys.exit(1)
        pairs.append((fields[0], fields[1]))
    return pairs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check-bundled", action="store_true",
                    help="instead of selecting, fail when a file an Xcode project copies into a bundle is missing")
    ap.add_argument("--package", help="swift package dump-package JSON")
    ap.add_argument("--changed",
                    help="file with one changed path per line, from a rename-detecting diff (a rename's new path)")
    ap.add_argument("--renames",
                    help="file with one rename per line, the old and new paths tab-separated; an old path is "
                         "attributed, and an unknown one fails closed unless the new path is attributed")
    ap.add_argument("--groups", help="group definition JSON")
    ap.add_argument("--repo-root", default=SCRIPT_CHECKOUT,
                    help="checkout whose Xcode projects --check-bundled reads (default: the one holding this "
                         "script)")
    args = ap.parse_args()
    if args.check_bundled:
        sys.exit(check_bundled(args.repo_root))
    if not (args.package and args.changed and args.groups):
        ap.error("--package, --changed and --groups are required unless --check-bundled is given")

    pkg = json.load(open(args.package))
    groups = json.load(open(args.groups))
    changed = read_paths(args.changed)
    renames = read_renames(args.renames) if args.renames else []
    renamed_from = [old for old, _ in renames]

    path_of, deps_of, is_test = build_graph(pkg)
    ignored = is_always_ignored

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

    def classify(f):
        """"attributed" (recording f's owning target, if any), "ignored", or "unknown"."""
        if ignored(f):
            return "ignored"
        owner = max((n for n, p in path_of.items() if f.startswith(p)),
                    key=lambda n: len(path_of[n]), default=None)
        if owner:
            changed_targets.add(owner)
            return "attributed"
        if f.startswith(XCSCHEME_DIR) and f.endswith(XCSCHEME_SUFFIX):
            # A per-target scheme -> attribute to that target and let dependency logic narrow it.
            # An umbrella/aggregate scheme names no target -> unknown (whole-package impact).
            scheme = f[len(XCSCHEME_DIR):-len(XCSCHEME_SUFFIX)]
            if scheme in path_of:
                changed_targets.add(scheme)
                return "attributed"
            return "unknown"
        if any(f.startswith(p) for p in group_paths):
            return "attributed"  # to a group, by its path rule below
        if (f.endswith(IGNORE_SUFFIXES) or f.startswith(IGNORE_PREFIXES)
                or f.rsplit("/", 1)[-1] in IGNORE_NAMES
                or any(s in f for s in IGNORE_PATH_SUBSTRINGS)):
            return "ignored"
        return "unknown"

    for f in changed:
        if classify(f) == "unknown":
            emit(groups.keys())
    # A rename's old path: attributed the same way. An unknown one is skipped only when the rename's
    # new path (also in `changed`) is itself attributed; otherwise it fails closed, as its deletion
    # would (see the module docstring).
    for old, new in renames:
        if classify(old) == "unknown" and classify(new) != "attributed":
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

    # Groups selected by a path rule (dirs that are not SwiftPM targets). An ignored file (a README
    # under a group's path, bundled or not) selects nothing here either, as in the file loop above.
    # A rename's old path counts here too.
    relevant = [f for f in changed + renamed_from if not ignored(f)]
    for name, group in groups.items():
        if any(f.startswith(p) for p in group.get("paths", []) for f in relevant):
            selected.add(name)
    emit(selected)


if __name__ == "__main__":
    main()
