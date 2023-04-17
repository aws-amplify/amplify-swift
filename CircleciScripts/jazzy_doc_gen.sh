#!/bin/sh

# This script generates API documentation using jazzy.
# It requires jazzy.

set -e

echo "Working Directory: $CIRCLE_WORKING_DIRECTORY"

git config user.email $GITHUB_EMAIL
git config user.name $GITHUB_USER

cd $CIRCLE_WORKING_DIRECTORY
bundle exec jazzy --swift-build-tool spm --build-tool-arguments -Xswiftc,-swift-version,-Xswiftc,5
ln -s ../readme-images docs
git add docs
git commit -m "chore: update API docs [skip ci]"
git push origin HEAD:gh-pages -f

set +e
