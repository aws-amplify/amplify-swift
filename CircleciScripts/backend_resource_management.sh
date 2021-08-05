#!/bin/bash

set -x
set -e

# This bucket contains a collection of config files that are used by the
# integration tests. The configuration files contain sensitive
# tokens/credentials/identifiers, so are not published publicly.
readonly config_bucket=$1
readonly schema=$2

if [ $schema == "AWSS3StoragePluginFunctionalTests" ]; then
    aws s3 cp "s3://$config_bucket/$schema/amplifyconfiguration.json" "$schema/AWSS3StoragePluginTests-amplifyconfiguration.json"
    aws s3 cp "s3://$config_bucket/$schema/credentials.json" "$schema/AWSS3StoragePluginTests-credentials.json"
fi

wait
