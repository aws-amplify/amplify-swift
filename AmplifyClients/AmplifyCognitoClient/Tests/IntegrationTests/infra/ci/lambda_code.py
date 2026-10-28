#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""The code of the CI Lambdas (provision-ci.sh), and the check that what is deployed is what the repository holds.
No AWS call is made here: provision-ci.sh's `lambda-drift` reads each function with GetFunction (read-only) and
hands over its CodeSha256 and the presigned URL of its deployed zip, which this script downloads and reads.

    lambda_code.py zip <suffix> <out.zip> [<build-dir>]
        Writes function <suffix>'s zip, deterministic (the files sorted, each dated 1980-01-01 and mode 644, as
        parity.py builds the sandbox's). The custom sender's comes from <build-dir>, where `npm ci` has run
        (index.mjs, package.json and node_modules).
    lambda_code.py compare <deployed.json> <zips-dir> [--baseline FILE] [--github]
        <deployed.json>: {"<suffix>": {"codeSha256": …, "location": <presigned URL>} or null when the function
        does not exist}, a mode-600 file (the URL is a credential for a few minutes: it is never printed, nor put on
        a command line). <zips-dir> holds <suffix>.zip as `zip` built it from this checkout (a missing one is not
        compared). Each deployed zip is downloaded into a private temporary directory and read file by file; the
        function is in sync when its files (paths and SHA-256 of their contents) are its checkout zip's, or else
        when they are the files the baseline accepted for the same sources. The compression, dates and modes in
        the zip, and so its CodeSha256, do not count: CodeSha256 is printed only as a note. Nor do the custom
        sender's node_modules/.bin/ entries: npm's links to its packages' commands, which Lambda never loads, and
        which a zip stores as links or as copies of their targets depending on how it was made. Prints, a function,
        one line by name and, when it differs, which files differ (names escaped), never a hash. A function the
        baseline records that is not deployed is DRIFT too. Exit 1 on any DRIFT, a deployed zip that cannot be
        read, or no ccit-ci- function deployed at all (another region or account), else 0.
    lambda_code.py record <deployed.json> <zips-dir> [--baseline FILE] [--accept-deployed]
        Prints the same per-file comparison, then records each deployed function's files (paths and content
        hashes), with the digest of its sources now, as the baseline. Without --accept-deployed it records nothing
        and exits 1: the operator accepts what is deployed, as the comparison shows it, by passing it. It records
        nothing either (exit 1) while a deployed function could not be read or was not compared (no zip from this
        checkout: the custom sender's needs npm), a function the baseline records is not deployed, or no function
        is deployed at all.
    lambda_code.py check-baseline [--baseline FILE] [--github]
        Offline: whether the sources each recorded function was accepted for are still this checkout's. Exit 0
        when they are, 1 when one changed (redeploy it, then lambda-drift), 3 when no baseline is recorded (or it
        records no function).

Any other exit status is a failure of the script itself (4: an unexpected error, with its traceback, or a
<deployed.json> that anyone but its owner can read; 2: usage).

The baseline is lambda-baseline.json beside this script (CCIT_CI_LAMBDA_BASELINE, or --baseline, names another), and
holds only file paths, content hashes and source digests: no identifier, no secret. Only the code is compared. A
function's RuntimeVersionConfig, which Lambda moves by itself with the runtime's automatic updates, is never read.

A deployed zip's URL must be https:// on the host of one of Lambda's code buckets: <bucket>.s3.<region>.amazonaws.com
(or <bucket>.s3.amazonaws.com), the bucket's name ending in -tasks, as GetFunction's example in the Lambda
documentation (awslambda-us-west-2-tasks.s3.us-west-2.amazonaws.com) and the code buckets seen in us-east-1
(prod-04-2014-tasks and others) are. It is a pattern, not a list: Lambda does not document the names, and anyone can
name an S3 bucket <something>-tasks, so it keeps out other AWS endpoints (execute-api, path-style S3, most customer
buckets) but cannot prove the bucket is Lambda's: that the URL comes from GetFunction's response does. A host
outside the pattern only makes lambda-drift say that the code could not be read, naming no URL.
A redirect is never followed (S3 answers a presigned GET with the object), and a download larger than a zip Lambda
takes directly (50 MB; provision-ci.sh uploads them with --zip-file) is refused. The self-tests set
CCIT_CI_TEST_FILE_CODE_URLS=1, which also lets through a file:// URL, for the zips their fake AWS CLI serves from local
files, and an http:// URL on 127.0.0.1, for a local server.
"""

import base64
import hashlib
import io
import json
import os
import re
import shutil
import stat
import sys
import tempfile
import traceback
import urllib.parse
import urllib.request
import zipfile

CI_DIR = os.path.dirname(os.path.abspath(__file__))
INFRA = os.environ.get("CCIT_CI_INFRA_DIR") or os.path.dirname(CI_DIR)
PREFIX = "ccit-ci-"
# Each function's sources, relative to infra/: the files its zip holds (the custom sender's also holds node_modules,
# which its package-lock.json pins, so the lock file stands for them in the digest).
TRIGGERS = ("lambda/triggers", ("triggers.mjs",))
SOURCES = {
    "pre-sign-up": TRIGGERS,
    "pre-sign-up-confirmable": TRIGGERS,
    "define-auth-challenge": TRIGGERS,
    "create-auth-challenge": TRIGGERS,
    "verify-auth-challenge": TRIGGERS,
    "discard-sender": ("ci/lambda/discard-sender", ("index.mjs",)),
    "new-password-reset": ("ci/lambda/new-password-reset", ("index.mjs",)),
    "custom-sender": ("lambda/custom-sender", ("index.mjs", "package.json", "package-lock.json")),
}
# Lambda takes a zip of up to 50 MB directly (provision-ci.sh's --zip-file) and 250 MB unzipped; anything past the
# first is not one of these, and anything far past the second neither.
MAX_ZIP_BYTES = 50 * 1024 * 1024
MAX_UNZIPPED_BYTES = 512 * 1024 * 1024
# How many paths of each kind a difference lists before it says how many more.
LISTED = 20
# A redeploy reruns every scope: a plain --apply is phase 1, which makes only pre-sign-up and discard-sender again,
# and adds the invoke permissions of its own pool only.
ALL_SCOPES = "provision-ci.sh --apply --scope all"
PHASE_1 = ("(not a plain --apply: that is phase 1, which makes only two of the functions and leaves the other pools "
           "without their invoke permissions)")
REDEPLOY = ("Redeploy it: first check that the function carries purpose=amplify-cognito-client-integ (aws lambda "
            f"list-tags), and only then delete it by hand and rerun {ALL_SCOPES}, which makes it again from this "
            f"checkout {PHASE_1}; or, once you accept the deployed files, run provision-ci.sh lambda-drift --record "
            "--accept-deployed.")
NONE_DEPLOYED = ("No ccit-ci- function is deployed where the AWS CLI is pointed: check CCIT_CI_REGION and the "
                 "account of the profile before anything else.")


def baseline_path(argv):
    if "--baseline" in argv:
        return argv[argv.index("--baseline") + 1]
    return os.environ.get("CCIT_CI_LAMBDA_BASELINE") or os.path.join(CI_DIR, "lambda-baseline.json")


def deterministic_zip(root, files):
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as archive:
        for relative in sorted(files):
            info = zipfile.ZipInfo(relative, date_time=(1980, 1, 1, 0, 0, 0))
            info.external_attr = 0o644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            with open(os.path.join(root, relative), "rb") as f:
                archive.writestr(info, f.read())
    return buffer.getvalue()


def zip_bytes(suffix, build_dir=None):
    directory, files = SOURCES[suffix]
    if suffix != "custom-sender":
        return deterministic_zip(os.path.join(INFRA, directory), files)
    if not build_dir:
        raise SystemExit("the custom sender's zip needs its build directory, where npm ci has run.")
    names = ["index.mjs", "package.json"]
    for walk_root, _, walk_files in os.walk(os.path.join(build_dir, "node_modules")):
        for name in walk_files:
            path = os.path.join(walk_root, name)
            if not os.path.islink(path) and name != ".package-lock.json":
                names.append(os.path.relpath(path, build_dir))
    return deterministic_zip(build_dir, names)


# npm's links to its packages' commands (node_modules/.bin/, at any depth): Lambda never loads them, zip_bytes leaves
# the links out, and a `zip -r` without -y (how the CI's functions were first made) stores a copy of each target.
NPM_BIN = re.compile(r"(?:^|/)node_modules/\.bin/")


def compared_files(suffix, files):
    """The files of function `suffix` that the comparison counts: the custom sender's without npm's .bin entries."""
    if suffix != "custom-sender":
        return files
    return {path: digest for path, digest in files.items() if not NPM_BIN.search(path)}


def code_sha256(data):
    return base64.b64encode(hashlib.sha256(data).digest()).decode()


def source_digest(suffix):
    directory, files = SOURCES[suffix]
    digest = hashlib.sha256()
    for name in files:
        with open(os.path.join(INFRA, directory, name), "rb") as f:
            digest.update(name.encode() + b"\0" + f.read() + b"\0")
    return digest.hexdigest()


class NotPrivate(Exception):
    """A <deployed.json> that anyone but its owner can read: the presigned URLs in it are credentials."""


class Unreadable(Exception):
    """A deployed zip that could not be downloaded or read; the message names no URL."""


def manifest(data):
    """{path: SHA-256 hex of its contents} for every file in zip `data` (directory entries left out). The members
    are read one by one, never extracted, so no path in the zip can write anywhere."""
    files, total = {}, 0
    try:
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            for info in archive.infolist():
                if info.is_dir():
                    continue
                total += info.file_size
                if total > MAX_UNZIPPED_BYTES:
                    raise Unreadable("it unzips to more than a Lambda function can hold")
                digest = hashlib.sha256()
                with archive.open(info) as member:
                    for chunk in iter(lambda: member.read(1 << 20), b""):
                        digest.update(chunk)
                files[info.filename] = digest.hexdigest()
    except (zipfile.BadZipFile, zipfile.LargeZipFile, OSError, ValueError, NotImplementedError) as error:
        raise Unreadable(f"it is not a zip this script can read ({type(error).__name__})") from None
    return files


AWS_DOMAIN = ".amazonaws.com"
# What comes before AWS_DOMAIN in the host of a Lambda code bucket (see the docstring): <bucket>.s3[.<region>].
CODE_BUCKET = re.compile(r"[a-z0-9][a-z0-9-]*-tasks\.s3(?:\.[a-z0-9-]+)?")


def allowed_host(host):
    """Whether `host` is a Lambda code bucket's: it ends in .amazonaws.com, at a label boundary, and what precedes
    that is <bucket>-tasks.s3 or <bucket>-tasks.s3.<region>."""
    host = host.lower()
    return host.endswith(AWS_DOMAIN) and CODE_BUCKET.fullmatch(host[:-len(AWS_DOMAIN)]) is not None


def allowed_url(url):
    parsed = urllib.parse.urlsplit(url)
    if parsed.scheme == "https":
        return allowed_host(parsed.hostname or "")
    if os.environ.get("CCIT_CI_TEST_FILE_CODE_URLS") != "1":
        return False
    return parsed.scheme == "file" or (parsed.scheme == "http" and parsed.hostname == "127.0.0.1")


class RefuseRedirects(urllib.request.HTTPRedirectHandler):
    """Ends the download at a redirect: the allowlist holds for the code location, not for where it points."""

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        raise Unreadable(f"its code location answered with a redirect ({code}), which is not followed")


# urlopen's default opener follows redirects to any http, https or ftp URL; this one stops at them.
OPENER = urllib.request.build_opener(RefuseRedirects)


def download(url, directory, suffix):
    """The deployed zip's bytes, downloaded into `directory` (private) as <suffix>.zip."""
    try:
        allowed = isinstance(url, str) and allowed_url(url)
    except ValueError:  # urlsplit's, for a malformed netloc such as [::1].amazonaws.com
        raise Unreadable("its code location is not a well-formed URL") from None
    if not allowed:
        raise Unreadable("its code location is not an https:// URL on a Lambda code bucket's S3 host")
    path = os.path.join(directory, f"{suffix}.zip")
    try:
        with OPENER.open(url, timeout=60) as response, open(path, "wb") as out:
            size = 0
            for chunk in iter(lambda: response.read(1 << 20), b""):
                size += len(chunk)
                if size > MAX_ZIP_BYTES:
                    raise Unreadable(f"its zip is larger than the {MAX_ZIP_BYTES >> 20} MB a Lambda zip upload can be")
                out.write(chunk)
    except Unreadable:
        raise
    except Exception as error:  # urllib's errors can quote the URL: only the error's kind is told.
        raise Unreadable(f"its zip could not be downloaded ({type(error).__name__})") from None
    with open(path, "rb") as f:
        return f.read()


def difference(deployed, built):
    """(changed, only deployed, only in the checkout): sorted path lists."""
    changed = sorted(p for p in deployed.keys() & built.keys() if deployed[p] != built[p])
    return changed, sorted(deployed.keys() - built.keys()), sorted(built.keys() - deployed.keys())


def shown(path):
    """`path` as it prints: a zip member's name is the deployed zip's to choose, so a backslash and every character
    that is not printable (a newline, a carriage return, an escape, a line separator) are escaped as in a Python
    string. A name can then never end the line it is on, nor start a line, and so never a workflow command. A `#` is
    escaped too (as \\x23), since the runner's legacy commands (##[…]) are found anywhere in a line."""
    return "".join(c if c.isprintable() and c not in "\\#" else "\\x23" if c == "#"
                   else c.encode("unicode_escape").decode("ascii") for c in path)


def difference_lines(changed, extra, missing):
    lines = []
    for label, paths in (("changed", changed), ("only deployed", extra), ("only in the checkout", missing)):
        if paths:
            shown_paths = ", ".join(shown(path) for path in paths[:LISTED])
            more = f", and {len(paths) - LISTED} more" if len(paths) > LISTED else ""
            lines.append(f"      {label} ({len(paths)}): {shown_paths}{more}")
    return lines


def load_baseline(path):
    try:
        with open(path) as f:
            functions = json.load(f).get("functions")
        return functions if isinstance(functions, dict) else None
    except (OSError, ValueError, AttributeError):
        return None


def say(line, github, level=None):
    print(f"::{level}::{line}" if github and level else line)


def compared(argv):
    """Each function's comparison, in name order: (status, files, lines). `status` is "absent", "missing" (not
    deployed, though the baseline records it), "unchecked", "unreadable", "same", "accepted" or "drift"; `files` the
    deployed files as compared (None when there are none to record); `lines` what to print, each with the level of
    its annotation (None for a plain line)."""
    mode = stat.S_IMODE(os.stat(argv[1]).st_mode)
    if mode & 0o077:
        raise NotPrivate(f"{os.path.basename(argv[1])} is mode {mode:o}: it holds presigned URLs, which are "
                         "credentials, so only its owner may read it (mode 600). Nothing was downloaded.")
    with open(argv[1]) as f:
        deployed = json.load(f)
    zips = argv[2]
    baseline = load_baseline(baseline_path(argv)) or {}
    results = {}
    workdir = tempfile.mkdtemp(prefix="ccit-ci-lambda-code.")
    try:
        for suffix in sorted(SOURCES):
            name = PREFIX + suffix
            entry = deployed.get(suffix)
            if not isinstance(entry, dict) and suffix in baseline:
                results[suffix] = ("missing", None,
                                   [(f"DRIFT {name}: not deployed, though the baseline records its deployment. Make "
                                     f"it again: rerun {ALL_SCOPES} {PHASE_1}, then lambda-drift.", "error")])
                continue
            if not isinstance(entry, dict):
                results[suffix] = ("absent", None, [(f"  - {name}: not deployed", None)])
                continue
            try:
                files = compared_files(suffix, manifest(download(entry.get("location"), workdir, suffix)))
            except Unreadable as error:
                results[suffix] = ("unreadable", None,
                                   [(f"! {name}: the deployed code could not be read: {error}.", "error")])
                continue
            zip_path = os.path.join(zips, f"{suffix}.zip")
            if not os.path.isfile(zip_path):
                why = " (it needs npm on PATH)" if suffix == "custom-sender" else ""
                results[suffix] = ("unchecked", files,
                                   [(f"  ? {name}: not compared: no zip was built from this checkout{why}", None)])
                continue
            with open(zip_path, "rb") as f:
                built_bytes = f.read()
            built = compared_files(suffix, manifest(built_bytes))
            note = ("      CodeSha256, a note only: the same as this checkout's zip's"
                    if entry.get("codeSha256") == code_sha256(built_bytes)
                    else "      CodeSha256, a note only: not this checkout's zip's (the files decide)")
            recorded = baseline.get(suffix) if isinstance(baseline.get(suffix), dict) else {}
            detail = [(line, None) for line in difference_lines(*difference(files, built))]
            if files == built:
                results[suffix] = ("same", files,
                                   [(f"  = {name}: the deployed files are this checkout's", None), (note, None)])
            elif recorded.get("files") == files and recorded.get("sources") == source_digest(suffix):
                results[suffix] = ("accepted", files,
                                   [(f"  = {name}: the deployed files are the ones the baseline accepted for this "
                                     f"checkout's sources. Against this checkout:", None)] + detail + [(note, None)])
            else:
                reason = ("its sources changed since the baseline accepted its deployed files"
                          if recorded.get("files") == files
                          else "the deployed files are neither this checkout's nor the ones the baseline accepted")
                results[suffix] = ("drift", files,
                                   [(f"DRIFT {name}: {reason}. Against this checkout:", "error")] + detail
                                   + [(note, None), (f"      {REDEPLOY}", None)])
    finally:
        shutil.rmtree(workdir, ignore_errors=True)
    return results


def print_results(results, github):
    for _, _, lines in results.values():
        for line, level in lines:
            say(line, github, level)


def none_deployed(results):
    return all(status in ("absent", "missing") for status, _, _ in results.values())


def compare(argv):
    github = "--github" in argv
    results = compared(argv)
    print_results(results, github)
    if none_deployed(results):
        say(NONE_DEPLOYED, github, "error")
        return 1
    return 1 if any(status in ("drift", "missing", "unreadable") for status, _, _ in results.values()) else 0


def with_status(results, wanted):
    return ", ".join(PREFIX + suffix for suffix, (status, _, _) in results.items() if status == wanted)


def record(argv):
    results = compared(argv)
    print_results(results, False)
    if none_deployed(results):
        print(f"Nothing recorded. {NONE_DEPLOYED}")
        return 1
    if any(status == "unreadable" for status, _, _ in results.values()):
        print("Nothing recorded: a deployed function's code could not be read.")
        return 1
    if missing := with_status(results, "missing"):
        print(f"Nothing recorded: not deployed, though the baseline records it: {missing}. Make it again with "
              f"{ALL_SCOPES} first; a record never drops a function.")
        return 1
    if unchecked := with_status(results, "unchecked"):
        print(f"Nothing recorded: not compared, since no zip was built from this checkout (the custom sender's needs "
              f"npm on PATH): {unchecked}. Rerun where it can be built: only what was compared can be accepted.")
        return 1
    if "--accept-deployed" not in argv:
        print("Nothing recorded. The baseline accepts the deployed files, as compared above, for this checkout's "
              "sources: rerun with --accept-deployed once you have checked every difference.")
        return 1
    functions = {suffix: {"files": files, "sources": source_digest(suffix)}
                 for suffix, (_, files, _) in results.items() if files is not None}
    path = baseline_path(argv)
    with open(path + ".tmp", "w") as f:
        json.dump({"functions": functions}, f, indent=1, sort_keys=True)
        f.write("\n")
    os.replace(path + ".tmp", path)
    print(f"Recorded the deployed files of {len(functions)} functions in {os.path.basename(path)}; commit it.")
    return 0


def check_baseline(argv):
    github = "--github" in argv
    baseline = load_baseline(baseline_path(argv))
    if not baseline:  # None, or a baseline of no function (one recorded against another region or account)
        say("No CI Lambda deployment is recorded (infra/ci/lambda-baseline.json, or it records no function): run "
            "infra/ci/provision-ci.sh lambda-drift (read-only), then lambda-drift --record --accept-deployed once "
            "you accept what it shows, and commit the file.", github, "warning")
        return 3
    changed = [suffix for suffix, entry in sorted(baseline.items())
               if suffix in SOURCES and (not isinstance(entry, dict) or entry.get("sources") != source_digest(suffix))]
    for suffix in changed:
        say(f"CHANGED {PREFIX}{suffix}: its sources are not the ones its recorded deployment was accepted for. "
            f"Redeploy it: first check that it carries purpose=amplify-cognito-client-integ (aws lambda list-tags), "
            f"and only then delete the function and rerun infra/ci/{ALL_SCOPES} {PHASE_1}. Then record it again: "
            f"lambda-drift --record --accept-deployed.", github, "error")
    if not changed:
        say(f"The sources of the {len(baseline)} recorded CI Lambdas are the ones their deployment was accepted for.",
            github)
    return 1 if changed else 0


def main(argv):
    if argv[:1] == ["zip"] and len(argv) in (3, 4) and argv[1] in SOURCES:
        data = zip_bytes(argv[1], argv[3] if len(argv) == 4 else None)
        with open(argv[2], "wb") as f:
            f.write(data)
        return 0
    if argv[:1] == ["compare"] and len(argv) >= 3:
        return compare(argv)
    if argv[:1] == ["record"] and len(argv) >= 3:
        return record(argv)
    if argv[:1] == ["check-baseline"]:
        return check_baseline(argv)
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except NotPrivate as refusal:
        print(f"lambda_code.py: {refusal}", file=sys.stderr)
        sys.exit(4)
    except Exception:  # Not a status the callers act on (1, 3): the script itself failed.
        traceback.print_exc()
        sys.exit(4)
