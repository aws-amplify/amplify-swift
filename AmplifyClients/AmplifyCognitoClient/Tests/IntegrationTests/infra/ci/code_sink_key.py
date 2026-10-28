#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""The reminder for the CI code sink's API key (provision-ci.sh, phase 2), which lives 364 days. The key's expiry is
recorded, as a date only (no identifier, no secret), in code-sink-key-expiry.json beside this script, committed, so
the reminder needs no AWS call and no credentials: a scheduled job, or any CI run, can read it.

    code_sink_key.py check [--today YYYY-MM-DD] [--github] [--record FILE]
        Exit 0 while the key has more than WARN_DAYS (30) days left; 1 within them, or once it has expired (renew
        it); 3 when no expiry is recorded (or the record does not read). Prints one line; with --github, as a GitHub
        Actions annotation (::warning:: within the 30 days or unrecorded, ::error:: on the expiry date, when the key
        may already have expired, and after it).
    code_sink_key.py reuse-days
        Prints REUSE_DAYS (31): provision-ci.sh reuses a key only while it lives more than that many days from the
        run, and extends it otherwise (until it expires).
    code_sink_key.py record <expires-epoch-seconds> [--record FILE]
        Writes the record (provision-ci.sh, once it has read, created or extended the key, and the uploaded files
        that name a key name that one). Prints the date.

Any other exit status is a failure of the script itself (2: usage; 4: an unexpected error, with its traceback),
never a status of the key.

--record (or CCIT_CI_KEY_RECORD) names another record file than the committed one, as the self-tests do. Within the
30 days, `infra/ci/provision-ci.sh --apply --scope all` extends the key in place (the same id, so the uploaded files
stay valid) and records the new date. An expired key cannot be extended: that rerun makes a new key, but the two
uploaded files that name the old one (UPLOADED_FILES) are never rewritten (--upload never overwrites), so it records
the new expiry only once they no longer name the old key: delete both by hand, after checking their tag, and rerun
with --upload, which uploads them again with the new key.
"""

import datetime
import json
import os
import sys
import traceback

WARN_DAYS = 30
# The record is a date only, and `check` counts whole UTC days, so a key it gives WARN_DAYS days left can still live up
# to a second short of WARN_DAYS + 1 days from now. provision-ci.sh reuses a key only while it lives more than
# REUSE_DAYS (it reads them from `reuse-days`), so a rerun extends every key this check warns about. A key with
# WARN_DAYS + 1 days left passes, and a rerun may extend it a day early or reuse it.
REUSE_DAYS = WARN_DAYS + 1
DEFAULT_RECORD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "code-sink-key-expiry.json")
UPLOADED_FILES = ("ccit-ci-default-amplify_outputs.json", "ccit-ci-email-alias-codes-amplify_outputs.json")
EXTEND = ("rerun infra/ci/provision-ci.sh --apply --scope all, which extends it in place to 364 days from then (the "
          "same key, so the uploaded files that name it stay valid), and commit the expiry it records")
REPLACE = ("An expired key cannot be extended. infra/ci/provision-ci.sh --apply --scope all makes a new one, but the "
           "two uploaded files that name the key (auth/cognito-client-ci/" + " and ".join(UPLOADED_FILES) + ") are "
           "never overwritten, so it records the new key's expiry only while no uploaded file names the old key: check "
           "that each carries "
           "purpose=amplify-cognito-client-integ, delete both by hand, rerun infra/ci/provision-ci.sh --apply "
           "--scope all --upload, which uploads them again with the new key and records its expiry, and commit "
           "the record.")


def record_path(argv):
    if "--record" in argv:
        return argv[argv.index("--record") + 1]
    return os.environ.get("CCIT_CI_KEY_RECORD") or DEFAULT_RECORD


def read_expiry(path):
    """The recorded expiry as a date, or None when there is no record, or it does not read."""
    try:
        with open(path) as f:
            value = json.load(f).get("expires")
        return datetime.date.fromisoformat(value) if isinstance(value, str) else None
    except (OSError, ValueError, AttributeError):
        return None


def check(argv):
    github = "--github" in argv
    today = (datetime.date.fromisoformat(argv[argv.index("--today") + 1]) if "--today" in argv
             else datetime.datetime.now(datetime.timezone.utc).date())
    expires = read_expiry(record_path(argv))
    if expires is None:
        level, status = "warning", 3
        message = ("The CI code sink's API key has no recorded expiry (infra/ci/code-sink-key-expiry.json). Record it: "
                   "infra/ci/provision-ci.sh key-expiry --record (read-only), then commit the file.")
    else:
        left = (expires - today).days
        if left < 0:
            level, status = "error", 1
            message = (f"The CI code sink's API key expired on {expires.isoformat()}: the client's code-reading tests "
                       f"on CI fail until it is replaced. {REPLACE}")
        elif left == 0:
            # The date alone does not tell whether the key has expired yet: both paths.
            level, status = "error", 1
            message = (f"The CI code sink's API key expires today, {expires.isoformat()}, at an hour the record does "
                       f"not hold. If it has not expired yet, {EXTEND}. If it has, the client's code-reading tests on "
                       f"CI fail until it is replaced. {REPLACE}")
        elif left <= WARN_DAYS:
            level, status = "warning", 1
            message = (f"The CI code sink's API key expires on {expires.isoformat()}, in {left} days. Before then, "
                       f"{EXTEND}.")
        else:
            level, status = None, 0
            message = f"The CI code sink's API key expires on {expires.isoformat()}, in {left} days."
    print(f"::{level}::{message}" if github and level else message)
    return status


def record(argv):
    expires = datetime.datetime.fromtimestamp(int(argv[1]), datetime.timezone.utc).date()
    path = record_path(argv)
    with open(path + ".tmp", "w") as f:
        json.dump({"expires": expires.isoformat()}, f)
        f.write("\n")
    os.replace(path + ".tmp", path)
    print(expires.isoformat())
    return 0


def main(argv):
    if argv[:1] == ["check"]:
        return check(argv)
    if argv == ["reuse-days"]:
        print(REUSE_DAYS)
        return 0
    if argv[:1] == ["record"] and len(argv) >= 2 and argv[1].isdigit():
        return record(argv)
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1:]))
    except Exception:  # Not a status of the key (1, 3): the script itself failed.
        traceback.print_exc()
        sys.exit(4)
