#!/bin/bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Gate G1(b): the api-digester, run so that it cannot silently pass.
#
#   scripts/m2/api_digester.sh dump <out.json> [module]   # after `swift build`; module defaults to AWSCognitoAuthPlugin
#   scripts/m2/api_digester.sh diff <base.json> <head.json>
#   scripts/m2/api_digester.sh check <dump.json> [digester-stderr]   # the size / TypeDecl guard on its own
#   scripts/m2/api_digester.sh self-test
#
# `dump` passes every -I / -F / -Xcc argument of the module's compile command (scripts/m2/digester_args.py),
# because `-I .build/debug/Modules` alone makes the digester write an empty dump and exit 0. It refuses to
# report success when the dump is smaller than M2_DIGESTER_MIN_BYTES (default 200000) or has fewer than
# M2_DIGESTER_MIN_TYPEDECLS of the module's own (non-external) type declarations (default 35; external
# extension nodes are excluded because the engine move takes conformances out of the plugin, which removes them), or when the digester reports missing modules.
#
# `diff` runs -diagnose-sdk and exits 1 if any section of its report is non-empty, 0 if all are empty.
#
# Typical base-vs-head use: build and dump at base, check out head, build and dump again, then diff.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MIN_BYTES="${M2_DIGESTER_MIN_BYTES:-200000}"
MIN_TYPEDECLS="${M2_DIGESTER_MIN_TYPEDECLS:-35}"

sdk_path() { xcrun --show-sdk-path; }

digester() {
    if swift api-digester -help > /dev/null 2>&1; then
        swift api-digester "$@"
    else
        xcrun swift-api-digester "$@"
    fi
}

# Fails unless $1 looks like a real dump.
check_dump() {
    local dump="$1" stderr_file="$2"
    local bytes typedecls
    bytes=$(wc -c < "$dump" | tr -d ' ')
    typedecls=$(python3 - "$dump" <<'PY'
import json, sys
def walk(node):
    count = 0
    if isinstance(node, dict):
        if node.get("kind") == "TypeDecl" and not node.get("isExternal", False):
            count += 1
        for child in node.get("children", []):
            count += walk(child)
    return count
data = json.load(open(sys.argv[1]))
print(walk(data.get("ABIRoot", data)))
PY
)
    if grep -q "missing required module" "$stderr_file"; then
        echo "error: the digester could not load every module:" >&2
        grep "missing required module" "$stderr_file" >&2
        return 2
    fi
    if [ "$bytes" -lt "$MIN_BYTES" ] || [ "$typedecls" -lt "$MIN_TYPEDECLS" ]; then
        echo "error: $dump is not a real dump ($bytes bytes, $typedecls TypeDecls; need >= $MIN_BYTES and >= $MIN_TYPEDECLS)." >&2
        echo "       This is the empty-dump trap: the digester exits 0 on it." >&2
        return 2
    fi
    echo "dump ok: $dump ($bytes bytes, $typedecls TypeDecls)"
}

dump() {
    local out="$1" module="${2:-AWSCognitoAuthPlugin}"
    local args=() stderr_file
    while IFS= read -r line; do args+=("$line"); done < <(cd "$ROOT" && python3 scripts/m2/digester_args.py --module "$module")
    stderr_file="$(mktemp)"
    digester -sdk "$(sdk_path)" -dump-sdk -module "$module" -o "$out" "${args[@]}" 2> "$stderr_file" || {
        cat "$stderr_file" >&2
        rm -f "$stderr_file"
        return 2
    }
    local status=0
    check_dump "$out" "$stderr_file" || status=$?
    rm -f "$stderr_file"
    return "$status"
}

# Prints the report without its section headers and blank lines; empty output means clean.
findings() {
    grep -v -E '^\s*$|^/\* .* \*/$' "$1" || true
}

diff_dumps() {
    local base="$1" head="$2" report
    report="$(mktemp)"
    digester -sdk "$(sdk_path)" -diagnose-sdk --input-paths "$base" --input-paths "$head" > "$report" 2>&1
    cat "$report"
    if [ -n "$(findings "$report")" ]; then
        echo "api-digester: DIFFERENCES FOUND" >&2
        rm -f "$report"
        return 1
    fi
    echo "api-digester: clean (every section empty)"
    rm -f "$report"
}

self_test() {
    local dir
    dir="$(mktemp -d)"
    printf '{"kind": "Root"}\n' > "$dir/empty.json"
    : > "$dir/stderr"
    if check_dump "$dir/empty.json" "$dir/stderr" > /dev/null 2>&1; then
        echo "self-test FAILED: an empty dump was accepted" >&2
        return 1
    fi
    python3 - "$dir/big.json" "$MIN_BYTES" "$MIN_TYPEDECLS" << 'EOF'
import sys
path, size, decls = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
with open(path, "w") as f:
    f.write('{"children": [\n' + ',\n'.join('{"kind": "TypeDecl", "name": "T%d"}' % i for i in range(decls)) + "\n]}")
    f.write(" " * size)
EOF
    check_dump "$dir/big.json" "$dir/stderr" > /dev/null
    echo "error: missing required modules: 'AwsCAuth'" > "$dir/stderr"
    if check_dump "$dir/big.json" "$dir/stderr" > /dev/null 2>&1; then
        echo "self-test FAILED: missing modules were accepted" >&2
        return 1
    fi
    printf '\n/* Generic Signature Changes */\n\n/* Removed Decls */\n\n' > "$dir/clean.txt"
    [ -z "$(findings "$dir/clean.txt")" ] || { echo "self-test FAILED: clean report flagged" >&2; return 1; }
    printf '/* Removed Decls */\nFunc Foo.bar() has been removed\n' > "$dir/dirty.txt"
    [ -n "$(findings "$dir/dirty.txt")" ] || { echo "self-test FAILED: finding missed" >&2; return 1; }
    rm -rf "$dir"
    echo "api_digester.sh self-test passed"
}

case "${1:-}" in
    dump) shift; dump "$@" ;;
    diff) shift; diff_dumps "$@" ;;
    check) shift; check_dump "$1" "${2:-/dev/null}" ;;
    self-test) self_test ;;
    *) grep '^#   scripts/m2' "$0"; exit 64 ;;
esac
