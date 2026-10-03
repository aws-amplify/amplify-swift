#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""The privacy-manifest check of the Cognito engine (InternalAWSCognitoAuth).

  scripts/m2/check_engine_privacy_manifest.py                        # over `swift package dump-package`
  scripts/m2/check_engine_privacy_manifest.py --package-json p.json  # use a saved dump
  scripts/m2/check_engine_privacy_manifest.py --self-test

The engine target (InternalAWSCognitoAuth) is not a product and has no privacy manifest of its own. So
every library product that links it must declare each required-reason API category the engine's sources
use, with an accepted reason. The categories are found by scanning the engine's sources for the APIs in
REQUIRED_REASON_APIS.

A product's declarations are the `PrivacyInfo.xcprivacy` resources of the in-package targets that link it
to the engine: its own targets and every target on a dependency path from them to the engine. Their
resource bundles ship wherever the product does, and Apple aggregates every bundle's manifest. A manifest
of a target off those paths does not count, since it would stop shipping if that unrelated dependency
were dropped. For example AWSPinpointAnalyticsPlugin reaches the engine through InternalAWSPinpoint and
AWSCognitoAuthPlugin, whose manifest declares the category.

It fails when a product linking the engine has no such manifest, or those manifests miss a category the
engine uses, or declare it without one of the accepted reasons. It also fails when no product links the
engine at all (a wrong target name or a broken dump would otherwise pass silently).
"""
import argparse
import json
import os
import plistlib
import re
import subprocess
import sys

ENGINE = "InternalAWSCognitoAuth"

# category: (the source pattern that uses it, the reasons accepted for the engine's use)
# https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
REQUIRED_REASON_APIS = {
    "NSPrivacyAccessedAPICategoryUserDefaults": (re.compile(r"\bUserDefaults\b|\bCFPreferences\w*"), {"CA92.1"}),
    "NSPrivacyAccessedAPICategoryFileTimestamp": (
        re.compile(r"\b(?:creationDate|modificationDate|contentModificationDate\w*|fileModificationDate)\b"
                   r"|\.(?:creationDateKey|contentModificationDateKey)\b|\b(?:stat|fstat|lstat|getattrlist)\("),
        {"C617.1", "3B52.1", "0A2A.1"},
    ),
    "NSPrivacyAccessedAPICategorySystemBootTime": (
        re.compile(r"\bsystemUptime\b|\bmach_absolute_time\("),
        {"35F9.1"},
    ),
    "NSPrivacyAccessedAPICategoryDiskSpace": (
        re.compile(r"\bvolume(?:Available|Total)Capacity\w*|\bsystemFreeSize\b|\bsystemSize\b|\bf?statv?fs\("),
        {"E174.1", "85F4.1"},
    ),
    "NSPrivacyAccessedAPICategoryActiveKeyboards": (re.compile(r"\bactiveInputModes\b"), {"54BD.1", "3EC4.1"}),
}
MISSING = "missing file: "


def targets_by_name(package):
    return {target["name"]: target for target in package["targets"]}


def target_path(target):
    if target.get("path"):
        return target["path"]
    kind = "Tests" if target.get("type") == "test" else "Sources"
    return os.path.join(kind, target["name"])


def dependency_targets(target, targets):
    for dependency in target.get("dependencies", []):
        for kind in ("byName", "target"):
            if kind in dependency and dependency[kind] and dependency[kind][0] in targets:
                yield dependency[kind][0]


def reaching(package, name):
    """Every in-package target from which `name` is reachable, `name` included."""
    targets = targets_by_name(package)
    memo = {}

    def reaches(current, visiting):
        if current == name:
            return True
        if current in memo:
            return memo[current]
        if current in visiting or current not in targets:
            return False
        visiting.add(current)
        result = any([reaches(dependency, visiting) for dependency in dependency_targets(targets[current], targets)])
        visiting.discard(current)
        memo[current] = result
        return result

    return {current for current in targets if reaches(current, set())}


def linking_path_targets(package, product, name, reach):
    """The product's in-package targets that lie on a dependency path from it to `name`."""
    targets = targets_by_name(package)
    stack, seen = [t for t in product["targets"] if t in reach], set()
    while stack:
        current = stack.pop()
        if current in seen:
            continue
        seen.add(current)
        stack.extend(d for d in dependency_targets(targets.get(current, {}), targets) if d in reach)
    return seen


def strip_comment(line):
    """The line up to a `//` comment. A `//` inside a string literal (a URL, say) is not a comment."""
    in_string, escaped = False, False
    for index, character in enumerate(line):
        if in_string:
            if escaped:
                escaped = False
            elif character == "\\":
                escaped = True
            elif character == '"':
                in_string = False
        elif character == '"':
            in_string = True
        elif line.startswith("//", index):
            return line[:index]
    return line


def used_categories(root, package):
    """The required-reason categories the engine's sources use, with the first file:line of each."""
    engine_dir = os.path.join(root, target_path(targets_by_name(package)[ENGINE]))
    used = {}
    for directory, _, files in os.walk(engine_dir):
        for name in sorted(files):
            if not name.endswith(".swift"):
                continue
            path = os.path.join(directory, name)
            with open(path, encoding="utf-8") as f:
                for number, line in enumerate(f, 1):
                    code = strip_comment(line)
                    for category, (pattern, _) in REQUIRED_REASON_APIS.items():
                        if category not in used and pattern.search(code):
                            used[category] = f"{os.path.relpath(path, root)}:{number}"
    return used


def manifests(root, package, target_names):
    """Every PrivacyInfo.xcprivacy resource of the given targets; missing files are reported with MISSING."""
    targets = targets_by_name(package)
    found = []
    for name in sorted(target_names):
        target = targets.get(name, {})
        for resource in target.get("resources", []) or []:
            if os.path.basename(resource["path"]) == "PrivacyInfo.xcprivacy":
                path = os.path.join(target_path(target), resource["path"])
                found.append(path if os.path.isfile(os.path.join(root, path)) else MISSING + path)
    return found


def declared(root, manifest_paths):
    """category -> {reason: [manifests declaring it]}, over the given manifests."""
    result = {}
    for path in manifest_paths:
        if path.startswith(MISSING):
            continue
        with open(os.path.join(root, path), "rb") as f:
            plist = plistlib.load(f)
        for entry in plist.get("NSPrivacyAccessedAPITypes", []):
            reasons = result.setdefault(entry.get("NSPrivacyAccessedAPIType"), {})
            for reason in entry.get("NSPrivacyAccessedAPITypeReasons", []):
                reasons.setdefault(reason, []).append(path)
    return result


def check(root, package, used=None):
    """Returns (problems, {product: {category: manifest}}, used)."""
    used = used_categories(root, package) if used is None else used
    reach = reaching(package, ENGINE)
    linking = sorted((product for product in package.get("products", [])
                      if "library" in product.get("type", {}) and set(product["targets"]) & reach),
                     key=lambda product: product["name"])
    problems, sources = [], {}
    if not linking:
        problems.append(f"no library product links {ENGINE}")
    for product in linking:
        name = product["name"]
        paths = manifests(root, package, linking_path_targets(package, product, ENGINE, reach))
        problems += [f"{name}: {path}" for path in paths if path.startswith(MISSING)]
        present = [path for path in paths if not path.startswith(MISSING)]
        if not present:
            problems.append(f"{name} links {ENGINE} but no target linking it there has a PrivacyInfo.xcprivacy")
            continue
        reasons = declared(root, present)
        sources[name] = {}
        for category, site in sorted(used.items()):
            accepted = REQUIRED_REASON_APIS[category][1]
            matching = sorted(reason for reason in reasons.get(category, {}) if reason in accepted)
            if category not in reasons:
                problems.append(f"{name} does not declare {category} (the engine uses it at {site})")
            elif not matching:
                problems.append(
                    f"{name} declares {category} with {sorted(reasons[category])}, "
                    f"none of {sorted(accepted)} (the engine uses it at {site})"
                )
            else:
                sources[name][category] = f"{matching[0]} in {reasons[category][matching[0]][0]}"
    return problems, sources, used


def self_test():
    import tempfile

    def manifest(categories):
        return plistlib.dumps({"NSPrivacyAccessedAPITypes": [
            {"NSPrivacyAccessedAPIType": category, "NSPrivacyAccessedAPITypeReasons": reasons}
            for category, reasons in categories.items()
        ]})

    with tempfile.TemporaryDirectory() as root:
        for directory in ("Engine", "Plugin/Resources", "Client/Resources", "Mid/Resources", "Core/Resources", "Other"):
            os.makedirs(os.path.join(root, directory))
        with open(os.path.join(root, "Engine/Store.swift"), "w") as f:
            f.write("let defaults = UserDefaults.standard\n// systemUptime in a comment is not a use\n")
        good = manifest({"NSPrivacyAccessedAPICategoryUserDefaults": ["CA92.1"]})
        for directory, content in (("Plugin", good), ("Core", good), ("Mid", manifest({})),
                                   ("Client", manifest({"NSPrivacyAccessedAPICategoryUserDefaults": ["1C8F.1"]}))):
            with open(os.path.join(root, directory, "Resources/PrivacyInfo.xcprivacy"), "wb") as f:
                f.write(content)
        resource = [{"path": "Resources/PrivacyInfo.xcprivacy", "rule": {"copy": {}}}]
        package = {
            "targets": [
                {"name": ENGINE, "path": "Engine", "dependencies": []},
                {"name": "Plugin", "path": "Plugin", "resources": resource, "dependencies": [{"target": [ENGINE, None]}]},
                {"name": "Client", "path": "Client", "resources": resource, "dependencies": [{"byName": [ENGINE, None]}]},
                # Reaches the engine only through Plugin, whose manifest counts for it.
                {"name": "Mid", "path": "Mid", "resources": resource,
                 "dependencies": [{"byName": ["Plugin", None]}, {"byName": ["Core", None]}]},
                # Off the path to the engine: its manifest must not count.
                {"name": "Core", "path": "Core", "resources": resource, "dependencies": []},
                {"name": "Bare", "path": "Other", "dependencies": [{"byName": [ENGINE, None]}, {"byName": ["Core", None]}]},
                {"name": "Unrelated", "path": "Other", "dependencies": []},
            ],
            "products": [
                {"name": name, "targets": [name], "type": {"library": ["automatic"]}}
                for name in ("Plugin", "Client", "Mid", "Bare", "Unrelated")
            ],
        }
        problems, sources, used = check(root, package)
        assert set(used) == {"NSPrivacyAccessedAPICategoryUserDefaults"}, used
        assert set(sources) == {"Plugin", "Client", "Mid"}, sources
        assert sources["Mid"]["NSPrivacyAccessedAPICategoryUserDefaults"].endswith("Plugin/Resources/PrivacyInfo.xcprivacy"), sources
        assert problems == [
            f"Bare links {ENGINE} but no target linking it there has a PrivacyInfo.xcprivacy",
            "Client declares NSPrivacyAccessedAPICategoryUserDefaults with ['1C8F.1'], none of ['CA92.1'] "
            "(the engine uses it at Engine/Store.swift:1)",
        ], problems
        package["products"] = package["products"][:1]
        problems, _, _ = check(root, package, used={**used, "NSPrivacyAccessedAPICategorySystemBootTime": "x:1"})
        assert len(problems) == 1 and "does not declare NSPrivacyAccessedAPICategorySystemBootTime" in problems[0], problems
        os.remove(os.path.join(root, "Plugin/Resources/PrivacyInfo.xcprivacy"))
        problems, _, _ = check(root, package)
        assert problems[0] == "Plugin: missing file: Plugin/Resources/PrivacyInfo.xcprivacy", problems
        package["products"] = [{"name": "Unrelated", "targets": ["Unrelated"], "type": {"library": ["automatic"]}}]
        problems, _, _ = check(root, package)
        assert problems == [f"no library product links {ENGINE}"], problems
    # The scanner itself: `//` in a string is not a comment, and the added patterns.
    assert strip_comment('let u = "https://x.test/a" // UserDefaults\n') == 'let u = "https://x.test/a" '
    assert strip_comment('let q = "a \\"//\\" b"; f() // c') == 'let q = "a \\"//\\" b"; f() '
    with tempfile.TemporaryDirectory() as root:
        os.makedirs(os.path.join(root, "Engine"))
        with open(os.path.join(root, "Engine/Scan.swift"), "w") as f:
            f.write("\n".join([
                'let url = URL(string: "https://example.com")!; let d = UserDefaults.standard',  # 1
                "let value = CFPreferencesCopyAppValue(key, app)",                               # 2
                "// fstatfs(fd, &buffer) in a comment is not a use",                             # 3
                "let keys: Set<URLResourceKey> = [.volumeTotalCapacityKey]",                     # 4
                "",
            ]))
        with open(os.path.join(root, "Engine/Stat.swift"), "w") as f:
            f.write("_ = fstatvfs(fd, &buffer)\n_ = fstatfs(fd, &other)\n")
        package = {"targets": [{"name": ENGINE, "path": "Engine", "dependencies": []}]}
        used = used_categories(root, package)
        assert used == {"NSPrivacyAccessedAPICategoryUserDefaults": "Engine/Scan.swift:1",
                        "NSPrivacyAccessedAPICategoryDiskSpace": "Engine/Scan.swift:4"}, used
        os.remove(os.path.join(root, "Engine/Scan.swift"))
        used = used_categories(root, package)
        assert used == {"NSPrivacyAccessedAPICategoryDiskSpace": "Engine/Stat.swift:1"}, used
        with open(os.path.join(root, "Engine/Stat.swift"), "w") as f:
            f.write("_ = fstatfs(fd, &other)\nlet v = CFPreferencesGetAppBooleanValue(k, a, nil)\n")
        used = used_categories(root, package)
        assert used == {"NSPrivacyAccessedAPICategoryDiskSpace": "Engine/Stat.swift:1",
                        "NSPrivacyAccessedAPICategoryUserDefaults": "Engine/Stat.swift:2"}, used
    print("check_engine_privacy_manifest.py self-test passed")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--package-json")
    parser.add_argument("--self-test", action="store_true")
    options = parser.parse_args()
    if options.self_test:
        self_test()
        return 0
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    if options.package_json:
        with open(options.package_json) as f:
            package = json.load(f)
    else:
        package = json.loads(subprocess.check_output(["swift", "package", "dump-package"], cwd=root))
    problems, sources, used = check(root, package)
    print(f"{ENGINE} uses: {', '.join(f'{c} ({s})' for c, s in sorted(used.items())) or 'no required-reason API'}")
    for product, categories in sorted(sources.items()):
        for category, source in sorted(categories.items()):
            print(f"{product}: {category} {source}")
    for problem in problems:
        print(problem)
    print(f"engine privacy manifests: {'FAILED' if problems else 'clean'}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
