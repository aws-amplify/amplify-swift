#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""Gate G6: the engine's dependency direction.

  scripts/cognito-engine/check_engine_deps.py                      # every step: the engine never reaches AmplifyCognitoClient
  scripts/cognito-engine/check_engine_deps.py --stage final        # nor Amplify, AWSPluginsCore, InternalAmplifyCredentials;
                                                       # and AmplifyCognitoClient reaches none of them
                                                       # nor imports one
  scripts/cognito-engine/check_engine_deps.py --package-json p.json   # use a saved `swift package dump-package`
  scripts/cognito-engine/check_engine_deps.py --self-test

Walks the transitive in-package target dependencies of InternalAWSCognitoAuth in `swift package
dump-package`. With `--stage final` it also greps Engine/ for `import` of a forbidden module (including
`@_spi(...) import`, `@testable import` and Swift 6 access-level imports such as `internal import`),
which is the grep half of G6, and fails if any target in the engine's closure has its `path` under
`AmplifyPlugins/` (the client must never build a target that lives in a plugin directory).
It also greps the client's Sources/ for `import` of a module the client must not use: SwiftPM lets a target
import a module built in the same graph without declaring it, so the dependency graph alone can miss one.
"""
import argparse
import json
import os
import re
import subprocess
import sys

ENGINE = "InternalAWSCognitoAuth"
ENGINE_DIR = "AmplifyClients/Internal/InternalAWSCognitoAuth/Sources"
ALWAYS_FORBIDDEN = {"AmplifyCognitoClient"}
FINAL_FORBIDDEN = ALWAYS_FORBIDDEN | {"Amplify", "AWSPluginsCore", "InternalAmplifyCredentials"}
PLUGIN_ROOT = "AmplifyPlugins/"
# The client depends on the engine. It must still reach no Amplify core, no AWSPluginsCore and no plugin (the
# client is built on AmplifyFoundation and AmplifyFoundationBridge, never on Amplify core), and no target
# under AmplifyPlugins/, directly or through the engine.
CLIENT = "AmplifyCognitoClient"
CLIENT_DIR = "AmplifyClients/AmplifyCognitoClient/Sources"
# The names the client may never reach or import. `client_forbidden` adds every target whose path is under
# AmplifyPlugins/ (InternalAWSPinpoint, InternalCloudWatchLogging, ...), so a new plugin-side module is covered
# without editing this list.
CLIENT_FORBIDDEN = {"Amplify", "AWSPluginsCore", "InternalAmplifyCredentials", "AWSCognitoAuthPlugin"}


def dependency_names(target):
    names = []
    for dependency in target.get("dependencies", []):
        for kind in ("byName", "target", "product"):
            if kind in dependency and dependency[kind]:
                names.append((kind, dependency[kind][0]))
    return names


def closure(package, root):
    """Every in-package target reachable from `root`, with the path that reaches it, and every product."""
    targets = {target["name"]: target for target in package["targets"]}
    reached, products, stack = {root: [root]}, {}, [root]
    while stack:
        name = stack.pop()
        for kind, dependency in dependency_names(targets.get(name, {})):
            if kind == "product" or dependency not in targets:
                products.setdefault(dependency, reached[name] + [dependency])
                continue
            if dependency not in reached:
                reached[dependency] = reached[name] + [dependency]
                stack.append(dependency)
    return reached, products


IMPORT_PATTERN = re.compile(
    r"^\s*(?:@\w+(?:\([^)]*\))?\s+)*"                                # @_spi(X), @testable, @preconcurrency, ...
    r"(?:(?:public|package|internal|fileprivate|private)\s+)?"        # a Swift 6 access-level import
    r"(?:@\w+(?:\([^)]*\))?\s+)*"
    r"import\s+(?:(?:struct|class|enum|protocol|func|var|let|typealias)\s+)?(\w+)")


def target_path(target):
    """The target's directory as SwiftPM resolves it: its `path`, else the Sources/ or Tests/ default."""
    if target.get("path"):
        return os.path.normpath(target["path"])
    return os.path.join("Tests" if target.get("type") == "test" else "Sources", target["name"])


def plugin_path_targets(package, reached):
    """Every target in the closure whose directory is under AmplifyPlugins/, with the path that reaches it."""
    targets = {target["name"]: target for target in package["targets"]}
    return [(name, target_path(targets[name]), reached[name]) for name in sorted(reached)
            if name in targets and (target_path(targets[name]) + "/").startswith(PLUGIN_ROOT)]


def forbidden_imports(root, forbidden, sources=ENGINE_DIR):
    pattern = IMPORT_PATTERN
    hits = []
    for directory, _, files in os.walk(os.path.join(root, sources)):
        for name in sorted(files):
            if not name.endswith(".swift"):
                continue
            path = os.path.join(directory, name)
            with open(path, encoding="utf-8") as f:
                for number, line in enumerate(f, 1):
                    match = pattern.match(line)
                    if match and match.group(1) in forbidden:
                        hits.append(f"{os.path.relpath(path, root)}:{number}: {line.strip()}")
    return hits


def check(package, stage, root=None):
    forbidden = FINAL_FORBIDDEN if stage == "final" else ALWAYS_FORBIDDEN
    reached, products = closure(package, ENGINE)
    problems = [f"{ENGINE} depends on {name}: {' -> '.join(path)}"
                for name, path in sorted({**reached, **products}.items()) if name in forbidden]
    if stage == "final":
        problems += [f"{name} is under {PLUGIN_ROOT} ({directory}): {' -> '.join(path)}"
                     for name, directory, path in plugin_path_targets(package, reached)]
    if stage == "final" and root:
        # The grep half must look where the engine really is: a stale ENGINE_DIR would walk nothing and pass.
        declared = {target["name"]: target for target in package["targets"]}.get(ENGINE, {}).get("path")
        if declared and declared.rstrip("/") != ENGINE_DIR:
            problems.append(f"{ENGINE}'s path is {declared}, but ENGINE_DIR is {ENGINE_DIR}")
        if not os.path.isdir(os.path.join(root, ENGINE_DIR)):
            problems.append(f"engine sources not found at {ENGINE_DIR}")
        problems += [f"forbidden import: {hit}" for hit in forbidden_imports(root, forbidden)]
    if stage == "final":
        problems += client_problems(package, root)
    return problems, reached, products


def client_forbidden(package):
    """CLIENT_FORBIDDEN plus every target in the package whose directory is under AmplifyPlugins/."""
    return CLIENT_FORBIDDEN | {target["name"] for target in package["targets"]
                               if (target_path(target) + "/").startswith(PLUGIN_ROOT)}


def client_problems(package, root=None):
    """The client's closure, when the package has the client: no Amplify core, AWSPluginsCore or plugin, and no
    target under AmplifyPlugins/. With `root`, its sources import none of those modules either."""
    targets = {target["name"]: target for target in package["targets"]}
    if CLIENT not in targets:
        return []
    reached, products = closure(package, CLIENT)
    # A dependency on a plugin-path target is reported once, by the path check below.
    problems = [f"{CLIENT} depends on {name}: {' -> '.join(path)}"
                for name, path in sorted({**reached, **products}.items()) if name in CLIENT_FORBIDDEN]
    problems += [f"{name} is under {PLUGIN_ROOT} ({directory}): {' -> '.join(path)}"
                 for name, directory, path in plugin_path_targets(package, reached)]
    if root:
        # As for the engine: a stale CLIENT_DIR would walk nothing and pass.
        declared = targets[CLIENT].get("path")
        if declared and declared.rstrip("/") != CLIENT_DIR:
            problems.append(f"{CLIENT}'s path is {declared}, but CLIENT_DIR is {CLIENT_DIR}")
        if not os.path.isdir(os.path.join(root, CLIENT_DIR)):
            problems.append(f"client sources not found at {CLIENT_DIR}")
        problems += [f"forbidden client import: {hit}"
                     for hit in forbidden_imports(root, client_forbidden(package), CLIENT_DIR)]
    return problems


def self_test():
    package = {"targets": [
        {"name": ENGINE, "dependencies": [{"byName": ["Amplify", None]}, {"target": ["Leaf", None]},
                                           {"product": ["AWSClientRuntime", "aws-sdk-swift", None, None]}]},
        {"name": "Amplify", "dependencies": [{"byName": ["AmplifyAvailability", None]}]},
        {"name": "AmplifyAvailability", "dependencies": []},
        {"name": "Leaf", "dependencies": []},
        {"name": "AmplifyCognitoClient", "dependencies": [{"target": [ENGINE, None]}]},
    ]}
    problems, reached, products = check(package, "pre-sever")
    assert problems == [], problems
    assert set(reached) == {ENGINE, "Amplify", "AmplifyAvailability", "Leaf"}, reached
    assert "AWSClientRuntime" in products
    problems, _, _ = check(package, "final")
    # The engine reaches Amplify, and so does the client, through the engine.
    assert len(problems) == 2 and "Amplify" in problems[0], problems
    assert problems[1] == f"{CLIENT} depends on Amplify: {CLIENT} -> {ENGINE} -> Amplify", problems
    package["targets"][3]["dependencies"] = [{"byName": ["AmplifyCognitoClient", None]}]
    problems, _, _ = check(package, "pre-sever")
    assert len(problems) == 1 and "Leaf -> AmplifyCognitoClient" in problems[0], problems
    # No target in the closure may live under AmplifyPlugins/.
    located = {"targets": [
        {"name": ENGINE, "path": ENGINE_DIR, "dependencies": [{"target": ["SRP", None]}, {"byName": ["Near", None]}]},
        {"name": "SRP", "path": "AmplifyClients/Internal/SRP/Sources", "dependencies": [{"target": ["BigInt", None]}]},
        {"name": "BigInt", "path": "AmplifyPlugins/Auth/Sources/BigInt/", "dependencies": []},
        {"name": "Near", "path": "AmplifyPluginsLookalike/Near", "dependencies": []},
        {"name": "Plugin", "path": "AmplifyPlugins/Auth/Sources/Plugin", "dependencies": [{"target": [ENGINE, None]}]},
    ]}
    problems, _, _ = check(located, "pre-sever")
    assert problems == [], problems
    problems, _, _ = check(located, "final")
    assert problems == [f"BigInt is under AmplifyPlugins/ (AmplifyPlugins/Auth/Sources/BigInt): {ENGINE} -> SRP -> BigInt"], problems
    located["targets"][0]["path"] = "AmplifyPlugins/Internal/Sources/InternalAWSCognitoAuth"
    problems, _, _ = check(located, "final")
    assert len(problems) == 2 and problems[1].startswith(f"{ENGINE} is under AmplifyPlugins/"), problems
    # The client's own closure may not reach a target under AmplifyPlugins/ either.
    client_located = {"targets": [
        {"name": ENGINE, "path": ENGINE_DIR, "dependencies": []},
        {"name": CLIENT, "path": "AmplifyClients/AmplifyCognitoClient/Sources",
         "dependencies": [{"target": [ENGINE, None]}, {"target": ["Helper", None]}]},
        {"name": "Helper", "path": "AmplifyPlugins/Auth/Sources/Helper", "dependencies": []},
    ]}
    problems, _, _ = check(client_located, "final")
    assert problems == [f"Helper is under AmplifyPlugins/ (AmplifyPlugins/Auth/Sources/Helper): {CLIENT} -> Helper"], problems
    import tempfile
    clean = {"targets": [{"name": ENGINE, "path": ENGINE_DIR, "dependencies": []}]}
    with tempfile.TemporaryDirectory() as root:
        problems, _, _ = check(clean, "final", root)
        assert problems == [f"engine sources not found at {ENGINE_DIR}"], problems
        os.makedirs(os.path.join(root, ENGINE_DIR))
        with open(os.path.join(root, ENGINE_DIR, "A.swift"), "w") as f:
            f.write("import Foundation\n@_spi(X) import Amplify\n")
        problems, _, _ = check(clean, "final", root)
        assert len(problems) == 1 and problems[0].startswith("forbidden import:") and "A.swift:2" in problems[0], problems
        # Swift 6 access-level imports, alone and after an attribute, are imports too.
        access_level = [
            "internal import Amplify",                              # 1
            "package import AWSPluginsCore",                        # 2
            "public import Amplify",                                # 3
            "@preconcurrency internal import Amplify",              # 4
            "fileprivate import InternalAmplifyCredentials",        # 5
            "private import struct Amplify.AuthSession",            # 6
            "@_spi(X) @preconcurrency public import AWSPluginsCore",  # 7
            "internal import Foundation",                           # not forbidden
            "// internal import Amplify",                           # a comment
            "let internalImport = \"import Amplify\"",              # not an import
        ]
        with open(os.path.join(root, ENGINE_DIR, "B.swift"), "w") as f:
            f.write("\n".join(access_level) + "\n")
        hits = forbidden_imports(root, FINAL_FORBIDDEN)
        assert [hit.split(":")[1] for hit in hits if "B.swift" in hit] == [str(n) for n in range(1, 8)], hits
        os.remove(os.path.join(root, ENGINE_DIR, "B.swift"))
        clean["targets"][0]["path"] = "Elsewhere/Sources"
        problems, _, _ = check(clean, "final", root)
        assert any("but ENGINE_DIR is" in problem for problem in problems), problems
    # The client's sources are grepped too, against the client's list.
    with tempfile.TemporaryDirectory() as root:
        with_client = {"targets": [
            {"name": ENGINE, "path": ENGINE_DIR, "dependencies": []},
            {"name": CLIENT, "path": CLIENT_DIR, "dependencies": [{"target": [ENGINE, None]}]},
        ]}
        os.makedirs(os.path.join(root, ENGINE_DIR))
        problems, _, _ = check(with_client, "final", root)
        assert problems == [f"client sources not found at {CLIENT_DIR}"], problems
        os.makedirs(os.path.join(root, CLIENT_DIR, "Engine"))
        with open(os.path.join(root, CLIENT_DIR, "Engine", "C.swift"), "w") as f:
            f.write("\n".join([
                "import Foundation",                           # 1: allowed
                "import InternalAWSCognitoAuth",               # 2: allowed for the client
                "@_spi(X) import AWSPluginsCore",              # 3
                "internal import Amplify",                     # 4
                "@testable import AWSCognitoAuthPlugin",       # 5
                "import InternalAmplifyCredentials",           # 6
                "// import Amplify",                           # a comment
            ]) + "\n")
        problems, _, _ = check(with_client, "final", root)
        assert [problem.split(":")[2] for problem in problems] == ["3", "4", "5", "6"], problems
        assert all(problem.startswith("forbidden client import: ") for problem in problems), problems
        os.remove(os.path.join(root, CLIENT_DIR, "Engine", "C.swift"))
        problems, _, _ = check(with_client, "final", root)
        assert problems == [], problems
        # A plugin-side module the fixed list does not name is forbidden too, by its path.
        with_client["targets"].append({"name": "InternalAWSPinpoint", "path": "AmplifyPlugins/Internal/Sources/InternalAWSPinpoint",
                                       "dependencies": []})
        with open(os.path.join(root, CLIENT_DIR, "Engine", "D.swift"), "w") as f:
            f.write("import InternalAWSPinpoint\n")
        problems, _, _ = check(with_client, "final", root)
        assert len(problems) == 1 and problems[0].startswith("forbidden client import: ") and "D.swift:1" in problems[0], problems
        os.remove(os.path.join(root, CLIENT_DIR, "Engine", "D.swift"))
        with_client["targets"][1]["dependencies"].append({"target": ["InternalAWSPinpoint", None]})
        problems, _, _ = check(with_client, "final", root)
        assert problems == [
            f"InternalAWSPinpoint is under AmplifyPlugins/ (AmplifyPlugins/Internal/Sources/InternalAWSPinpoint): "
            f"{CLIENT} -> InternalAWSPinpoint",
        ], problems
        with_client["targets"][1]["dependencies"].pop()
        with_client["targets"].pop()
        with_client["targets"][1]["path"] = "Elsewhere/Client"
        problems, _, _ = check(with_client, "final", root)
        assert problems == [f"{CLIENT}'s path is Elsewhere/Client, but CLIENT_DIR is {CLIENT_DIR}"], problems
    print("check_engine_deps.py self-test passed")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--stage", choices=["pre-sever", "final"], default="pre-sever")
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
    problems, reached, products = check(package, options.stage, root)
    print(f"{ENGINE} reaches {len(reached) - 1} package targets: {', '.join(sorted(set(reached) - {ENGINE}))}")
    print(f"and {len(products)} products: {', '.join(sorted(products))}")
    if options.stage == "final" and CLIENT in {target["name"] for target in package["targets"]}:
        client_reached, _ = closure(package, CLIENT)
        print(f"{CLIENT} reaches {len(client_reached) - 1} package targets: "
              f"{', '.join(sorted(set(client_reached) - {CLIENT}))}")
    for problem in problems:
        print(problem)
    print(f"G6 ({options.stage}): {'FAILED' if problems else 'clean'}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
