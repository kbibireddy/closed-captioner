#!/bin/sh
set -euo pipefail

# Set a unique build number for each Xcode Cloud build.
# App Store Connect rejects duplicate CFBundleVersion values.

cd "${CI_PRIMARY_REPOSITORY_PATH}"

if [ -z "${CI_BUILD_NUMBER:-}" ]; then
  echo "ci_pre_xcodebuild: CI_BUILD_NUMBER not set, skipping version bump"
  exit 0
fi

echo "ci_pre_xcodebuild: setting build number to ${CI_BUILD_NUMBER}"
xcrun agvtool new-version -all "${CI_BUILD_NUMBER}"
