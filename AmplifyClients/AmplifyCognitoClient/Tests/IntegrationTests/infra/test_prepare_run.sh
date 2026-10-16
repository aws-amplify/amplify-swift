#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Self-test for prepare-run.sh's create_user_unless_created: a user created, one an overlapping run created first
# (which must not stop the run), and any other error (which must). A fake `aws` on PATH answers; no AWS call is made
# and prepare-run.sh itself never runs.
#
#   bash infra/test_prepare_run.sh
set -euo pipefail
P="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/prepare-run.sh"
BIN=$(mktemp -d)
trap 'rm -rf "$BIN"' EXIT
cat > "$BIN/aws" <<'EOF'
#!/usr/bin/env bash
case "$FAKE" in
  created) echo '{"User": {}}' ;;
  exists) echo "An error occurred (UsernameExistsException) when calling the AdminCreateUser operation: User account already exists" >&2; exit 254 ;;
  denied) echo "An error occurred (AccessDeniedException) when calling the AdminCreateUser operation: denied" >&2; exit 254 ;;
esac
EOF
chmod +x "$BIN/aws"
export PATH="$BIN:$PATH"
# shellcheck disable=SC2034  # read by the function under test
REGION=xx-test-1 USER_POOL_ID=placeholder-pool
redact() { cat; }
require_user_pool_tag() { :; }
eval "$(python3 - "$P" <<'PY'
import sys
s = open(sys.argv[1]).read()
start = s.index("create_user_unless_created() {")
print(s[start:s.index("\n}\n", start) + 3])
PY
)"
export FAKE=created
[[ $(create_user_unless_created erin) == "Created user erin" ]] || { echo "FAIL created"; exit 1; }
echo "ok created"
export FAKE=exists
[[ $(create_user_unless_created erin) == "erin: already created by another run" ]] || { echo "FAIL exists"; exit 1; }
echo "ok created by another run first does not stop the run"
export FAKE=denied
if out=$( (create_user_unless_created erin) 2>&1 ); then
    echo "FAIL denied read as '$out'"
    exit 1
fi
[[ "$out" == *AccessDeniedException* ]] || { echo "FAIL denied: '$out'"; exit 1; }
echo "ok any other error stops"
