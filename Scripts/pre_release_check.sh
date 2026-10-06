#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PROJECT="Scarlight.xcodeproj"
SCHEME="Scarlight"
# Use the installed Xcode without changing the machine's global xcode-select setting.
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
SIMULATOR_ID=""
if [[ -n "${SCARLIGHT_DESTINATION:-}" ]]; then
  DESTINATION="$SCARLIGHT_DESTINATION"
else
  SIMULATOR_ID="$(xcrun simctl list devices available --json | python3 -c '
import json, os, sys
name = os.environ.get("SCARLIGHT_SIMULATOR_NAME")
devices = [d for values in json.load(sys.stdin)["devices"].values() for d in values
           if d.get("isAvailable") and "iPhone" in d["name"] and not d["name"].startswith("Clone")]
if name:
    devices = [d for d in devices if d["name"] == name]
devices.sort(key=lambda d: d["state"] != "Booted")
if not devices:
    sys.exit("Kullanılabilir iPhone simülatörü yok. Xcode > Settings > Components üzerinden iOS Simulator yükleyin.")
print(devices[0]["udid"])
')"
  DESTINATION="platform=iOS Simulator,id=$SIMULATOR_ID"
fi
DERIVED_DATA="${SCARLIGHT_DERIVED_DATA:-/tmp/scarlight-pre-release-derived}"
XCODEBUILD_COMMON=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -destination "$DESTINATION"
  -destination-timeout 120
  -derivedDataPath "$DERIVED_DATA"
)

if [[ -n "$SIMULATOR_ID" ]]; then
  xcrun simctl bootstatus "$SIMULATOR_ID" -b
fi

echo "== Content audit =="
python3 Tools/content_audit.py --strict-warnings

echo "== Unit tests =="
echo "Destination: $DESTINATION"
xcodebuild test "${XCODEBUILD_COMMON[@]}" -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO

echo "== Release build =="
xcodebuild build "${XCODEBUILD_COMMON[@]}" -configuration Release CODE_SIGNING_ALLOWED=NO

echo "== Diff whitespace check =="
git diff --check

echo "Pre-release check passed."
