#!/bin/sh

# This script generates API documentation using jazzy.
# It requires jazzy.

set -e

REPO="aws-amplify/amplify-swift.git"

git clone git@github.com:$REPO $(mktemp -d -t amplify-release)
TEMP_DIR=$_

echo "Temporary Directory: $TEMP_DIR"

generate_docs() {
    cd $TEMP_DIR
    git checkout gh-pages
    git reset --hard origin/release
    pod install
    gem install -n /usr/local/bin jazzy
    jazzy && ln -s ../readme-images docs
    git add docs
    git commit -m "chore: update API docs [skip ci]"
    git push --force
}

generate_docs

set +e