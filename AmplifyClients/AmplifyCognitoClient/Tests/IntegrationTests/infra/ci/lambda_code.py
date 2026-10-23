#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""The code of the CI Lambdas (provision-ci.sh), and the check that what is deployed is what the repository holds.
No AWS call is made here: provision-ci.sh's `lambda-drift` reads the deployed CodeSha256s and hands them over.

    lambda_code.py zip <suffix> <out.zip> [<build-dir>]
        Writes function <suffix>'s zip, deterministic (the files sorted, each dated 1980-01-01 and mode 644, as
        parity.py builds the sandbox's), so its SHA-256 is the CodeSha256 Lambda reports for that code. The custom
        sender's comes from <build-dir>, where `npm ci` has run (index.mjs, package.json and node_modules).
    lambda_code.py compare <deployed.json> <zips-dir> [--baseline FILE] [--github]
        <deployed.json>: {"<suffix>": "<CodeSha256>" or null when the function does not exist}; <zips-dir> holds
        <suffix>.zip as `zip` built it from this checkout (a missing one is not checked). Each deployed function is
        in sync when its CodeSha256 is its zip's, or else when the baseline records that CodeSha256 for the same
        sources (a function deployed before the zips were deterministic). Prints one line a function, by name, never
        a hash. Exit 1 on any DRIFT, else 0.
    lambda_code.py record <deployed.json> [--baseline FILE]
        Records each deployed function's CodeSha256 with the digest of its sources now, as the baseline: run it only
        when the deployed code is known to be this checkout's (right after a deploy from it).
    lambda_code.py check-baseline [--baseline FILE] [--github]
        Offline: whether the sources each recorded function was deployed from are still this checkout's. Exit 0
        when they are, 1 when one changed (redeploy it: delete the function, rerun provision-ci.sh --apply, then
        lambda-drift --record), 3 when no baseline is recorded.

The baseline is lambda-baseline.json beside this script (CCIT_CI_LAMBDA_BASELINE, or --baseline, names another), and
holds only CodeSha256s and source digests: no identifier, no secret. Only the code is compared. A function's
RuntimeVersionConfig, which Lambda moves by itself with the runtime's automatic updates, is never read.
"""

import base64
import hashlib
import io
import json
import os
import sys
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


def code_sha256(data):
    return base64.b64encode(hashlib.sha256(data).digest()).decode()


def source_digest(suffix):
    directory, files = SOURCES[suffix]
    digest = hashlib.sha256()
    for name in files:
        with open(os.path.join(INFRA, directory, name), "rb") as f:
            digest.update(name.encode() + b"\0" + f.read() + b"\0")
    return digest.hexdigest()


def load_baseline(path):
    try:
        with open(path) as f:
            functions = json.load(f).get("functions")
        return functions if isinstance(functions, dict) else None
    except (OSError, ValueError, AttributeError):
        return None


def say(line, github, level=None):
    print(f"::{level}::{line}" if github and level else line)


def compare(argv):
    with open(argv[1]) as f:
        deployed = json.load(f)
    zips, github = argv[2], "--github" in argv
    baseline = load_baseline(baseline_path(argv)) or {}
    drift = False
    for suffix in sorted(SOURCES):
        name = PREFIX + suffix
        sha = deployed.get(suffix)
        zip_path = os.path.join(zips, f"{suffix}.zip")
        if sha is None:
            say(f"  - {name}: not deployed", github)
            continue
        if not os.path.isfile(zip_path):
            say(f"  ? {name}: not checked (no zip built from this checkout)", github)
            continue
        with open(zip_path, "rb") as f:
            built = code_sha256(f.read())
        recorded = baseline.get(suffix) or {}
        if sha == built:
            say(f"  = {name}: the deployed code is this checkout's", github)
        elif recorded.get("codeSha256") == sha and recorded.get("sources") == source_digest(suffix):
            say(f"  = {name}: the deployed code is the recorded deployment of this checkout's sources", github)
        else:
            reason = ("its sources changed since the recorded deployment" if recorded.get("codeSha256") == sha
                      else "the deployed code is neither this checkout's nor the recorded deployment's")
            say(f"DRIFT {name}: {reason}. Delete the function by hand and rerun provision-ci.sh --apply, which makes "
                f"it again from this checkout; then provision-ci.sh lambda-drift --record.", github, "error")
            drift = True
    return 1 if drift else 0


def record(argv):
    with open(argv[1]) as f:
        deployed = json.load(f)
    functions = {suffix: {"codeSha256": sha, "sources": source_digest(suffix)}
                 for suffix, sha in sorted(deployed.items()) if suffix in SOURCES and isinstance(sha, str)}
    path = baseline_path(argv)
    with open(path + ".tmp", "w") as f:
        json.dump({"functions": functions}, f, indent=1, sort_keys=True)
        f.write("\n")
    os.replace(path + ".tmp", path)
    print(f"Recorded {len(functions)} deployed functions in {os.path.basename(path)}; commit it.")
    return 0


def check_baseline(argv):
    github = "--github" in argv
    baseline = load_baseline(baseline_path(argv))
    if baseline is None:
        say("No CI Lambda deployment is recorded (infra/ci/lambda-baseline.json): run infra/ci/provision-ci.sh "
            "lambda-drift (read-only), then lambda-drift --record once it is in sync, and commit the file.",
            github, "warning")
        return 3
    changed = [suffix for suffix, entry in sorted(baseline.items())
               if suffix in SOURCES and entry.get("sources") != source_digest(suffix)]
    for suffix in changed:
        say(f"CHANGED {PREFIX}{suffix}: its sources are not the ones its recorded deployment was built from. "
            f"Redeploy it (delete the function, rerun infra/ci/provision-ci.sh --apply), then lambda-drift --record.",
            github, "error")
    if not changed:
        say(f"The sources of the {len(baseline)} recorded CI Lambdas are the ones they were deployed from.", github)
    return 1 if changed else 0


def main(argv):
    if argv[:1] == ["zip"] and len(argv) in (3, 4) and argv[1] in SOURCES:
        data = zip_bytes(argv[1], argv[3] if len(argv) == 4 else None)
        with open(argv[2], "wb") as f:
            f.write(data)
        return 0
    if argv[:1] == ["compare"] and len(argv) >= 3:
        return compare(argv)
    if argv[:1] == ["record"] and len(argv) >= 2:
        return record(argv)
    if argv[:1] == ["check-baseline"]:
        return check_baseline(argv)
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
