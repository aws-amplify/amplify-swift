#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""Generate the explicit `package init` that mirrors a struct's synthesized memberwise init.

  scripts/m2/memberwise.py <File.swift> <TypeName> [--access package]
  scripts/m2/memberwise.py --self-test

Rules reproduced:
- one parameter per stored property, in declaration order, labels equal to the property names;
- `let` properties with an initial value are excluded;
- `var` properties with an initial value become defaulted parameters with the same default;
- no other defaults;
- closure-typed parameters are `@escaping` (`@Sendable` is kept where the property's type has it).

Skipped, with a message and exit status 3:
- types whose body already declares an `init(` (they keep it and only gain `package`);
- enums (raw-value enums need no init; other enums have no memberwise init).

It is a line-based generator for review, not a Swift parser: the compiler checks the result, because
every existing call site must compile unchanged. Multi-line property declarations are not supported and
are reported.
"""
import re
import sys

DECL = re.compile(r"^\s*(?:(?:public|package|internal|fileprivate|private)(?:\(set\))?\s+)*(struct|enum|class)\s+(\w+)\b")
PROPERTY = re.compile(
    r"^\s*(?P<attrs>(?:@\w+(?:\([^)]*\))?\s+)*)"
    r"(?:(?:public|package|internal|fileprivate|private)(?:\(set\))?\s+)*"
    r"(?P<kind>let|var)\s+(?P<name>\w+)\s*(?::\s*(?P<type>[^=]+?))?\s*(?:=\s*(?P<default>.+?))?\s*$"
)


class Skip(Exception):
    pass


def type_body(lines, name):
    """Returns (kind, body lines at depth 1) of the first declaration of `name`."""
    for index, line in enumerate(lines):
        match = DECL.match(line)
        if not match or match.group(2) != name:
            continue
        kind = match.group(1)
        depth, body, started = 0, [], False
        for inner in lines[index:]:
            code = inner.split("//", 1)[0]
            if started and depth == 1:
                body.append(code)
            depth += code.count("{") - code.count("}")
            if "{" in code:
                started = True
            if started and depth == 0:
                return kind, body
        raise SystemExit(f"unbalanced braces in the body of {name}")
    raise SystemExit(f"no declaration of {name}")


def generate(source, name, access="package"):
    kind, body = type_body(source.splitlines(), name)
    if kind == "enum":
        raise Skip(f"{name} is an enum: no memberwise init to mirror")
    if any(re.match(r"^\s*(?:\w+\s+)*init[?!]?\s*[(<]", line) for line in body):
        raise Skip(f"{name} already declares an init: keep it and only add `{access}`")
    parameters, assignments = [], []
    for line in body:
        stripped = line.strip()
        if not stripped or re.match(r"^(?:\w+\s+)*(?:static|class)\s", stripped):
            continue
        match = PROPERTY.match(line)
        if not match:
            continue
        if "{" in stripped:  # computed property or observers
            if re.search(r"\b(?:willSet|didSet)\b", stripped) or stripped.endswith("{"):
                raise Skip(f"{name}.{match.group('name')}: property with a body; write this init by hand")
            continue
        prop_type, default = match.group("type"), match.group("default")
        if prop_type is None:
            raise Skip(f"{name}.{match.group('name')}: no explicit type; write this init by hand")
        prop_type = prop_type.strip()
        if match.group("kind") == "let" and default is not None:
            continue
        param_type = prop_type
        if "->" in prop_type and not prop_type.endswith("?") and not prop_type.startswith("("):
            param_type = "@escaping " + prop_type
        elif "->" in prop_type and prop_type.startswith("(") and not prop_type.endswith(")?"):
            param_type = "@escaping " + prop_type
        parameter = f"{match.group('name')}: {param_type}"
        if default is not None:
            parameter += f" = {default.strip()}"
        parameters.append(parameter)
        assignments.append(f"self.{match.group('name')} = {match.group('name')}")
    if not parameters:
        return f"{access} init() {{}}"
    lines = [f"{access} init("]
    lines += [f"    {p}," for p in parameters[:-1]] + [f"    {parameters[-1]}"]
    lines += [") {"] + [f"    {a}" for a in assignments] + ["}"]
    return "\n".join(lines)


def self_test():
    source = """
struct Plain {
    let a: String
    var b: Int = 3
    let c: Bool = true
    static let shared = 1
    var computed: Int { 1 }
    let handler: @Sendable () throws -> Int
    let optionalClosure: (() -> Void)?
    let nested: [String: Int]
}
struct HasInit {
    let a: String
    init(a: String) { self.a = a }
}
enum Raw: String { case one }
"""
    expected = "\n".join([
        "package init(",
        "    a: String,",
        "    b: Int = 3,",
        "    handler: @escaping @Sendable () throws -> Int,",
        "    optionalClosure: (() -> Void)?,",
        "    nested: [String: Int]",
        ") {",
        "    self.a = a",
        "    self.b = b",
        "    self.handler = handler",
        "    self.optionalClosure = optionalClosure",
        "    self.nested = nested",
        "}",
    ])
    result = generate(source, "Plain")
    assert result == expected, result
    for skipped in ("HasInit", "Raw"):
        try:
            generate(source, skipped)
        except Skip:
            pass
        else:
            raise AssertionError(f"{skipped} must be skipped")
    print("memberwise.py self-test passed")


def main(argv):
    if argv[:1] == ["--self-test"]:
        self_test()
        return 0
    if len(argv) < 2:
        print(__doc__)
        return 64
    access = argv[argv.index("--access") + 1] if "--access" in argv else "package"
    with open(argv[0]) as f:
        source = f.read()
    try:
        print(generate(source, argv[1], access))
    except Skip as skip:
        print(f"skipped: {skip}", file=sys.stderr)
        return 3
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
