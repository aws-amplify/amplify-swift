#!/usr/bin/env bash
#
# Copyright Amazon.com Inc. or its affiliates.
# All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Self-test for teardown.sh's read_tag: a tag, a resource already gone, and any other error (which must
# stop the teardown). A fake `aws` on PATH answers; no AWS call is made and teardown.sh itself never runs.
#
#   bash infra/test_teardown.sh
set -euo pipefail
T="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/teardown.sh"
BIN=$(mktemp -d)
cat > "$BIN/aws" <<'EOF'
#!/usr/bin/env bash
case "$FAKE" in
  tagged) echo "amplify-cognito-client-integ" ;;
  gone) echo "An error occurred (ResourceNotFoundException) when calling ..." >&2; exit 254 ;;
  denied) echo "An error occurred (AccessDeniedException) when calling ..." >&2; exit 254 ;;
esac
EOF
chmod +x "$BIN/aws"
export PATH="$BIN:$PATH"
REGION=xx-test-1
redact() { cat; }
eval "$(python3 - "$T" <<'PY'
import sys
s = open(sys.argv[1]).read()
start = s.index("read_tag() {")
print(s[start:s.index("\n}\n", start) + 3])
PY
)"
export FAKE=tagged; [[ $(read_tag x) == "amplify-cognito-client-integ" ]] || { echo "FAIL tagged"; exit 1; }; echo "ok tagged"
export FAKE=gone; [[ $(read_tag x) == "__gone__" ]] || { echo "FAIL gone"; exit 1; }; echo "ok gone"
export FAKE=denied; if tag=$(read_tag x 2>/dev/null); then echo "FAIL denied read as '$tag'"; exit 1; else echo "ok denied stops"; fi
rm -rf "$BIN"
