#!/usr/bin/env python3
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
"""The snapshot that proves provision-ci.sh changed nothing it did not create (provision-ci.sh snapshot and
verify-unchanged). No AWS call is made here.

    snapshot.py build <raw.ndjson> <snapshot.json> <tag-value>
        raw.ndjson: one {"kind", "id", "name", "doc"} per line, as provision-ci.sh's `record` writes them.
        Writes <snapshot.json> (mode 600, version 2): each resource under "<kind>:<first 16 hex of SHA-256(id)>",
        with a masked label and the SHA-256 of its normalized document (`normalize`) in canonical JSON; and
        <snapshot>.docs.json (mode 600), the documents themselves, so a later diff can name the fields that
        changed. Prints counts only.
    snapshot.py verify <before.json> <after.json> [--allow-foreign-additions]
        Fails (exit 1) on a resource changed or removed since <before>, and on one added that is not a ccit-ci-
        resource (unless allowed). A ccit-ci- addition is expected, and so is a change to a ccit-ci- resource: a
        rerun that adds a pool updates some of the script's own (a Lambda it gives a new invoke permission, say),
        and each is listed. A ccit-ci- resource removed still fails. An AWS-managed KMS alias (alias/aws/*) that
        appears is listed as such and does not fail: AWS creates one the first time a service uses its default key.
        Where both snapshots have their .docs.json, the hashes are made again from the normalized documents, so a
        version-1 snapshot (hashed unnormalized) compares with a version-2 one. Prints kinds, masked labels and
        field names, never values or identifiers.

The documents leave out only what AWS changes by itself, with no change to the resource:
    - a user pool's EstimatedNumberOfUsers, which every sign-up and deletion of a CI run moves;
    - a Lambda's State, StateReason(Code) and LastUpdateStatus(Reason)(Code): Lambda makes a function idle for
      weeks Inactive, and Active again at its next invoke;
    - an IAM role's RoleLastUsed (when ListRoles returns it), which every use of the role moves.
LastModifiedDate stays in: Cognito moves it only when a pool or app client is updated, not on sign-ups, so it is
the plainest sign of a change.

A document is normalized before it is hashed, so the same resource listed in another order is no change: AWS gives
no order for these lists, and IAM and Cognito return them as stored, which a rewrite of the same content can
reorder. Lists whose order means something (a Lambda's Layers) keep it.
"""

import hashlib
import json
import os
import re
import sys

OURS = re.compile(r"(^|/)(ccit-ci-|ccit_ci_|alias/ccit-ci-|/aws/lambda/ccit-ci-|/ccit-ci/)")
VOLATILE = {
    "user-pool": ("EstimatedNumberOfUsers",),
    "trigger-lambda": ("State", "StateReason", "StateReasonCode", "LastUpdateStatus", "LastUpdateStatusReason",
                       "LastUpdateStatusReasonCode"),
    "lambda": ("State", "StateReason", "StateReasonCode", "LastUpdateStatus", "LastUpdateStatusReason",
               "LastUpdateStatusReasonCode"),
    "iam-role": ("RoleLastUsed",),
}
MASKS = [
    (re.compile(r"[a-z]{2}-[a-z]+-[0-9]_[A-Za-z0-9]{6,}"), "<user-pool>"),
    (re.compile(r"[a-z]{2}-[a-z]+-[0-9]:[0-9a-f-]{36}"), "<identity-pool>"),
    (re.compile(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"), "<id>"),
    (re.compile(r"[0-9]{12}"), "<account>"),
    (re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"), "<email>"),
]
# Any run of 10 or more letters and digits that has a digit (app ids, client ids, hashes in generated names).
TOKEN = re.compile(r"[A-Za-z0-9]{10,}")


def label(name):
    text = name
    for pattern, replacement in MASKS:
        text = pattern.sub(replacement, text)
    return TOKEN.sub(lambda m: "<id>" if any(c.isdigit() for c in m.group()) else m.group(), text)


def canonical(doc):
    return json.dumps(doc, sort_keys=True, separators=(",", ":"))


SNAPSHOT_VERSION = 2
# IAM policy keys whose value is a set of strings, written as one string or a list.
POLICY_SET_KEYS = {"Action", "NotAction", "Resource", "NotResource"}
PRINCIPAL_SET_KEYS = {"Service", "AWS", "Federated", "CanonicalUser"}
# Cognito list fields with no order.
COGNITO_SET_KEYS = {"AutoVerifiedAttributes", "UsernameAttributes", "AliasAttributes", "ExplicitAuthFlows",
                    "CallbackURLs", "LogoutURLs", "SupportedIdentityProviders", "ReadAttributes", "WriteAttributes"}
# Lists whose order matters: normalized inside, never sorted.
ORDERED_KEYS = {"Layers"}


def as_sorted_set(value):
    """A string or a list of strings as a sorted list: "x" is ["x"]."""
    values = value if isinstance(value, list) else [value]
    return sorted(values, key=canonical)


def sorted_by_canonical(values):
    return sorted(values, key=canonical)


def normalize(value, key=None):
    """The document with every unordered list sorted (see the module's doc). Idempotent."""
    if isinstance(value, dict):
        out = {}
        for name, child in value.items():
            if name == "Statement":
                statements = child if isinstance(child, list) else [child]
                out[name] = sorted_by_canonical([normalize(s, name) for s in statements])
            elif name == "Principal" and isinstance(child, dict):
                out[name] = {k: as_sorted_set(v) if k in PRINCIPAL_SET_KEYS and isinstance(v, (str, list)) else
                             normalize(v, k) for k, v in child.items()}
            elif name in POLICY_SET_KEYS and isinstance(child, (str, list)):
                out[name] = as_sorted_set(child)
            elif name == "Condition" and isinstance(child, dict):
                out[name] = {operator: {k: as_sorted_set(v) if isinstance(v, (str, list, bool, int, float)) else
                                        normalize(v, k) for k, v in keys.items()}
                             if isinstance(keys, dict) else normalize(keys, operator)
                             for operator, keys in child.items()}
            else:
                out[name] = normalize(child, name)
        return out
    if isinstance(value, list):
        items = [normalize(v, key) for v in value]
        if key in ORDERED_KEYS:
            return items
        if key == "Tags" or key == "TagSet" or key == "TagList" or key == "CognitoIdentityProviders":
            return sorted_by_canonical(items)
        if key == "SchemaAttributes":
            return sorted(items, key=lambda a: (a.get("Name", "") if isinstance(a, dict) else "", canonical(a)))
        if (key in COGNITO_SET_KEYS or (key or "").startswith("AllowedOAuth")) \
                and all(not isinstance(v, (dict, list)) for v in items):
            return sorted_by_canonical(items)
        return items
    return value


def doc_hash(doc):
    return hashlib.sha256(canonical(normalize(doc)).encode()).hexdigest()


def key_of(kind, identifier):
    return f"{kind}:{hashlib.sha256(identifier.encode()).hexdigest()[:16]}"


def write_private(path, value):
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        json.dump(value, f, indent=1, sort_keys=True)
        f.write("\n")
    os.chmod(path, 0o600)


def build(raw_path, out_path, tag_value):
    entries, docs, counts = {}, {}, {}
    with open(raw_path) as f:
        for line in f:
            if not line.strip():
                continue
            row = json.loads(line)
            doc = row["doc"]
            if isinstance(doc, dict):
                doc = {k: v for k, v in doc.items() if k not in VOLATILE.get(row["kind"], ())}
            key = key_of(row["kind"], row["id"])
            entries[key] = {"kind": row["kind"], "label": label(row["name"]),
                            "ours": bool(OURS.search(row["name"])),
                            "sha256": doc_hash(doc)}
            docs[key] = doc
            counts[row["kind"]] = counts.get(row["kind"], 0) + 1
    snapshot = {"version": SNAPSHOT_VERSION, "tag": tag_value, "counts": counts, "entries": entries}
    write_private(out_path, snapshot)
    write_private(docs_path(out_path), docs)
    ours = sum(1 for e in entries.values() if e["ours"])
    print(f"Wrote {out_path} (and its .docs.json), mode 600: {len(entries)} resources, {ours} of them ccit-ci-.")
    for kind in sorted(counts):
        print(f"  {kind}: {counts[kind]}")


def docs_path(snapshot_path):
    base = snapshot_path[:-5] if snapshot_path.endswith(".json") else snapshot_path
    return base + ".docs.json"


def load(path):
    with open(path) as f:
        return json.load(f)


def changed_fields(before, after):
    """The names of the fields where two documents differ, and of their differing subfields one level down."""
    if not (isinstance(before, dict) and isinstance(after, dict)):
        return ["(document)"]
    paths = []
    for name in sorted(set(before) | set(after)):
        old, new = before.get(name), after.get(name)
        if old == new:
            continue
        if isinstance(old, dict) and isinstance(new, dict):
            paths += [f"{name}.{sub}" for sub in sorted(set(old) | set(new)) if old.get(sub) != new.get(sub)] or [name]
        else:
            paths.append(name)
    return paths


def verify(before_path, after_path, allow_foreign):
    before, after = load(before_path), load(after_path)
    before_docs = load(docs_path(before_path)) if os.path.exists(docs_path(before_path)) else {}
    after_docs = load(docs_path(after_path)) if os.path.exists(docs_path(after_path)) else {}
    a, b = before["entries"], after["entries"]
    # With both sides' documents, hash them again normalized: the same rule whatever version each was written by.
    if before_docs and after_docs:
        a = {k: dict(v, sha256=doc_hash(before_docs[k])) if k in before_docs else v for k, v in a.items()}
        b = {k: dict(v, sha256=doc_hash(after_docs[k])) if k in after_docs else v for k, v in b.items()}
    elif before.get("version", 1) != after.get("version", 1):
        print(f"FAIL: the snapshots are versions {before.get('version', 1)} and {after.get('version', 1)}, and "
              "without both .docs.json files their hashes cannot be compared. Take both again.")
        return 1
    changed_all = sorted(k for k in a if k in b and a[k]["sha256"] != b[k]["sha256"])
    changed = [k for k in changed_all if not a[k]["ours"]]
    ours_changed = [k for k in changed_all if a[k]["ours"]]
    removed = sorted(k for k in a if k not in b)
    added = sorted(k for k in b if k not in a)
    ours_added = [k for k in added if b[k]["ours"]]
    aws_managed_added = [k for k in added if not b[k]["ours"] and aws_managed(b[k])]
    foreign_added = [k for k in added if not b[k]["ours"] and not aws_managed(b[k])]
    failed = False
    for key in changed:
        fields = ""
        if key in before_docs and key in after_docs:
            fields = ": " + ", ".join(changed_fields(before_docs[key], after_docs[key]))
        print(f"CHANGED  {a[key]['kind']} {a[key]['label']}{fields}")
        failed = True
    for key in ours_changed:
        fields = ""
        if key in before_docs and key in after_docs:
            fields = ": " + ", ".join(changed_fields(before_docs[key], after_docs[key]))
        print(f"changed  {a[key]['kind']} {a[key]['label']}{fields} (ccit-ci-, this script's own)")
    for key in removed:
        print(f"REMOVED  {a[key]['kind']} {a[key]['label']}")
        failed = True
    for key in foreign_added:
        print(f"ADDED    {b[key]['kind']} {b[key]['label']} (not ccit-ci-{'; allowed' if allow_foreign else ''})")
        failed = failed or not allow_foreign
    for key in ours_added:
        print(f"added    {b[key]['kind']} {b[key]['label']} (ccit-ci-, expected)")
    for key in aws_managed_added:
        print(f"added    {b[key]['kind']} {b[key]['label']} (AWS-managed, made by AWS on first use)")
    print(f"{len(a)} resources before, {len(b)} after: {len(changed)} changed, {len(ours_changed)} ccit-ci- changed, "
          f"{len(removed)} removed, {len(ours_added)} ccit-ci- added, {len(aws_managed_added)} AWS-managed added, "
          f"{len(foreign_added)} other added.")
    if failed:
        print("FAIL: an existing resource changed, was removed, or one that is not ccit-ci- appeared.")
        return 1
    print("OK: every resource in the first snapshot that is not ccit-ci- is unchanged.")
    return 0


def aws_managed(entry):
    """An AWS-managed KMS alias (alias/aws/<service>), which AWS makes the first time a service uses its key."""
    return entry["kind"] == "kms-alias" and entry["label"].startswith("alias/aws/")


def main(argv):
    if len(argv) == 4 and argv[0] == "build":
        build(argv[1], argv[2], argv[3])
        return 0
    if len(argv) in (3, 4) and argv[0] == "verify" and (len(argv) == 3 or argv[3] == "--allow-foreign-additions"):
        return verify(argv[1], argv[2], len(argv) == 4)
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
