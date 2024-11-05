#!/bin/bash

# This script must be run from the directory containing aws-sdk-swift.
SMOKE_TESTS_DIR="aws-sdk-swift/SmokeTests/"
cd "$SMOKE_TESTS_DIR" || { echo "ERROR: Failed to change directory to $SMOKE_TESTS_DIR"; exit 1; }

print_header() {
  local header=$1
  print_empty_line
  echo "##### $header #####"
  print_empty_line
}

print_empty_line() {
  echo ""
}

print_header "SETUP SMOKE TESTS"

# Clean build
swift package clean > /dev/null 2>&1

# Expect comma-separated service names from AWS_SMOKE_TEST_SERVICE_IDS environment variable.
# The service names in environment variable must be in the format "AWSName", e.g., "AWSS3".
# The resulting array will be in the format "AWSNameSmokeTestRunner", e.g., "AWSS3SmokeTestRunner".
if [ -z "$AWS_SMOKE_TEST_SERVICE_IDS" ]; then
  echo "INFO: The environment variable AWS_SMOKE_TEST_SERVICE_IDS is not set or is empty."
  echo "INFO: It must set to a comma-separated string of service names for which you want to run smoke test for."
  echo "INFO: Exiting run-smoke-tests.sh with exit code 0."
  exit 0
else
  IFS=',' read -r -a testRunnerNames <<< "$AWS_SMOKE_TEST_SERVICE_IDS"
  for i in "${!testRunnerNames[@]}"; do
    testRunnerNames[$i]="${testRunnerNames[$i]}SmokeTestRunner"
  done
  echo "INFO: Retrieved the value of AWS_SMOKE_TEST_SERVICE_IDS: $AWS_SMOKE_TEST_SERVICE_IDS."
  echo "INFO: Constructed test runner names: ${testRunnerNames[@]}"
fi

# Array of test failure logs.
testFailureLogs=()

print_header "RUN SMOKE TESTS"

for testRunnerName in "${testRunnerNames[@]}"; do
  # If test runner was generated under SmokeTests/
  if [ -d "$testRunnerName" ]; then
    echo "INFO: Found smoke tests for the service ${testRunnerName%SmokeTestRunner}."
    echo "INFO: Building smoke test(s) for the service ${testRunnerName%SmokeTestRunner}..."
    # Build the test runner executable (discard output for clean log)
    swift build --target "$testRunnerName" > /dev/null 2>&1
    echo "INFO: Running smoke test(s) for the service ${testRunnerName%SmokeTestRunner}..."
    # Run executable and save output to `testRunOutput`
    testRunOutput=$(swift run --quiet "$testRunnerName")
    # Get test runner exit code
    testRunExitCode=$?
    # If exit code was 1, one or more tests failed. Save its output to array.
    if [ "$testRunExitCode" -eq 1 ]; then
      testFailureLogs+=("$testRunOutput")
    fi
    print_empty_line
  # If no smoke tests were generated, no-op
  else
    echo "INFO: No smoke tests found for the service ${testRunnerName%SmokeTestRunner}. Skipping..."
    print_empty_line
  fi
done

print_header "SMOKE TEST RESULTS"

# Log any failure outputs if present and exit with 1
if [ ${#testFailureLogs[@]} -gt 0 ]; then
  echo "# One or more smoke test(s) failed. See the log(s) for failed test runner(s) below:"
  print_empty_line
  for failureLog in "${testFailureLogs[@]}"; do
    echo "${failureLog}"
    print_empty_line
  done
  exit 1
else
  echo "INFO: Every smoke test for every service passed!"
  exit 0
fi
