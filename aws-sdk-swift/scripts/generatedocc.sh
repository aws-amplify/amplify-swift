#!/bin/bash
# generate docs for all packages in a swift package

# Create temporary dir for staging docs
OUTPUT_DIR=`mktemp -d`

usage() {
    echo "Usage:"
    echo "  ./scripts/generatedocc [version] [currentJob] [totalJobs] [ignorelist]"
    echo ""
    echo "Example:"
    echo " ./scripts/generatedocc 0.7.0 0 16 AWSBatch,AWSIoTAnalytics"
}

# Generates docs for one Swift package and uploads them to S3.
# Takes the package name and version as parameters.
generateDocs() {
    package=$1
    VERSION=$2

    # Change the package name to lowercase
    package_lowercase=$(echo $package | tr '[:upper:]' '[:lower:]')

    # generate docs for version
    echo "Generating docs for $package $VERSION"
    swift package \
            --allow-writing-to-directory $OUTPUT_DIR \
            generate-documentation \
            --target $package \
            --disable-indexing \
            --transform-for-static-hosting \
            --output-path $OUTPUT_DIR/$package_lowercase-$VERSION.doccarchive \
            --hosting-base-path swift/api/$package_lowercase/$VERSION

    # break if swift package generate-documentation fails
    if [ $? -ne 0 ]; then
        echo "Failed to generate docs for $package $VERSION"
        exit 1
    else
        echo "Generating docs complete"
    fi

    # Delete any old version of this doccarchive before upload
    aws s3 rm --recursive --only-show-errors \
      s3://$DOCS_BUCKET/$package-lowercase-$VERSION.doccarchive

    # copy the new docs to AWS S3
    echo "Copying doccarchive to S3 for $package_lowercase-$VERSION"
    aws s3 cp --recursive --only-show-errors \
      $OUTPUT_DIR/$package_lowercase-$VERSION.doccarchive \
      s3://$DOCS_BUCKET/$package_lowercase-$VERSION.doccarchive

    # break if S3 copy fails
    if [ $? -ne 0 ]; then
        echo "Failed to copy $package_lowercase-$VERSION"
        exit 1
    else
        echo "$package_lowercase-$VERSION copied successfully"
    fi

    # delete docs from temp files
    rm -rf $OUTPUT_DIR/*
}

# Break if all params aren't supplied
if [ $# -ne 5 ]; then
    usage
    exit 1
fi

VERSION="$1"
CURRENT_JOB="$2"
TOTAL_JOBS="$3"

# convert comma separated ignore list to array
IGNORE=($(echo $4 | tr ',' '\n'))

IS_AWS="$5"

echo "Finding package names, unquoting names, sorting"
packages=$(swift package dump-package | jq '.products[].name' | sed 's/"//g' | sort)

# loop through each package with index
current=0
for package in $packages; do
    # skip if not current job
    if [ $((current % TOTAL_JOBS)) -ne $CURRENT_JOB ]; then
        current=$((current + 1))
        continue
    fi

    # skip if in ignore list
    if [[ " ${IGNORE[@]} " =~ " ${package} " ]]; then
        echo "Skipping $package"
        current=$((current + 1))
        continue
    fi

    generateDocs "$package" "$VERSION"

    current=$((current + 1))
done

# Generate an index with the current version, and
# the literal version "latest"
if [ $CURRENT_JOB -eq 0 -a $IS_AWS -eq 1 ]; then
  generateDocs "AWSSDKForSwift" "$VERSION"
  generateDocs "AWSSDKForSwift" "latest"
fi
