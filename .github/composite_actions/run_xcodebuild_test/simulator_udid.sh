#!/bin/bash
# Prints the UDID of the simulator an xcodebuild destination names, by `id=`, or by `name=` and `OS=` (an
# available device of that name on that runtime; any runtime for `OS=latest` or none). Prints nothing for a
# destination that names no simulator, such as `platform=macOS`, or when no such device exists.
set -o pipefail
destination="$1"

udid=""; name=""; os=""
IFS=, read -ra parts <<< "$destination"
for part in "${parts[@]}"; do
  case "$part" in
    id=*) udid="${part#id=}" ;;
    name=*) name="${part#name=}" ;;
    OS=*) os="${part#OS=}" ;;
  esac
done
if [ -z "$udid" ] && [ -n "$name" ]; then
  runtime_suffix=""
  if [ -n "$os" ] && [ "$os" != "latest" ]; then runtime_suffix="-${os//./-}"; fi
  udid=$(xcrun simctl list devices available -j | jq -r --arg name "$name" --arg suffix "$runtime_suffix" \
    '.devices | to_entries[] | select(.key | endswith($suffix)) | .value[] | select(.name == $name) | .udid' | head -n 1)
fi
echo "$udid"
