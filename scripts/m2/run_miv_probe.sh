#!/bin/bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Gate G1(c): the MemberImportVisibility client-compile probe.
#
#   swift build --target AWSCognitoAuthPlugin     # or any build that leaves .build/debug current
#   scripts/m2/run_miv_probe.sh [probe.swift]      # defaults to scripts/m2/miv-probe/Probe.swift
#   scripts/m2/run_miv_probe.sh --self-test        # NegativeProbe.swift must pass off and fail on
#
# Type-checks the probe, a client file that imports only AWSCognitoAuthPlugin, against the built module
# twice: without and with `-enable-upcoming-feature MemberImportVisibility` (SE-0444). Exits 0 only if both
# are clean. Build-only: nothing is linked or run. The module-search arguments come from the plugin's own
# compile command (scripts/m2/digester_args.py), as for the api-digester.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SELF_TEST=0
if [ "${1:-}" = "--self-test" ]; then
    SELF_TEST=1
    PROBE="$ROOT/scripts/m2/miv-probe/NegativeProbe.swift"
else
    PROBE="${1:-$ROOT/scripts/m2/miv-probe/Probe.swift}"
fi

args=()
while IFS= read -r line; do args+=("$line"); done < <(cd "$ROOT" && python3 scripts/m2/digester_args.py --with-target)
if [ "${#args[@]}" -eq 0 ]; then
    echo "error: no compile arguments for AWSCognitoAuthPlugin; build first" >&2
    exit 2
fi

status=0
results=()
for mode in off on; do
    feature=()
    [ "$mode" = on ] && feature=(-enable-upcoming-feature MemberImportVisibility)
    output="$(xcrun swiftc -typecheck -sdk "$(xcrun --show-sdk-path)" -swift-version 6 ${feature[@]+"${feature[@]}"} "${args[@]}" "$PROBE" 2>&1)"
    code=$?
    errors="$(printf '%s\n' "$output" | grep -cE '\.swift:[0-9]+:[0-9]+: error:' || true)"
    if [ $code -eq 0 ] && [ "$errors" -eq 0 ]; then
        echo "[MemberImportVisibility=$mode] probe type-checks cleanly"
        results+=("$mode=clean")
    else
        results+=("$mode=errors")
        status=1
        echo "[MemberImportVisibility=$mode] FAILED ($errors errors):"
        printf '%s\n' "$output" | grep -E '\.swift:[0-9]+:[0-9]+: error:' | sed -E 's/^.*\/([^/]+:[0-9]+):[0-9]+: error: /   \1: /' | sort | uniq -c
    fi
done
if [ $SELF_TEST -eq 1 ]; then
    if [ "${results[*]}" = "off=clean on=errors" ]; then
        echo "run_miv_probe.sh self-test passed (the feature is really enabled)"
        exit 0
    fi
    echo "run_miv_probe.sh self-test FAILED: expected off=clean on=errors, got ${results[*]}" >&2
    exit 1
fi
exit $status
