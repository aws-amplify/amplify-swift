#!/bin/bash

set -e

echo

# Log OS version (sw_vers on Mac, uname -a on Linux)

if command -v sw_vers &> /dev/null
then
  sw_vers
else
  uname -a
fi



# Log CPU for hardware in use, if running on Mac

if [[ "$OSTYPE" == "darwin"* ]];
then
  which sysctl
  sysctl -a | grep machdep.cpu || true
else
  echo "sysctl not run (not a Mac)"
fi
echo

# Log location & version for swiftc, xcodebuild, java, xcbeautify

if command -v swiftc &> /dev/null
then
  which swiftc
  swiftc --version
else
  echo "swiftc not installed"
fi
echo

if command -v xcodebuild &> /dev/null
then
  which xcodebuild
  xcodebuild -version
else
  echo "xcodebuild not installed"
fi
echo

if command -v java &> /dev/null
then
  which java
  java --version
else
  echo "java not installed"
fi
echo

if command -v kotlin &> /dev/null
then
  which kotlin
  kotlin -version
else
  echo "kotlin not installed"
fi
echo

if command -v xcbeautify &> /dev/null
then
  which xcbeautify
  xcbeautify --version
else
  echo "xcbeautify not installed"
fi
