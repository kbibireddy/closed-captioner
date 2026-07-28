#!/bin/sh
set -euo pipefail

# Xcode Cloud runs this after cloning the repository.
# ClosedCaptioner has no CocoaPods, Carthage, or Swift Package dependencies to resolve.

echo "ci_post_clone: repository ready"
