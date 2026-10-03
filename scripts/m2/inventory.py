#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""Type-reference inventory of the plugin, used to plan which files could move into the engine.

  scripts/m2/inventory.py closure [--file <plugin-relative path>] [--json]
  scripts/m2/inventory.py --self-test

`closure` prints, for each plugin file, the plugin-declared top-level types it references directly and the
transitive closure of files that declare them. A file can move into the engine only when every file in its
closure is already moved or moves with it. `--file` restricts the output to one file.

This is a static, token-level analysis: comments and string literals are
removed, and a reference is a whole-word use of a top-level type, protocol, enum, typealias or actor
declared in another plugin file. Extension-only members reached by dot syntax are not seen. The compiler is
the final judge; this narrows where to look.
"""
import argparse
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PLUGIN = "AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin"
TOP_LEVEL = re.compile(
    r"^(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:public|package|internal|fileprivate|private|open|final|indirect)\s+)*"
    r"(?:struct|class|enum|protocol|typealias|actor)\s+(\w+)",
    re.MULTILINE,
)
WORD = re.compile(r"\b[A-Z]\w*\b")


def strip(source):
    source = re.sub(r"/\*.*?\*/", "", source, flags=re.DOTALL)
    source = re.sub(r'"""[\s\S]*?"""', '""', source)
    source = re.sub(r'"(?:\\.|[^"\\\n])*"', '""', source)
    return re.sub(r"//[^\n]*", "", source)


def load(root=ROOT, base=PLUGIN):
    files = {}
    for directory, _, names in os.walk(os.path.join(root, base)):
        for name in names:
            if name.endswith(".swift"):
                path = os.path.join(directory, name)
                with open(path, encoding="utf-8") as f:
                    files[os.path.relpath(path, os.path.join(root, base))] = strip(f.read())
    return files


def analyse(files):
    declared_in = {}
    for path, source in files.items():
        for name in TOP_LEVEL.findall(source):
            declared_in.setdefault(name, set()).add(path)
    direct = {}
    for path, source in files.items():
        own = set(TOP_LEVEL.findall(source))
        referenced = {word for word in WORD.findall(source) if word in declared_in and word not in own}
        direct[path] = {name: sorted(declared_in[name] - {path}) for name in sorted(referenced) if declared_in[name] - {path}}
    closure = {}
    for path in files:
        seen, stack = set(), [path]
        while stack:
            current = stack.pop()
            for declaring in direct.get(current, {}).values():
                for other in declaring:
                    if other not in seen and other != path:
                        seen.add(other)
                        stack.append(other)
        closure[path] = sorted(seen)
    return direct, closure


def self_test():
    files = {
        "A.swift": "struct A { let b: B }",
        "B.swift": "enum B { case c(C) } // mentions D",
        "C.swift": 'struct C { let s = "A D" }',
        "D.swift": "protocol D {}",
    }
    files = {path: strip(source) for path, source in files.items()}
    direct, closure = analyse(files)
    assert direct["A.swift"] == {"B": ["B.swift"]}, direct
    assert closure["A.swift"] == ["B.swift", "C.swift"], closure
    assert closure["C.swift"] == [] and closure["D.swift"] == [], closure
    print("inventory.py self-test passed")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", nargs="?", choices=["closure"])
    parser.add_argument("--file")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    options = parser.parse_args()
    if options.self_test:
        self_test()
        return 0
    if options.command != "closure":
        parser.print_help()
        return 64
    direct, closure = analyse(load())
    paths = [options.file] if options.file else sorted(closure)
    if options.json:
        print(json.dumps({p: {"direct": direct[p], "closure": closure[p]} for p in paths}, indent=2, sort_keys=True))
        return 0
    for path in paths:
        print(f"## {path}: {len(closure[path])} files in closure")
        for name, declaring in direct[path].items():
            print(f"  uses {name} ({', '.join(declaring)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
