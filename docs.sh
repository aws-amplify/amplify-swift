#!/bin/bash

## Requirements: https://github.com/realm/jazzy
## [sudo] gem install jazzy


jazzy \
  --min-acl internal \
  --theme fullwidth \
  --author AWS \
  --author_url https://aws.amazon.com/amplify \
  --github_url https://github.com/aws-amplify/amplify-ios \
  --github-file-prefix https://github.com/aws-amplify/amplify-ios/tree/master \