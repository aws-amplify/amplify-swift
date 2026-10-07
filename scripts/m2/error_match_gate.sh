#!/bin/bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Gate G8: silent error matches. A `catch` pattern, cast or type test
# against a type the engine no longer throws still compiles and never matches, so every such site is
# listed and counted at every step. The steps (S0 to S9) are the stages in which the Cognito engine was
# moved out of the plugin, in order; S9 and later changes enforce every rule.
#
#   scripts/m2/error_match_gate.sh report                 # every site, classified engine-destined / split / glue
#   scripts/m2/error_match_gate.sh diff <baseline.txt>    # compared with a committed report; exit 1 if sites were added
#   scripts/m2/error_match_gate.sh check <step>           # enforce the rules in force at S3, S4 or later
#   scripts/m2/error_match_gate.sh self-test
#
# The engine-destined set is scripts/m2/engine_paths.txt (scripts/m2/gen_engine_paths.py).
#
# Matched forms, for each of KeychainStoreError, AWSCognitoAuthError, AuthErrorConvertible and AuthError:
# `catch T.case`, `catch let x as T`, `catch is T`, `as? T`, `as! T`, `is T` (each also with `any T`),
# and `case T.x` patterns (`if case`, `guard case`, `switch`). `extension X: …, AuthErrorConvertible`
# conformances (single or multi-protocol) are listed too.
#
# Rules:
#   from S3: no `AuthErrorConvertible` token at all in engine-destined files or Engine/; no glue match on
#            AuthErrorConvertible (cast, catch, type test) outside Plugin/Support/EngineBridge/.
#   from S4: no `KeychainStoreError` token in Plugin/ (except EngineBridge/ and
#            KeychainStoreError+AuthConvertible.swift) nor anywhere in Engine/.
# Before S3, `diff` against the baseline is the gate: a new site fails it.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

exec python3 - "$@" << 'PYTHON'
import os
import re
import sys

PLUGIN = "AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin/"
ENGINE = "AmplifyClients/Internal/InternalAWSCognitoAuth/Sources/"
TYPES = ["KeychainStoreError", "AWSCognitoAuthError", "AuthErrorConvertible", "AuthError"]
STEP_ORDER = ["S0", "S1", "S2", "S3", "S4q", "S4", "S5a", "S5b", "S6", "S7", "S8a", "S8b", "S8c", "S9"]


def patterns_for(name):
    t = rf"(?:any\s+)?{name}\b"
    return [
        (f"catch {name}.case", re.compile(rf"\bcatch\s+{name}\.")),
        (f"catch let … as {name}", re.compile(rf"\bcatch\s+(?:let|var)\s+\w+\s+as\s+{t}")),
        (f"catch is {name}", re.compile(rf"\bcatch\s+is\s+{t}")),
        (f"as? {name}", re.compile(rf"\bas\?\s*{t}")),
        (f"as! {name}", re.compile(rf"\bas!\s*{t}")),
        (f"is {name}", re.compile(rf"(?<!catch )\bis\s+{t}")),
        (f"case {name}.x", re.compile(rf"\bcase\s+(?:let\s+)?{name}\.")),
    ]


PATTERNS = [p for name in TYPES for p in patterns_for(name)]
PATTERNS.append((
    "extension …: AuthErrorConvertible",
    re.compile(r"^\s*(?:(?:public|package|internal|fileprivate|private)\s+)?extension\s+[\w.<>]+\s*:\s*(?:[^{]*,\s*)?AuthErrorConvertible\b"),
))
LABELS = [label for label, _ in PATTERNS]


def engine_paths(path="scripts/m2/engine_paths.txt"):
    enforced, split = set(), set()
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            (split if line.startswith("?") else enforced).add(line.lstrip("?"))
    return enforced, split


def classify(path, enforced, split):
    if path in enforced or path.startswith(ENGINE):
        return "engine"
    if path in split:
        return "split"
    return "glue"


def code_only(line):
    line = re.sub(r'"(?:\\.|[^"\\])*"', '""', line)
    return line.split("//", 1)[0]


def swift_files(*bases):
    for base in bases:
        for directory, _, files in os.walk(base):
            for name in sorted(files):
                if name.endswith(".swift"):
                    yield os.path.join(directory, name)


def lines_of(path):
    with open(path, encoding="utf-8") as f:
        for number, line in enumerate(f, 1):
            yield number, line.rstrip("\n"), code_only(line)


def sites(enforced, split):
    found = []
    for path in swift_files(PLUGIN, ENGINE):
        for number, line, code in lines_of(path):
            for label, pattern in PATTERNS:
                if pattern.search(code):
                    found.append((label, classify(path, enforced, split), path, number, line.strip()))
    return sorted(found, key=lambda s: (LABELS.index(s[0]), s[1], s[2], s[3]))


def report_lines(found):
    lines = []
    for label in LABELS:
        group = [s for s in found if s[0] == label]
        counts = {c: sum(1 for s in group if s[1] == c) for c in ("engine", "split", "glue")}
        lines.append(f"## {label}: {len(group)} (engine {counts['engine']}, split {counts['split']}, glue {counts['glue']})")
        for _, cls, path, number, text in group:
            lines.append(f"{cls}\t{path}:{number}\t{text}")
    return lines


def keychain_allowed(path):
    return path.startswith(PLUGIN) and (
        "/Support/EngineBridge/" in path or path.endswith("KeychainStoreError+AuthConvertible.swift")
    )


def check(step, found, enforced, split):
    if step not in STEP_ORDER:
        sys.exit(f"unknown step {step}; expected one of {', '.join(STEP_ORDER)}")
    at = STEP_ORDER.index
    violations = []
    if at(step) >= at("S3"):
        token = re.compile(r"\bAuthErrorConvertible\b")
        for path in swift_files(PLUGIN, ENGINE):
            if classify(path, enforced, split) != "engine":
                continue
            for number, line, code in lines_of(path):
                if token.search(code):
                    violations.append(f"{path}:{number}: AuthErrorConvertible in an engine-destined file: {line.strip()}")
        for label, cls, path, number, text in found:
            if label.endswith(" AuthErrorConvertible") and not label.startswith("extension") and cls != "engine" \
                    and "/Support/EngineBridge/" not in path:
                violations.append(f"{path}:{number}: glue match on AuthErrorConvertible outside AuthError(converting:): {text}")
    if at(step) >= at("S4"):
        token = re.compile(r"\bKeychainStoreError\b")
        for path in swift_files(PLUGIN, ENGINE):
            if keychain_allowed(path):
                continue
            for number, line, code in lines_of(path):
                if token.search(code):
                    violations.append(f"{path}:{number}: KeychainStoreError outside EngineBridge/: {line.strip()}")
    return violations


def site_key(line):
    # Line numbers move with every edit; compare sites without them.
    return re.sub(r":\d+\t", "\t", line)


def keyed_sites(lines):
    """Each site line prefixed with its section's pattern, so two patterns on one line count twice."""
    keyed, label = [], ""
    for line in lines:
        if line.startswith("## "):
            label = line[3:].split(":")[0] if ": " not in line[3:] else line[3:].rsplit(": ", 1)[0]
            continue
        keyed.append(f"[{label}] {site_key(line)}")
    return keyed


def diff(baseline_lines, now_lines):
    base = keyed_sites(baseline_lines)
    now = keyed_sites(now_lines)
    removed = sorted(set(base) - set(now))
    added = sorted(set(now) - set(base))
    return removed, added


def self_test():
    import tempfile
    global PLUGIN, ENGINE
    with tempfile.TemporaryDirectory() as tmp:
        plugin = os.path.join(tmp, "Plugin") + "/"
        engine = os.path.join(tmp, "Engine") + "/"
        for directory in (plugin + "Actions", plugin + "Task", plugin + "Support/EngineBridge", engine):
            os.makedirs(directory)
        files = {
            plugin + "Actions/A.swift": "do {} catch KeychainStoreError.itemNotFound {}\n"
                                        "let x = e as? any AuthErrorConvertible\n"
                                        "// as? AuthErrorConvertible\n"
                                        "if case KeychainStoreError.itemNotFound = e {}\n"
                                        "let s = \"as? KeychainStoreError\"\n",
            plugin + "Task/T.swift": "} catch let error as AuthErrorConvertible {\n"
                                     "if let c = u as? AWSCognitoAuthError {}\n"
                                     "} catch let error as AuthError {\n"
                                     "} catch AuthError.signedOut {\n"
                                     "if e is AuthErrorConvertible {}\n",
            plugin + "Support/EngineBridge/B.swift": "let k = e as? KeychainStoreError\nlet c = e as? AuthErrorConvertible\n",
            engine + "E.swift": "} catch let error as KeychainStoreError {\n"
                                "} catch is KeychainStoreError {\n"
                                "extension Foo: Sendable, AuthErrorConvertible {}\n"
                                "let y = e as! AuthErrorConvertible\n",
        }
        for path, text in files.items():
            with open(path, "w") as f:
                f.write(text)
        paths = os.path.join(tmp, "paths.txt")
        with open(paths, "w") as f:
            f.write(f"# comment\n{plugin}Actions/A.swift\n")
        PLUGIN, ENGINE = plugin, engine
        enforced, split = engine_paths(paths)
        found = sites(enforced, split)
        summary = sorted((s[0], s[1], os.path.basename(s[2])) for s in found)
        expected = sorted([
            ("catch KeychainStoreError.case", "engine", "A.swift"),
            ("as? AuthErrorConvertible", "engine", "A.swift"),
            ("case KeychainStoreError.x", "engine", "A.swift"),
            ("catch let … as AuthErrorConvertible", "glue", "T.swift"),
            ("as? AWSCognitoAuthError", "glue", "T.swift"),
            ("catch let … as AuthError", "glue", "T.swift"),
            ("catch AuthError.case", "glue", "T.swift"),
            ("is AuthErrorConvertible", "glue", "T.swift"),
            ("as? KeychainStoreError", "glue", "B.swift"),
            ("as? AuthErrorConvertible", "glue", "B.swift"),
            ("catch let … as KeychainStoreError", "engine", "E.swift"),
            ("catch is KeychainStoreError", "engine", "E.swift"),
            ("extension …: AuthErrorConvertible", "engine", "E.swift"),
            ("as! AuthErrorConvertible", "engine", "E.swift"),
        ])
        assert summary == expected, "\n".join(map(str, summary))
        assert check("S2", found, enforced, split) == []
        s3 = check("S3", found, enforced, split)
        # engine tokens: A.swift:2, E.swift:3, E.swift:4; glue matches outside EngineBridge: T.swift:1, T.swift:5
        assert len(s3) == 5, "\n".join(s3)
        s4 = check("S4", found, enforced, split)
        # + KeychainStoreError tokens: A.swift:1, A.swift:4, E.swift:1, E.swift:2 (B.swift is allowed)
        assert len(s4) == 9, "\n".join(s4)
        report = report_lines(found)
        removed, added = diff(report, report + ["glue\tX.swift:1\tcatch KeychainStoreError.itemNotFound"])
        assert removed == [] and len(added) == 1
        # Two patterns on one line are two sites.
        one_line = [s for s in found if os.path.basename(s[2]) == "E.swift" and s[3] == 1]
        assert len(keyed_sites(report_lines(found))) == len(found)
        del one_line
    print("error_match_gate.sh self-test passed")


def main(argv):
    command = argv[0] if argv else ""
    if command == "self-test":
        self_test()
        return 0
    enforced, split = engine_paths()
    found = sites(enforced, split)
    if command == "report":
        print("\n".join(report_lines(found)))
        return 0
    if command == "diff" and len(argv) == 2:
        with open(argv[1]) as f:
            baseline = [line.rstrip("\n") for line in f]
        removed, added = diff(baseline, report_lines(found))
        for line in removed:
            print(f"- {line}")
        for line in added:
            print(f"+ {line}")
        print(f"error-match sites: {len(removed)} removed, {len(added)} added since the baseline")
        return 1 if added else 0
    if command == "check" and len(argv) == 2:
        violations = check(argv[1], found, enforced, split)
        for violation in violations:
            print(violation)
        print(f"G8 at {argv[1]}: {'FAILED, ' + str(len(violations)) + ' violations' if violations else 'clean'}")
        return 1 if violations else 0
    print("usage: error_match_gate.sh report | diff <baseline> | check <step> | self-test")
    return 64


sys.exit(main(sys.argv[1:]))
PYTHON
