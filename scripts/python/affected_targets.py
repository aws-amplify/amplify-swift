#!/usr/bin/env python3
"""
Select which build groups are affected by a change set, using the SwiftPM dependency graph.

A "group" is a unit-test scheme or an integration-test category. Groups are defined in a JSON
config mapping each group name to the targets and/or path prefixes that make it up:

    {
      "geo": { "targets": ["AWSLocationGeoPlugin"], "paths": ["AmplifyPlugins/Geo/"] },
      ...
    }

A group is affected when a changed file:
  * belongs to one of its `targets`, or to anything those targets transitively depend on,
    or to their test targets (dependency closure, read from `swift package dump-package`); or
  * lives under one of its `paths` prefixes (covers dirs that are not SwiftPM targets, e.g.
    integration-test folders or host apps).

Fail-closed: a changed file that matches no target, no group path, and no ignore rule selects
ALL groups. That covers Package.swift, CI config, and — importantly — a target/dir that has been
added to the CI matrix but not yet wired into Package.swift, so its tests are never silently skipped.

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
IGNORE_SUFFIXES = (".md",)
IGNORE_PREFIXES = ("readme-images/", "docs/", ".github/ISSUE_TEMPLATE/")


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


def forward_closure(start, deps_of):
    """All targets `start` transitively depends on, including `start`."""
    seen, stack = set(), [start]
    while stack:
        node = stack.pop()
        if node not in seen:
            seen.add(node)
            stack.extend(deps_of.get(node, ()))
    return seen


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
        owner = max((n for n, p in path_of.items() if f.startswith(p)),
                    key=lambda n: len(path_of[n]), default=None)
        if owner:
            changed_targets.add(owner)
        elif any(f.startswith(p) for p in group_paths):
            continue  # attributed to a group by its path rule below
        elif f.endswith(IGNORE_SUFFIXES) or f.startswith(IGNORE_PREFIXES):
            continue
        else:
            emit(groups.keys())

    # The set of targets whose change should flag a given source target: the target itself, its
    # transitive dependencies, its test targets, and those test targets' dependencies.
    def flagging_set(target):
        rel = forward_closure(target, deps_of)
        for tt, tdeps in deps_of.items():
            if is_test[tt] and target in tdeps:
                rel |= forward_closure(tt, deps_of)
        return rel

    selected = set()
    for name, group in groups.items():
        hit = any(flagging_set(t) & changed_targets for t in group.get("targets", []))
        if not hit:
            hit = any(f.startswith(p) for p in group.get("paths", []) for f in changed)
        if hit:
            selected.add(name)
    emit(selected)


if __name__ == "__main__":
    main()
