#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""Give every declaration of a moved file the `package` access level (a move is "git mv plus package").

  scripts/m2/package_access.py <File.swift>...          # rewrite in place, print a count per file
  scripts/m2/package_access.py --check <File.swift>...  # exit 1 and list the declarations still implicit
  (a path argument written `@list.txt` reads one path per line from that file)
  scripts/m2/package_access.py --self-test

A declaration gets `package` when it has no access modifier of its own and it sits at file scope or directly
in a type or extension body. That covers types, typealiases, functions, initializers, subscripts and
properties, including `private(set)` ones (their getter becomes `package`). Left alone:
- anything with an explicit `public`, `package`, `internal`, `fileprivate`, `private` or `open`;
- enum cases, `deinit`, extension headers, and protocol requirements;
- the members of a `private` or `fileprivate` type or extension (the header's own level bounds them);
- everything inside a function, accessor, closure or statement body (locals).

The modifier is inserted after the leading attributes on the declaration's own line, so
`@MainActor static func f()` becomes `@MainActor package static func f()`. Only that line changes, which
keeps `git diff -M` reporting the move as a rename. Memberwise initializers are not written here: that is
`memberwise.py`, and the compiler reports the ones the plugin needs. This is a line-based rewriter for
reviewed code, not a Swift parser: strings, comments and braces are tracked well enough for the auth
state-machine sources, and the compiler is the final check.
"""
import re
import sys

ACCESS = {"public", "package", "internal", "fileprivate", "private", "open"}
MODIFIERS = {
    "static", "class", "final", "mutating", "nonmutating", "lazy", "override", "convenience", "required",
    "nonisolated", "indirect", "weak", "unowned", "dynamic", "optional",
}
DECLARATIONS = {"struct", "enum", "class", "actor", "protocol", "typealias", "func", "init", "var", "let", "subscript"}
TYPE_KEYWORDS = {"struct", "enum", "class", "actor", "extension", "protocol"}
ATTRIBUTE = re.compile(r"@\w+(?:\([^()]*(?:\([^()]*\)[^()]*)*\))?\s*")
# A word, with an optional parenthesised suffix: `private(set)`, `nonisolated(unsafe)`, `unowned(safe)`.
WORD = re.compile(r"[A-Za-z_]\w*(?:\(\w+\))?")


def code_of(line, state):
    """The line with string contents and comments blanked out, so that braces in them are not counted.
    `state` carries an open block comment or multi-line string across lines."""
    out, i = [], 0
    while i < len(line):
        if state["block"]:
            end = line.find("*/", i)
            if end < 0:
                return "".join(out)
            state["block"], i = False, end + 2
            continue
        if state["multiline"]:
            end = line.find('"""', i)
            if end < 0:
                return "".join(out)
            state["multiline"], i = False, end + 3
            out.append('""')
            continue
        if line.startswith("//", i):
            break
        if line.startswith("/*", i):
            state["block"], i = True, i + 2
            continue
        if line.startswith('"""', i):
            state["multiline"], i = True, i + 3
            continue
        if line[i] == '"':
            j, depth = i + 1, 0
            while j < len(line):
                if line[j] == "\\" and line.startswith("\\(", j):
                    depth, j = depth + 1, j + 2
                    continue
                if line[j] == "\\":
                    j += 2
                    continue
                if depth and line[j] == ")":
                    depth -= 1
                elif not depth and line[j] == '"':
                    break
                j += 1
            out.append('""')
            i = j + 1
            continue
        out.append(line[i])
        i += 1
    return "".join(out)


def leading(code):
    """(attribute text, the run of leading words) for a declaration candidate. A word ends at the first
    character that cannot continue it, so `init(from` gives `init`, and `private(set)` and
    `nonisolated(unsafe)` each stay one word."""
    stripped = code.lstrip()
    attributes = ""
    while stripped.startswith("@"):
        match = ATTRIBUTE.match(stripped)
        if not match:
            break
        attributes += match.group(0)
        stripped = stripped[match.end():]
    words = []
    for token in stripped.split():
        match = WORD.match(token)
        if not match:
            break
        words.append(match.group(0))
        if match.end() != len(token) or len(words) == 6:
            break
    return attributes, words


def scope_opened(statement):
    """The kind of scope a `{` opens, from the statement text in front of it."""
    _, words = leading(statement)
    for index, word in enumerate(words):
        base = word.split("(")[0]
        if base in {"private", "fileprivate"} and "(" not in word:
            # The members of a private or fileprivate type or extension are no more visible than it is,
            # so they are left alone: its body is not a type scope for this rewrite.
            return "other"
        if base in ACCESS or base in {"final", "indirect"}:
            continue
        if base == "class" and index + 1 < len(words) and words[index + 1].split("(")[0] in (
            DECLARATIONS | MODIFIERS | ACCESS
        ) - {"class"}:
            return "other"
        if base == "protocol":
            return "protocol"
        if base in TYPE_KEYWORDS:
            return "type"
        return "other"
    return "other"


def needs_package(code):
    """True for a declaration line that has no access modifier of its own."""
    _, words = leading(code)
    for index, word in enumerate(words):
        base = word.split("(")[0]
        if base in ACCESS and "(" not in word:
            return False
        if base in ACCESS:          # private(set) and friends: the getter still needs one
            continue
        if base == "class":         # `class func` / `class var` in a class body, or a class declaration
            following = words[index + 1].split("(")[0] if index + 1 < len(words) else ""
            if following in DECLARATIONS | MODIFIERS | ACCESS:
                continue
            return True
        if base in MODIFIERS:
            continue
        return base in DECLARATIONS
    return False


def insert_package(line):
    indent = line[: len(line) - len(line.lstrip())]
    rest = line[len(indent):]
    attributes = ""
    while rest.startswith("@"):
        match = ATTRIBUTE.match(rest)
        if not match:
            break
        attributes += match.group(0)
        rest = rest[match.end():]
    return f"{indent}{attributes}package {rest}"


def rewrite(text):
    """Returns (new text, list of (line number, original line) that gained `package`)."""
    lines = text.split("\n")
    state = {"block": False, "multiline": False}
    scopes = ["file"]
    statement = ""
    changed = []
    for number, line in enumerate(lines, start=1):
        at_start_of_line_in = scopes[-1]
        in_string_or_comment = state["block"] or state["multiline"]
        code = code_of(line, state)
        stripped = code.strip()
        if (
            not in_string_or_comment
            and at_start_of_line_in in ("file", "type")
            and not statement.strip()
            and stripped
            and not stripped.startswith("#")
            and needs_package(code)
        ):
            lines[number - 1] = insert_package(line)
            changed.append((number, line.strip()))
        for char in code:
            if char == "{":
                scopes.append(scope_opened(statement))
                statement = ""
            elif char == "}":
                if len(scopes) > 1:
                    scopes.pop()
                statement = ""
            elif char == ";":
                statement = ""
            else:
                statement += char
        # A declaration without a body ends with its line; a type header, or a line that ends in a
        # continuation, carries on to the next line.
        head = statement.strip()
        if scopes[-1] in ("file", "type", "protocol") and head:
            if scope_opened(head) == "other" and not head.endswith((",", "(", "[", ":", "->", "=", "&", "where")):
                statement = ""
        statement += " "
    return "\n".join(lines), changed


SAMPLE = '''import Foundation

typealias AccessToken = String

enum AuthConfiguration {
    case userPools(String)
    case identityPools(Int)
}

extension AuthConfiguration: Codable {
    enum CodingKeys: CodingKey {
        case userPools
    }

    func encode(to encoder: Encoder) throws {
        let local = "{ not a scope"
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .userPools(let value):
            try container.encode(value, forKey: .userPools)
        default:
            break
        }
    }

    init(from decoder: Decoder) throws {
        self = .userPools("")
    }
}

struct Data1: Equatable {
    let poolId: String
    private(set) var count: Int = 0
    private let secret: String = ""
    package let already: String
    @MainActor static func make() -> Data1 { fatalError() }
    var computed: String {
        let inner = poolId
        return inner
    }
    /* a { comment */
    struct Nested {
        let value: Int
    }
}

protocol Provider: Sendable {
    func logins() async throws -> [String: String]
}

final class Box {
    class func make() -> Box { Box() }
    let text = """
    struct NotADeclaration {
    """
}

private extension Box {
    func encode(object: Int) throws -> Int { object }
    static let hidden = 0
}

fileprivate struct Hidden {
    let value: Int
    func read() -> Int { value }
}

enum Globals {
    nonisolated(unsafe) static var shared = 0
    private struct Probe {
        let schemaVersion: Int
    }
}
'''

EXPECTED = '''import Foundation

package typealias AccessToken = String

package enum AuthConfiguration {
    case userPools(String)
    case identityPools(Int)
}

extension AuthConfiguration: Codable {
    package enum CodingKeys: CodingKey {
        case userPools
    }

    package func encode(to encoder: Encoder) throws {
        let local = "{ not a scope"
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .userPools(let value):
            try container.encode(value, forKey: .userPools)
        default:
            break
        }
    }

    package init(from decoder: Decoder) throws {
        self = .userPools("")
    }
}

package struct Data1: Equatable {
    package let poolId: String
    package private(set) var count: Int = 0
    private let secret: String = ""
    package let already: String
    @MainActor package static func make() -> Data1 { fatalError() }
    package var computed: String {
        let inner = poolId
        return inner
    }
    /* a { comment */
    package struct Nested {
        package let value: Int
    }
}

package protocol Provider: Sendable {
    func logins() async throws -> [String: String]
}

package final class Box {
    package class func make() -> Box { Box() }
    package let text = """
    struct NotADeclaration {
    """
}

private extension Box {
    func encode(object: Int) throws -> Int { object }
    static let hidden = 0
}

fileprivate struct Hidden {
    let value: Int
    func read() -> Int { value }
}

package enum Globals {
    package nonisolated(unsafe) static var shared = 0
    private struct Probe {
        let schemaVersion: Int
    }
}
'''


def self_test():
    result, changed = rewrite(SAMPLE)
    if result != EXPECTED:
        for number, (got, want) in enumerate(zip(result.split("\n"), EXPECTED.split("\n")), start=1):
            if got != want:
                print(f"line {number}: got {got!r}, want {want!r}")
        sys.exit("package_access.py self-test FAILED")
    again, second = rewrite(result)
    if again != result or second:
        sys.exit("package_access.py self-test FAILED: the rewrite is not idempotent")
    print(f"package_access.py self-test passed ({len(changed)} declarations)")


def main(argv):
    if argv[1:] == ["--self-test"]:
        return self_test()
    check = "--check" in argv
    paths = []
    for argument in argv[1:]:
        if argument == "--check":
            continue
        if argument.startswith("@"):        # a file listing one path per line
            with open(argument[1:]) as listing:
                paths += [line.strip() for line in listing if line.strip()]
        else:
            paths.append(argument)
    if not paths:
        sys.exit(__doc__)
    missing = 0
    for path in paths:
        with open(path) as source:
            text = source.read()
        result, changed = rewrite(text)
        if check:
            for number, line in changed:
                print(f"{path}:{number}: no access modifier: {line}")
            missing += len(changed)
            continue
        if changed:
            with open(path, "w") as target:
                target.write(result)
        print(f"{path}: {len(changed)} declarations")
    if check and missing:
        sys.exit(1)


if __name__ == "__main__":
    main(sys.argv)
