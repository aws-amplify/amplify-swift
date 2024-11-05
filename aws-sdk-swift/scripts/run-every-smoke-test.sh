#!/bin/bash

# This is a convenience script for developers for running every smoke test under SmokeTests/.
# The script must be run from aws-sdk-swift/, the directory containing SmokeTests/.

# cd into test module dir
cd SmokeTests/ || { echo "ERROR: Failed to change directory to SmokeTests."; exit 1; }

# Build and discard output for clean log
echo "INFO: Building SmokeTests module..."
swift build > /dev/null 2>&1

# Header print helpers
print_header() {
  print_spacer
  local header=$1
  echo "##### $header #####"
  print_spacer
}

print_spacer() {
  echo ""
}

# Build and run each and every test runner; save result to results array
print_header "TEST RUNS"
results=()
for runnerName in ./*; do
    if [ -d "$runnerName" ]; then
      swift run "${runnerName#./}"
      if [ $? -eq 0 ]; then
        # Record success
        results+=("SUCCESS: ${runnerName#./}")
      else
        # record failure
        results+=("FAILURE: ${runnerName#./}")
      fi
      print_spacer
    fi
done

# Print result summary
print_header "TEST RESULT SUMMARY"
for result in "${results[@]}"; do
  echo "$result"
done
