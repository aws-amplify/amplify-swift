#!/bin/bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Self-test for check_fixture_lock.sh's self-file check, in a scratch repository: commit A holds the locked
# trees (from this repository's HEAD) and this checkout's copy of the script and its workflow. Branches made
# from A stand for open PRs, and B, a later commit on main, edits the workflow. As in CI, each run uses the
# base's copy of the script, with the PR head and the base tip:
#   - a PR that edits neither file passes, though main changed the workflow after it branched;
#   - a PR that edits the workflow, or the script, fails, naming the file.
#
#   bash scripts/cognito-engine/test_check_fixture_lock.sh
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCK=scripts/cognito-engine/check_fixture_lock.sh
WORKFLOW=.github/workflows/auth_golden_fixture_lock.yml
RUNNER=scripts/cognito-engine/.check_fixture_lock.run.sh
SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

failures=0
fail() {
    echo "FAIL $1"
    failures=$((failures + 1))
}

git_scratch() {
    git -C "$SCRATCH" -c user.name=test -c user.email=test@example.com -c commit.gpgsign=false "$@"
}

# The locked directories, read from the script's pins.
directories=()
while IFS= read -r directory; do
    directories+=("$directory")
done < <(sed -n 's/^    "\([^ "]*\) [0-9a-f]\{40\}"$/\1/p' "$REPO/$LOCK")
if [ ${#directories[@]} -eq 0 ]; then
    echo "FAIL no locked directories found in $LOCK"
    exit 1
fi

git_scratch init -q -b main
git -C "$REPO" archive HEAD -- "${directories[@]}" | tar -x -C "$SCRATCH"
mkdir -p "$SCRATCH/$(dirname "$LOCK")" "$SCRATCH/$(dirname "$WORKFLOW")"
cp "$REPO/$LOCK" "$SCRATCH/$LOCK"
cp "$REPO/$WORKFLOW" "$SCRATCH/$WORKFLOW"
echo a > "$SCRATCH/app.txt"
git_scratch add -A
git_scratch commit -q -m A

# Open PRs, each branched from A.
pull_request() {
    local name="$1" file="$2"
    git_scratch checkout -q -b "$name" main
    echo "# $name" >> "$SCRATCH/$file"
    git_scratch commit -q -am "$name"
    git_scratch checkout -q main
}
pull_request app-only app.txt
pull_request edits-workflow "$WORKFLOW"
pull_request edits-script "$LOCK"

# B: main changes the workflow after every PR branched.
echo "# a later change on main" >> "$SCRATCH/$WORKFLOW"
git_scratch commit -q -am B

# Runs the base's copy of the script, as the workflow does.
run_lock() {
    local head="$1" base="$2"
    git_scratch show "$base:$LOCK" > "$SCRATCH/$RUNNER"
    bash "$SCRATCH/$RUNNER" "$head" "$base" 2>&1
}

if ! output="$(run_lock main main)"; then
    echo "FAIL the locked trees from HEAD do not match the pins, so no case can pass: $output"
    exit 1
fi

if output="$(run_lock app-only main)"; then
    echo "ok a PR that edits neither file passes after main changed the workflow"
else
    fail "a PR that edits neither file failed after main changed the workflow: $output"
fi

for case in "edits-workflow $WORKFLOW" "edits-script $LOCK"; do
    branch="${case%% *}"
    file="${case#* }"
    if output="$(run_lock "$branch" main)"; then
        fail "a PR that edits $file passed: $output"
    elif [[ "$output" != *"error: $file changed; the lock's own script and workflow are locked too"* ]]; then
        fail "a PR that edits $file failed without naming it: $output"
    else
        echo "ok a PR that edits $file fails, named"
    fi
done

if [ "$failures" -ne 0 ]; then
    echo "$failures failure(s)"
    exit 1
fi
echo "all check_fixture_lock.sh self-file tests passed"
