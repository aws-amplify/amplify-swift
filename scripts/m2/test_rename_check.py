#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""The G3 test-edit policy check: a test may change only by the renames the engine move made.

  scripts/m2/test_rename_check.py <base-ref> [--step S5a] [--head HEAD] [--tests <dir>]
  scripts/m2/test_rename_check.py --self-test

For every test file changed between <base-ref> and the head (the working tree by default):
1. apply the rename table (scripts/m2/rename_table.json; entries up to and including --step, or all) to
   the base version, bare names on word boundaries;
2. compare with the head version.

The steps (S0 to S9) are the stages in which the Cognito engine was moved out of the plugin, in order;
each rename table entry names the step that introduced it.

Lines that still differ are the residue: they are printed for the PR description. The check fails (exit
1) if any residue line touches an `XCTAssert*` call, or a line that is part of one (a continuation line
of a multi-line assertion). Added and deleted test files are listed, not checked.
"""
import argparse
import difflib
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TESTS = "AmplifyPlugins/Auth/Tests/AWSCognitoAuthPluginUnitTests"
STEPS = ["S0", "S1", "S2", "S3", "S4q", "S4", "S5a", "S5b", "S6", "S7", "S8a", "S8b", "S8c", "S9"]


def load_renames(step=None, path=os.path.join(ROOT, "scripts/m2/rename_table.json")):
    with open(path) as f:
        renames = json.load(f)["renames"]
    if step:
        limit = STEPS.index(step)
        renames = [r for r in renames if STEPS.index(r["step"]) <= limit]
    return [(r["from"]["name"], r["to"]["name"]) for r in renames]


def apply_renames(text, renames):
    for old, new in renames:
        text = re.sub(rf"\b{re.escape(old)}\b", new, text)
    return text


def assertion_lines(lines):
    """Indexes of lines inside an XCTAssert* call (the call line and its continuation lines)."""
    inside, depth = set(), 0
    for index, line in enumerate(lines):
        if depth == 0 and re.search(r"\bXCTAssert\w*\s*\(|\bXCTUnwrap\s*\(|\bXCTFail\s*\(", line):
            depth = 0
            start = re.search(r"\bXCT(?:Assert\w*|Unwrap|Fail)\s*\(", line).start()
            segment = line[start:]
            depth = segment.count("(") - segment.count(")")
            inside.add(index)
            continue
        if depth > 0:
            inside.add(index)
            depth += line.count("(") - line.count(")")
    return inside


def residue(base_text, head_text, renames):
    renamed = apply_renames(base_text, renames).splitlines()
    head = head_text.splitlines()
    base_asserts, head_asserts = assertion_lines(renamed), assertion_lines(head)
    changed, violations = [], []
    matcher = difflib.SequenceMatcher(a=renamed, b=head, autojunk=False)
    for tag, a0, a1, b0, b1 in matcher.get_opcodes():
        if tag == "equal":
            continue
        for index in range(a0, a1):
            entry = f"- {renamed[index]}"
            changed.append(entry)
            if index in base_asserts:
                violations.append(entry)
        for index in range(b0, b1):
            entry = f"+ {head[index]}"
            changed.append(entry)
            if index in head_asserts:
                violations.append(entry)
    return changed, violations


def git(*args):
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True, check=True).stdout


def self_test():
    renames = [("AWSCognitoUserPoolTokens", "EngineUserPoolTokens")]
    base = "let t = AWSCognitoUserPoolTokens.testData\nXCTAssertEqual(a,\n    b)\nlet x = 1\n"
    head = "let t = EngineUserPoolTokens.testData\nXCTAssertEqual(a,\n    b)\nlet x = 2\n"
    changed, violations = residue(base, head, renames)
    assert changed == ["- let x = 1", "+ let x = 2"] and violations == [], (changed, violations)
    head = "let t = EngineUserPoolTokens.testData\nXCTAssertEqual(a,\n    c)\nlet x = 1\n"
    changed, violations = residue(base, head, renames)
    assert violations == ["-     b)", "+     c)"], violations
    assert apply_renames("AWSCognitoUserPoolTokensX AWSCognitoUserPoolTokens", renames) == \
        "AWSCognitoUserPoolTokensX EngineUserPoolTokens"
    print("test_rename_check.py self-test passed")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("base", nargs="?")
    parser.add_argument("--head")
    parser.add_argument("--step", choices=STEPS)
    parser.add_argument("--tests", default=TESTS)
    parser.add_argument("--self-test", action="store_true")
    options = parser.parse_args()
    if options.self_test:
        self_test()
        return 0
    if not options.base:
        parser.error("base ref required")
    renames = load_renames(options.step)
    range_args = [options.base] + ([options.head] if options.head else [])
    status_lines = git("diff", "--name-status", "-M", *range_args, "--", options.tests).splitlines()
    total_violations = 0
    for status_line in status_lines:
        fields = status_line.split("\t")
        status, paths = fields[0], fields[1:]
        if status.startswith(("A", "D")):
            print(f"{status[0]} {paths[-1]} (not checked)")
            continue
        old_path, new_path = paths[0], paths[-1]
        base_text = git("show", f"{options.base}:{old_path}")
        if options.head:
            head_text = git("show", f"{options.head}:{new_path}")
        else:
            with open(os.path.join(ROOT, new_path)) as f:
                head_text = f.read()
        changed, violations = residue(base_text, head_text, renames)
        if changed:
            print(f"## {new_path}: {len(changed)} residue lines, {len(violations)} in assertions")
            print("\n".join(changed))
        total_violations += len(violations)
    print(f"test_rename_check: {len(status_lines)} files, {total_violations} assertion lines changed beyond renames")
    return 1 if total_violations else 0


if __name__ == "__main__":
    sys.exit(main())
