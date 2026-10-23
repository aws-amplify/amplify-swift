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
        Exit 0 while the key has more than WARN_DAYS (30) days left; 1 within them, or once it has expired; 3 when no
        expiry is recorded (or the record does not read). Prints one line; with --github, as a GitHub Actions
        annotation (::warning:: within the 30 days or unrecorded, ::error:: once expired).
    code_sink_key.py record <expires-epoch-seconds> [--record FILE]
        Writes the record (provision-ci.sh, after it reads, creates or extends the key). Prints the date.

--record (or CCIT_CI_KEY_RECORD) names another record file than the committed one, as the self-tests do. Within the
30 days, `infra/ci/provision-ci.sh --apply --scope all` extends the key in place (the same id, so the uploaded files
stay valid) and records the new date; once it has expired, that rerun makes a new key, and the two uploaded files
that name the old one must be replaced by hand (--upload never overwrites).
"""

import datetime
import json
import os
import sys

WARN_DAYS = 30
DEFAULT_RECORD = os.path.join(os.path.dirname(os.path.abspath(__file__)), "code-sink-key-expiry.json")
RENEW = ("rerun infra/ci/provision-ci.sh --apply --scope all, which extends it to 364 days from then, and commit "
         "the expiry it records")


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
                       f"on CI fail until it is replaced. {RENEW[0].upper() + RENEW[1:]}; it makes a new key, and "
                       f"the two uploaded files that name the old one must then be replaced by hand.")
        elif left <= WARN_DAYS:
            level, status = "warning", 1
            message = (f"The CI code sink's API key expires on {expires.isoformat()}, in {left} days. Before then, "
                       f"{RENEW}.")
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
    if argv[:1] == ["record"] and len(argv) >= 2 and argv[1].isdigit():
        return record(argv)
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
