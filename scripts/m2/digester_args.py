#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""Print the module-search arguments SwiftPM passed when compiling a module.

`swift api-digester` and `swiftc -typecheck` against a SwiftPM build need every `-I`, `-F` and `-Xcc`
argument of the module's compile command: with `-I .build/debug/Modules` alone the digester cannot load
the C modules (AwsCAuth, AwsCCal, ...), writes an empty dump and still exits 0. This reads them from the
llbuild manifest SwiftPM writes, `.build/<config>.yaml`.

Usage:
  scripts/m2/digester_args.py [--module AWSCognitoAuthPlugin] [--build-dir .build] [--configuration debug]
                              [--with-target] [--with-sdk] [--format lines|json]
  scripts/m2/digester_args.py --self-test

Prints one argument per line (the default), or a JSON array.
"""
import argparse
import json
import os
import re
import sys

KEEP_WITH_VALUE = {"-I", "-F", "-Xcc"}
OPTIONAL_WITH_VALUE = {"-target": "with_target", "-sdk": "with_sdk"}


def find_args(manifest_text, module):
    """Returns the `args` list of the `C.<module>-<triple>-<config>.module` command."""
    header = re.compile(r'^  "C\.' + re.escape(module) + r'-[^"]*\.module":\s*$')
    lines = manifest_text.split("\n")
    for index, line in enumerate(lines):
        if header.match(line):
            for candidate in lines[index + 1:index + 12]:
                stripped = candidate.strip()
                if stripped.startswith("args: "):
                    return json.loads(stripped[len("args: "):])
                if candidate.startswith("  \"") and not candidate.startswith("    "):
                    break
    raise SystemExit(f"no compile command for module {module!r} in the manifest; run `swift build` first")


def search_args(args, with_target=False, with_sdk=False):
    """Keeps -I/-F/-Xcc pairs (in order), and optionally -target and -sdk."""
    kept = []
    index = 0
    while index < len(args):
        arg = args[index]
        if arg in KEEP_WITH_VALUE and index + 1 < len(args):
            kept += [arg, args[index + 1]]
            index += 2
            continue
        if arg in OPTIONAL_WITH_VALUE and index + 1 < len(args):
            if (arg == "-target" and with_target) or (arg == "-sdk" and with_sdk):
                kept += [arg, args[index + 1]]
            index += 2
            continue
        index += 1
    return kept


def self_test():
    manifest = "\n".join([
        "commands:",
        '  "C.Other-arm64-apple-macosx-debug.module":',
        "    tool: shell",
        '    args: ["swiftc","-I","/other"]',
        "",
        '  "C.AWSCognitoAuthPlugin-arm64-apple-macosx-debug.module":',
        "    tool: shell",
        '    description: "Compiling"',
        '    args: ["swiftc","-module-name","AWSCognitoAuthPlugin","-I","/mods","-target","arm64-apple-macosx12.0",'
        '"-Xcc","-fmodule-map-file=/a/module.modulemap","-Xcc","-I","-Xcc","/a/include","-sdk","/sdk",'
        '"-F","/frameworks","-swift-version","6","-emit-module"]',
    ])
    args = find_args(manifest, "AWSCognitoAuthPlugin")
    assert search_args(args) == [
        "-I", "/mods", "-Xcc", "-fmodule-map-file=/a/module.modulemap", "-Xcc", "-I", "-Xcc", "/a/include",
        "-F", "/frameworks",
    ], search_args(args)
    assert search_args(args, with_target=True, with_sdk=True)[2:4] == ["-target", "arm64-apple-macosx12.0"]
    assert "-sdk" in search_args(args, with_sdk=True)
    try:
        find_args(manifest, "Missing")
    except SystemExit:
        pass
    else:
        raise AssertionError("a missing module must fail")
    print("digester_args.py self-test passed")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--module", default="AWSCognitoAuthPlugin")
    parser.add_argument("--build-dir", default=".build")
    parser.add_argument("--configuration", default="debug")
    parser.add_argument("--with-target", action="store_true")
    parser.add_argument("--with-sdk", action="store_true")
    parser.add_argument("--format", choices=["lines", "json"], default="lines")
    parser.add_argument("--self-test", action="store_true")
    options = parser.parse_args()
    if options.self_test:
        self_test()
        return
    manifest_path = os.path.join(options.build_dir, f"{options.configuration}.yaml")
    with open(manifest_path) as manifest:
        args = find_args(manifest.read(), options.module)
    kept = search_args(args, options.with_target, options.with_sdk)
    if not any(arg.startswith("-fmodule-map-file=") for arg in kept):
        print("warning: no -fmodule-map-file arguments found; the digester will likely write an empty dump",
              file=sys.stderr)
    if options.format == "json":
        print(json.dumps(kept))
    else:
        print("\n".join(kept))


if __name__ == "__main__":
    main()
