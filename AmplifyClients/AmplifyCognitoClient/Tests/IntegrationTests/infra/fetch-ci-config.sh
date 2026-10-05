#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Downloads the plugin's CI test configuration (the `auth` folder) into a directory of your own, for a local run
# of the client's integration tests on CI's file set. It runs the same command as
# .github/composite_actions/download_test_configuration (resource_subfolder: auth):
#
#   aws s3 cp <bucket>/auth/ <dest-dir> --recursive
#
# The bucket and the profile are read from the environment, never from the repository:
#
#   COGNITO_CLIENT_INTEG_CI_BUCKET   the bucket CI reads (its AWS_S3_BUCKET_INTEG_V2), `s3://<name>` or `<name>`
#   COGNITO_CLIENT_INTEG_CI_PROFILE  an AWS CLI profile that can read it
#
#   infra/fetch-ci-config.sh [--dry-run] <dest-dir>
#
# <dest-dir> must be an existing, empty directory (`mktemp -d`). The script refuses one inside ~/.aws-amplify,
# which holds your own plugin configuration, symlinks resolved, so nothing there is ever overwritten. The files
# are written mode 600. `--dry-run` makes every check and prints the command, with the bucket masked, without
# calling AWS. Nothing prints the bucket or an identifier: the AWS CLI's error output is masked too.
set -euo pipefail
INFRA="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$INFRA/lib.sh"

usage() {
    echo "Usage: infra/fetch-ci-config.sh [--dry-run] <dest-dir>" >&2
    exit 2
}

DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=1
    shift
fi
[[ $# -eq 1 && -n "$1" ]] || usage
DEST_ARG="$1"

BUCKET="${COGNITO_CLIENT_INTEG_CI_BUCKET:-}"
PROFILE="${COGNITO_CLIENT_INTEG_CI_PROFILE:-}"
if [[ -z "$BUCKET" || -z "$PROFILE" ]]; then
    echo "Refusing: set COGNITO_CLIENT_INTEG_CI_BUCKET (the bucket CI downloads its test configuration from) and" \
        "COGNITO_CLIENT_INTEG_CI_PROFILE (an AWS CLI profile that can read it)." >&2
    exit 1
fi
BUCKET="${BUCKET%/}"
[[ "$BUCKET" == s3://* ]] || BUCKET="s3://$BUCKET"
if [[ ! "$BUCKET" =~ ^s3://[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$ ]]; then
    echo "Refusing: COGNITO_CLIENT_INTEG_CI_BUCKET must be a bucket name, with or without s3://, and no path." >&2
    exit 1
fi

if [[ ! -d "$DEST_ARG" ]]; then
    echo "Refusing: $DEST_ARG is not a directory. Make one first: DIR=\$(mktemp -d /tmp/ccit-ci-set.XXXXXX)" >&2
    exit 1
fi
DEST="$(cd "$DEST_ARG" && pwd -P)"
# ~/.aws-amplify, resolved when it exists (it can be a symlink), and as written either way.
PROTECTED=("$HOME/.aws-amplify")
if [[ -d "$HOME/.aws-amplify" ]]; then
    PROTECTED+=("$(cd "$HOME/.aws-amplify" && pwd -P)")
fi
for protected in "${PROTECTED[@]}"; do
    if [[ "$DEST" == "$protected" || "$DEST" == "$protected"/* ]]; then
        echo "Refusing: $DEST_ARG is inside ~/.aws-amplify, which holds your own plugin configuration." \
            "Use a directory of its own: DIR=\$(mktemp -d /tmp/ccit-ci-set.XXXXXX)" >&2
        exit 1
    fi
done
if [[ -n "$(ls -A "$DEST")" ]]; then
    echo "Refusing: $DEST_ARG is not empty. Use a new directory, so no file of another set is mixed in." >&2
    exit 1
fi

if (( DRY_RUN )); then
    echo "Would run: aws s3 cp s3://<bucket>/auth/ $DEST --recursive --profile <profile>"
    exit 0
fi

umask 077
ERR="$(mktemp "${TMPDIR:-/tmp}/fetch-ci-config.XXXXXX")"
trap 'rm -f "$ERR"' EXIT
status=0
command aws s3 cp "$BUCKET/auth/" "$DEST" --recursive --only-show-errors --profile "$PROFILE" 2>"$ERR" || status=$?
# The CLI's errors name the bucket and the profile: mask both (as literal text), then every other identifier.
sed_literal() { printf '%s' "$1" | sed -e 's/[][\\.*^$#/]/\\&/g'; }
sed -e "s#$(sed_literal "${BUCKET#s3://}")#<bucket>#g" -e "s#$(sed_literal "$PROFILE")#<profile>#g" "$ERR" | redact >&2
if (( status != 0 )); then
    echo "The download failed (exit $status). Check the profile's credentials and access to the bucket." >&2
    exit "$status"
fi
find "$DEST" -type f -exec chmod 600 {} +
count=$(find "$DEST" -type f | wc -l | tr -d ' ')
echo "Downloaded $count files into $DEST:"
(cd "$DEST" && find . -type f | sed 's#^\./#  #' | sort)
