#!/bin/bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Gate G1(a): the public-declaration grep diff, over the plugin and the engine together, so a declaration that moves between them
# does not count as a change.
#
#   scripts/m2/public_decls.sh list [git-ref]          # sorted public/open declaration lines; worktree if no ref
#   scripts/m2/public_decls.sh diff <base-ref> [head]  # empty diff and exit 0 = pass; head defaults to the worktree
#   scripts/m2/public_decls.sh self-test
#
# It is a text gate, deliberately simple: it catches an added, removed or re-spelled public line. The
# api-digester (scripts/m2/api_digester.sh) is the semantic gate.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
# The engine's directory before and after it moved out of the plugin, so a diff across the move compares like with like.
PATHS=(
    AmplifyPlugins/Auth/Sources/AWSCognitoAuthPlugin
    AmplifyClients/Internal/InternalAWSCognitoAuth/Sources
    AmplifyPlugins/Internal/Sources/InternalAWSCognitoAuth
)
PATTERN='^[[:space:]]*(@[A-Za-z_]+(\([^)]*\))?[[:space:]]+)*(public|open) '

list() {
    local ref="${1:-}"
    cd "$ROOT"
    if [ -z "$ref" ]; then
        grep -rhE --include='*.swift' "$PATTERN" "${PATHS[@]}" 2> /dev/null | sort || true
    else
        git grep -hE "$PATTERN" "$ref" -- "${PATHS[@]/%//*.swift}" 2> /dev/null | sort || true
    fi
}

diff_refs() {
    local base="$1" head="${2:-}" base_file head_file
    base_file="$(mktemp)"
    head_file="$(mktemp)"
    list "$base" > "$base_file"
    list "$head" > "$head_file"
    echo "public declarations: $(wc -l < "$base_file" | tr -d ' ') at $base, $(wc -l < "$head_file" | tr -d ' ') at ${head:-worktree}"
    if diff "$base_file" "$head_file"; then
        echo "public-declaration diff: empty"
        rm -f "$base_file" "$head_file"
    else
        rm -f "$base_file" "$head_file"
        return 1
    fi
}

self_test() {
    local dir sample
    dir="$(mktemp -d)"
    sample="$dir/Sample.swift"
    printf '%s\n' \
        'public struct A {}' \
        '    @available(*, deprecated) public init() {}' \
        '@discardableResult public func f() -> Int { 1 }' \
        'open class B {}' \
        'package struct C {}' \
        'struct D { let publicValue = 1 }' > "$sample"
    local count
    count=$(grep -hE "$PATTERN" "$sample" | wc -l | tr -d ' ')
    rm -rf "$dir"
    if [ "$count" != "4" ]; then
        echo "public_decls.sh self-test FAILED: matched $count lines, expected 4" >&2
        return 1
    fi
    echo "public_decls.sh self-test passed"
}

case "${1:-}" in
    list) shift; list "$@" ;;
    diff) shift; diff_refs "$@" ;;
    self-test) self_test ;;
    *) grep '^#   scripts/m2' "$0"; exit 64 ;;
esac
