#!/usr/bin/env bash
# Low-memory xcodebuild test runner for Instance 2's Services suite.
#
# Why this script exists: a default `xcodebuild test` on this project compiles
# the full app + tests + every SPM dependency (Supabase, RevenueCat, Sentry,
# PostHog, Kingfisher) across all 10 cores, then boots an iPhone simulator on
# top. On a 16 GB Mac that combination thrashes swap and crashes the OS.
#
# We trade wall-clock time for headroom:
#   • -jobs 2                                     → cap parallel compile at 2 cores
#   • -parallel-testing-enabled NO                → run test cases serially
#   • -maximum-concurrent-test-simulator-destinations 1
#   • -only-testing:HerbLensTests/Services        → skip Shared tests we don't need
#   • COMPILER_INDEX_STORE_ENABLE=NO              → no index-while-building
#   • SWIFT_COMPILATION_MODE=singlefile           → lower per-job RSS
#   • Smallest available sim (iPhone 16e if present)
#   • Output piped to a logfile; only the tail surfaces unless you pass --verbose
set -euo pipefail

DEVELOPER_DIR=${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}
export DEVELOPER_DIR

PROJECT_DIR=/Users/amadeobonde/Desktop/HerbLens/HerbLens
LOG_DIR=/Users/amadeobonde/Desktop/HerbLens/scripts/.logs
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test-services-$(date +%Y%m%d-%H%M%S).log"

# Pick the lightest available iPhone simulator runtime so we don't boot a big device.
DEVICE=$(xcrun simctl list devices available | grep -E "iPhone (16e|17 Pro|17|Air)" | head -n 1 | sed -E 's/.*(iPhone [^()]+) \(([A-F0-9-]+)\).*/\2/')
if [[ -z "$DEVICE" ]]; then
  echo "No iPhone simulator found via simctl; falling back to platform-only destination."
  DESTINATION="platform=iOS Simulator,name=iPhone 17 Pro,OS=latest"
else
  DESTINATION="id=$DEVICE"
fi

VERBOSE=0
ACTION="test"
for arg in "$@"; do
  case "$arg" in
    --verbose) VERBOSE=1 ;;
    --build-only) ACTION="build" ;;
    # Compile both the app and the test bundle without running tests.
    # Cheapest way to surface remaining test-target compile errors.
    --build-tests-only) ACTION="build-for-testing" ;;
    --test-without-build) ACTION="test-without-building" ;;
  esac
done

echo "Logging to: $LOG_FILE"
echo "Destination: $DESTINATION"
echo "Action: $ACTION"
echo

cd "$PROJECT_DIR"

CMD=(
  xcodebuild "$ACTION"
  -project HerbLens.xcodeproj
  -scheme HerbLens
  -configuration Debug
  -destination "$DESTINATION"
  -jobs 2
  -parallel-testing-enabled NO
  -maximum-concurrent-test-simulator-destinations 1
  -disableAutomaticPackageResolution
  -skipPackagePluginValidation
  -skipMacroValidation
  COMPILER_INDEX_STORE_ENABLE=NO
  SWIFT_COMPILATION_MODE=singlefile
  ONLY_ACTIVE_ARCH=YES
)

if [[ "$ACTION" == "test" || "$ACTION" == "test-without-building" ]]; then
  # Skip UI tests (they boot the full app and are wildly RAM-heavy). The
  # HerbLensTests bundle holds all Swift Testing suites — Shared's from Instance 1
  # and Services' from Instance 2.
  CMD+=(-skip-testing:HerbLensUITests)
fi

set +e
"${CMD[@]}" >"$LOG_FILE" 2>&1
STATUS=$?
set -e

if [[ "$VERBOSE" == "1" ]]; then
  cat "$LOG_FILE"
else
  # Surface compiler errors and the trailing pass/fail line — that's almost always
  # all we need to drive the next iteration.
  grep -E "error:|warning:|Test Suite|Executed|tests passed|tests failed|\*\* (BUILD|TEST) (SUCCEEDED|FAILED)" "$LOG_FILE" | tail -80
fi

exit $STATUS
