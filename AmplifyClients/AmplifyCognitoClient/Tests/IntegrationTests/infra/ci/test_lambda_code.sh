#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Self-test for lambda_code.py, the CI Lambdas' code and drift check, over a copy of infra/'s Lambda sources in a
# temporary directory: no AWS call (the "deployed" zips are local files, given as file:// URLs, which
# CCIT_CI_TEST_FILE_CODE_URLS lets through), and the committed baseline is only read.
#
#   bash infra/ci/test_lambda_code.sh
#
# It checks that a zip is deterministic (the same bytes from another checkout time, files dated 1980, mode 644) and
# holds only the function's files; that the custom sender's holds node_modules but not npm's .package-lock.json;
# that compare reads the deployed zips file by file: a function deployed from this checkout is in sync, so is one
# whose zip holds the same files compressed and dated otherwise (its CodeSha256 only noted), and one with other
# files is DRIFT, by name, with the files that differ, never a hash or a URL, each name escaped (so with --github none
# can end its line or start a workflow command, nor hold a legacy ##[ one); that a URL that is not https:// on a
# Lambda code bucket's S3 host (the real hosts' shapes are, other amazonaws.com hosts and look-alikes are not; file://
# and http://127.0.0.1 only in the self-tests), a redirect, a download over 50 MB or one that is no zip is refused
# (over a local server on 127.0.0.1, which only the self-tests' variable lets through), and a malformed URL is
# unreadable (exit 1), not a traceback; that record
# shows the same and writes nothing without --accept-deployed, and with it the deployed files, which compare then
# accepts until the sources change; that check-baseline is 0 with the recorded sources, 1 once one changed, 3 with
# no baseline; that an unexpected error is status 4, never 1, and so is a deployed.json anyone but its owner can read;
# that no download directory is left behind; and that the committed baseline, when there is one, names this
# checkout's sources. It also checks:
# - that npm's node_modules/.bin/ links count on neither side, so a sender zipped with `zip -r` (which stores a copy
#   of each link's target) is in sync;
# - that a function the baseline records but that is not deployed is DRIFT, and record keeps it rather than drop it,
#   and that the redeploy advice checks the purpose tag first and reruns --apply --scope all;
# - that no function deployed at all (another region or account) fails compare and record, and that an empty
#   baseline is no baseline;
# - that a function not compared (no zip from this checkout) is never recorded;
# - that a corrupt or encrypted member is unreadable (exit 1), not a traceback.
set -euo pipefail
CI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA="$(cd "$CI_DIR/.." && pwd)"
SCRIPT="$CI_DIR/lambda_code.py"
WORK=$(mktemp -d)
SERVER=""
trap '[[ -z "$SERVER" ]] || kill "$SERVER" 2>/dev/null; rm -rf "$WORK"' EXIT
unset CCIT_CI_LAMBDA_BASELINE
# Files written here are the owner's only, as provision-ci.sh writes deployed.json (one test opens it up).
umask 077
# A copy of the sources, so a test can change one.
COPY="$WORK/infra"
mkdir -p "$COPY/lambda" "$COPY/ci/lambda"
cp -R "$INFRA/lambda/triggers" "$INFRA/lambda/custom-sender" "$COPY/lambda/"
cp -R "$INFRA/ci/lambda/discard-sender" "$INFRA/ci/lambda/new-password-reset" "$COPY/ci/lambda/"
rm -rf "$COPY/lambda/custom-sender/node_modules"
export CCIT_CI_INFRA_DIR="$COPY" CCIT_CI_TEST_FILE_CODE_URLS=1
# The local server is never reached through a proxy.
export no_proxy="127.0.0.1${no_proxy:+,$no_proxy}"
BASELINE="$WORK/baseline.json"
SUFFIXES=(create-auth-challenge custom-sender define-auth-challenge discard-sender new-password-reset pre-sign-up
          pre-sign-up-confirmable verify-auth-challenge)

failures=0
check() {
    local name="$1"
    shift
    if "$@"; then echo "ok - $name"; else echo "FAIL - $name"; failures=$((failures + 1)); fi
}

run() {
    STATUS=0
    OUT=$(python3 "$SCRIPT" "$@" 2>&1) || STATUS=$?
}

sha() { python3 -c 'import base64,hashlib,sys;print(base64.b64encode(hashlib.sha256(open(sys.argv[1],"rb").read()).digest()).decode())' "$1"; }

# A custom sender build, as provision-ci.sh's `npm ci` leaves it (with npm's own .package-lock.json).
BUILD="$WORK/build"
mkdir -p "$BUILD/node_modules/dependency"
cp "$COPY/lambda/custom-sender/index.mjs" "$COPY/lambda/custom-sender/package.json" "$BUILD/"
echo 'export {};' > "$BUILD/node_modules/dependency/index.js"
echo '{}' > "$BUILD/node_modules/.package-lock.json"

# Every function's zip into $1, built from the copy.
build_all() {
    local suffix
    mkdir -p "$1"
    for suffix in "${SUFFIXES[@]}"; do
        if [[ "$suffix" == custom-sender ]]; then
            python3 "$SCRIPT" zip "$suffix" "$1/$suffix.zip" "$BUILD"
        else
            python3 "$SCRIPT" zip "$suffix" "$1/$suffix.zip"
        fi
    done
}

# "Deploys" every zip in $1: a copy of each in $WORK/deployed, and deployed.json naming it by a file:// URL with its
# CodeSha256, as provision-ci.sh writes it from GetFunction.
deploy_all() {
    local suffix json="{}"
    rm -rf "$WORK/deployed"
    mkdir -p "$WORK/deployed"
    for suffix in "${SUFFIXES[@]}"; do
        cp "$1/$suffix.zip" "$WORK/deployed/$suffix.zip"
        json=$(jq -c --arg k "$suffix" --arg s "$(sha "$1/$suffix.zip")" --arg u "file://$WORK/deployed/$suffix.zip" \
            '.[$k] = {codeSha256: $s, location: $u}' <<<"$json")
    done
    printf '%s\n' "$json" > "$WORK/deployed.json"
}

# Replaces deployed function $1's zip: "rezipped", the same files stored and dated 2024; "edited", with the first
# file changed and notes.txt added. Its CodeSha256 in deployed.json follows.
redeploy() {
    python3 - "$WORK/deployed/$1.zip" "$2" <<'PY'
import io, sys, zipfile
path, how = sys.argv[1:]
with zipfile.ZipFile(path) as z:
    files = {n: z.read(n) for n in z.namelist()}
if how == "edited":
    first = sorted(files)[0]
    files[first] += b"\n// edited by hand\n"
    files["notes.txt"] = b"not from the checkout\n"
buffer = io.BytesIO()
with zipfile.ZipFile(buffer, "w", zipfile.ZIP_STORED) as z:
    for n, data in sorted(files.items()):
        z.writestr(zipfile.ZipInfo(n, date_time=(2024, 5, 6, 7, 8, 10)), data)
with open(path, "wb") as f:
    f.write(buffer.getvalue())
PY
    jq -c --arg k "$1" --arg s "$(sha "$WORK/deployed/$1.zip")" '.[$k].codeSha256 = $s' "$WORK/deployed.json" > "$WORK/d" \
        && mv "$WORK/d" "$WORK/deployed.json"
}

# Sets deployed function $1's location to $2.
relocate() {
    jq -c --arg k "$1" --arg u "$2" '.[$k].location = $u' "$WORK/deployed.json" > "$WORK/d" && mv "$WORK/d" "$WORK/deployed.json"
}

zips_are_deterministic_and_hold_only_the_functions_files() {
    build_all "$WORK/a"
    touch -t 202001010000 "$COPY/lambda/triggers/triggers.mjs" "$BUILD/index.mjs"
    chmod 600 "$COPY/lambda/triggers/triggers.mjs"
    build_all "$WORK/b"
    chmod 644 "$COPY/lambda/triggers/triggers.mjs"
    local suffix
    for suffix in "${SUFFIXES[@]}"; do
        cmp -s "$WORK/a/$suffix.zip" "$WORK/b/$suffix.zip" || { echo "$suffix differs"; return 1; }
    done
    python3 - "$WORK/a" <<'PY'
import os, sys, zipfile
root = sys.argv[1]
with zipfile.ZipFile(os.path.join(root, "pre-sign-up.zip")) as z:
    assert z.namelist() == ["triggers.mjs"], z.namelist()
    info = z.getinfo("triggers.mjs")
    assert info.date_time == (1980, 1, 1, 0, 0, 0) and info.external_attr >> 16 == 0o644, info
with zipfile.ZipFile(os.path.join(root, "discard-sender.zip")) as z:
    assert z.namelist() == ["index.mjs"], z.namelist()
with zipfile.ZipFile(os.path.join(root, "custom-sender.zip")) as z:
    assert z.namelist() == ["index.mjs", "node_modules/dependency/index.js", "package.json"], z.namelist()
PY
}

compare_reads_the_deployed_files() {
    build_all "$WORK/z"
    deploy_all "$WORK/z"
    run compare "$WORK/deployed.json" "$WORK/z" --baseline "$BASELINE"
    (( STATUS == 0 )) && [[ "$(grep -c "the deployed files are this checkout's" <<<"$OUT")" == 8 ]] \
        && [[ "$(grep -c "CodeSha256, a note only: the same as this checkout's zip's" <<<"$OUT")" == 8 ]] \
        || { echo "$OUT"; return 1; }
    # The same files in another zip: in sync; only the note tells the CodeSha256 apart.
    redeploy discard-sender rezipped
    run compare "$WORK/deployed.json" "$WORK/z" --baseline "$BASELINE"
    (( STATUS == 0 )) && [[ "$(grep -c "the deployed files are this checkout's" <<<"$OUT")" == 8 ]] \
        && [[ "$(grep -A1 '= ccit-ci-discard-sender' <<<"$OUT")" == *"not this checkout's zip's (the files decide)"* ]] \
        || { echo "$OUT"; return 1; }
    # Other files: DRIFT, by name, with what differs.
    redeploy custom-sender edited
    run compare "$WORK/deployed.json" "$WORK/z" --baseline "$BASELINE" --github
    (( STATUS == 1 )) && [[ "$OUT" == *"::error::DRIFT ccit-ci-custom-sender: the deployed files are neither"* ]] \
        && [[ "$OUT" == *"      changed (1): index.mjs"$'\n'"      only deployed (1): notes.txt"* ]] \
        && [[ "$OUT" == *"carries purpose=amplify-cognito-client-integ"* && "$(grep -c DRIFT <<<"$OUT")" == 1 ]] \
        && [[ "$OUT" != *file:* && "$OUT" != *"$WORK"* && "$OUT" != *"$(sha "$WORK/z/custom-sender.zip")"* ]] \
        && ! grep -qE '[0-9a-f]{64}' <<<"$OUT" || { echo "$OUT"; return 1; }
    # Not deployed, or no zip from this checkout: reported, not drift.
    deploy_all "$WORK/z"
    jq -c '.["discard-sender"] = null' "$WORK/deployed.json" > "$WORK/d2.json"
    rm "$WORK/z/custom-sender.zip"
    run compare "$WORK/d2.json" "$WORK/z" --baseline "$BASELINE"
    (( STATUS == 0 )) && [[ "$OUT" == *"ccit-ci-discard-sender: not deployed"* && "$OUT" == *"ccit-ci-custom-sender: not compared"* ]]
}

REFUSED_URL="its code location is not an https:// URL on a Lambda code bucket's S3 host."

# The hosts of Lambda's code buckets, as GetFunction's Code.Location names them, are allowed; other AWS endpoints, a
# path-style S3 URL (any bucket), a bucket not named -tasks and look-alike domains are not.
real_code_hosts_are_the_only_ones_allowed() {
    env -u CCIT_CI_TEST_FILE_CODE_URLS python3 - "$CI_DIR" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import lambda_code
allowed = [
    "https://awslambda-us-west-2-tasks.s3.us-west-2.amazonaws.com/snapshots/123456789012/f-1?versionId=v&X-Amz-Signature=s",
    "https://prod-04-2014-tasks.s3.us-east-1.amazonaws.com/snapshots/123456789012/f-1",
    "https://prod-iad-c1-djusa-tasks.s3.us-east-1.amazonaws.com/snapshots/123456789012/f-1",
    "https://awslambda-ap-ne-1-tasks.s3.ap-northeast-1.amazonaws.com/snapshots/123456789012/f-1",
    "https://prod-04-2014-tasks.s3.amazonaws.com/snapshots/123456789012/f-1",
    "https://AWSLAMBDA-US-EAST-2-TASKS.S3.US-EAST-2.AMAZONAWS.COM/x",
]
refused = [
    "https://amazonaws.com/x", "https://evilamazonaws.com/x",
    "https://s3.us-east-1.amazonaws.com/awslambda-us-east-1-tasks/x", "https://my-bucket.s3.us-east-1.amazonaws.com/x",
    "https://abc123.execute-api.us-east-1.amazonaws.com/x", "https://lambda.us-east-1.amazonaws.com/x",
    "https://awslambda-us-east-1-tasks.s3.us-east-1amazonaws.com/x",
    "https://awslambda-us-east-1-tasks.s3.us-east-1.amazonaws.com.example.com/x",
    "https://awslambda-us-east-1-tasks.s3.us-east-1.amazonaws.com./x",
    "https://x.awslambda-us-east-1-tasks.s3.us-east-1.amazonaws.com/x",
    "https://-tasks.s3.us-east-1.amazonaws.com/x", "https://tasks.s3.us-east-1.amazonaws.com/x",
    "https://awslambda-us-east-1-tasks.s3.us-east-1.amazonaws.com@example.com/x",
    "http://awslambda-us-east-1-tasks.s3.us-east-1.amazonaws.com/x",
    "ftp://awslambda-us-east-1-tasks.s3.us-east-1.amazonaws.com/x",
    "http://127.0.0.1/x", "file:///tmp/x.zip",
]
wrong = [u for u in allowed if not lambda_code.allowed_url(u)] + [u for u in refused if lambda_code.allowed_url(u)]
assert not wrong, wrong
PY
}

# A deployed zip whose member names hold a newline, a carriage return, an escape, a line separator, a backslash and
# the runner's legacy ##[ commands: with --github each prints escaped, on its line, and the only workflow command is
# the DRIFT annotation.
member_names_print_escaped() {
    build_all "$WORK/n"
    deploy_all "$WORK/n"
    python3 - "$WORK/deployed/discard-sender.zip" <<'PY'
import sys, zipfile
with zipfile.ZipFile(sys.argv[1], "a") as z:
    for name in ("a\n::error::injected", "b\r\n::warning file=x::injected", "c\x1b[31m", "d\u2028::notice::injected", "e\\n",
                 "f/##[warning]injected", "x/##[stop-commands]t"):
        z.writestr(name, b"x")
PY
    jq -c --arg s "$(sha "$WORK/deployed/discard-sender.zip")" '.["discard-sender"].codeSha256 = $s' "$WORK/deployed.json" \
        > "$WORK/d" && mv "$WORK/d" "$WORK/deployed.json"
    run compare "$WORK/deployed.json" "$WORK/n" --baseline "$BASELINE" --github
    local expected='      only deployed (7): a\n::error::injected, b\r\n::warning file=x::injected, c\x1b[31m, d\u2028::notice::injected, e\\n, f/\x23\x23[warning]injected, x/\x23\x23[stop-commands]t'
    (( STATUS == 1 )) && [[ "$(grep -c '^::' <<<"$OUT")" == 1 && "$(grep '^::' <<<"$OUT")" == "::error::DRIFT ccit-ci-discard-sender: "* ]] \
        && grep -qxF -- "$expected" <<<"$OUT" && [[ "$OUT" != *'##['* ]] \
        && python3 -c 'import sys; sys.exit(any(c in sys.stdin.read() for c in "\r\x1b\u2028"))' <<<"$OUT" \
        || { echo "$OUT"; return 1; }
}

only_an_aws_https_url_is_downloaded() {
    local url
    build_all "$WORK/u"
    deploy_all "$WORK/u"
    for url in "https://example.com/code.zip" "https://amazonaws.com.example.com/code.zip" "http://lambda.us-east-1.amazonaws.com/x" \
        "ftp://lambda.amazonaws.com/x" "https://evilamazonaws.com/x" "https://awslambda-us-east-1-tasks.s3.us-east-1amazonaws.com/x" \
        "https://my-bucket.s3.us-east-1.amazonaws.com/x" "https://abc123.execute-api.us-east-1.amazonaws.com/x"; do
        relocate pre-sign-up "$url"
        run compare "$WORK/deployed.json" "$WORK/u" --baseline "$BASELINE"
        (( STATUS == 1 )) && [[ "$OUT" == *"! ccit-ci-pre-sign-up: the deployed code could not be read: $REFUSED_URL"* ]] \
            && [[ "$OUT" != *"$url"* ]] || { echo "$url: $OUT"; return 1; }
    done
    # A URL that urlsplit cannot parse (the last one holds a full-width slash): unreadable, not the script's own failure.
    for url in "https://[::1].amazonaws.com/x" "https://[awslambda-us-east-1-tasks.s3.us-east-1.amazonaws.com/x" \
        "https://a／b-tasks.s3.us-east-1.amazonaws.com/x"; do
        relocate pre-sign-up "$url"
        run compare "$WORK/deployed.json" "$WORK/u" --baseline "$BASELINE"
        (( STATUS == 1 )) && [[ "$OUT" == *"! ccit-ci-pre-sign-up: the deployed code could not be read: its code location is not a well-formed URL."* ]] \
            && [[ "$OUT" != *Traceback* && "$OUT" != *"$url"* && "$OUT" != *amazonaws* ]] || { echo "$url: $STATUS $OUT"; return 1; }
    done
    # file:// only for the self-tests.
    relocate pre-sign-up "file://$WORK/deployed/pre-sign-up.zip"
    STATUS=0
    OUT=$(env -u CCIT_CI_TEST_FILE_CODE_URLS python3 "$SCRIPT" compare "$WORK/deployed.json" "$WORK/u" --baseline "$BASELINE" 2>&1) \
        || STATUS=$?
    (( STATUS == 1 )) && [[ "$(grep -c 'could not be read' <<<"$OUT")" == 8 ]] || { echo "$OUT"; return 1; }
    # A download that is no zip, or none at all.
    echo 'not a zip' > "$WORK/deployed/pre-sign-up.zip"
    relocate discard-sender "file://$WORK/deployed/missing.zip"
    run compare "$WORK/deployed.json" "$WORK/u" --baseline "$BASELINE"
    (( STATUS == 1 )) && [[ "$OUT" == *"! ccit-ci-pre-sign-up: the deployed code could not be read: it is not a zip"* ]] \
        && [[ "$OUT" == *"! ccit-ci-discard-sender: the deployed code could not be read: its zip could not be downloaded"* ]] \
        && [[ "$OUT" != *missing.zip* ]] || { echo "$OUT"; return 1; }
    run record "$WORK/deployed.json" "$WORK/u" --baseline "$BASELINE" --accept-deployed
    (( STATUS == 1 )) && [[ "$OUT" == *"Nothing recorded: a deployed function's code could not be read."* && ! -e "$BASELINE" ]]
}

# A local server on 127.0.0.1 only (an ephemeral port), which logs each path it is asked for: /zip serves $1,
# /redirect redirects to /zip, /large streams 51 MB.
start_server() {
    cat > "$WORK/server.py" <<'PY'
import http.server
import os
import sys

port_file, log_file, zip_file = sys.argv[1:]


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_GET(self):
        if self.path == "/ready":
            self.send_response(204)
            self.end_headers()
            return
        with open(log_file, "a") as log:
            log.write(self.path + "\n")
        if self.path == "/redirect":
            self.send_response(302)
            self.send_header("Location", f"http://127.0.0.1:{self.server.server_port}/zip")
            self.end_headers()
        elif self.path == "/zip":
            with open(zip_file, "rb") as f:
                data = f.read()
            self.send_response(200)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
        elif self.path == "/large":
            self.send_response(200)
            self.send_header("Content-Length", str(51 << 20))
            self.end_headers()
            try:
                for _ in range(51):
                    self.wfile.write(bytes(1 << 20))
            except OSError:
                pass
        else:
            self.send_error(404)


server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
with open(port_file + ".tmp", "w") as f:
    f.write(str(server.server_port))
os.replace(port_file + ".tmp", port_file)
server.serve_forever()
PY
    rm -f "$WORK/port" "$WORK/server.log"
    python3 "$WORK/server.py" "$WORK/port" "$WORK/server.log" "$1" &
    SERVER=$!
    local tries
    PORT=""
    for tries in $(seq 100); do
        if [[ -s "$WORK/port" ]] && PORT=$(cat "$WORK/port") \
            && python3 -c 'import sys, urllib.request; urllib.request.urlopen(sys.argv[1], timeout=1)' \
                "http://127.0.0.1:$PORT/ready" 2>/dev/null; then
            return 0
        fi
        sleep 0.1
    done
    echo "the local server did not start"
    return 1
}

stop_server() {
    kill "$SERVER" 2>/dev/null || true
    wait "$SERVER" 2>/dev/null || true
    SERVER=""
}

# A redirect is refused wherever it points (here to a URL the self-tests allow, which serves the right zip), and its
# target is never asked for; a download over 50 MB is refused; http://127.0.0.1 only with the self-tests' variable.
a_redirect_and_a_large_download_are_refused() {
    build_all "$WORK/h"
    deploy_all "$WORK/h"
    start_server "$WORK/h/pre-sign-up.zip" || { stop_server; return 1; }
    relocate pre-sign-up "http://127.0.0.1:$PORT/zip"
    run compare "$WORK/deployed.json" "$WORK/h" --baseline "$BASELINE"
    (( STATUS == 0 )) && [[ "$OUT" == *"= ccit-ci-pre-sign-up: the deployed files are this checkout's"* ]] \
        || { echo "served: $OUT"; stop_server; return 1; }
    relocate pre-sign-up "http://127.0.0.1:$PORT/redirect"
    run compare "$WORK/deployed.json" "$WORK/h" --baseline "$BASELINE"
    (( STATUS == 1 )) && [[ "$OUT" == *"! ccit-ci-pre-sign-up: the deployed code could not be read: its code location answered with a redirect (302), which is not followed."* ]] \
        && [[ "$(cat "$WORK/server.log")" == "/zip"$'\n'"/redirect" && "$OUT" != *127.0.0.1* ]] \
        || { echo "redirect: $OUT"; cat "$WORK/server.log"; stop_server; return 1; }
    relocate pre-sign-up "http://127.0.0.1:$PORT/large"
    run compare "$WORK/deployed.json" "$WORK/h" --baseline "$BASELINE"
    (( STATUS == 1 )) && [[ "$OUT" == *"! ccit-ci-pre-sign-up: the deployed code could not be read: its zip is larger than the 50 MB a Lambda zip upload can be."* ]] \
        || { echo "large: $OUT"; stop_server; return 1; }
    relocate pre-sign-up "http://127.0.0.1:$PORT/zip"
    STATUS=0
    OUT=$(env -u CCIT_CI_TEST_FILE_CODE_URLS python3 "$SCRIPT" compare "$WORK/deployed.json" "$WORK/h" --baseline "$BASELINE" 2>&1) \
        || STATUS=$?
    stop_server
    (( STATUS == 1 )) && [[ "$OUT" == *"! ccit-ci-pre-sign-up: the deployed code could not be read: $REFUSED_URL"* ]] \
        && [[ "$(grep -c '^/zip$' "$WORK/server.log")" == 1 ]] || { echo "without the variable: $OUT"; return 1; }
}

an_accepted_deployment_is_in_sync_until_its_sources_change() {
    build_all "$WORK/r"
    deploy_all "$WORK/r"
    redeploy pre-sign-up edited
    run compare "$WORK/deployed.json" "$WORK/r" --baseline "$BASELINE"
    (( STATUS == 1 )) || { echo "before the record: $OUT"; return 1; }
    run record "$WORK/deployed.json" "$WORK/r" --baseline "$BASELINE"
    (( STATUS == 1 )) && [[ "$OUT" == *"DRIFT ccit-ci-pre-sign-up"*"changed (1): triggers.mjs"*"Nothing recorded."* ]] \
        && [[ ! -e "$BASELINE" ]] || { echo "record without --accept-deployed: $OUT"; return 1; }
    run record "$WORK/deployed.json" "$WORK/r" --baseline "$BASELINE" --accept-deployed
    (( STATUS == 0 )) && jq -e '.functions | (keys | length == 8) and (.["pre-sign-up"].files | keys == ["notes.txt", "triggers.mjs"])
        and all(.[]; (.sources | test("^[0-9a-f]{64}$")) and (.files | all(.[]; test("^[0-9a-f]{64}$"))))' "$BASELINE" >/dev/null \
        || { echo "record: $OUT"; return 1; }
    run compare "$WORK/deployed.json" "$WORK/r" --baseline "$BASELINE"
    (( STATUS == 0 )) && [[ "$OUT" == *"= ccit-ci-pre-sign-up: the deployed files are the ones the baseline accepted"* ]] \
        && [[ "$(grep -c "the deployed files are this checkout's" <<<"$OUT")" == 7 ]] || { echo "after the record: $OUT"; return 1; }
    run check-baseline --baseline "$BASELINE"
    (( STATUS == 0 )) || { echo "check-baseline: $OUT"; return 1; }
    # triggers.mjs changes: the accepted deployment of pre-sign-up is no longer this checkout's.
    echo '// changed' >> "$COPY/lambda/triggers/triggers.mjs"
    run check-baseline --baseline "$BASELINE" --github
    (( STATUS == 1 )) && [[ "$OUT" == *"::error::CHANGED ccit-ci-pre-sign-up"* && "$OUT" != *discard-sender* ]] \
        && [[ "$OUT" == *"purpose=amplify-cognito-client-integ"* ]] || { echo "check-baseline after the change: $OUT"; return 1; }
    build_all "$WORK/r2"
    run compare "$WORK/deployed.json" "$WORK/r2" --baseline "$BASELINE"
    (( STATUS == 1 )) && [[ "$OUT" == *"DRIFT ccit-ci-pre-sign-up: its sources changed since the baseline accepted"* ]] \
        && [[ "$OUT" == *"= ccit-ci-discard-sender"* ]] || { echo "compare after the change: $OUT"; return 1; }
    cp "$INFRA/lambda/triggers/triggers.mjs" "$COPY/lambda/triggers/triggers.mjs"
}

# Sets deployed function $1 to null in deployed.json: not deployed.
undeploy() {
    jq -c --arg k "$1" '.[$k] = null' "$WORK/deployed.json" > "$WORK/d" && mv "$WORK/d" "$WORK/deployed.json"
}

# Sets deployed function $1's CodeSha256 in deployed.json to its deployed zip's.
resha() {
    jq -c --arg k "$1" --arg s "$(sha "$WORK/deployed/$1.zip")" '.[$k].codeSha256 = $s' "$WORK/deployed.json" > "$WORK/d" \
        && mv "$WORK/d" "$WORK/deployed.json"
}

# npm ci links each package's commands into node_modules/.bin/. zip_bytes leaves the links out, and the CI's sender
# was first made with `zip -q -X -r` (no -y), which stores a copy of each link's target: neither side counts them,
# at any depth, so that sender is in sync, and a record holds none.
npm_bin_links_count_on_neither_side() {
    local BUILD="$WORK/build-bin" baseline="$WORK/bin-baseline.json"
    mkdir -p "$BUILD/node_modules/dependency/bin" "$BUILD/node_modules/.bin" \
        "$BUILD/node_modules/dependency/node_modules/inner" "$BUILD/node_modules/dependency/node_modules/.bin"
    cp "$COPY/lambda/custom-sender/index.mjs" "$COPY/lambda/custom-sender/package.json" "$BUILD/"
    echo 'export {};' > "$BUILD/node_modules/dependency/index.js"
    printf '#!/usr/bin/env node\n' > "$BUILD/node_modules/dependency/bin/cli.js"
    printf '#!/usr/bin/env node\n// inner\n' > "$BUILD/node_modules/dependency/node_modules/inner/cli.js"
    ln -s ../dependency/bin/cli.js "$BUILD/node_modules/.bin/dependency"
    ln -s ../inner/cli.js "$BUILD/node_modules/dependency/node_modules/.bin/inner"
    echo '{}' > "$BUILD/node_modules/.package-lock.json"
    build_all "$WORK/bin"
    deploy_all "$WORK/bin"
    # The sender as the CI's was first made.
    rm -f "$WORK/deployed/custom-sender.zip"
    (cd "$BUILD" && rm -f node_modules/.package-lock.json && zip -q -X -r "$WORK/deployed/custom-sender.zip" index.mjs package.json node_modules)
    resha custom-sender
    python3 - "$WORK/deployed/custom-sender.zip" <<'PY' || { echo "the zip -r sender holds no copy of the links"; return 1; }
import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as z:
    names = z.namelist()
    assert z.read("node_modules/.bin/dependency").startswith(b"#!") and "node_modules/dependency/node_modules/.bin/inner" in names, names
PY
    run compare "$WORK/deployed.json" "$WORK/bin" --baseline "$baseline"
    (( STATUS == 0 )) && [[ "$OUT" == *"= ccit-ci-custom-sender: the deployed files are this checkout's"* ]] \
        && [[ "$OUT" != *.bin* && "$OUT" != *DRIFT* ]] || { echo "compare: $OUT"; return 1; }
    run record "$WORK/deployed.json" "$WORK/bin" --baseline "$baseline" --accept-deployed
    (( STATUS == 0 )) && jq -e '.functions["custom-sender"].files | keys
        == ["index.mjs", "node_modules/dependency/bin/cli.js", "node_modules/dependency/index.js",
            "node_modules/dependency/node_modules/inner/cli.js", "package.json"]' "$baseline" >/dev/null \
        || { echo "record: $OUT"; return 1; }
    # Any other file still counts.
    echo '// edited' >> "$BUILD/node_modules/dependency/index.js"
    rm -f "$WORK/deployed/custom-sender.zip"
    (cd "$BUILD" && zip -q -X -r "$WORK/deployed/custom-sender.zip" index.mjs package.json node_modules)
    resha custom-sender
    run compare "$WORK/deployed.json" "$WORK/bin" --baseline "$WORK/bin-none.json"
    (( STATUS == 1 )) && [[ "$OUT" == *"DRIFT ccit-ci-custom-sender"*"changed (1): node_modules/dependency/index.js"* ]] \
        && [[ "$OUT" != *.bin* ]] || { echo "edited: $OUT"; return 1; }
}

# The redeploy that a DRIFT or a CHANGED line asks for checks the purpose tag first and then reruns every scope: a
# plain --apply (phase 1) makes only two of the functions again. If it was run anyway, the functions it did not make
# are not deployed though the baseline records them: DRIFT, and record keeps them rather than drop them. Without a
# baseline, a function that is not deployed is only reported, as on an account that has phase 1 only.
a_baselined_function_that_is_not_deployed_is_drift() {
    local baseline="$WORK/m-baseline.json" suffix
    local advice="first check that the function carries purpose=amplify-cognito-client-integ (aws lambda list-tags), and only then delete it by hand and rerun provision-ci.sh --apply --scope all, which makes it again"
    build_all "$WORK/m"
    deploy_all "$WORK/m"
    redeploy pre-sign-up edited
    run compare "$WORK/deployed.json" "$WORK/m" --baseline "$baseline"
    (( STATUS == 1 )) && [[ "$OUT" == *"DRIFT ccit-ci-pre-sign-up"*"$advice"*"not a plain --apply: that is phase 1"* ]] \
        || { echo "the advice: $OUT"; return 1; }
    deploy_all "$WORK/m"
    run record "$WORK/deployed.json" "$WORK/m" --baseline "$baseline" --accept-deployed
    (( STATUS == 0 )) && [[ "$(jq '.functions | length' "$baseline")" == 8 ]] || { echo "record: $OUT"; return 1; }
    cp "$baseline" "$WORK/m-recorded.json"
    # The five triggers deleted, then a plain --apply, which makes pre-sign-up again but not the other four.
    for suffix in create-auth-challenge define-auth-challenge pre-sign-up-confirmable verify-auth-challenge; do
        undeploy "$suffix"
    done
    run compare "$WORK/deployed.json" "$WORK/m" --baseline "$baseline" --github
    (( STATUS == 1 )) && [[ "$(grep -c '^::error::DRIFT ccit-ci-.*: not deployed, though the baseline records its deployment. Make it again: rerun provision-ci.sh --apply --scope all (not a plain --apply' <<<"$OUT")" == 4 ]] \
        && [[ "$OUT" == *"::error::DRIFT ccit-ci-verify-auth-challenge: not deployed"* && "$(grep -c "are this checkout's" <<<"$OUT")" == 4 ]] \
        || { echo "compare: $OUT"; return 1; }
    run record "$WORK/deployed.json" "$WORK/m" --baseline "$baseline" --accept-deployed
    (( STATUS == 1 )) && [[ "$OUT" == *"Nothing recorded: not deployed, though the baseline records it: ccit-ci-create-auth-challenge, ccit-ci-define-auth-challenge, ccit-ci-pre-sign-up-confirmable, ccit-ci-verify-auth-challenge. Make it again with provision-ci.sh --apply --scope all first"* ]] \
        && cmp -s "$baseline" "$WORK/m-recorded.json" || { echo "record: $OUT"; return 1; }
    run compare "$WORK/deployed.json" "$WORK/m" --baseline "$WORK/m-none.json"
    (( STATUS == 0 )) && [[ "$(grep -c ': not deployed$' <<<"$OUT")" == 4 && "$OUT" != *DRIFT* ]] || { echo "no baseline: $OUT"; return 1; }
    # The CHANGED line gives the same advice.
    echo '// changed' >> "$COPY/ci/lambda/discard-sender/index.mjs"
    run check-baseline --baseline "$baseline"
    cp "$INFRA/ci/lambda/discard-sender/index.mjs" "$COPY/ci/lambda/discard-sender/index.mjs"
    (( STATUS == 1 )) && [[ "$OUT" == *"CHANGED ccit-ci-discard-sender"*"Redeploy it: first check that it carries purpose=amplify-cognito-client-integ (aws lambda list-tags), and only then delete the function and rerun infra/ci/provision-ci.sh --apply --scope all (not a plain --apply"* ]] \
        || { echo "check-baseline: $OUT"; return 1; }
}

# Another region or account, where no ccit-ci- function exists: compare fails rather than pass, record writes no
# empty baseline, and an empty baseline, had one been committed, is no baseline (status 3), never a pass.
nothing_deployed_is_refused() {
    local baseline="$WORK/e-baseline.json" suffix
    build_all "$WORK/e"
    deploy_all "$WORK/e"
    for suffix in "${SUFFIXES[@]}"; do
        undeploy "$suffix"
    done
    run compare "$WORK/deployed.json" "$WORK/e" --baseline "$baseline" --github
    (( STATUS == 1 )) && [[ "$OUT" == *"::error::No ccit-ci- function is deployed where the AWS CLI is pointed: check CCIT_CI_REGION and the account"* ]] \
        || { echo "compare: $OUT"; return 1; }
    run record "$WORK/deployed.json" "$WORK/e" --baseline "$baseline" --accept-deployed
    (( STATUS == 1 )) && [[ "$OUT" == *"Nothing recorded. No ccit-ci- function is deployed"* && ! -e "$baseline" ]] \
        || { echo "record: $OUT"; return 1; }
    echo '{"functions": {}}' > "$baseline"
    run check-baseline --baseline "$baseline" --github
    (( STATUS == 3 )) && [[ "$OUT" == "::warning::No CI Lambda deployment is recorded"*"or it records no function"* ]] \
        || { echo "check-baseline: $OUT"; return 1; }
}

# A deployed function that was not compared (no zip from this checkout: the custom sender's needs npm) is never
# recorded, whatever it holds; the ? line says why.
an_unchecked_function_is_never_recorded() {
    local baseline="$WORK/c-baseline.json"
    build_all "$WORK/c"
    deploy_all "$WORK/c"
    redeploy custom-sender edited
    rm "$WORK/c/custom-sender.zip"
    run compare "$WORK/deployed.json" "$WORK/c" --baseline "$baseline"
    (( STATUS == 0 )) && [[ "$OUT" == *"  ? ccit-ci-custom-sender: not compared: no zip was built from this checkout (it needs npm on PATH)"* ]] \
        || { echo "compare: $OUT"; return 1; }
    run record "$WORK/deployed.json" "$WORK/c" --baseline "$baseline" --accept-deployed
    (( STATUS == 1 )) && [[ "$OUT" == *"Nothing recorded: not compared, since no zip was built from this checkout (the custom sender's needs npm on PATH): ccit-ci-custom-sender."* && ! -e "$baseline" ]] \
        || { echo "record: $OUT"; return 1; }
}

# A deployed zip whose member's deflate data is corrupt, or whose member is marked encrypted: unreadable, exit 1,
# with every other function still compared, and nothing recorded; never a traceback.
a_corrupt_or_encrypted_member_is_unreadable() {
    local baseline="$WORK/k-baseline.json"
    build_all "$WORK/k"
    deploy_all "$WORK/k"
    python3 - "$WORK/deployed/discard-sender.zip" "$WORK/deployed/pre-sign-up.zip" <<'PY'
import struct, sys
corrupt, encrypted = sys.argv[1:]
with open(corrupt, "rb") as f:
    data = bytearray(f.read())
name_length, extra_length = struct.unpack("<HH", data[26:30])
data[30 + name_length + extra_length] = 0x07  # a final block of the reserved type: zlib's "invalid block type"
with open(corrupt, "wb") as f:
    f.write(data)
with open(encrypted, "rb") as f:
    data = bytearray(f.read())
data[6] |= 1  # the local header's encrypted flag
central = data.index(b"PK\x01\x02")
data[central + 8] |= 1  # and the central directory's
with open(encrypted, "wb") as f:
    f.write(data)
PY
    resha discard-sender
    resha pre-sign-up
    run compare "$WORK/deployed.json" "$WORK/k" --baseline "$baseline"
    (( STATUS == 1 )) && [[ "$OUT" == *"! ccit-ci-discard-sender: the deployed code could not be read: it is not a zip this script can read (error)."* ]] \
        && [[ "$OUT" == *"! ccit-ci-pre-sign-up: the deployed code could not be read: it is not a zip this script can read (RuntimeError)."* ]] \
        && [[ "$(grep -c "the deployed files are this checkout's" <<<"$OUT")" == 6 && "$OUT" != *Traceback* ]] \
        || { echo "compare: $STATUS $OUT"; return 1; }
    run record "$WORK/deployed.json" "$WORK/k" --baseline "$baseline" --accept-deployed
    (( STATUS == 1 )) && [[ "$OUT" == *"Nothing recorded: a deployed function's code could not be read."* && ! -e "$baseline" ]] \
        || { echo "record: $STATUS $OUT"; return 1; }
}

no_baseline_is_its_own_status() {
    run check-baseline --baseline "$WORK/none.json" --github
    (( STATUS == 3 )) && [[ "$OUT" == "::warning::No CI Lambda deployment is recorded"* ]]
}

# deployed.json holds presigned URLs: compare and record refuse it (status 4, before any download) unless only its
# owner can read it.
a_deployed_json_others_can_read_is_refused() {
    local mode command baseline="$WORK/p-baseline.json"
    build_all "$WORK/p"
    deploy_all "$WORK/p"
    [[ "$(stat -f '%Lp' "$WORK/deployed.json" 2>/dev/null || stat -c '%a' "$WORK/deployed.json")" == 600 ]] || return 1
    for mode in 644 640 604; do
        chmod "$mode" "$WORK/deployed.json"
        for command in compare record; do
            run "$command" "$WORK/deployed.json" "$WORK/p" --baseline "$baseline" --accept-deployed
            (( STATUS == 4 )) && [[ "$OUT" == "lambda_code.py: deployed.json is mode $mode: it holds presigned URLs"*"Nothing was downloaded." ]] \
                && [[ ! -e "$baseline" ]] || { echo "$command at $mode: $STATUS $OUT"; return 1; }
        done
    done
    chmod 600 "$WORK/deployed.json"
    run compare "$WORK/deployed.json" "$WORK/p" --baseline "$baseline"
    (( STATUS == 0 )) || { echo "at 600: $OUT"; return 1; }
}

# compare and record download into a private ccit-ci-lambda-code.* directory under TMPDIR, and remove it, whether the
# functions are in sync, DRIFT or unreadable.
no_download_directory_is_left_behind() {
    local baseline="$WORK/t-baseline.json"
    build_all "$WORK/t"
    deploy_all "$WORK/t"
    redeploy pre-sign-up edited
    relocate discard-sender "file://$WORK/deployed/missing.zip"
    mkdir -p "$WORK/tmp"
    STATUS=0
    OUT=$(TMPDIR="$WORK/tmp" python3 "$SCRIPT" compare "$WORK/deployed.json" "$WORK/t" --baseline "$baseline" 2>&1) || STATUS=$?
    (( STATUS == 1 )) && [[ "$OUT" == *"DRIFT ccit-ci-pre-sign-up"* && "$OUT" == *"! ccit-ci-discard-sender"* ]] || { echo "$OUT"; return 1; }
    OUT=$(TMPDIR="$WORK/tmp" python3 "$SCRIPT" record "$WORK/deployed.json" "$WORK/t" --baseline "$baseline" 2>&1) || true
    deploy_all "$WORK/t"
    STATUS=0
    OUT=$(TMPDIR="$WORK/tmp" python3 "$SCRIPT" compare "$WORK/deployed.json" "$WORK/t" --baseline "$baseline" 2>&1) || STATUS=$?
    (( STATUS == 0 )) || { echo "$OUT"; return 1; }
    [[ -z "$(ls -A "$WORK/tmp")" ]] || { ls -la "$WORK/tmp"; return 1; }
}

an_unexpected_error_is_status_4() {
    echo 'not json' > "$WORK/broken.json"
    run compare "$WORK/broken.json" "$WORK/z" --baseline "$BASELINE"
    (( STATUS == 4 )) && [[ "$OUT" == *Traceback* ]] || { echo "$STATUS $OUT"; return 1; }
    run nothing
    (( STATUS == 2 ))
}

the_committed_baseline_names_this_checkouts_sources() {
    [[ -f "$CI_DIR/lambda-baseline.json" ]] || { echo "  (no committed baseline yet)"; return 0; }
    STATUS=0
    OUT=$(env -u CCIT_CI_INFRA_DIR python3 "$SCRIPT" check-baseline 2>&1) || STATUS=$?
    (( STATUS == 0 )) || { echo "$OUT"; return 1; }
}

check "zips are deterministic and hold only the function's files" zips_are_deterministic_and_hold_only_the_functions_files
check "compare reads the deployed files: the same files in another zip are in sync, other files are DRIFT" \
    compare_reads_the_deployed_files
check "a deployed zip's member names print escaped: none ends its line or starts a workflow command" member_names_print_escaped
check "only the hosts of Lambda's code buckets are allowed, at a label boundary" real_code_hosts_are_the_only_ones_allowed
check "only an https:// URL on a Lambda code bucket's host is downloaded, and a download that is no zip is refused" \
    only_an_aws_https_url_is_downloaded
check "a redirect is not followed, and a download over 50 MB is refused" a_redirect_and_a_large_download_are_refused
check "record writes the deployed files only with --accept-deployed; they are in sync until the sources change" \
    an_accepted_deployment_is_in_sync_until_its_sources_change
check "npm's node_modules/.bin/ links count on neither side: a sender zipped with zip -r is in sync" \
    npm_bin_links_count_on_neither_side
check "a function the baseline records that is not deployed is DRIFT, and record keeps it; the advice is --scope all" \
    a_baselined_function_that_is_not_deployed_is_drift
check "no function deployed fails compare and record, and an empty baseline is no baseline" nothing_deployed_is_refused
check "a function not compared (no zip from this checkout) is never recorded" an_unchecked_function_is_never_recorded
check "a corrupt or encrypted member is unreadable, exit 1, not a traceback" a_corrupt_or_encrypted_member_is_unreadable
check "no baseline is status 3 with a warning" no_baseline_is_its_own_status
check "a deployed.json anyone but its owner can read is refused, status 4" a_deployed_json_others_can_read_is_refused
check "no download directory is left behind" no_download_directory_is_left_behind
check "an unexpected error is status 4, never 1" an_unexpected_error_is_status_4
check "the committed baseline, when there is one, names this checkout's sources" \
    the_committed_baseline_names_this_checkouts_sources

if (( failures > 0 )); then
    echo "$failures failed"
    exit 1
fi
echo "All passed"
