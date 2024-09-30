#!/bin/bash

set -e

# This script selects the Git reference for a locally installed dependency of another "original" repo.
# It matches the original's checked-out branch name if available, and if not, falls back to main.

# Checks to see if Git repository at DEPENDENCY_REPO_URL has a branch named ORIGINAL_REPO_HEAD_REF.
# If so, the latest SHA for that branch is obtained and stored as DEPENDENCY_REPO_SHA in the Github env.
#
# If a branch named ORIGINAL_REPO_HEAD_REF does not exist in the Git repository at DEPENDENCY_REPO_URL,
# the SHA for the main branch is obtained and stored as DEPENDENCY_REPO_SHA in the Github env.

# Parameters:
#   ORIGINAL_REPO_HEAD_REF : the branch or tag name for the original repo branch being built.
#   DEPENDENCY_REPO_URL : the URL to the dependency that will be matched to the branch

# Output:
#   DEPENDENCY_REPO_SHA : the Git SHA for the dependency repo commit to be built (set in the Github environment)

echo "Finding correct branch for dependency repo: $DEPENDENCY_REPO_URL"
DEPENDENCY_BRANCH_SHA=`git ls-remote --heads "$DEPENDENCY_REPO_URL" "refs/heads/$ORIGINAL_REPO_HEAD_REF" | awk '{print $1}'`
if [[ ! -z "${DEPENDENCY_BRANCH_SHA}" ]]; then
  echo "Ref $ORIGINAL_REPO_HEAD_REF was found on dependency repo at SHA $DEPENDENCY_BRANCH_SHA"
  echo "Selecting dependency repo branch $ORIGINAL_REPO_HEAD_REF at $DEPENDENCY_BRANCH_SHA"
  echo "DEPENDENCY_REPO_SHA=$DEPENDENCY_BRANCH_SHA" >> "$GITHUB_ENV"
else
  echo "Ref $ORIGINAL_REPO_HEAD_REF was not found on dependency repo at SHA $DEPENDENCY_BRANCH_SHA"
  DEPENDENCY_MAIN_SHA=`git ls-remote --heads "$ORIGINAL_REPO_HEAD_REF" "refs/heads/main" | awk '{print $1}'`
  echo "Selecting dependency repo main branch at $DEPENDENCY_MAIN_SHA"
  echo "DEPENDENCY_REPO_SHA=$DEPENDENCY_MAIN_SHA" >> "$GITHUB_ENV"
fi

