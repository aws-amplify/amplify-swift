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
#   aws s3 cp <AWS_S3_BUCKET_INTEG_V2>/auth/ <dest-dir> --recursive
#
# The secret's value is a bucket with a path, s3://<bucket>/<path>, the folder that holds auth/. It and the profile
# are read from the environment, never from the repository:
#
#   COGNITO_CLIENT_INTEG_CI_BUCKET   the value of CI's AWS_S3_BUCKET_INTEG_V2: `s3://<bucket>/<path>`, with or without
#                                    s3:// and a trailing slash; a bare bucket, for a configuration at its root
#   COGNITO_CLIENT_INTEG_CI_PROFILE  an AWS CLI profile that can read it
#
#   infra/fetch-ci-config.sh [--dry-run] <dest-dir>
#
# <dest-dir> must be an existing, empty directory (`mktemp -d`). The script refuses one inside ~/.aws-amplify,
# which holds your own plugin configuration, symlinks resolved, so nothing there is ever overwritten. The files
# are written mode 600. `--dry-run` makes every check and prints the command, with the bucket and the path
# masked, without calling AWS. Nothing prints the bucket, the path or an identifier: the AWS CLI's error output is
# masked too.
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
    echo "Refusing: set COGNITO_CLIENT_INTEG_CI_BUCKET (CI's AWS_S3_BUCKET_INTEG_V2, s3://<bucket>/<path>, the folder" \
        "that holds auth/) and COGNITO_CLIENT_INTEG_CI_PROFILE (an AWS CLI profile that can read it)." >&2
    exit 1
fi
BUCKET="${BUCKET%/}"
BUCKET="${BUCKET#s3://}"
if [[ ! "$BUCKET" =~ ^([a-z0-9][a-z0-9.-]{1,61}[a-z0-9])(/([A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*))?$ ]] \
    || [[ "$BUCKET" == *..* ]]; then
    echo "Refusing: COGNITO_CLIENT_INTEG_CI_BUCKET must be s3://<bucket>/<path> (CI's AWS_S3_BUCKET_INTEG_V2), or a" \
        "bucket, with or without s3://." >&2
    exit 1
fi
BUCKET_NAME="${BASH_REMATCH[1]}"
CONFIG_PATH="${BASH_REMATCH[3]}"
if [[ "$CONFIG_PATH" == auth || "$CONFIG_PATH" == */auth ]]; then
    echo "Refusing: COGNITO_CLIENT_INTEG_CI_BUCKET names the auth/ folder itself; give the folder that holds it, as" \
        "CI's AWS_S3_BUCKET_INTEG_V2 does." >&2
    exit 1
fi
SOURCE="s3://$BUCKET_NAME${CONFIG_PATH:+/$CONFIG_PATH}/auth/"
SHOWN="s3://<bucket>${CONFIG_PATH:+/<path>}/auth/"

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
    echo "Would run: aws s3 cp $SHOWN $DEST --recursive --profile <profile>"
    exit 0
fi

umask 077
ERR="$(mktemp "${TMPDIR:-/tmp}/fetch-ci-config.XXXXXX")"
trap 'rm -f "$ERR"' EXIT
status=0
command aws s3 cp "$SOURCE" "$DEST" --recursive --only-show-errors --profile "$PROFILE" 2>"$ERR" || status=$?
# The CLI's errors name the bucket, the path and the profile: mask them (as literal text), then every other
# identifier.
sed_literal() { printf '%s' "$1" | sed -e 's/[][\\.*^$#/]/\\&/g'; }
masks=(-e "s#$(sed_literal "$BUCKET_NAME")#<bucket>#g" -e "s#$(sed_literal "$PROFILE")#<profile>#g")
[[ -z "$CONFIG_PATH" ]] || masks+=(-e "s#$(sed_literal "$CONFIG_PATH")#<path>#g")
sed "${masks[@]}" "$ERR" | redact >&2
if (( status != 0 )); then
    echo "The download failed (exit $status). Check the profile's credentials and access to the bucket." >&2
    exit "$status"
fi
find "$DEST" -type f -exec chmod 600 {} +
count=$(find "$DEST" -type f | wc -l | tr -d ' ')
echo "Downloaded $count files into $DEST:"
(cd "$DEST" && find . -type f | sed 's#^\./#  #' | sort)
